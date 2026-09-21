#!/bin/bash

_bc_write() {
    # \r\n, not \n: readline leaves the pty in raw mode while it waits for
    # input, so a bare newline is line-feed only and the text lands indented at
    # the cursor column.
    printf '\r\n%s\r\n' "$2" > "$1" 2>/dev/null
    # Nudge the row count so readline redraws the prompt; without this the
    # terminal looks frozen until the student presses Enter.
    rows=$(stty -F "$1" size 2>/dev/null | cut -d' ' -f1)
    if [ -n "$rows" ]; then
        stty -F "$1" rows $((rows + 1)) 2>/dev/null
        stty -F "$1" rows "$rows" 2>/dev/null
    fi
}

broadcast() {
    # Write ONCE. This used to loop over every writable pty, and the Killercoda
    # box has two that both render to the student's terminal - which is why every
    # message appeared twice. Prefer a pty that has a process attached to it; if
    # none does, fall back to writing to all of them so feedback is never lost.
    for pts in /dev/pts/[0-9]*; do
        [ -w "$pts" ] || continue
        if ps -e -o tty= 2>/dev/null | grep -qx "${pts#/dev/}"; then
            _bc_write "$pts" "$1"
            return
        fi
    done
    for pts in /dev/pts/[0-9]*; do
        [ -w "$pts" ] && _bc_write "$pts" "$1"
    done
}

TARGET="deployment.yaml"

if [ ! -f ~/"$TARGET" ]; then
    broadcast "❌ Missing ~/$TARGET file!"
    exit 1
fi

# Apply the user's manifests
kubectl apply -f ~/"$TARGET" >/dev/null 2>&1
APPLY_EXIT=$?

if [ $APPLY_EXIT -ne 0 ]; then
    broadcast "❌ Your manifest failed to apply to the cluster. Please check for syntax errors."
    exit 1
fi

# Query the running deployment to find the volume mounted at /app/data
VOL_NAME=$(kubectl get deployment gift-tracker -o jsonpath='{.spec.template.spec.containers[?(@.name=="tracker")].volumeMounts[?(@.mountPath=="/app/data")].name}')

if [ -z "$VOL_NAME" ]; then
    broadcast "❌ North Pole needs you to mount a volume to the exact path '/app/data' inside the 'tracker' container!"
    exit 1
fi

# Retrieve the PVC claim name for that volume from the deployment spec
CLAIM_NAME=$(kubectl get deployment gift-tracker -o jsonpath='{.spec.template.spec.volumes[?(@.name=="'"$VOL_NAME"'")].persistentVolumeClaim.claimName}')

if [ -z "$CLAIM_NAME" ]; then
    broadcast "❌ The volume mounted at /app/data is not backed by a persistentVolumeClaim!"
    exit 1
fi

# Verify the user actually created the PersistentVolumeClaim
kubectl get pvc "$CLAIM_NAME" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The PersistentVolumeClaim '${CLAIM_NAME}' does not exist in the cluster. Did you define and apply it?"
    exit 1
else
    broadcast "✅ North Pole approves: PersistentVolumeClaim '${CLAIM_NAME}' exists and is mounted!"
fi

# Step 1 provisioned MongoDB a disk. Only a volumeMounts entry makes MongoDB
# actually write to it, and nothing checked that: step 1 reads
# volumeClaimTemplates and this step used to look only at the gift-tracker
# Deployment. A claim nobody mounts leaves /data/db on ephemeral container
# storage, so the original data-loss bug survived a fully passing challenge.
MONGO_VOL=$(kubectl get statefulset mongodb -o jsonpath='{.spec.template.spec.containers[?(@.name=="mongodb")].volumeMounts[?(@.mountPath=="/data/db")].name}' 2>/dev/null)
if [ -z "$MONGO_VOL" ]; then
    broadcast "❌ MongoDB has a claim but nothing mounts it - /data/db is still ephemeral. Add a volumeMounts entry to the mongodb container in statefulset.yaml."
    exit 1
fi

# ...and it has to mount the claim template, not some unrelated volume. The
# two are linked only by name, which is the easiest thing to get out of step.
TEMPLATE_NAME=$(kubectl get statefulset mongodb -o jsonpath='{.spec.volumeClaimTemplates[*].metadata.name}' 2>/dev/null)
case " $TEMPLATE_NAME " in
    *" $MONGO_VOL "*)
        broadcast "✅ North Pole approves: MongoDB mounts its claim at /data/db - the data survives a restart."
        ;;
    *)
        broadcast "❌ The volume mounted at /data/db is '${MONGO_VOL}', but the volumeClaimTemplates is named '${TEMPLATE_NAME}'. They must use the same name."
        exit 1
        ;;
esac

# Verify the user created the 'mongodb-service' to fix network connectivity
kubectl get service mongodb-service >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The Python app is isolated! North Pole needs you to create the 'mongodb-service' Service so it can route to the database!"
    exit 1
else
    broadcast "✅ North Pole approves: 'mongodb-service' Service was successfully created!"
fi

broadcast "✅ North Pole approves of your solution!"
broadcast "🏁 CHALLENGE COMPLETE - submit this flag in CTFd: aWxvdmVfbWFzdGVyY2xhc3NfMjAyNl9zZXA="

exit 0
