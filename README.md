# vite-plus issue #3422 reproduction

Reproduction for [voidzero-dev/vite-plus#3422](https://github.com/voidzero-dev/vite-plus/issues/3422): `vp upgrade` fails when the Node.js mirror in `VP_NODE_DIST_MIRROR` does not serve the Node.js version that the target release requires.

## Requirements

- macOS or Linux
- `bash`, `curl`, `python3`
- Network access to `vite.plus`, `registry.npmjs.org`, and `nodejs.org`

## Run

```sh
./repro.sh
```

The script does these steps:

1. It installs `vp` 1.5.0 into `./.home` (an isolated `VP_HOME`). It does not change your shell profile.
2. It removes the managed Node.js from `./.home/js_runtime/node`. The reporter had only an older Node.js (24.15.0).
3. It starts `mirror.py` on `127.0.0.1:18422` and runs `vp upgrade 1.5.1` with `VP_NODE_DIST_MIRROR` set to that mirror.

`mirror.py` returns `403` for each version in `BLOCK_VERSIONS` (default `24.22.2`). This simulates a mirror that has not synced the release yet. For all other paths, it redirects to `https://nodejs.org/dist`.

## Expected result

`vp upgrade` installs 1.5.1. Vite+ can use the Node.js that is already installed, or it can show an error that tells the user what to do.

## Actual result

```
info: checking for updates...
info: found vite-plus@1.5.1 (current: 1.5.0)
info: downloading vite-plus@1.5.1 for darwin-arm64...
info: installing...
info: Preparing Node.js and pnpm...
[mirror] "GET /v24.22.2/SHASUMS256.txt.asc HTTP/1.1" 403 -
[mirror] "GET /v24.22.2/SHASUMS256.txt HTTP/1.1" 403 -
error: Setup error: Failed to install Node.js 24.22.2: Failed to download from http://127.0.0.1:18422/v24.22.2/SHASUMS256.txt: HTTP status client error (403 Forbidden) for url (http://127.0.0.1:18422/v24.22.2/SHASUMS256.txt)
```

## Control

The same upgrade succeeds when the mirror blocks no version:

```sh
BLOCK_VERSIONS=none ./repro.sh
```

```
✓ Updated vite-plus from 1.5.0 → 1.5.1
```

## Options

| Variable         | Default    | Description                          |
| ---------------- | ---------- | ------------------------------------ |
| `VP_FROM`        | `1.5.0`    | Installed `vp` version               |
| `VP_TO`          | `1.5.1`    | Target version for `vp upgrade`      |
| `BLOCK_VERSIONS` | `24.22.2`  | Comma-separated Node.js versions that return 403 |
| `PORT`           | `18422`    | Mirror port                          |

## Cleanup

```sh
rm -rf .home
```
