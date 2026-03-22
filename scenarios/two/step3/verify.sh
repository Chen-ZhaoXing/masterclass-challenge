broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl apply -f /var/kyverno-policies/require-labels.yaml -n kyverno >/dev/null 2>&1
kubectl apply -f ~/app.yaml
if [ $? -eq 0 ]; then
    broadcast "✅ North Pole approves of your labels!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the labels!"
    exit 1