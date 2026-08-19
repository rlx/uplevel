<!-- Say what was done. Reasoning, alternatives and history are context — offer them and ask,
     rather than adding them here by default. Delete any section below that does not apply. -->

## What this does

## If it adds or changes a check

- [ ] Watched it fail on the case that motivated it — a real one, not a synthetic stand-in — then pass
- [ ] Exercised the skip path, if it degrades when a tool or credential is absent
- [ ] Recorded it in `.claude/guardrails.yml`, saying what it enforces
- [ ] If it loosens an existing check: re-proved the original failure still fires
- [ ] Timed the whole gate before and after, and updated `CONTRIBUTING.md` if the figure moved

## If it changes anything under `skills/uplevel/`

- [ ] `version:` bumped in `SKILL.md`
- [ ] `CHANGELOG.md` entry written in this change, not a follow-up
- [ ] Every command it ships was run here and observed to work

## Anything else

- [ ] If the gate was bypassed with `--no-verify`, said why above
