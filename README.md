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
