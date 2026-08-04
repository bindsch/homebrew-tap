#!/usr/bin/env bash
#
# Build a bottle for a tap formula, publish it as a tap release asset, and write
# the resulting `bottle do` block back into the formula.
#
# Bottles are per-OS/arch. This builds for the machine it runs on; platforms
# without a published bottle fall back to building from source, which is why a
# missing bottle is never fatal.
#
# Two failure modes this script exists to prevent:
#
#   1. Bottles are not byte-reproducible. Every rebuild produces a different
#      sha256, so a human pasting the block is one slip away from a formula that
#      cannot install. The block is written automatically instead.
#   2. Republishing a bottle for an already-published version reuses the asset
#      filename, leaving stale copies in Homebrew's download cache and behind
#      GitHub's CDN. Installs then fail with "Bottle reports different
#      checksum". The `rebuild` counter is bumped so the filename is distinct.
#
# Usage:
#   scripts/bottle.sh <formula>          # version read from the formula
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TAP="bindsch/tap"
readonly REPO="bindsch/homebrew-tap"

die() {
  printf 'bottle: %s\n' "$1" >&2
  exit 1
}

formula="${1:-}"
[ -n "$formula" ] || die "usage: $0 <formula>"
formula_file="${REPO_ROOT}/Formula/${formula}.rb"
[ -f "$formula_file" ] || die "no such formula: ${formula}"

command -v gh >/dev/null || die "gh CLI is required to publish the bottle"

# Ask Homebrew for the version rather than parsing the formula ourselves.
version="$(brew info --json=v2 "${TAP}/${formula}" |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["formulae"][0]["versions"]["stable"])')"
[ -n "$version" ] || die "could not determine version for ${formula}"

tag="${formula}-${version}"
root_url="https://github.com/${REPO}/releases/download/${tag}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# Bump `rebuild` when this version already has a published bottle, so the new
# artifact gets a distinct filename instead of colliding with cached copies.
if gh release view "$tag" --repo "$REPO" --json assets --jq '.assets[].name' 2>/dev/null |
     grep -q '\.bottle\.'; then
  python3 "${REPO_ROOT}/scripts/formula_bottle.py" bump "$formula_file"
  echo "bottle: ${tag} already has a published bottle; bumped rebuild"
fi

echo "bottle: building ${formula} ${version} for $(uname -m)"

# A bottle must be built from source with --build-bottle so that Homebrew
# records the prefix placeholders needed to relocate it.
brew uninstall --ignore-dependencies "$formula" 2>/dev/null || true
brew install --build-bottle "${TAP}/${formula}"

cd "$workdir"
# Capture `brew bottle` output so the sha256 written into the formula is always
# exactly the one uploaded. No --no-rebuild: the rebuild counter must reach the
# filename.
brew bottle --json --root-url="$root_url" "${TAP}/${formula}" | tee bottle-output.txt

json="$(ls ./*.json)"
read -r local_file upload_file <<EOF
$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
t=next(iter(next(iter(d.values()))["bottle"]["tags"].values()))
print(t["local_filename"], t["filename"])' "$json")
EOF

# Homebrew names the local artifact with a double dash; the download URL uses a
# single dash, so the release asset must be renamed before upload.
mv "$local_file" "$upload_file"

if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
  echo "bottle: adding asset to release ${tag}"
  gh release upload "$tag" "$upload_file" --repo "$REPO" --clobber
else
  echo "bottle: creating release ${tag}"
  gh release create "$tag" "$upload_file" \
    --repo "$REPO" \
    --title "${formula} ${version} bottles" \
    --notes "Prebuilt Homebrew bottle for ${formula} ${version}. Platforms without a bottle build from source."
fi

python3 "${REPO_ROOT}/scripts/formula_bottle.py" write "$formula_file" bottle-output.txt
ruby -c "$formula_file" >/dev/null || die "formula no longer parses after update"

echo
echo "bottle: ${formula} ${version} published; Formula/${formula}.rb updated."
echo "bottle: review the diff, then commit and push the tap."
