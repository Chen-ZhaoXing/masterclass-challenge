broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

kubectl delete clusterpolicies --all --force
kubectl apply -f /var/kyverno-policies/require-non-root.yaml > /dev/null 2>&1

APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
APPLY_EXIT=$?

if [ $APPLY_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your Non Root Configuration!"
else
    broadcast "❌ North Pole needs you to set the Non Root Configuration!"
    exit 1
fi

kubectl apply -f /var/kyverno-policies/require-drop-all.yaml > /dev/null 2>&1
BONUS_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
BONUS_EXIT=$?

if [ $BONUS_EXIT -eq 0 ]; then
    broadcast "🌟 BONUS ACHIEVED: North Pole approves of your Drop All Capabilities Configuration!"
else
    broadcast "❌ North Pole needs you to set the Drop All Capabilities Configuration!"
fi

broadcast "============================================================\n"
broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
broadcast "        rpSfRGkcco6/wFV9XcMNR+boN8EQ0k2mVN9p06cSqfc=        \n"
broadcast "============================================================\n"

exit 0
