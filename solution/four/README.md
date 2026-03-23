# Challenge 4: The Frozen Handshake - Solution

## The Vulnerability
The elves successfully routed internal traffic to a TLS-enabled endpoint, but neglected to configure the client application to trust the Certificate Authority. Because the client couldn't verify the TLS handshake, it crashed safely, isolating itself.

## The Solution
We updated the frontend `deployment.yaml` to retrieve the correct certificates and provide them to the application logic:

1. **Certificate Volumes:** Included a `volumes` block mapping to the secret `northpole-ca`.
2. **VolumeMounts:** Mapped the certificate into the container at `/etc/tls`.
3. **Application Configuration:** Set the `TLS_CERT_PATH` environment variable so the Curl operations inside the container knew exactly where to find and load the internal CA certificate (`/etc/tls/ca.crt`) to complete the handshake securely.
