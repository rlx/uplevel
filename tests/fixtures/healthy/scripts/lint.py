"""Fails when a source line carries trailing whitespace. Reads only."""
import pathlib
import sys

bad = []
for path in sorted(pathlib.Path(".").glob("*/*.py")):
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if line != line.rstrip():
            bad.append("%s:%d trailing whitespace" % (path, number))
print("\n".join(bad))
sys.exit(1 if bad else 0)
