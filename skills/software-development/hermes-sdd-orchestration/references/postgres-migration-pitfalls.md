# Postgres migration pitfalls (MongoDB → PostgreSQL)

Domain notes for the Postgres side of a Mongo→Postgres migration, beyond the generic
orchestration rules in SKILL.md.

## Platform external IDs overflow Postgres int4

Telegram (and Discord, Stripe, Slack) user/group IDs are **int64** — real values like
`8413599296` or `-1002000000001` exceed Postgres `int4`, so `Int`-typed ID columns
overthrow at write time with `Unable to fit integer value '...' into an INT4`. MongoDB
holds them fine as doubles, so the bug only surfaces after the cutover. Before rollout,
model every platform ID field (`telegramId`, `groupId`, `bannedBy`, `adminTelegramIds`)
as `BigInt @db.BigInt` and generate the migration — do NOT hide it with int32-safe seed
placeholders, which pass the gate and still break on real production values.

- **Data layer bigint, API/bot boundary Number.** Prisma returns `bigint` for those
  columns; JS callers compare/arithmetic need the same type, but exposing a `bigint` over
  an HTTP/JSON contract breaks the frontend (JSON has no bigint literal). Convert back to
  `Number()` at the repository/DTO boundary and in grammY/event payloads; the frontend
  contract stays `number`. IDs `< 2^53` are safe to round-trip this way.
- **Array-of-ID columns** (`adminTelegramIds`) become `BigInt[]` in DB; expose as
  `Number[]` in the config/read DTO.
- **A local DB can hold a stale orphan migration** (e.g. a past `migrate dev` experiment
  that created a non-versioned `_bigint` migration) so the worktree's `prisma migrate`
  reports drift against that local database even though git is clean. Note which DB each
  gate actually ran against (`tga_smoke` vs leftover `tga`); reset the orphaned local DB
  (`prisma migrate reset`) rather than chasing drift.

## Verify gate failures are real, not a suite-isolation artifact

A repo-wide `bun test` run without `--isolate` can show a couple of red tests that pass
cleanly in isolation — worker-thread pollution, not a regression. Before blaming a schema
change: re-run just the failing `--test-name-pattern` files with `--isolate` and see them
pass. Only a truly green full-suite run (1924 pass / 0 fail) plus the touched-suites-in-isolation
check proves the change is clean.
