> **Points:** 100 · **Time:** ~15 min
>
> **Prerequisites:** Basic Docker knowledge
>
> **You'll learn:** Reading a vulnerability scan, fixed vs. unfixed issues, why a small image isn't automatically a safe one.

# The Poisoned Present

## The Situation

Every year the Sleigh Telemetry Service passes its pre-flight review without comment. It is small, it runs as an unprivileged user, and the dashboard the Chief Holiday Officer actually looks at has been solid green since the day it shipped.

Then a routine supply-chain scan was run against it for the first time — and came back with **96 fixable HIGH and CRITICAL findings.**

Nothing had broken. Nothing had changed. The image had simply sat there, unrebuilt, while the world moved on around it: the base image reached end-of-life and stopped receiving patches, and the dependency versions frozen into it aged past their own published fixes.

That is what the rogue elves were counting on. They never had to break anything. They only had to make sure nobody looked past the file size.

New rule from the Chief Holiday Officer:

> *"No image with a known, fixable HIGH or CRITICAL vulnerability ships. Full stop."*

## Your Mission

Fix the image, push it, get the scan clean. There are exactly **two files to edit**, both in `~/sleigh-telemetry/`:

- **`Dockerfile`** — the base image it starts `FROM` is end-of-life and gets no more patches
- **`requirements.txt`** — four dependencies are pinned to ancient versions

Bump both, rebuild, push, and scan again. The app still has to work when you're done.

Good luck, Security Elf.
