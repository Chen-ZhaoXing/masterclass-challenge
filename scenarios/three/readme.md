# Scenario Objective: Container Image Best Practices

## What Developers Will Learn

This scenario teaches developers to stop building bloated, insecure container images by applying production-grade Dockerfile best practices.

## North Pole Container Standards

To pass this challenge, participants must fix a deliberately bad Dockerfile to meet the following requirements:

- **Build Strategy:** The Dockerfile must use an appropriate, modern build strategy that separates build-time dependencies from the final runtime image.
- **Base Image:** The final image must use a minimal, secure base image to reduce attack surface and unnecessary packages.
- **Execution Context:** The container process must never run as root.
- **Image Size:** The final image must be exceptionally small (under 250 MB).
- **Application Functionality:** After all optimizations, the FastAPI app must still start and respond correctly on port 8000.

## What's Wrong With the Starting Dockerfile

The provided Dockerfile commits several cardinal sins of container image building, leading to a massive image size and critical security vulnerabilities. Your objective is to identify and resolve these anti-patterns without breaking the application logic.

> 💡 **Tip:** If you need specific actionable guidance on identifying the anti-patterns or implementing the fixes, refer to the available hints on the challenge portal.
