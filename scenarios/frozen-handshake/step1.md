## Restore the TLS Handshake

The telemetry client currently fails because it cannot find a trusted certificate file.

Your Helm chart now deploys both:

- a simple HTTPS endpoint app (`tls-echo`), and
- a client pod (`challenge4-tls-client`) used to test connectivity.

Your task is to update `~/tls-client-chart/templates/deployment.yaml` so that:

1. The certificate secret `northpole-ca` is mounted into the container as a volume.
2. `TLS_CERT_PATH` points to the mounted certificate file (`ca.crt`).
3. The pod becomes healthy and remains running.


### Expected behavior

- Before fixing the chart, `curl` without cert fails with TLS trust errors, and `curl --cacert "$TLS_CERT_PATH"` fails because cert path is missing/unmounted.
- After mounting `northpole-ca` and setting `TLS_CERT_PATH` to `<mountPath>/ca.crt`, the same `curl` command should return `north-pole-secure-endpoint`.

## Your Task

1. Run `kubectl exec -n challenge4 deploy/challenge4-tls-client -- sh -c 'curl -v --cacert "$TLS_CERT_PATH" https://tls-echo.challenge4.svc.cluster.local:8443/'`{{exec}} and see the output without a CA cert
2. Update the `deployment.yaml` file found at `tls-client-chart/templates` accordingly
3. Once done, upgrade your helm deployment `helm upgrade --install challenge4 ~/tls-client-chart -n challenge4`{{exec}}
4. Ensure pods are running with `kubectl get pods -n challenge4`{{exec}}
5. Click the `Check` button!

Once you are done, run verification.
