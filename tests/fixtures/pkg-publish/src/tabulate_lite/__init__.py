"""Render rows as aligned text tables."""

__version__ = "1.3.0"


def render(rows):
    widths = [max(len(str(c)) for c in col) for col in zip(*rows)]
    return "\n".join("  ".join(str(c).ljust(w) for c, w in zip(r, widths)).rstrip() for r in rows)
