#!/bin/bash
#
# Step 1 verification: the player has written a root-cause report and it
# names the actual bug — that the elf is declared as a *regular* container,
# so it starts in parallel with the app instead of as an initContainer.

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
            rows=$(stty -F "$pts" size 2>/dev/null | cut -d' ' -f1)
            if [ -n "$rows" ]; then
                stty -F "$pts" rows $((rows + 1)) 2>/dev/null
                stty -F "$pts" rows "$rows" 2>/dev/null
            fi
        fi
    done
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

REPORT="${HOME:-/root}/root-cause.txt"

fail() {
    broadcast "❌ [FAIL] $1"
    if [ -f "$REPORT" ]; then
        broadcast "  Your report so far: $(head -c 240 "$REPORT" | tr '\n' ' ')"
    fi
    exit 1
}

[ -f "$REPORT" ] || fail "I can't find $REPORT — write your root cause there first (step 1 tells you what to put in it)."

text="$(tr '[:upper:]' '[:lower:]' < "$REPORT")"

# 1) Must name the init-container concept (in any reasonable spelling).
echo "$text" | grep -Eq 'init[ _-]?containers?' \
  || fail "your report doesn't mention *init containers* — the bug is about which list in the Pod spec the elf is declared in."

# 2) Must explain the parallel/simultaneous start of regular containers.
echo "$text" | grep -Eq 'parallel|simultaneous|same (time|instant|moment)|at the same|together|race|side by side|concurrent' \
  || fail "your report doesn't explain that regular containers start *at the same time* (in parallel) — that race is the heart of the bug."

# 3) Must connect the two: the elf (or its rebuild/migration/seed work) vs the app/shop.
echo "$text" | grep -Eq 'elf|rebuild|restock|seed|migrat' \
  && echo "$text" | grep -Eq 'shop|app|registry|gift' \
  || fail "your report should connect the two workloads: the elf's rebuild racing the gift-registry app."

broadcast "✅ [PASS] Root cause identified: the elf is a regular container racing the app, instead of an initContainer that finishes first."
exit 0
