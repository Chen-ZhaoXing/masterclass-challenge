# Local preview

Killercoda has no dry-run and no local preview: the only way to see a scenario
there is to connect this GitHub repo to a creator profile and push, which
publishes it. These two scripts close that gap so scenario content can be
reviewed, and obvious deploy blockers caught, before anything goes live.

Both use only the Python standard library plus `markdown`, and neither touches
the network.

## Preview the scenario

```bash
python3 preview/serve.py          # http://localhost:8777
python3 preview/serve.py --port 9000 --no-open
```

Renders every scenario in `scenarios/` straight from the working tree:

- **Left pane** — intro, each step, and finish, with the same navigation a
  student gets. Deep-linkable: `#p1/terminal` is step 1 with the terminal tab open.
- **Editor tab** — the asset files at the paths `index.json` actually places them
  (`assets` globs resolved against `assets/`, `target` expanded), so a wrong glob
  or a lost `src/` subdirectory shows up here.
- **Terminal tab** — the student's opening screen, from `foreground.sh`'s literal
  `echo` lines. Branches are tracked, so failure-path output is dimmed and
  labelled rather than shown alongside the success path.
- **Scripts tab** — `background.sh`, `foreground.sh` and `verify.sh` as source,
  for authoring review.

**What it cannot do.** There is no VM here: no cluster, no registry, no Trivy.
Nothing in `scenarios/` is executed, real command output is never invented, and
the Check button cannot pass or fail a step — it opens the relevant `verify.sh`
instead. Anything that depends on the live environment is still only verifiable
on Killercoda.

## Validate before pushing

```bash
python3 preview/validate.py       # exit 0 = no blocking problems
```

Catches the failures that are silent on Killercoda: malformed `index.json`, a
`text`/`verify`/`foreground`/`background` key pointing at a missing or empty
file, an asset glob matching nothing, CRLF line endings in a `.sh`, a missing
shebang, an unknown `backend.imageid` or `interface.layout`.

Suitable as a pre-push hook or CI step.

## Deploying to Killercoda

Publishing is a one-time connection, then plain `git push`:

1. Sign in at <https://killercoda.com/creators> with GitHub.
2. Add this repository and pick the branch to track.
3. Killercoda reads `scenarios/*/index.json`; every push to that branch
   republishes. The scenario lands at
   `killercoda.com/<profile>/scenario/<directory-name>`.

Step 1 is an interactive OAuth grant on their site and cannot be scripted.
