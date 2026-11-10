# vite-plus issue #3422 reproduction

Reproduction for [voidzero-dev/vite-plus#3422](https://github.com/voidzero-dev/vite-plus/issues/3422): `vp upgrade` fails with `403 Forbidden` when `VP_NODE_DIST_MIRROR` is the aliyun mirror.

## Cause

The aliyun mirror returns `403` for requests that have no `User-Agent` header. `vp` sends its Node.js download requests without a `User-Agent` header.

```sh
./check-ua.sh
```

```
with User-Agent (curl default): 200
without User-Agent:             403
```

The mirror has the files. Its directory listing shows `v24.22.2/SHASUMS256.txt` since 2026-10-29 02:35 (UTC+8). This is the same time as the `Last-Modified` value on nodejs.org (2026-10-28 18:35 UTC).

## Why `vp upgrade` downloads Node.js 24.22.2

`vp upgrade` installs the dependencies of the new release with the Node.js version that the release specifies. The platform package metadata contains this version:

```sh
curl -s https://registry.npmjs.org/@voidzero-dev%2Fvite-plus-cli-darwin-arm64/1.5.1 | jq .vpNodeVersion
# "24.22.2"
```

The upgrade does not use the Node.js that `vp env` manages (24.15.0 in the issue). If the managed runtime cache does not contain 24.22.2, `vp` downloads it from `VP_NODE_DIST_MIRROR`.

## Requirements

- macOS or Linux
- `bash`, `curl`, `python3`
- Network access to `vite.plus`, `registry.npmjs.org`, `nodejs.org`, and `mirrors.aliyun.com`

## Run

```sh
./repro.sh                # MODE=aliyun: the real aliyun mirror
MODE=local ./repro.sh     # mirror.py: a local mirror with the same User-Agent rule
MODE=none ./repro.sh      # no mirror (control)
```

The script does these steps:

1. It installs `vp` 1.5.0 into `./.home` (an isolated `VP_HOME`) from nodejs.org. It does not change your shell profile.
2. It removes the managed Node.js from `./.home/js_runtime/node`, so that the upgrade must download Node.js 24.22.2.
3. It runs `vp upgrade 1.5.1` with `VP_NODE_DIST_MIRROR` set for the selected mode.

`mirror.py` listens on `127.0.0.1:18422`. It returns `403` when the request has no `User-Agent` header. Otherwise, it redirects to `https://nodejs.org/dist`. It also logs the `User-Agent` of each request.

## Results

| Mode     | Mirror                                       | Result                                     |
| -------- | -------------------------------------------- | ------------------------------------------ |
| `aliyun` | `https://mirrors.aliyun.com/nodejs-release`  | Fails with `403 Forbidden`                 |
| `local`  | `http://127.0.0.1:18422` (`mirror.py`)       | Fails with `403 Forbidden`                 |
| `none`   | not set (nodejs.org)                         | `✓ Updated vite-plus from 1.5.0 → 1.5.1`   |

`MODE=aliyun`:

```
info: Preparing Node.js and pnpm...
error: Setup error: Failed to install Node.js 24.22.2: Failed to download from https://mirrors.aliyun.com/nodejs-release/v24.22.2/SHASUMS256.txt: HTTP status client error (403 Forbidden) for url (https://mirrors.aliyun.com/nodejs-release/v24.22.2/SHASUMS256.txt)
```

`MODE=local` shows that `vp` sends no `User-Agent`:

```
[mirror] "GET /v24.22.2/SHASUMS256.txt.asc HTTP/1.1" 403 - user-agent=(none)
[mirror] "GET /v24.22.2/SHASUMS256.txt HTTP/1.1" 403 - user-agent=(none)
```

`vp` sends each request 4 times (1 request and 3 retries). It tries the signed `SHASUMS256.txt.asc` first. The signature is optional for a mirror that is not nodejs.org, so `vp` then tries the plain `SHASUMS256.txt`.

## Expected result

`vp upgrade` installs 1.5.1 through the aliyun mirror.

## Options

| Variable  | Default  | Description                        |
| --------- | -------- | ---------------------------------- |
| `MODE`    | `aliyun` | `aliyun`, `local`, or `none`       |
| `VP_FROM` | `1.5.0`  | Installed `vp` version             |
| `VP_TO`   | `1.5.1`  | Target version for `vp upgrade`    |
| `PORT`    | `18422`  | Port for `mirror.py` (`MODE=local`) |

## Cleanup

```sh
rm -rf .home
```
