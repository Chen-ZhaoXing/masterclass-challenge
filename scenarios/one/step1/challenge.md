## Jam 1

The application deployed in the kubernetes cluster now reads a secret from an environment variable `APP_TOKEN`. 

We were told that referencing secrets in environment variables does not meet the security posture. 

The application team has now edited the source code & rebuilt the container image to read the secret from a file with the environment variable `APP_TOKEN_PATH` instead.

### Your task 
- Edit the existing helm chart at `~/masterclass-fastapi-app/templates/deployment.yaml`
- Align to the security recommendations & practices
- Edit the values file at `~/masterclass-fastapi-app/values.yaml`
- Deploy the application into the namespace `challenge1`






