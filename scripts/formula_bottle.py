#!/usr/bin/env python3
"""Edit the `bottle do` block of a Homebrew formula.

Used by scripts/bottle.sh. Kept as a separate file rather than an inline
heredoc so the formula-rewriting logic can be read and tested on its own.

Commands:
  bump  <formula.rb>                 increment (or introduce) `rebuild N`
  write <formula.rb> <bottle-output> replace the block with brew's printed one
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

BLOCK_RE = re.compile(r"^  bottle do\n(?P<body>.*?)^  end$", re.M | re.S)
REBUILD_RE = re.compile(r"^\s*rebuild (?P<n>\d+)$", re.M)


def fail(message: str) -> None:
    print(f"formula_bottle: {message}", file=sys.stderr)
    raise SystemExit(1)


def bump(formula: Path) -> None:
    """Increment `rebuild`, adding it if the block has none yet."""
    text = formula.read_text()
    block = BLOCK_RE.search(text)
    if not block:
        fail(f"{formula} has no bottle block to bump")

    body = block.group("body")
    existing = REBUILD_RE.search(body)
    if existing:
        nxt = int(existing.group("n")) + 1
        new_body = body[: existing.start()] + f"    rebuild {nxt}" + body[existing.end() :]
    else:
        nxt = 1
        new_body = f"    rebuild {nxt}\n" + body

    formula.write_text(text[: block.start("body")] + new_body + text[block.end("body") :])
    print(f"formula_bottle: rebuild = {nxt}")


def write(formula: Path, bottle_output: Path) -> None:
    """Replace the bottle block with the one `brew bottle` printed."""
    printed = BLOCK_RE.search(bottle_output.read_text())
    if not printed:
        fail(f"no bottle block found in {bottle_output}")
    new_block = f"  bottle do\n{printed.group('body')}  end"

    text = formula.read_text()
    current = BLOCK_RE.search(text)
    if current:
        # brew bottle does not echo `rebuild`, so carry it across explicitly.
        rebuild = REBUILD_RE.search(current.group("body"))
        if rebuild and not REBUILD_RE.search(new_block):
            lines = new_block.split("\n")
            lines.insert(1, f"    rebuild {rebuild.group('n')}")
            new_block = "\n".join(lines)
        text = text[: current.start()] + new_block + text[current.end() :]
    else:
        # No block yet: place it after the `head` line, matching the tap's layout.
        head = re.search(r"^  head .*$", text, re.M)
        if not head:
            fail(f"{formula} has neither a bottle block nor a head line")
        text = text[: head.end()] + "\n\n" + new_block + text[head.end() :]

    formula.write_text(text)
    print(f"formula_bottle: wrote bottle block into {formula}")


def main(argv: list[str]) -> None:
    if len(argv) < 3:
        fail(__doc__ or "usage error")
    command, formula = argv[1], Path(argv[2])
    if command == "bump":
        bump(formula)
    elif command == "write":
        if len(argv) < 4:
            fail("write requires a bottle-output file")
        write(formula, Path(argv[3]))
    else:
        fail(f"unknown command: {command}")


if __name__ == "__main__":
    main(sys.argv)
