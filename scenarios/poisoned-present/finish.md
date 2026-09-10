## Challenge Complete: The Supply Chain is Clean

The scan comes back clean. The image is now both small **and** current — two different things, and the rogue elves were counting on you mixing them up.

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

**Problem 2: Old pinned dependencies**

```
# ❌ years-old, known issues
urllib3==1.23       Pillow==8.1.0
PyYAML==5.3.1       requests==2.24.0

# ✅ patched versions, as floors
urllib3>=2.2.2      Pillow>=10.3.0
PyYAML>=6.0.1       requests>=2.32.0
```

Pinning versions is good practice — but a pin is a promise you have to keep renewing.

**Why `>=` and not `==`?**

If you tried bumping `urllib3` on its own, pip probably stopped you:

```
ERROR: Cannot install -r requirements.txt (line 7) and urllib3>=2.2.2
because these package versions have conflicting dependencies.
```

`requests==2.24.0` requires `urllib3<1.26`. An exact pin doesn't just freeze the package you named — **it freezes everything that package depends on too.** That's how one stale line quietly holds a dozen others back.

A floor (`>=`) says "at least this new, newer is fine," so a rebuild picks up patches automatically. Use a ceiling only when you have a specific reason.

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
