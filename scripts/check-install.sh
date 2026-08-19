#!/usr/bin/env bash
# Runs the install commands README.md actually prints, against a clean HOME.
#   ./scripts/check-install.sh
#
# The commands are EXTRACTED from README.md, never transcribed here. A copy
# would drift from the document and then verify itself, which is the failure
# this check exists to prevent: an install path documented and never executed is
# a claim, not a control, and this one has broken before.
#
# Only two substitutions are made, both stated out loud below. Everything else
# runs exactly as a reader would type it.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
fail=0; note() { echo "  !! $1"; fail=1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- extract ------------------------------------------------------------------
# Fenced sh blocks under "## Install", up to the next second-level heading.
# Inline-backtick commands are deliberately NOT extracted: the section quotes
# `cp -R skills/uplevel ~/.claude/skills/` as the mistake to avoid, and running
# the anti-pattern would be a check that asserts the bug.
mkdir -p "$WORK/blocks"
awk -v d="$WORK/blocks" '
  /^## Install[ \t]*$/ { inst = 1; next }
  /^## /               { inst = 0 }
  inst && /^```sh[ \t]*$/ { n++; cap = 1; out = d "/block" n ".sh"; next }
  inst && /^```[ \t]*$/   { if (cap) { close(out); cap = 0 }; next }
  cap                     { print > out }
' README.md

blocks=0
for b in "$WORK"/blocks/*.sh; do
  [ -e "$b" ] || continue
  blocks=$((blocks + 1))
done

echo "== the README's install section still has the shape this check knows =="
# Pinned on purpose. If the section grows a third path or loses one, this check
# silently stops covering it while still reporting green -- so it fails instead
# and asks to be updated. The count is the contract between document and check.
if [ "$blocks" = "2" ]; then
  echo "  2 fenced install blocks: link, then copy"
else
  note "expected 2 fenced sh blocks under '## Install', found $blocks -- the section changed shape, so update this check to match"
  echo "REPO INSTALL FAILED"; exit 1
fi

# The uninstall command is prose, in backticks, so it is pulled by shape.
uninstall="$(grep -oE 'rm -rf ~/\.claude/skills/uplevel' README.md | head -1)"
[ -n "$uninstall" ] || note "README.md no longer documents an uninstall command"

# --- harness ------------------------------------------------------------------
# SUBSTITUTION 1: the clone URL becomes this checkout, so the check tests the
# README in front of it rather than whatever is published. The explicit
# destination replaces the name git would infer from the remote -- on GitHub
# that is "uplevel", which is what the block's `cd uplevel` expects, and locally
# it would be whatever the working directory happens to be called.
prepare() {
  sed -e 's|^git clone https://github.com/[^ ]*$|git clone --quiet "$SOURCE" uplevel|' "$1"
}

# SUBSTITUTION 2: HOME points at a directory this script owns, so nothing
# touches the real ~/.claude. The blocks expand ~ themselves; nothing else is
# changed. A repeat install is a fresh working directory against the SAME HOME,
# which is the hazard the README warns about and needs no edit to reproduce.
run_block() {
  blockfile="$1"; sandbox="$2"; workdir="$3"
  mkdir -p "$sandbox" "$workdir"
  ( cd "$workdir" \
    && HOME="$sandbox" SOURCE="$ROOT" bash -e -c "$(prepare "$blockfile")" ) >"$WORK/out" 2>&1
  rc=$?
  [ "$rc" = "0" ] || { echo "--- output ---"; sed 's/^/  /' "$WORK/out"; }
  return $rc
}

installed_ok() {
  sandbox="$1"; label="$2"
  target="$sandbox/.claude/skills/uplevel"
  if [ ! -f "$target/SKILL.md" ]; then
    note "$label: $target/SKILL.md is missing, so the install did not resolve"
    return 1
  fi
  # The nesting bug: a second install landing INSIDE the first. Both documented
  # commands have produced it, which is why the README names the destination
  # explicitly and why this runs every block twice.
  nested_found=""
  for nested in "$target/uplevel" "$target/skills"; do
    [ -e "$nested" ] && { note "$label: nested install at $nested"; nested_found=yes; }
  done
  if ( cd "$target" && ./selfcheck.sh ) >"$WORK/self" 2>&1; then
    if [ -n "$nested_found" ]; then
      echo "  $label: resolves and passes its own selfcheck, but see the nesting above"
    else
      echo "  $label: resolves, no nesting, passes its own selfcheck"
    fi
  else
    note "$label: the installed skill fails its own selfcheck"
    sed 's/^/     /' "$WORK/self"
  fi
}

# --- the link path ------------------------------------------------------------
echo "== the documented link install, on a clean HOME and then over itself =="
sandbox="$WORK/home-link"
if run_block "$WORK/blocks/block1.sh" "$sandbox" "$WORK/link-1"; then
  installed_ok "$sandbox" "link install"
  # The second run is the same block, verbatim, from a fresh working directory
  # against the HOME that is already installed into. That is the case the README
  # warns about, and reaching it needs no edit to the block: a reader who clones
  # again, or who re-runs the steps after moving the clone, is in exactly it.
  if run_block "$WORK/blocks/block1.sh" "$sandbox" "$WORK/link-2"; then
    installed_ok "$sandbox" "link install, second run"
    [ -L "$sandbox/.claude/skills/uplevel" ] \
      || note "link install, second run: the destination is no longer a symlink"
  else
    note "the documented link install failed when run a second time"
  fi
else
  note "the documented link install failed on a clean HOME"
fi

# --- the copy path ------------------------------------------------------------
echo "== the documented copy install, on a clean HOME and then over itself =="
# Block 2 replaces the last line of block 1 rather than following it, so the
# clone is the harness's job here -- the README states that precondition in
# prose ("From the repository root"), not in the block.
sandbox="$WORK/home-copy"; clone="$WORK/copy-1/uplevel"
mkdir -p "$WORK/copy-1"
if git clone --quiet "$ROOT" "$clone" 2>/dev/null; then
  if run_block "$WORK/blocks/block2.sh" "$sandbox" "$clone"; then
    installed_ok "$sandbox" "copy install"
    if run_block "$WORK/blocks/block2.sh" "$sandbox" "$clone"; then
      installed_ok "$sandbox" "copy install, second run"
      [ -L "$sandbox/.claude/skills/uplevel" ] \
        && note "copy install: the destination is a symlink, so the copy did not survive the clone"
    else
      note "the documented copy install failed when run a second time"
    fi
  else
    note "the documented copy install failed on a clean HOME"
  fi
else
  note "could not clone this checkout to test the copy install"
fi

# --- uninstall ----------------------------------------------------------------
echo "== the documented uninstall removes the install and not the clone =="
if [ -n "$uninstall" ] && [ -d "$WORK/home-link/.claude/skills" ]; then
  HOME="$WORK/home-link" bash -e -c "$uninstall" >/dev/null 2>&1
  [ -e "$WORK/home-link/.claude/skills/uplevel" ] \
    && note "uninstall left something at ~/.claude/skills/uplevel"
  [ -f "$WORK/link-2/uplevel/skills/uplevel/SKILL.md" ] \
    || note "uninstall removed the clone, which the README says it never does"
  [ "$fail" = "0" ] && echo "  install gone, clone intact"
else
  note "could not exercise the uninstall command"
fi

[ "$fail" = "0" ] && echo "INSTALL OK" || { echo "INSTALL FAILED"; exit 1; }
