# Parallel execution — change collision detector

## Purpose

Make the agency's parallelism decision a derived, reproducible one: before dispatching
two changes concurrently, `bin/change-collision` reads both file sets from git and
prints `parallelizable` / `collision` / `cannot assess`, so the same diff always gets
the same verdict and a `collision` always names the overlapping paths and the
high-risk classes that forced it.

## ADDED Requirements

### Requirement: Collision verdict from file sets

Given two refs and a base, the loop MUST be able to derive a `parallelizable` /
`collision` verdict from the file sets alone (`git diff --name-only` per branch), where
`parallelizable` means no path is touched by both changes, and `collision` names the
overlapping paths.

#### Scenario: Disjoint file sets are parallelizable

- **WHEN** change A touches `src/auth/**` and change B touches `src/events/**` with a
  common base
- **THEN** the verdict is `parallelizable` and no overlapping path is reported

#### Scenario: Overlapping file sets are a collision

- **WHEN** both changes touch `src/shared/service.ts`
- **THEN** the verdict is `collision`, naming the overlapping path(s)

### Requirement: High-risk classes force collision

Schema/migration, auth/contract, `openspec/` and dependency-manifest paths MUST force
`collision` even when the two file sets do not overlap literally — a change that touches
`prisma/schema.prisma` and another that touches a migration in the same directory risk
state corruption when run concurrently.

#### Scenario: Schema and migration overlap without shared paths

- **WHEN** change A touches `prisma/schema.prisma` and change B touches
  `prisma/migrations/0002_x/` (no literal shared path)
- **THEN** the verdict is still `collision`, naming the high-risk class that forced it

### Requirement: Cannot-assess never defaults to parallelizable

An unmeasurable input (no base ref, an empty diff, a ref that does not resolve) MUST
report `cannot assess` with the reason and a non-zero exit — never a silent
`parallelizable`.

#### Scenario: Empty diff is cannot assess

- **WHEN** the base equals a branch tip (the diff is empty — wrong base or nothing yet)
- **THEN** the verdict is `cannot assess` with the reason, and the exit is non-zero
