# Scenario Objective: Put the Elf Back in Line

You know why the shop keeps slamming shut. Fix the `gift-registry` Deployment in namespace `workshop` so the elf's catalog rebuild is guaranteed to **exit successfully before the shop container starts**.

The manifest to fix is `~/app.yaml`.

Requirements:

- The elf's work (migrate + restock) must run to completion **first** — not in parallel with the shop.
- The shop container must only start once that work has **exited with code 0**.
- `wait-for-db` must keep doing its job.
- Don't cheat by removing the elf — the shelves still have to be restocked.

Apply your change to the **Deployment** (not a temporary Pod), then wait a moment for a fresh Pod to boot. You'll know it's fixed when:

```bash
kubectl -n workshop get pods -l app=gift-registry
# NAME                           READY   STATUS    RESTARTS
# gift-registry-...              1/1     Running   0

kubectl -n workshop exec deploy/gift-registry -- \
  python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8000/healthz").read())'
# {"status": "ok", "catalog_rows": 15000}
```

1. Edit `~/app.yaml` so the elf's work finishes before the shop container starts.
2. Redeploy: `kubectl apply -f ~/app.yaml`{{exec}}
3. Watch a fresh Pod come up healthy: `kubectl -n workshop get pods -w`{{exec}}
4. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
