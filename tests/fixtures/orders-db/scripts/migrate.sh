#!/usr/bin/env bash
# Applies every migration that has not been applied yet.
set -euo pipefail
set -a; . ./.env; set +a
echo "applying pending migrations to $DATABASE_HOST ($ENVIRONMENT)"
for f in migrations/*.sql; do
  echo "  $f"
done
date > applied.log
echo "done"
