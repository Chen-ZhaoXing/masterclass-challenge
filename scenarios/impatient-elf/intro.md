> **Points:** 150
>
> **Prerequisites:** Basic Kubernetes (Deployments, Pods, initContainers), `kubectl apply`
>
> **Learning Objectives:** Pod startup ordering, initContainers, fixing CrashLoopBackOff races
>
>
> <br>
>
> # The Impatient Elf
>
> ## The Situation
>
> It's a week before Christmas and the North Pole Workshop just shipped a new build of the **Gift Registry** — the web app elves use to register the toys on Santa's list. The stack is a classic one: a **Django** app in front of **PostgreSQL**, both running in your Kubernetes cluster.
>
> Except the registry keeps **crash-looping** the moment it boots. The on-call elf left a note in the incident ticket:
>
> > "The shop opens *before* the shelves are stocked — every single time. The logs complain about an empty catalog and then the whole Pod comes back down a minute later. I swear the elf is restocking the shelves *after* the shop opens. One of the rogue elves moved the restocking elf out of the prep shift — **put them back!**"
>
> ## Your Mission
>
> Everything is already deployed in namespace `workshop`, including the misbehaving Deployment — its manifest is waiting at `~/app.yaml`. `kubectl` is ready to go.
>
> The Deployment has two containers:
>
> - `elf`: An initContainer that **migrates** the database schema and then **restocks** the catalog (deletes all rows and reinserts the full reference dataset).
> - `shop`: A gunicorn server that serves the Django app and needs a populated catalog to start.
>
> The elf is currently declared as a **regular container**, so Kubernetes starts both `elf` and `shop` in parallel. In the race:
>
> - t≈1s: the elf begins truncating the catalog
> - t≈2-4s: the shop checks the catalog and finds it empty → exits with code 1
> - t≈5-15s: the elf finishes loading all 15,000 rows
> - The Pod crashes and Kubernetes restarts it — and the loop never ends.
>
> ### Your Task
>
> Fix the Deployment so the elf's work is guaranteed to **exit with code 0 before the shop container starts**.
>
> Move the `elf` container from `containers:` to `initContainers:` (after `wait-for-db`). The guaranteed start order becomes:
>
> ```
> wait-for-db (init) → elf: migrate + restock, exit 0 (init) → gift-registry
> ```
>
> You'll know it's fixed when the Deployment starts cleanly with **0 restarts** and the health check reports a populated catalog.
>
> ## Useful Commands
>
> - View the Deployment spec: `kubectl -n workshop get deployment gift-registry -o yaml`{{exec interrupt}}
>
> Edit `~/app.yaml`:
>
> - Remove the `elf` from `containers:`
> - Add the `elf` to `initContainers:` (as an init container)
> - Ensure the `elf` exits with code 0 (keep the existing `wait-for-db` initContainer)
>
> Then redeploy and watch for a healthy Pod:
>
> ```bash
> kubectl apply -f ~/app.yaml
> kubectl -n workshop get pods -w  # press Ctrl+C when done
> kubectl -n workshop get pods -l app=gift-registry
> ```
>
> ## Verification
>
> Your fix will be checked against the requirements above.
>
> 🎅 Happy fixing!
