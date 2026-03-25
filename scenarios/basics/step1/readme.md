# Scenario Objective: The Elf's Typo

The rogue elves left behind a `typo-app.yaml` manifest that is riddled with basic YAML and Kubernetes API errors. It won't even pass `kubectl apply`!

Your job is simple: read the error messages, fix the syntax, and get this deployment running.

## Your Task

1. Try applying the manifest: `kubectl apply -f ~/typo-app.yaml`{{exec}}
2. Read the error message carefully — it tells you exactly what's wrong.
3. Fix the error, save the file, and try again.
4. Repeat until the deployment is successfully created!
5. Click the `Check` button!
