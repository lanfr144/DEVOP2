# Changelog

Version numbers have three digits, `UNIT.CHANGE.FIX` (for example `2.1.0`):

| Digit | When it changes | Command | Example |
|---|---|---|---|
| 1st | the work moves on to the **next unit** | `./scripts/release.sh next-unit "..."` | `1.4.1` → `2.0.0` |
| 2nd | a change **inside the same unit** (new script, new deliverable, new part) | `./scripts/release.sh same-unit "..."` | `2.0.0` → `2.1.0` |
| 3rd | a small fix (typo, wording, refreshed output) | `./scripts/release.sh fix "..."` | `2.1.0` → `2.1.1` |

A higher digit resets the lower ones to 0. Each version is a Git tag (`v2.0.0`); a published tag is never moved.
`major`, `minor` and `patch` are accepted as synonyms of `next-unit`, `same-unit` and `fix`.
Rule in force since 2026-11-16; the versions up to `v1.4.1` (units 01 to 03) were numbered before it.

## v2.3.1 - 2026-11-17
- Missing paragraphs

## v2.3.0 - 2026-11-17
- Unit 04b and 04c: answers and GitKraken exercise

## v2.2.0 - 2026-11-17
- Unit 04b: answers document

## v2.1.1 - 2026-11-17
- README updated: units 01 to 03 done, Unit 04 status

## v2.1.0 - 2026-11-16
- Unit 04b: lab redone in Docker, history record script

## v2.0.0 - 2026-11-16
- Units 01 to 03 validated in Docker; versioning rule; start of Unit 04

## v1.4.1 - 2026-11-16
- Unit 03: Docker instructions in the deliverable, refreshed test output

## v1.4.0 - 2026-11-15
- Unit 02: query, reload and curl scripts

## v1.3.0 - 2026-11-15
- Unit 02: four-panel dashboard verified, refreshed test output

## v1.2.0 - 2026-11-15
- Unit 01: Docker start checks, no clear-text password, refreshed test output

## v1.1.0 - 2026-11-15
- Unit 01 milestone text, line endings, verification sheets

## v1.0.0 - 2026-11-15
- Initial version: units 01 to 03 done and tested, unit 05 script and theory answers, unit 04 to do.
- Every exercise runs in Docker (toolbox image, port check, healthchecks).
