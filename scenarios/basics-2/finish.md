## OJT Complete: You Can Debug!

You've proven you can diagnose real Kubernetes failures — not just fix typos.

- **`kubectl describe`:** The Events section at the bottom reveals *why* a pod failed to start — image pull errors, scheduling failures, and probe misconfigurations all show up here.
- **`kubectl logs`:** When a container starts but crashes immediately, the application logs tell you exactly what went wrong. Always check logs before guessing.
- **Kubernetes Secrets:** Never hardcode credentials in manifests. Use `kubectl create secret` and reference them with `secretKeyRef`. Anyone with `kubectl get deployment -o yaml` access can read plaintext values!

You are now cleared for the advanced challenges. The rogue elves won't know what hit them.
