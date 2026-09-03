# LBK Launcher — Flatpak Packaging

No application source lives here. This repo repacks the prebuilt x86_64 `LBK-Launcher-linux.AppImage` published by the separate repo `Vadko/lbk-launcher` into a Flatpak (`com.lbk.launcher`), signs an OSTree repo with GPG key `284A1984`, bakes that repo into an `nginx:alpine` image pushed to `ghcr.io/vadko/lbk-flatpak`, and redeploys it at `https://flatpak.lbklauncher.com` through a Coolify webhook. 16 tracked files; `.github/workflows/build-repo.yml` is the whole pipeline. The packaging is deliberately gaming-oriented: it carries an i386 / `Compat.i386` / `GL32` / `com.valvesoftware.Steam.Utility` stack so umu/Proton's pressure-vessel can nest bubblewrap and run 32-bit Wine inside the sandbox.

## Commands

```bash
# Build prerequisites — this is CI's list (workflow lines 34-37); the README's is wrong
flatpak install --user -y flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08 \
  org.electronjs.Electron2.BaseApp//25.08 org.freedesktop.Sdk.Compat.i386//25.08 \
  org.freedesktop.Sdk.Extension.toolchain-i386//25.08 org.freedesktop.Platform.Compat.i386//25.08

# Build + sign the commit, exactly as CI does (workflow line 104)
flatpak-builder --user --force-clean --default-branch=stable --gpg-sign=284A1984 --repo=repo build-dir com.lbk.launcher.yml

# Second, separate signature: repo summary + appstream branch (workflow lines 108-111)
flatpak build-update-repo repo --gpg-sign=284A1984 --generate-static-deltas --prune

# Smoke test — runs WITHOUT finish-args or extensions, so Proton/umu paths are untestable this way
flatpak-builder --run build-dir com.lbk.launcher.yml lbk-launcher

# Publish one specific tag, including a draft release
gh workflow run build-repo.yml -f app_version=v1.31.0
```

Secrets the pipeline needs: `GH_PAT` (cross-repo + draft asset access), `GPG_PRIVATE_KEY` (base64 of a **passphrase-less** secret key), `COOLIFY_WEBHOOK_URL`, `COOLIFY_API_TOKEN`.

## Release pipeline

- Triggers: push to `main`, `repository_dispatch` type `new-release` (`client_payload.tag`), and `workflow_dispatch` input `app_version`. With no input it auto-selects the newest **non-draft** release of `Vadko/lbk-launcher`.
- CI patches `com.lbk.launcher.yml` (Python regex, workflow 71-89) and `com.lbk.launcher.metainfo.xml` (`sed`, 91-96) inside the runner and never commits back. Tracked values stay frozen — currently pinned `v1.30.0` and metainfo `1.29.1` / `2025-01-01` — so a local build always ships those, never the latest release.
- To move the pin by hand, edit only `com.lbk.launcher.yml:189` (tag in the URL) and `:190` (`sha256`, lowercase 64 hex): `curl -fsSL https://github.com/Vadko/lbk-launcher/releases/download/<TAG>/LBK-Launcher-linux.AppImage | sha256sum`. That URL 404s for draft releases; drafts need `gh api repos/Vadko/lbk-launcher/releases/assets/<ID> -H 'Accept: application/octet-stream'`.
- `com.lbk.launcher.flatpakref` and `com.lbk.launcher.desktop` hold nothing version-specific. Never touch them for a release bump.
- Both signatures are required for gpg-verifying clients: the commit (`flatpak-builder --gpg-sign`) and the summary (`build-update-repo --gpg-sign`).

## Manifest rules (`com.lbk.launcher.yml`)

- Version literals live in YAML anchors (`&runtime-version` :3, `&gl-version` :10, `&gl-versions` :11). A runtime bump must change six places together: `:3`, `:6` (`base-version` — the anchor does not cover it), `:11` (`25.08;1.4`), and workflow lines 34, 35, 37. Commit 4647255 is the worked example.
- `base: org.electronjs.Electron2.BaseApp` is load-bearing at build time, not just runtime: `patch-desktop-filename` at `:176` (comment `:175`, Wayland app_id) comes from outside this repo, so a base change can remove it. `com.lbk.launcher` must agree in three places — that command, `app-id:` at `:1`, and `StartupWMClass=` in `com.lbk.launcher.desktop:11` — or the window has no icon.
- Every file a build-command touches needs a `sources:` entry, and any path with a directory prefix needs a `dest-filename:` that flattens it: the `simple` buildsystem runs commands in a flat directory. Adding an icon size means editing both lists (`:182-186` and `:198-211`); nothing verifies PNG dimensions, so check them yourself.
- Five of the `mkdir -p` targets in `platform-bootstrap` (`:144-147`, `:152`) create the mount points the `add-extensions` `directory:` keys need — `lib/i386-linux-gnu`, `lib/i386-linux-gnu/GL`, `lib/i386-linux-gnu/dri/intel-vaapi-driver`, `lib/debug/lib/i386-linux-gnu`, `utils`; delete one of those and the matching extension silently never mounts. The rest (`/app/bin`, `/app/lib/debug/.../GL`, `/app/lib{,32}/ffmpeg`, `/app/share/steam/compatibilitytools.d`, `/app/share/vulkan`, `/app/links/lib`) are plain plumbing with no extension behind them.
- Do not describe this packaging as sandboxed and do not bother tightening the path list: `--filesystem=home` (`:78`) already subsumes the 16 `~/...` entries at `:49-76`, and `--talk-name=org.freedesktop.Flatpak` (`:84`) grants host command execution. Removing `:78` is the necessary first move if the sandbox is ever really tightened.
- Args that break real features if removed: `--allow=devel` (pressure-vessel nests bubblewrap), `--allow=multiarch` (32-bit exec), `--device=all` (raised from `--device=dri` in 2fec378 "allow gamepad access") and `--filesystem=/run/udev:ro` (commented at `:45`, udev access for Chromium/Electron) — both gamepad-related. `--allow=bluetooth` (`:29`) is uncommented and undocumented; it came in with the Heroic-matching batch in 4647255, so verify before assuming what it buys. `--system-talk-name=org.freedesktop.UDisks2` (Wine drive enumeration), `--filesystem=xdg-run/gamescope-0:rw` (Steam Deck game mode).
- What running under Flatpak changes for the app: `PATH` is replaced, not extended (`:34`); `LD_LIBRARY_PATH` is force-set (`:35`); config/data move to `~/.var/app/com.lbk.launcher/{config,data,cache}` with no migration from an AppImage install; `TMPDIR` is redirected in `lbk-launcher.sh:2`; Chromium's own sandbox is off (`--no-sandbox`, no zypak); AppImage self-update is dead because the AppImage is extracted at build time to `/app/lbk-launcher`. x86_64 only.

## Metadata and serving

- The metainfo must keep exactly ONE `<release>` element: CI's `sed` has no line address and would rewrite every one to the same version and date.
- `RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo` in the flatpakref is mandatory, not boilerplate — the private repo hosts only `com.lbk.launcher`; the runtime, BaseApp, `Compat.i386`, `GL32` and the auto-downloading `com.valvesoftware.Steam.Utility` all come from Flathub.
- `Branch=stable` (flatpakref `:4`) and `--default-branch=stable` move together. The `.flatpakref` install path creates a remote named `lbk-launcher` (`SuggestRemoteName`), not `lbk`.
- `Dockerfile:4` copies the gitignored `repo/`, so `docker build .` from a clean checkout fails; the image is only buildable in a workspace where flatpak-builder just ran.
- `nginx.conf`: `location ~* /objects/` declares its own `add_header`, so it does not inherit the CORS headers from `location /repo/`; and `/summary` is cached `5m`, so a fresh deploy can look like a no-op for five minutes.

## Conventions

- Keep the `#` comment above each non-obvious finish-arg naming the concrete reason. It is the only design documentation in the repo — but it is incomplete: `--device=all` (2fec378) and `--allow=bluetooth` (4647255) were both added with no comment. Add the missing ones rather than assuming an uncommented arg is unimportant.
- Copy gaming permissions and i386 plumbing from the upstreams this manifest already tracks — Heroic (`flathub/com.heroicgameslauncher.hgl`, cited at `:9` and `:37`) and the umu-launcher flatpak (cited at `:136`) — instead of inventing them; diff against those manifests first. Same instinct for everything else: before hand-rolling a helper or a script, check what the runtime, the Electron BaseApp, an existing extension or the tooling already installed in CI gives you.
- Anything new that flatpak itself consumes takes the `com.lbk.launcher.<ext>` name at the repo root, matching the app-id; infra files keep plain names.
- All descriptive copy is Ukrainian in the default (untranslated) slot — `.desktop:3`, metainfo `:5`/`:11-12`, flatpakref `:11-12` — while the name stays English (`LBK Launcher`) in all three; keep it consistent across all three if you ever add `[uk]` / `xml:lang` variants. A translation entry is «переклад» (also «українізатор»), the Steam Workshop area is «Майстерня» — never «айтем».
- Prefer a single-line comment; the only multi-line blocks are `com.lbk.launcher.yml:122-124`, `:135-137` and `lbk-launcher.sh:4-5`, where an extension contract or the i386 plumbing genuinely needs the extra line. Do not add a fourth.
- Commit messages: plain, terse, imperative. No AI co-author or attribution trailers.

## Comments

Everyone here reads TS faster than prose about TS. **Default to no comment** — write one only for what the code can't say: a workaround and what breaks without it, a business or regulatory rule, a non-obvious ordering or idempotency constraint.

Never narrate a function body — no step-by-step, no `// Step 1:`, no `// loop over users` above a loop. No JSDoc restating the signature; types carry it. No divider or changelog comments, no commented-out code. TODOs need an issue number.

This repo is YAML, shell, XML and nginx config rather than TypeScript, and the same rule holds: a one-line `#` explaining WHY a sandbox permission, build flag, extension or workaround exists earns its place — `com.lbk.launcher.yml` already does this well — while a comment restating what the line plainly does does not.

## Verification

```bash
# MUST print 1 after ANY edit to the AppImage source block, or CI will silently
# rebuild the stale pinned AppImage and publish it under the new version tag
python3 -c "import re; c=open('com.lbk.launcher.yml').read(); print(re.subn(r'- type: file\n\s+url: https://github\.com/Vadko/lbk-launcher/releases/download/[^/]+/LBK-Launcher-linux\.AppImage\n\s+sha256: [a-f0-9]{64}\n\s+dest-filename: LBK-Launcher-linux\.AppImage','X',c)[1])"

appstreamcli validate com.lbk.launcher.metainfo.xml
desktop-file-validate com.lbk.launcher.desktop
```

Neither validator runs in CI. A broken metainfo fails silently — the app just stops appearing in GNOME Software / Discover while `flatpak install` keeps working.

## Do not

- **Do not reorder or upper-case** the `url` / `sha256` / `dest-filename` block at `com.lbk.launcher.yml:188-191`. CI's `re.sub` hardcodes that key order, the `Vadko/lbk-launcher` release URL and `[a-f0-9]{64}` (indentation is `\s+`, so only the key order and the hex case matter); a miss is a no-op, so the build goes green and publishes the OLD binary under the NEW version tag. Run the check above after every manifest edit.
- Do not rename the asset basename `LBK-Launcher-linux.AppImage`. It must stay byte-identical in nine places: manifest `:172`, `:173`, `:189`, `:191`, and workflow lines 61 (`jq` asset selector), 65 (download target), 68 (`sha256sum`), 82 (regex) and 83 (regex replacement `path:`). Three consecutive commits already exist fixing exactly this.
- Do not follow README.md for a local build: it is stale on runtime version (24.08 vs 25.08), omits the three i386 extensions, omits `--default-branch=stable` (build lands on branch `master` and the `.flatpakref` will not resolve), names the remote `lbk`, and links the old upstream `Vadko/littlebit-launcher` — which also still leaks into `com.lbk.launcher.metainfo.xml:19`.
- Do not assume `--generate-static-deltas` makes updates incremental. `repo/` is gitignored and never cached or restored, so every run builds a brand-new OSTree repo with one parentless commit; clients re-download the full payload every release and `--prune` is a no-op.
- Do not add a `.dockerignore` mirroring `.gitignore`: `Dockerfile:4` is `COPY repo/ …`, and excluding `repo/` from the build context makes that COPY fail (`not found in build context or excluded by .dockerignore`).
- Do not add a second `<release>` entry to the metainfo without first replacing CI's address-less `sed`.
- Do not push docs-only changes to `main` casually: there is no `paths-ignore`, so every push rebuilds, re-signs and redeploys.
- Do not treat a green workflow as a deploy: the Coolify `curl` (workflow 135-136) has no `--fail`, so a 401/404 still exits 0 and the step goes green while the site keeps serving the old container — the error body is printed in the log, so read it rather than trusting the checkmark.
- Do not rotate the GPG key lightly. `284A1984` appears as literal text in only two files — workflow lines 104 and 109, and README.md:64. The key material itself ships twice: `lbk.gpg` is the binary (non-armored) 4096-bit RSA *public* key whose fingerprint ends `863CFF39284A1984`, and the flatpakref `GPGKey=` blob (`:7`) is exactly `base64(lbk.gpg)` — verified byte-identical, so the two must be regenerated together. Users who ran `flatpak remote-add` pin the old key locally; a new `.flatpakref` does not fix their remote.
- Do not "clean up" `mkdir -p /app/lib{,32}/ffmpeg` (`:150`) without also fixing `ln -srv /app/lib32 /app/links/lib/i386-linux-gnu` (`:157`) — nothing populates `/app/lib32`, the real 32-bit libs live at `/app/lib/i386-linux-gnu`, and that mkdir is all that keeps the symlink from dangling. The attribution in the comment at `:136-137` has already been rewritten once (4647255 changed it from "mirrors the Heroic flatpak" to "canonical umu-launcher flatpak"); check the upstream manifest before trusting it.
- Do not change the app-id. `com.lbk.launcher` does not match the `lbklauncher.com` domain (a blocker for any future Flathub submission), but renaming it orphans every existing install and touches the manifest, both `.desktop` fields, the metainfo `<id>` / `<launchable>` / `<developer id>`, the flatpakref, and all five icon install paths.
