## Restore the TLS Handshake

The telemetry client currently fails because it cannot find a trusted certificate file.

Your Helm chart now deploys both:

- a simple HTTPS endpoint app (`tls-echo`), and
- a client pod (`challenge4-tls-client`) used to test connectivity.

Your task is to update `~/tls-client-chart/templates/deployment.yaml` so that:

1. The certificate secret `northpole-ca` is mounted into the container as a volume.
2. `TLS_CERT_PATH` points to the mounted certificate file (`ca.crt`).
3. The pod becomes healthy and remains running.

### Helpful commands

```bash
helm upgrade --install challenge4 ~/tls-client-chart -n challenge4
kubectl get pods -n challenge4
kubectl logs -n challenge4 deploy/challenge4-tls-client --tail=50
helm template challenge4 ~/tls-client-chart
kubectl exec -n challenge4 deploy/challenge4-tls-client -- sh -c 'echo "$TLS_CERT_PATH"'
kubectl exec -n challenge4 deploy/challenge4-tls-client -- sh -c 'curl -v https://tls-echo.challenge4.svc.cluster.local:8443/'
kubectl exec -n challenge4 deploy/challenge4-tls-client -- sh -c 'curl -v --cacert "$TLS_CERT_PATH" https://tls-echo.challenge4.svc.cluster.local:8443/'
```

### Expected behavior

- Before fixing the chart, `curl` without cert fails with TLS trust errors, and `curl --cacert "$TLS_CERT_PATH"` fails because cert path is missing/unmounted.
- After mounting `northpole-ca` and setting `TLS_CERT_PATH` to `<mountPath>/ca.crt`, the same `curl` command should return `north-pole-secure-endpoint`.

Once you are done, run verification.
