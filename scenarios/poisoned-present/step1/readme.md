# Your Mission

Get the vulnerability scan clean. There are exactly **two files to edit**, and both are already open in `~/sleigh-telemetry/`.

## 1. `Dockerfile` — the base image

The `FROM` line points at a Python release that is end-of-life. It stopped receiving security patches, so every OS-level CVE found since then is still sitting in the image. Move it to a currently-supported release.

You don't need to change anything else in this file.

## 2. `requirements.txt` — the stale pins

Four packages are pinned to exact versions that are years old. Bump each one past the release that patched it.

Three of them carry known HIGH/CRITICAL findings of their own. The fourth looks innocent — it has no finding at all — but it still has to move. You'll find out why when you try to leave it alone.

> If you bump some pins but not others, `pip` may refuse to install: an old package can hold a newer one back. Read the error — it names the conflict.

## 3. Rebuild and push

1. Rebuild the image
2. Push it to `localhost:30500/sleigh-telemetry:latest`
3. The app still needs to run — check `/health`

Trivy is available in your terminal, so you can check your own work before clicking `Check`:

```bash
trivy image --severity HIGH,CRITICAL --ignore-unfixed <your-image>
```

Trivy prints two tables. The top one is OS packages — that's your `FROM` line. The bottom one is Python packages — that's `requirements.txt`.

Note the `--ignore-unfixed` flag: some CVEs have no patch available yet, so there's nothing you could upgrade to. Those don't count against you.

> 💡 Stuck? Hints are available in the challenge portal.

Click **Check** when ready.
