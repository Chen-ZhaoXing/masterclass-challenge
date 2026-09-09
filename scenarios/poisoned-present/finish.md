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
Slim only means "fewer packages" — not "newer packages." Once a base image stops getting patches, every bug found in it afterward just stays there.

**Problem 2: Old pinned dependencies**

```
# ❌ years-old, known issues
urllib3==1.23       Pillow==8.1.0
PyYAML==5.3.1       requests==2.24.0

# ✅ patched versions
urllib3>=2.2.2      Pillow>=10.3.0
PyYAML>=6.0.1       requests>=2.32.0
```
Pinning versions is good practice — but a pin is a promise you have to keep renewing.

**Problem 3: A dependency you never wrote down**

The scan flagged `starlette`, which appears nowhere in `requirements.txt`. It arrives through FastAPI — and the old `fastapi==0.115.6` pin held it *below* its own patched release.

```
# ❌ this line was capping starlette, three CVEs deep
fastapi==0.115.6

# ✅ a floor, not a ceiling
fastapi>=0.122.0
```

This is the part people miss. `==` doesn't just pin the package you named; it pins everything that package depends on. **An upper bound on one library can quietly hold a dozen others back.** Write floors (`>=`) unless you have a specific reason to cap.

**Problem 4: Shipping tools you don't run**

`msgpack` and `setuptools` showed up in the scan even though neither is imported anywhere — they came from pip's own bundled dependency list. Your app doesn't install packages at runtime, so pip doesn't need to be in the final image:

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt && \
    python -m pip uninstall -y pip
```

Same reasoning retired `gcc`. Every tool left in a production image is attack surface you're carrying for no reason.

**Problem 5: Fixed vs. unfixed**

Not every known issue has a patch available yet. We only fail the build on ones that *do* — chasing an unfixed issue wastes time, since there's nothing to upgrade to.

### Before / After

| | Before | After |
|---|---|---|
| Base image | `python:3.9-slim` (EOL) | `python:3.13-slim` |
| Fixable HIGH/CRITICAL | 97 | 0 |
| Build tooling in image | `gcc`, `pip` | neither |
| Image size | Small | Smaller (~59 MB) |
| App | Working | Working |

### Going Further

- Wire this scan into CI so a bad image never reaches the registry
- Audit your lockfile for upper bounds — they're where stale transitive deps hide
- Distroless base images take "ship nothing you don't run" to its conclusion
- Tools like Dependabot can open a PR the moment a fix ships, so nobody has to remember to check
