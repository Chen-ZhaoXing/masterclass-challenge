> **Points:** 50
>
> **Prerequisites:** Completed Trainee Elf OJT, basic `kubectl` commands
>
> **Learning Objectives:** Kubernetes Services (ClusterIP), ConfigMaps, environment variable injection, internal DNS

# The Trainee Elf Graduation

## The Situation

This is it, Trainee Elf — your final assessment before the Chief Holiday Officer clears you for the intermediate security missions.

The rogue elves left behind two more sabotaged deployments. These ones are trickier than anything you've seen so far: the pods run fine, but the **infrastructure around them** is broken. A running pod is useless if nothing can reach it, and an app is useless if it doesn't have its configuration.

You'll need to understand how Kubernetes **connects** applications to the network and how it **injects configuration** into running containers.

## Your Mission

1. **The Invisible App:** A deployment is running perfectly, but no other service in the cluster can reach it. Something is missing.
2. **The Missing Config:** A deployment keeps crashing because the application expects configuration that isn't there. Provide it the Kubernetes way.

Prove you can handle networking and configuration, and you'll earn your graduation badge.

Good luck, Trainee. You're almost a Senior Elf.
