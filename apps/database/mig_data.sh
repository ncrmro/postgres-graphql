#!/usr/bin/env bash
echo "Seeding the database..."

export DATABASE_DIR=${DATABASE_DIR:-..}

#retry() {
#  max_attempts="$1"
#  shift
#  seconds="$1"
#  shift
#  cmd="$@"
#  attempt_num=1
#
#  until $cmd; do
#    if [ $attempt_num -eq $max_attempts ]; then
#      echo "Attempt $attempt_num failed and there are no more attempts left!"
#      return 1
#    else
#      echo "Attempt $attempt_num failed! Trying again in $seconds seconds..."
#      attempt_num=$(expr "$attempt_num" + 1)
#      sleep "$seconds"
#    fi
#  done
#}
#retry 10 1 psql $DATABASE_URL --dbname=$DBNAME -c '\l' >/dev/null

echo >&2 "$(date +%Y%m%dt%H%M%S) Postgres is up - executing command"

for i in ./test_data/*.sql; do # Whitespace-safe but not recursive.
  echo "$i"
  yarn graphile-migrate run $i
done
