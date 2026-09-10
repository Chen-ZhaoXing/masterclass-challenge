> **Points:** 50 · **Time:** ~15 min
>
> **Prerequisites:** Basic Docker knowledge
>
> **You'll learn:** Reading a vulnerability scan, fixed vs. unfixed issues, why a small image isn't automatically a safe one.

# The Poisoned Present

## The Situation

The Sleigh Telemetry image is slim now — the bloated, root-running version is gone. But a security scan just found something worse: **the base image and several dependencies haven't been updated in years.**

A small image isn't automatically a safe one. The rogue elves snuck old, vulnerable packages back in, betting nobody would look past the file size.

New rule from the Chief Holiday Officer:

> *"No image with a known, fixable HIGH or CRITICAL vulnerability ships. Full stop."*

## Your Mission

Fix the image, push it, get the scan clean. There are exactly **two files to edit**, both in `~/sleigh-telemetry/`:

- **`Dockerfile`** — the base image it starts `FROM` is end-of-life and gets no more patches
- **`requirements.txt`** — four dependencies are pinned to ancient versions

Bump both, rebuild, push, and scan again. The app still has to work when you're done.

Good luck, Security Elf.
