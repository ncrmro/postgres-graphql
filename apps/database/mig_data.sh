#!/usr/bin/env bash
echo "Seeding the database..."

export DATABASE_DIR=${DATABASE_DIR:-..}

for i in ./test_data/*.sql; do # Whitespace-safe but not recursive.
  echo "$i"
  yarn graphile-migrate run $i
done
