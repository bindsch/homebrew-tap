# homebrew-tap

Homebrew tap for bindsch tools.

## Usage

```bash
brew tap bindsch/tap
brew install scode
```

Or directly:

```bash
brew install bindsch/tap/scode
```

## Formulae

| Formula | Description |
|---------|-------------|
| [scode](Formula/scode.rb) | Safe sandbox wrapper for AI coding harnesses |
| [codemux](Formula/codemux.rb) | Unified CLI for AI coding agents |

`codemux` depends on `scode`, so installing it pulls in the sandbox:

```bash
brew install bindsch/tap/codemux
```

## Bottles

Formulae ship prebuilt bottles for the maintainer's platform (currently
`arm64_tahoe`). Any other platform builds from source automatically.

`scripts/bottle.sh` builds the bottle, uploads it to the matching tap release,
and writes the resulting `bottle do` block back into the formula:

```bash
./scripts/bottle.sh scode
./scripts/bottle.sh codemux
```

Review the resulting diff, then commit and push the tap.

Two properties of bottles make this worth automating rather than doing by hand:

- **They are not byte-reproducible.** Every rebuild produces a different
  `sha256`, so the formula and the published artifact must be updated together.
  The script writes the checksum it just uploaded, which is why it is no longer
  a copy-paste step.
- **Re-publishing a version reuses the asset filename.** Stale copies then
  linger in Homebrew's download cache and behind GitHub's CDN, and installs fail
  with `Error: Bottle reports different checksum`. When the script sees a bottle
  already published for the version, it increments `rebuild` first so the new
  artifact gets a distinct name and cannot collide.

The formula rewriting lives in `scripts/formula_bottle.py` (`bump` and `write`)
so it can be read and exercised on its own.

If you do hit a stale cached bottle, clear it with:

```bash
rm -f ~/Library/Caches/Homebrew/downloads/*<formula>-<version>*.bottle.tar.gz
```
