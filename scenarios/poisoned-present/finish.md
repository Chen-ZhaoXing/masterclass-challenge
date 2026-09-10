## Challenge Complete: The Supply Chain is Clean

The scan comes back clean. The image was always small. Now it is also **current** — and those were never the same property, which is exactly what the rogue elves were counting on.

📸 **For CTFd:** screenshot the `SUPPLY CHAIN CHECK PASSED` output from your terminal and submit it as your challenge answer.

---

### Why This Mattered

**Problem 1: An outdated base image**

```dockerfile
# ❌ python:3.9 - no longer gets security patches
FROM python:3.9-slim

# ✅ a currently-supported version
FROM python:3.13-slim
```

Slim only means "fewer packages" — not "newer packages." Once a base image stops getting patches, every bug found in it afterward just stays there. This one line was responsible for **55 of the findings**, most of them in `openssl` and `util-linux`.

**Why bumping the base image actually fixed anything**

Here is the part that surprises people: `python:3.9-slim` and `python:3.13-slim` are **both Debian 13**. Changing that line did not move you to a newer operating system.

What changed is how recently the image was **rebuilt**.

Docker Hub rebuilds its images periodically, and each rebuild pulls in whatever Debian packages are current that day. When a Python version reaches end-of-life, those rebuilds stop — and the OS packages inside it freeze at whatever was current on the last build. Debian keeps publishing patches; that image just never picks them up again.

That is exactly what the scan was showing you:

```
Library:            openssl
Installed Version:  3.5.1-1+deb13u1     <- frozen in an image nobody rebuilds
Fixed Version:      3.5.5-1~deb13u2     <- Debian shipped this; your image missed it
```

A `Fixed Version` means the distro **has** published the patch. If your image doesn't have it, the image is stale, not the distro.

**How you find the version to move to**

The scanner won't tell you. Trivy reports that a fix exists; it has no idea which base image contains it. That step is yours:

1. A `Fixed Version` is listed → a patch exists
2. Your image doesn't have it → your base hasn't been rebuilt since
3. Rebuilds stop at end-of-life → check whether your version is still supported
4. Move to one that is — [endoflife.date/python](https://endoflife.date/python) is the fastest way to check

**The outcome worth remembering**

"Currently supported" is not the same as "patched right now." Even a supported base image drifts between rebuilds — a CVE published today sits in it until Docker Hub rebuilds and you pull again.

So the fix isn't only picking a fresher base. It's **scanning on a schedule, not just when you change something**. This image passed its review every year precisely because nobody re-scanned an artifact that hadn't changed.

**Problem 2: Old pinned dependencies**

```
# ❌ years-old, known issues
urllib3==1.23       Pillow==8.1.0
PyYAML==5.3.1       requests==2.24.0

# ✅ past the patched release
urllib3>=2.2.2      Pillow>=10.3.0
PyYAML>=6.0.1       requests>=2.32.0
```

Pinning versions is good practice — but a pin is a promise you have to keep renewing.

**The pin that fought back**

If you tried bumping `urllib3` on its own, pip probably stopped you:

```
ERROR: Cannot install -r requirements.txt (line 7) and urllib3>=2.2.2
because these package versions have conflicting dependencies.
```

`requests==2.24.0` has no finding of its own — it looks innocent. But it requires `urllib3<1.26`, so it blocks the fix for a package that *does* have one. A stale pin doesn't just freeze the package you named — **it freezes everything that package depends on too.** That's how one forgotten line quietly holds a dozen others back.

**So should you pin at all?**

Worth getting right, because the two obvious answers are each wrong on their own.

A floor (`>=`) lets a rebuild pick up patches automatically. It also means whatever pip resolves on build day is what ships: two builds of identical source produce different images, and a compromised upstream release reaches production with nobody reviewing it. That is the supply-chain attack this challenge is named after.

An exact pin (`==`) gives you a build you can reproduce and review — and then it rots. Look at how this image broke: exact pins, correct on the day they were written, left alone for years.

> **Pinning isn't the problem. Unattended is the problem.**

The production answer is exact pins — ideally hash-locked, via `pip-compile --generate-hashes`, `uv lock` or `poetry.lock` — with an automated updater opening a reviewed pull request the day a patch ships. That gets you patching, reproducibility, *and* review, instead of trading one away for another.

The floors above are fine for clearing this scan. They are not what you ship without something watching them.

**Problem 3: Fixed vs. unfixed**

Not every known issue has a patch available yet. We only fail the build on ones that *do* — that's the `--ignore-unfixed` flag. Chasing an unfixed CVE wastes time, since there's nothing to upgrade to. Re-run the scan periodically anyway: unfixed CVEs become fixed CVEs the moment a patch ships.

### Before / After

| | Before | After |
|---|---|---|
| Base image | `python:3.9-slim` (EOL) | `python:3.13-slim` |
| Fixable HIGH/CRITICAL | 96 | 0 |
| Image size | ~60 MB | ~60 MB |
| App | Working | Working |

Note the size column. Nothing about this fix made the image bigger or smaller — **size and safety are independent**, which was the whole trick the rogue elves were relying on.

### Going Further

- Wire this scan into CI so a bad image never reaches the registry
- Audit your lockfile for upper bounds — they're where stale transitive dependencies hide
- A runtime image doesn't need a package manager or a compiler; this one already drops `pip` after install, and `gcc` is only there to build one outdated package
- Distroless base images take "ship nothing you don't run" to its conclusion
- Tools like Dependabot can open a PR the moment a fix ships, so nobody has to remember to check
