# Proving a test-gate failure is environmental (pre-existing flake)

When a builder/reviewer/qa blames a red `bun run test` on a pre-existing flake, establish
it yourself before advancing: touched suites pass standalone AND the identical failure
reproduces on the pristine baseline. Do not take the word of an agent whose own suite
failed.

## Recipe (bun/Prisma repo, macOS)

```bash
# 1. The touched suites must pass in isolation (this is what unblocks the change):
bun test --isolate src/.../<touched>.test.ts ...   # expect 100% pass

# 2. Reproduce the failure on the baseline (the commit BEFORE the change under test):
BASE=<commit-sha-before-change>
git -C <worktree> worktree add --detach /tmp/<name>-baseline-test "$BASE"
ln -sfn <worktree>/node_modules /tmp/<name>-baseline-test/node_modules   # same deps
cd /tmp/<name>-baseline-test
git status --porcelain        # clean except untracked node_modules symlink
bun run test > /tmp/<name>-baseline-run.txt 2>&1; echo "EXIT:$?"
# expect: the SAME environmental signature (e.g. 'error: the worker thread exited' /
# 'Cannot call describe() after the test run has completed'), similar pass/fail counts.

# 3. Clean up the throwaway checkout:
cd <worktree>
git worktree remove --force /tmp/<name>-baseline-test
```

Caveat: a bare detached worktree lacks generated artifacts (e.g. `src/generated/prisma`)
that a real checkout has, so some baseline tests also fail with
`Cannot find module '@/generated/prisma'`. Count only the shared environmental signature
as proof; the missing-generate modules are your own instrumentation artifact, not a
comparison signal.

## Judgment gates

- If the touched suites pass standalone AND the baseline shows the same signature, the
  red full-gate is environmental: do NOT block on it, and do NOT tick a gate-based task `[x]`
  on a non-green run — record it in the final report instead.
- If the touched suites fail standalone, that is a real defect in the change, flake or not.
- pino `thread-stream` worker-thread exit cascading to "Cannot call describe() after the
test run has completed" is a class of environmental flake that recurs; the recipe above is
how to confirm it without re-litigating each case.
