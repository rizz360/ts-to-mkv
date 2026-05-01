# Refactoring Summary

## What changed

The project was restructured to a conventional layout:

- runtime scripts in `app/`
- environment config in `config/`
- validation scripts in `tests/`
- documentation in `docs/`

## Why

- clearer separation of runtime code vs tests vs docs
- easier CI targeting and tooling integration
- improved maintainability before larger future changes

## Operational updates

- Entrypoint moved to `/app/entrypoint.sh`
- Compose mounts switched to `./app` and `./config`
- Tests moved to `tests/`
- Safety checks updated for new path conventions

## Verification

Run:

```bash
bash tests/test_safety.sh
bash tests/test_modular.sh
```
