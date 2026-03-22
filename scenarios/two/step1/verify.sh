broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-resource-limits.yaml -n kyverno >/dev/null 2>&1

if kubectl apply -f ~/app.yaml --dry-run=server --force >/dev/null 2>&1; then
    broadcast "✅ North Pole approves of your resource requests and limits!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the resource requests and limits"
    exit 1
fi