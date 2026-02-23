## Jam 1

The application deployed in the kubernetes cluster now reads a secret from an environment variable `APP_TOKEN`. 

We were told that referencing secrets directly in environment variables are not good security practices. 

The application team has now edited the source code to read the secret from a file with the environment variable `APP_TOKEN_PATH` instead.

The application docker image is built and added to helm chart.

### Your task 
- Edit the existing helm chart at `~/masterclass-fastapi-app/templates/deployment.yaml`
- Follow the security recommendations & pratices
- Edit the values file at `~/masterclass-fastapi-app/values.yaml`
- Deploy the application into the namespace `challenge1`




