# Your Mission

Get the vulnerability scan clean. Everything you need to change is in `~/sleigh-telemetry/` — the `Dockerfile` and `requirements.txt`.

The obvious problems are the outdated base image and the outdated version pins. Fix those first, then **scan again**.

Some findings won't map neatly onto a line you can edit:

- A flagged package may not appear in `requirements.txt` at all — something else pulled it in
- A flagged package may not be one your app actually uses

Both are still your problem. Let the scan output, not `requirements.txt`, tell you when you're done.

Then:

1. Rebuild the image
2. Push it to `localhost:30500/sleigh-telemetry:latest`
3. The app still needs to run — check `/health`

Trivy is available in your terminal to check your own work before clicking `Check`.

> 💡 Stuck? Hints are available in the challenge portal.

Click **Check** when ready.
