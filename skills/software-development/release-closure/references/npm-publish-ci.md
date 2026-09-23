# Publishing an npm package from GitHub Actions CI/CD

End goal: `git merge → workflow publishes the package to npm` with no manual `npm publish`
and no human in the loop. Three distinct failure classes, each with a different fix — read
the workflow log before touching the token or the repo.

## The publish workflow is the release channel

An npm-publish GitHub Action that triggers on `pull_request` closed/merged publishes a new
version for EVERY merged PR — feature, fix, docs, or refactor that is NOT a version bump.
The version-bump step inside it runs `npm version <type>` on whatever is checked out, so on
a docs/refactor merge it will attempt a patch bump of the CURRENT version (which may already
be published) and fail with an already-exists error. Expect those runs to fail; they are not
bugs in the deliverable code. To publish deliberately: bump the version in a dedicated PR,
merge it, and the workflow publishes that bump (possibly one patch ahead of what you bumped,
because it bumps again on top).

## Failure class 1 — EOTP: npm 2FA blocks unattended publish

```
npm error code EOTP
npm error This operation requires a one-time password from your authenticator.
```

The npm account has **2FA in "auth-and-writes" mode**: every `npm publish` needs a fresh
OTP from the authenticator, impossible on a headless runner. Fix is on the npm side, not
the workflow:

1. npmjs.com → Access Tokens → Generate → **Granular Access Token** for the package scope/org,
   access **Read and write**, and tick the **automation flag** ("I will not use this token in
   interactive scripts"). Automation tokens are exempt from the per-publish OTP.
   A *regular* token does NOT fix EOTP — only automation-mode does.
2. Put it in the repo secret the workflow reads (`NPM_TOKEN` by default).
3. `gh run rerun <id> --failed` — no force-push needed; the updated secret takes effect on
   the re-run.

## Failure class 2 — E404 on PUT: token lacks publish access to the scope

```
npm error 404 Not Found - PUT https://registry.npmjs.org/@scope%2fpackage
npm error '@scope/package@x.y.z' is not in this registry.
```

`npm whoami` in the workflow log reads `401` / blank. The token's account must be an
owner/member with publish rights on the package scope or org — a disconnected personal
account is not enough.

## Verify a real publish (never trust the green step alone)

The workflow's last steps (create git tag, push version bump) only run after `npm publish`
succeeds, so a green tag step is strong evidence. But the runner's own green step is a
self-report — confirm on the registry, bypassing local npm cache (which serves a stale
answer for a while):

```bash
curl -sH "User-Agent: npm-cli/10" "https://registry.npmjs.org/@scope%2fpackage" \
  | jq '{latest: .["dist-tags"].latest, published: .time["<version>"]}'
```

npm prints `Your package is being processed and may take a few minutes to become available`
on success — the registry may legitimately lag before the raw endpoint shows the new
`latest`.

## pnpm `--frozen-lockfile` — ERR_PNPM_LOCKFILE_CONFIG_MISMATCH

pnpm 10+ reads `overrides` **only from `pnpm-workspace.yaml`**; the `pnpm.overrides` key in
`package.json` is ignored (`The "pnpm" field ... is no longer read`). If the lockfile was
generated under overrides but the workspace file is missing or carries different ones, the
frozen install aborts. This blocks `npm publish` and CI steps that run
`install --frozen-lockfile`.

- Put the overrides in `pnpm-workspace.yaml`, remove the dead `pnpm.overrides` block from
  `package.json`, regenerate the lockfile.
- Also add `onlyBuiltDependencies` (e.g. esbuild) or CI skips its build scripts
  (`ERR_PNPM_IGNORED_BUILDS`).
- Reproduce in a clean worktree of the EXACT branch with `CI=true pnpm install --frozen-lockfile`.
  A green install on your local pnpm version, or with `node_modules` already present, can mask
  it — the CI's `pnpm/action-setup` 10.x can be stricter about overrides than a local 10.3x.

## Changelog discipline (release docs)

English, concise, attractive — a tight summary grouped by effect (Added / Changed / Fixed),
never the internal report or exhaustive bullet dumps. Applies to every changelog the release
process writes. Verbose is a defect, not a preference. (See the `changelog-writing` skill.)
