broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml
touch /tmp/setup-finished
broadcast "✅ The Lab is now ready!"
