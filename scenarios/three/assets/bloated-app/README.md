# Sleigh Telemetry Service

This is the rogue elves' telemetry service. It definitely doesn't have any backdoors.

## Development

```bash
pip install -r requirements.txt
fastapi dev src/app.py
```

## Notes

This README, along with other unnecessary files, will be baked into the container image
because the rogue elves didn't bother creating a .dockerignore file.
