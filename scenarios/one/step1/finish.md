## Jam 1
### Rationale
The intent of this challenge is not to outright say that mounting secrets to environment variables is wrong and everyone should be mounting secrets as files instead.
Mounting secrets directly in plain to env with the block snippet below is not correct.
```
env:
  name: MY_SECRET_PASSWORD
  value: verysecretindeed
```
Mounting secrets to environment variables with `secretKeyRef` is better then the method above.
```
env:
  valueFrom:
    secretKeyRef:
      name: SECRET_PASSWORD
```
OWASP kubernetes cheatsheet & CIS benchmark do encourage secrets to be mounted as files with `volumes` & `volumneMounts` instead as `readOnly`.
This is primarily due to how environment variables might be more prone to leakages in logs and linux file permission mechanism.
However to do this most of the time the applications has to be written in such a way that takes this into account in a kubernetes environment.
There are other better methods such as KMS or external secret store which can involve both infrasturcture & source code changes.

