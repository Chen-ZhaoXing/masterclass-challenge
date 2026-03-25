> **Points:** 100
>
> **Prerequisites:** Basic YAML syntax, basic `kubectl` usage
>
> **Learning Objectives:** Reading Kubernetes error messages, image tag pinning, namespace scoping

# The Trainee Elf Orientation

## The Situation

Welcome to the North Pole Kubernetes Cluster, Trainee Elf! Before you can join the front lines against the rogue elf faction, the Chief Holiday Officer needs to verify that you can handle the basics.

The rogue elves left behind three sabotaged manifests during their last raid. Each one contains a simple but critical mistake that will prevent the application from deploying. These are the kinds of errors that even experienced engineers make under pressure - and catching them quickly is what separates a Trainee from a Senior Elf.

## Your Mission

1. **The Elf's Typo:** A manifest with basic YAML and API errors. Fix the syntax so `kubectl apply` succeeds.
2. **The Untagged Shipment:** A deployment using a dangerously mutable image tag. Pin it to a specific, stable version.
3. **The Lost Namespace:** A deployment targeting a namespace that doesn't exist. Create it and deploy.

Each task is a quick fix. Read the error messages carefully - they tell you exactly what's wrong.

Good luck, Trainee. Prove you belong on this team.
