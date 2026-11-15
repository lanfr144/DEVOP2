# Changelog

Version numbers have three digits, `MAJOR.MINOR.PATCH` (for example `1.0.0`):

| Digit | When it changes | Example |
|---|---|---|
| 1st (MAJOR) | big change: a new unit delivered, a structure change that breaks the way the exercises are run | `1.4.2` → `2.0.0` |
| 2nd (MINOR) | medium change: a new exercise part, a new script, a new deliverable inside an existing unit | `1.4.2` → `1.5.0` |
| 3rd (PATCH) | minor change: a fix, a typo, a clarification | `1.4.2` → `1.4.3` |

A higher digit resets the lower ones to 0. Each version is a Git tag (`v1.0.0`); a published tag is never moved.
New version: `./scripts/release.sh major|minor|patch "what changed"`.

## v1.2.0 - 2026-11-15
- Unit 01: Docker start checks, no clear-text password, refreshed test output

## v1.1.0 - 2026-11-15
- Unit 01 milestone text, line endings, verification sheets

## v1.0.0 - 2026-11-15
- Initial version: units 01 to 03 done and tested, unit 05 script and theory answers, unit 04 to do.
- Every exercise runs in Docker (toolbox image, port check, healthchecks).
