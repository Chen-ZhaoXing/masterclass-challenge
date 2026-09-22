#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done

echo ""

echo ""
echo "# 🎄 The Impatient Elf - Challenge: Put the Elf Back in Line"
echo ""
echo "🔴 Intermediate • ~25 min • initContainers, Pod Startup Ordering, CrashLoopBackOff"
echo ""
echo "The rogue elves moved the catalog-restocking elf out of the prep shift. The shop opens before the shelves are stocked and crash-loops."
echo ""
echo "## Your Task"
echo ""
echo "Fix the `gift-registry` Deployment in namespace `workshop` so the elf's catalog rebuild is guaranteed to **exit successfully before the shop container starts**."
echo ""
echo "### Requirements"
echo ""
echo "- The elf's work (migrate + restock) must run to completion **first** — not in parallel with the shop."
echo "- The shop container must only start once that work has **exited with code 0**."
echo "- `wait-for-db` must keep doing its job."
echo "- Don't cheat by removing the elf — the shelves still have to be restocked."
echo ""
echo "✅ You can now begin!"
