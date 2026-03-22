broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-http-probes.yaml -n kyverno > /dev/null 2>&1
APPLY_OUT=$(kubectl apply -f --dry-run=server -f ~/app.yaml 2>&1)
if [ $? -eq 0 ]; then
    broadcast "✅ North Pole approves of your HTTP probes!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the HTTP probes!"
    exit 1
fi