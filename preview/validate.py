#!/usr/bin/env python3
"""Validate Killercoda scenarios in this repo before pushing them live.

Killercoda has no dry-run: once the GitHub repo is connected, every push to the
tracked branch republishes whatever is in scenarios/. This checks the things
that silently produce a broken or unlisted scenario there.
"""
import glob
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENARIOS = os.path.join(REPO, "scenarios")

# Backends and layouts Killercoda accepts. A typo here yields a scenario that
# syncs but refuses to start, with no error shown in the creator dashboard.
KNOWN_BACKENDS = {
    "kubernetes-kubeadm-1node", "kubernetes-kubeadm-2nodes",
    "kubernetes-kubeadm-1node-1.29", "ubuntu", "ubuntu-4gb", "ubuntu-24gb",
    "docker", "kubernetes-kind",
}
KNOWN_LAYOUTS = {"default", "ide", "terminal", "external"}

problems, warnings = [], []


def fail(scenario, msg):
    problems.append("%s: %s" % (scenario, msg))


def warn(scenario, msg):
    warnings.append("%s: %s" % (scenario, msg))


def check_file(scenario, base, relpath, label):
    path = os.path.join(base, relpath)
    if not os.path.isfile(path):
        fail(scenario, "%s points at '%s', which does not exist" % (label, relpath))
        return None
    if os.path.getsize(path) == 0:
        fail(scenario, "%s ('%s') is empty" % (label, relpath))
        return None
    with open(path, "rb") as fh:
        raw = fh.read()
    if b"\r\n" in raw:
        fail(scenario, "%s ('%s') has CRLF line endings; scripts fail on the VM" % (label, relpath))
    if relpath.endswith(".sh") and not raw.startswith(b"#!"):
        warn(scenario, "%s ('%s') has no shebang" % (label, relpath))
    return raw


def check_scenario(sdir):
    scenario = os.path.basename(sdir)
    index = os.path.join(sdir, "index.json")
    if not os.path.isfile(index):
        fail(scenario, "no index.json; Killercoda will ignore this directory")
        return
    try:
        with open(index) as fh:
            cfg = json.load(fh)
    except ValueError as exc:
        fail(scenario, "index.json is not valid JSON: %s" % exc)
        return

    for key in ("title", "description"):
        if not cfg.get(key):
            fail(scenario, "index.json is missing required key '%s'" % key)
    if not cfg.get("time"):
        warn(scenario, "no 'time' set; the scenario card shows no duration")

    details = cfg.get("details") or {}
    if not details:
        fail(scenario, "index.json has no 'details' block")
        return

    intro = details.get("intro") or {}
    if not intro.get("text"):
        fail(scenario, "details.intro.text is not set")
    else:
        check_file(scenario, sdir, intro["text"], "details.intro.text")
    for hook in ("foreground", "background"):
        if intro.get(hook):
            check_file(scenario, sdir, intro[hook], "details.intro.%s" % hook)

    steps = details.get("steps") or []
    if not steps:
        fail(scenario, "details.steps is empty; there is nothing for a student to do")
    for i, step in enumerate(steps, 1):
        if not step.get("title"):
            warn(scenario, "step %d has no title" % i)
        if not step.get("text"):
            fail(scenario, "step %d has no 'text'" % i)
        else:
            check_file(scenario, sdir, step["text"], "step %d text" % i)
        if not step.get("verify"):
            warn(scenario, "step %d has no 'verify'; it cannot be graded" % i)
        else:
            check_file(scenario, sdir, step["verify"], "step %d verify" % i)

    finish = details.get("finish") or {}
    if finish.get("text"):
        check_file(scenario, sdir, finish["text"], "details.finish.text")
    else:
        warn(scenario, "no details.finish.text; students get no closing screen")

    # Asset globs are resolved relative to the scenario directory. A glob that
    # matches nothing fails silently: the VM just comes up without the files.
    for host, entries in (details.get("assets") or {}).items():
        for entry in entries:
            pattern = entry.get("file")
            if not pattern:
                fail(scenario, "asset entry for %s has no 'file'" % host)
                continue
            # Killercoda resolves asset globs relative to the scenario's
            # assets/ directory, not the scenario root.
            matches = glob.glob(os.path.join(sdir, "assets", pattern), recursive=True)
            files = [m for m in matches if os.path.isfile(m)]
            if not files:
                fail(scenario, "asset glob '%s' (%s) matches no files" % (pattern, host))
            if not entry.get("target"):
                warn(scenario, "asset glob '%s' has no 'target'" % pattern)

    backend = (cfg.get("backend") or {}).get("imageid")
    if not backend:
        fail(scenario, "backend.imageid is not set")
    elif backend not in KNOWN_BACKENDS:
        warn(scenario, "backend.imageid '%s' is not one I recognise; confirm it on killercoda.com" % backend)

    layout = (cfg.get("interface") or {}).get("layout")
    if layout and layout not in KNOWN_LAYOUTS:
        warn(scenario, "interface.layout '%s' is not a known layout" % layout)

    print("  checked %s (%d step%s)" % (scenario, len(steps), "" if len(steps) == 1 else "s"))


def main():
    if not os.path.isdir(SCENARIOS):
        print("No scenarios/ directory at %s" % SCENARIOS)
        return 1
    dirs = sorted(d for d in glob.glob(os.path.join(SCENARIOS, "*")) if os.path.isdir(d))
    print("Validating %d scenario(s) in %s" % (len(dirs), SCENARIOS))
    for sdir in dirs:
        check_scenario(sdir)

    print("")
    for w in warnings:
        print("  WARN  %s" % w)
    for p in problems:
        print("  FAIL  %s" % p)
    print("")
    if problems:
        print("%d blocking problem(s). Do not push until these are fixed." % len(problems))
        return 1
    print("No blocking problems. %d warning(s)." % len(warnings))
    return 0


if __name__ == "__main__":
    sys.exit(main())
