## CI Web Builds Checklist

- [x] Task A — `conf.lua` — Change `t.window.title` from `"Love Exemplar"` to `"Normal Apple Farming"` (line 13).

- [x] Task B — `package.json` — Create new file at repo root with `name: "normal-apple-farming"`, `version: "1.0.0"`, `scripts.build: "bash scripts/build_web.sh"`, and devDependencies `love.js@11.4.1` and `wrangler@^3`.

- [x] Task C — `scripts/build_web.sh` — Create new file (chmod +x). Adapt from `../wip/scripts/build_web.sh`: change the zip command to `zip -r game.love main.lua conf.lua lua/ core/ game/ assets/` (adds `core/` and `game/`); change the love.js title flag to `--title "Normal Apple Farming"`; keep the `controls.js` copy + inject step and the full IndexedDB save-sync patch on `web/love.js` unchanged.

- [x] Task D — `web-template/controls.js` — Create new file. Adapt from `../wip/web-template/controls.js`: in `KEY_CODES` replace `'o': 79, 'p': 80` with `'e': 69`; replace the right cluster's two buttons (O and P) with a single `E` button (`btn-e`, key `'e'`, code `'KeyE'`, label `'E'`); keep the Escape button; update right cluster grid to `grid-template-columns: repeat(2, 60px)` / `grid-template-rows: repeat(1, 60px)` to fit 2 buttons (E + Esc side by side). Keep left d-pad cluster, all touch/mouse listeners, canvas scaling, and the "Clear All Data" save-controls bar exactly as in wip.

- [x] Task E — `.github/workflows/ci.yml` — Create new file. Adapt from `../wip/.github/workflows/ci.yml`: change branch triggers from `main` to `master`; keep the LÖVE 11.5 install step and `love . --headless` run step unchanged.

- [x] Task F — `.github/workflows/web.yml` — Create new file. Adapt from `../wip/.github/workflows/web.yml`: change all `branches: [main]` to `branches: [master]`; change `--project-name=wip` to `--project-name=normal-apple-farming` in all three deploy steps; replace the PR preview comment URL `https://pr-${{ github.event.pull_request.number }}.wip-2qs.pages.dev` with `https://pr-${{ github.event.pull_request.number }}.normal-apple-farming.pages.dev` and add a comment `# TODO: update subdomain after first Cloudflare deploy`; change `projects/wip/deployments` to `projects/normal-apple-farming/deployments` in the cleanup curl calls. Everything else (artifact names, permissions, job conditions, peter-evans actions) stays the same.
