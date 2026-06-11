## Goal

Add GitHub Actions CI pipelines matching the pattern from `../wip`:
1. A CI test workflow that runs `love . --headless` on push/PR to `master`.
2. A web build + deploy workflow that builds a love.js web bundle, deploys to Cloudflare Pages on push to `master`, and deploys PR previews on PR open/sync with a comment link.

## Affected files

- `package.json` — new; dev deps: `love.js@11.4.1`, `wrangler@^3`
- `scripts/build_web.sh` — new; zips game files and runs love.js
- `web-template/controls.js` — new; mobile on-screen controls (WASD + E + Escape)
- `.github/workflows/ci.yml` — new; runs tests with `love . --headless`
- `.github/workflows/web.yml` — new; builds and deploys to Cloudflare Pages
- `conf.lua` — update window title from `"Love Exemplar"` to `"Normal Apple Farming"`

## What changes

**`package.json`** — identical to wip, just with `"name": "normal-apple-farming"`.

**`scripts/build_web.sh`** — adapted from wip:
- Zip command includes `core/` and `game/` in addition to wip's `main.lua conf.lua lua/ assets/`, because this repo splits engine code across `core/` and game logic across `game/`.
- Title flag: `--title "Normal Apple Farming"` instead of `"plant game"`.
- IndexedDB save-sync patch is identical to wip (hooks `FS.close` and `FS.writeFile` to call `FS.syncfs` after writes to `save.dat`).

**`web-template/controls.js`** — adapted from wip for this game's key bindings:
- Left cluster: WASD d-pad (same as wip).
- Right cluster: `E` (interact) + `Escape` — replaces wip's `O`, `P`, `Escape` trio, since this game only uses `e` for interact and `escape` to quit.
- `KEY_CODES`: adds `e: 69`, removes `o: 79` and `p: 80`.
- "Clear All Data" save button is identical to wip.

**`.github/workflows/ci.yml`** — adapted from wip:
- Branch: `master` instead of `main`.
- Install LÖVE 11.5 via PPA; run `love . --headless` (same command as wip).

**`.github/workflows/web.yml`** — adapted from wip:
- Branch triggers: `master` instead of `main`.
- Cloudflare project name: `normal-apple-farming` instead of `wip`.
- PR preview URL comment body: `https://pr-$N.normal-apple-farming-<subdomain>.pages.dev` — the exact subdomain suffix is only known after the Cloudflare Pages project is first created; leave a `TODO` placeholder and update after initial deploy.

**`conf.lua`** — change `t.window.title` from `"Love Exemplar"` to `"Normal Apple Farming"`.

## What stays the same

- Test command: `love . --headless` (identical to wip).
- love.js version: `11.4.1`.
- wrangler version: `^3`.
- CI runs on `ubuntu-latest`.
- LÖVE install method via `ppa:bartbes/love-stable`.

## Open questions

- **Cloudflare subdomain hash**: The PR preview comment URL contains a hash suffix (e.g., `wip-2qs` in wip). This is assigned by Cloudflare when the project is created and cannot be known in advance. The `web.yml` comment body should be updated with the correct value after the Cloudflare Pages project `normal-apple-farming` is first deployed.
- **GitHub secrets**: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` must be set in the repo's GitHub Actions secrets before the deploy jobs will succeed.
