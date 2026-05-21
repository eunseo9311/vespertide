# Unsafe Diff Demo

Reproduces the paper's Running Example: a developer tightens `users.email` by making it
`NOT NULL` and adding a `UNIQUE` constraint. Vespertide detects the data-dependent risks
during `diff`, prompts for a backfill strategy during `revision`, and emits the resulting
SQL through `log`.

## Layout

- `vespertide.json` — project config.
- `snapshots/users.before.json` — initial schema (email nullable, no UNIQUE).
- `snapshots/users.after.json` — target schema (email NOT NULL + UNIQUE).
- `models/` — active model directory, **rewritten by `run.sh`**. Do not edit by hand.
- `migrations/` — generated migration plans, also rewritten by `run.sh`.
- `expected_output/` — captured output from a successful run.
- `run.sh` — reproduces the end-to-end flow.

## Run

```sh
./run.sh
```

The script:

1. Builds the CLI from the workspace root.
2. Copies `snapshots/users.before.json` into `models/users.json` and creates the
   baseline migration (`vespertide revision -m "init users"`).
3. Swaps in `snapshots/users.after.json` and runs `vespertide diff` — the safety
   warnings (`[F1]`, `[F2]`) appear after the action list.
4. Runs `vespertide revision -m "require email" --fill-with users.email=…` to author
   the second migration non-interactively (the same value would be requested via the
   interactive prompt without `--fill-with`).
5. Runs `vespertide log` to show the resulting per-backend SQL, which contains the
   `UPDATE … WHERE … IS NULL` followed by `ALTER TABLE … SET NOT NULL` and the new
   `UNIQUE` constraint.

## Notes

- `snapshots/` is outside `models/` because the loader recursively reads every
  `.json` under `models/` — keeping both states inside would register two `users`
  tables and fail validation.
- `NO_COLOR=1` is set so the captured `.txt` files are free of ANSI escapes.
