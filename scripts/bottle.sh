#!/usr/bin/env bash
#
# Build a bottle for a tap formula, publish it as a tap release asset, and print
# the `bottle do` block to paste into the formula.
#
# Bottles are per-OS/arch. This builds for the machine it runs on; platforms
# without a published bottle fall back to building from source, which is why a
# missing bottle is never fatal.
#
# Usage:
#   scripts/bottle.sh <formula>          # version read from the formula
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TAP="bindsch/tap"

die() {
  printf 'bottle: %s\n' "$1" >&2
  exit 1
}

formula="${1:-}"
[ -n "$formula" ] || die "usage: $0 <formula>"
[ -f "${REPO_ROOT}/Formula/${formula}.rb" ] || die "no such formula: ${formula}"

command -v gh >/dev/null || die "gh CLI is required to publish the bottle"

# Ask Homebrew for the version rather than parsing the formula ourselves.
version="$(brew info --json=v2 "${TAP}/${formula}" |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["formulae"][0]["versions"]["stable"])')"
[ -n "$version" ] || die "could not determine version for ${formula}"

tag="${formula}-${version}"
root_url="https://github.com/bindsch/homebrew-tap/releases/download/${tag}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "bottle: building ${formula} ${version} for $(uname -m)"

# A bottle must be built from source with --build-bottle so that Homebrew
# records the prefix placeholders needed to relocate it.
brew uninstall --ignore-dependencies "$formula" 2>/dev/null || true
brew install --build-bottle "${TAP}/${formula}"

cd "$workdir"
# `brew bottle` prints the ready-to-paste `bottle do` block; keep it verbatim
# rather than reconstructing it, so the sha256 shown is always the one uploaded.
brew bottle --json --no-rebuild --root-url="$root_url" "${TAP}/${formula}" | tee bottle-output.txt

json="$(ls ./*.json)"
local_file="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
tag=next(iter(next(iter(d.values()))["bottle"]["tags"].values()))
print(tag["local_filename"])' "$json")"
upload_file="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
tag=next(iter(next(iter(d.values()))["bottle"]["tags"].values()))
print(tag["filename"])' "$json")"

# Homebrew names the local artifact with a double dash; the download URL uses a
# single dash, so the release asset must be renamed before upload.
mv "$local_file" "$upload_file"

if gh release view "$tag" --repo bindsch/homebrew-tap >/dev/null 2>&1; then
  echo "bottle: adding asset to existing release ${tag}"
  gh release upload "$tag" "$upload_file" --repo bindsch/homebrew-tap --clobber
else
  echo "bottle: creating release ${tag}"
  gh release create "$tag" "$upload_file" \
    --repo bindsch/homebrew-tap \
    --title "${formula} ${version} bottles" \
    --notes "Prebuilt Homebrew bottle for ${formula} ${version}. Platforms without a bottle build from source."
fi

echo
echo "bottle: bottles are not byte-reproducible, so the sha256 changes on every"
echo "bottle: rebuild. Formula/${formula}.rb MUST be updated with this block:"
echo
sed -n '/^  bottle do$/,/^  end$/p' bottle-output.txt
