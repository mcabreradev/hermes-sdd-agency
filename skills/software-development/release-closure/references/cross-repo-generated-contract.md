# Cross-repo generated contract sync (openapi → types)

The frontend derives its API types from the backend's `openapi.json` via
`bunx openapi-typescript ../tga-backend/openapi.json -o src/types/api.generated.ts`
(package.json `generate:types`). The relative `../tga-backend` path resolves from repo
sibling layout — which is exactly why worktrees break it.

## The trap

When the backend worktree is `tga-backend` (the main checkout, merged) and the frontend
worktree lives in a sibling `tga-frontend-worktrees/<slug>` directory, the frontend's
`../tga-backend` does NOT resolve to the backend repo. A fresh `generate:types` then reads a
missing path or stale content, and the regenerated `api.generated.ts` shows none of the new
endpoints.

`generate:types` is a codegen step; never hand-edit `api.generated.ts` to add the new
endpoints. Fix the source, regenerate, and verify the diff.

## Sequence that works

1. **Merge the backend first.** The frontend derives types from what the backend actually
   ships — there is no point generating against the draft branch. Get the backend PR merged
   to `main`.
2. **Fast-forward the backend `main` locally** so the checkout's `openapi.json` carries the
   new contract:

   ```bash
   git fetch origin main -q && git merge --ff-only origin/main
   python3 -c "import json; d=json.load(open('openapi.json')); p=d.get('paths',{}); print(any('new-endpoint' in k for k in p))"
   ```

   Confirm the new endpoints are present before trusting the frontend's regenerate.
3. **Make the frontend's `../tga-backend` resolve.** The frontend tooling walks up to a
   sibling dir; when the frontend is inside `tga-frontend-worktrees/`, create the missing
   sibling link so the path resolves to the real backend checkout:

   ```bash
   ln -sfn /abs/path/to/tga-backend tga-frontend-worktrees/tga-backend
   ```

   (`ln -sfn` keeps it a symlink to the backend, not a copy.)
4. **Regenerate and verify the diff:** `bun run generate:types` and `git diff
   src/types/api.generated.ts` must show the new tenant bot fields, lifecycle, bulk,
   plans/messages/bot-events endpoints, and the narrowed flag contract — not an empty diff.

## Pitfall reminders

- `../tga-backend` is resolved from the cwd; a symlink at `tga-frontend-worktrees/tga-backend`
is the clean fix and stays out of git. When the frontend runs from its own `tga-frontend` main
checkout (not a worktree), `../tga-backend` already resolves and no link is needed.
- After the frontend PR merges, delete that temporary symlink when removing the worktree — it
is a stray artifact that outlives the worktree otherwise (see the parent skill's Pitfalls).
- Type-only consumers (the browser api client, the proxy) only break at typecheck time; always
  run the frontend's own gate after regenerating.
