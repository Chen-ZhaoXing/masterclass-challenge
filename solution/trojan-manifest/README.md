# Challenge 3: The Trojan Manifest - Solution

## The Vulnerability
The elves tried to sneak in raw YAML manifests (`app.yaml`) that violated numerous security postures defined by the North Pole's admission controller. Without fixing these, the policy engine strictly blocks deployment.

## The Solution
We updated `app.yaml` to pass all validations:

1. **Resource Guardrails:** Added `resources.requests` and `resources.limits` (e.g., 100m CPU, 128Mi Memory) preventing the pod from executing a denial-of-service attack on the underlying node.
2. **Probes:** Added `livenessProbe` and `readinessProbe` to assure traffic isn't routed to dead containers.
3. **Standard Labels:** Injected `app.kubernetes.io/name` and `app.kubernetes.io/instance` to align with modern fleet management architectures.
4. **ServiceAccount Isolation:** We explicitly attached a dedicated ServiceAccount (`serviceAccountName: gift-tracking-sa`) rather than using the default SA.
5. **No Auto-Mounting (Bonus):** We explicitly set `automountServiceAccountToken: false` to verify that no unnecessary API tokens are loaded into the container.
6. **Non-Root / Capabilities (Bonus - Not enabled in base app.yaml):** Passing the `runAsNonRoot: true` security context.
