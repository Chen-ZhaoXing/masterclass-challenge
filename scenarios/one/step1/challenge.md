## Jam 1

The application deployed in the kubernetes cluster now reads a secret from an environment variable `APP_TOKEN`. 

We were told that referencing secrets in environment variables does not meet the security posture. 

The application team has now edited the source code & rebuilt the container image to read the secret from a file with the environment variable `APP_TOKEN_PATH` instead.

### Your task
The application token already exists in the cluster inside a Secret named masterclass-auth.

Inside this Secret, the token is stored under the specific data key: legacy-sys-token.

Strict Requirement: The application validation script requires the secret file to be mounted into the container and named exactly credentials.key (with the extension).

Set the APP_TOKEN_PATH environment variable to point to the absolute path of credentials.key.

Edit the Helm chart at ~/masterclass-fastapi-app/ to implement this.






