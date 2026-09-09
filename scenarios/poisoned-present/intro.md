> **Points:** 200 · **Time:** ~25 min
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

Fix the image, push it, get the scan clean.

- Look at the `Dockerfile` and `requirements.txt` in `~/sleigh-telemetry/`
- The base image **and** the dependency versions are outdated — start there
- Then scan again. Not every finding will point at a line you can edit
- The app still has to work after your fix

Good luck, Security Elf.
