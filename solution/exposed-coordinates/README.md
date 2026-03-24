# Challenge 1: The Exposed Coordinates - Solution

## The Vulnerability
In this challenge, the rogue elves originally deployed the application with the `APP_TOKEN` credentials defined as a plaintext environment variable. This meant anyone who could view the pod configuration, container process tree, or logs could easily steal the token.

## The Solution
To securely pass the coordinates to the application, we leverage **Kubernetes Secrets mounted as Volumes**:

1. **Volume Definition:** We added a `volumes` section that references the existing `masterclass-auth` Secret.
2. **Volume Mount:** Inside the container spec, we added `volumeMounts` to mount this secret securely to `/app/token` (marked as `readOnly: true`).
3. **Environment Variable Update:** Instead of passing the raw token, we updated the environment variable to `APP_TOKEN_PATH: /app/token/credentials.key` so the application knows where to read the securely injected file from memory (tmpfs).

By taking this approach, the secret is never exposed in the manifest definition or deployment logs!
