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

Bottles are not byte-reproducible: every rebuild produces a new `sha256`, so the
formula must be updated whenever a bottle is republished. `scripts/bottle.sh`
builds the bottle, uploads it to the matching tap release, and prints the exact
`bottle do` block to paste back into the formula:

```bash
./scripts/bottle.sh scode
./scripts/bottle.sh codemux
```
