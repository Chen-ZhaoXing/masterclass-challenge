#!/usr/bin/env python3
"""Local preview for the Killercoda scenarios in this repo.

Killercoda ships no local preview: the only way to see a scenario is to connect
the GitHub repo and push, which publishes it. This renders the same content --
intro, steps, finish, the asset files as the student receives them -- from the
working tree, so the content can be reviewed before anything goes live.

What this is not: the VM. background.sh, foreground.sh and verify.sh are shown
as source, never executed. Anything that depends on a running cluster (the Trivy
table, the Check button's real verdict) can only be exercised on Killercoda.

    python3 preview/serve.py [--port 8777] [--no-open]
"""
import argparse
import glob
import html
import json
import os
import re
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer

try:
    import markdown as md_lib
except ImportError:
    sys.exit("This preview needs the 'markdown' package: python3 -m pip install markdown")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENARIOS = os.path.join(REPO, "scenarios")
MD_EXTENSIONS = ["extra", "sane_lists"]

# Killercoda turns `cmd`{{execute}} and fenced blocks tagged {{execute}} into
# click-to-run chips. Reproduce the affordance so the markup is reviewable.
INLINE_MACRO = re.compile(r"<code>([^<]+)</code>\{\{(execute[^}]*|copy)\}\}")
BLOCK_MACRO = re.compile(r"(<pre><code[^>]*>.*?</code></pre>)\s*\{\{(execute[^}]*|copy)\}\}", re.S)


def render_markdown(text):
    out = md_lib.markdown(text, extensions=MD_EXTENSIONS)
    out = BLOCK_MACRO.sub(
        lambda m: '<div class="kc-run">%s<span class="kc-run-tag">%s</span></div>'
        % (m.group(1), html.escape(m.group(2))), out)
    out = INLINE_MACRO.sub(
        lambda m: '<code class="kc-inline-run" title="%s">%s</code>'
        % (html.escape(m.group(2)), html.escape(m.group(1))), out)
    return out


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def simulate_terminal(script_src):
    """Turn foreground.sh into a readable approximation of the opening terminal.

    Literal echo lines are shown as they will appear. Everything else is shown as
    a prompt line whose output is marked live-only -- the point is to show the
    student's first screen, not to invent results. Shell control flow is tracked
    rather than printed, so lines that only run on the failure branch of an
    if/else are labelled instead of appearing alongside the success path.
    """
    ctrl = re.compile(r"^(if|elif|while|for|case)\b|^(then|do|done|fi|esac|else)$")
    lines, branch, depth = [], None, 0
    for raw in script_src.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("if ") or line.startswith("if["):
            depth += 1
            branch = "then"
            continue
        if line == "else" and depth:
            branch = "else"
            continue
        if line == "fi" and depth:
            depth -= 1
            branch = None if depth == 0 else "then"
            continue
        if ctrl.match(line):
            continue
        m = re.match(r'^echo\s+(?:-e\s+)?"([^"$`]*)"$', line)
        if m:
            lines.append({"kind": "out", "text": m.group(1), "branch": branch})
            continue
        if line in ('echo ""', "echo ''", "echo"):
            lines.append({"kind": "out", "text": "", "branch": branch})
            continue
        lines.append({"kind": "cmd", "text": line, "branch": branch})
    return lines


def expand_target(target):
    t = target or "~/"
    if t.startswith("~"):
        t = "/root" + t[1:]
    if not t.endswith("/"):
        t += "/"
    return t


def collect_assets(sdir, details):
    """Reproduce where each asset file lands on the VM, per index.json."""
    assets_root = os.path.join(sdir, "assets")
    files = []
    for host, entries in (details.get("assets") or {}).items():
        for entry in entries:
            pattern = entry.get("file") or ""
            target = expand_target(entry.get("target"))
            for match in sorted(glob.glob(os.path.join(assets_root, pattern), recursive=True)):
                if not os.path.isfile(match):
                    continue
                rel = os.path.relpath(match, assets_root)
                try:
                    body = read(match)
                except UnicodeDecodeError:
                    body = "(binary file, %d bytes)" % os.path.getsize(match)
                files.append({
                    "host": host,
                    "path": target + rel.replace(os.sep, "/"),
                    "name": os.path.basename(match),
                    "content": body,
                })
    files.sort(key=lambda f: f["path"])
    return files


def build_scenario(sdir):
    cfg = json.loads(read(os.path.join(sdir, "index.json")))
    details = cfg.get("details") or {}
    intro = details.get("intro") or {}
    finish = details.get("finish") or {}

    pages = []
    if intro.get("text"):
        pages.append({"kind": "intro", "title": "Introduction",
                      "html": render_markdown(read(os.path.join(sdir, intro["text"])))})
    for i, step in enumerate(details.get("steps") or [], 1):
        pages.append({
            "kind": "step",
            "index": i,
            "title": step.get("title") or ("Step %d" % i),
            "html": render_markdown(read(os.path.join(sdir, step["text"]))),
            "verify": step.get("verify"),
            "verifySource": read(os.path.join(sdir, step["verify"])) if step.get("verify") else None,
        })
    if finish.get("text"):
        pages.append({"kind": "finish", "title": "Finish",
                      "html": render_markdown(read(os.path.join(sdir, finish["text"])))})

    foreground_src = read(os.path.join(sdir, intro["foreground"])) if intro.get("foreground") else ""
    background_src = read(os.path.join(sdir, intro["background"])) if intro.get("background") else ""

    return {
        "slug": os.path.basename(sdir),
        "title": cfg.get("title") or os.path.basename(sdir),
        "description": cfg.get("description") or "",
        "time": cfg.get("time") or "",
        "backend": (cfg.get("backend") or {}).get("imageid") or "",
        "layout": (cfg.get("interface") or {}).get("layout") or "default",
        "root": (cfg.get("interface") or {}).get("root") or "",
        "pages": pages,
        "assets": collect_assets(sdir, details),
        "terminal": simulate_terminal(foreground_src),
        "scripts": [s for s in [
            {"name": intro.get("background"), "src": background_src} if background_src else None,
            {"name": intro.get("foreground"), "src": foreground_src} if foreground_src else None,
        ] + [
            {"name": p["verify"], "src": p["verifySource"]}
            for p in pages if p.get("verifySource")
        ] if s],
    }


def all_scenarios():
    out = []
    for sdir in sorted(glob.glob(os.path.join(SCENARIOS, "*"))):
        if os.path.isfile(os.path.join(sdir, "index.json")):
            out.append(build_scenario(sdir))
    return out


PAGE = read(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui.html")) \
    if os.path.isfile(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui.html")) else None


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("  %s\n" % (fmt % args))

    def _send(self, body, ctype="text/html; charset=utf-8", code=200):
        raw = body.encode("utf-8") if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/api/scenarios":
            try:
                payload = json.dumps(all_scenarios())
            except Exception as exc:  # a broken scenario should say so, not 500
                payload = json.dumps({"error": str(exc)})
            self._send(payload, "application/json; charset=utf-8")
            return
        if path in ("/", "/index.html"):
            ui = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui.html")
            self._send(read(ui))
            return
        self._send("Not found", "text/plain; charset=utf-8", 404)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8777)
    ap.add_argument("--no-open", action="store_true")
    args = ap.parse_args()

    scenarios = all_scenarios()
    print("Killercoda local preview")
    print("  repo:      %s" % REPO)
    for s in scenarios:
        print("  scenario:  %s  (%d page(s), %d asset file(s), backend=%s, layout=%s)"
              % (s["slug"], len(s["pages"]), len(s["assets"]), s["backend"], s["layout"]))
    url = "http://localhost:%d/" % args.port
    print("  serving:   %s\n  Ctrl-C to stop.\n" % url)
    if not args.no_open:
        webbrowser.open(url)
    HTTPServer(("127.0.0.1", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
