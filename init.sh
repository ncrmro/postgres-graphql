# exit when any command fails
set -e

# Parse dotenv
if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

echo "Bringing down all containers"
docker-compose down --volumes

echo "Bringing up database, running migrations and loading data"
docker-compose up -d db
sleep 5

echo "Creating Graphile users and resetting the databasse"
docker-compose exec -T db psql -c "CREATE USER ${DATABASE_OWNER} WITH PASSWORD '${DATABASE_OWNER_PASSWORD}';"
docker-compose exec -T db psql -c "CREATE USER ${DATABASE_AUTHENTICATOR} WITH PASSWORD '${DATABASE_OWNER_PASSWORD}';"
docker-compose exec -T db psql -c "CREATE USER ${DATABASE_VISITOR};"

docker-compose run --rm --no-deps migrations yarn --frozen-lockfile
docker-compose run --rm --no-deps migrations yarn graphile-migrate reset --erase
docker-compose up -d migrations

docker-compose exec -T db psql -c "GRANT ALL ON DATABASE ${DATABASE_OWNER} TO ${DATABASE_OWNER};"
docker-compose exec -T db psql -c "GRANT CONNECT ON DATABASE ${DATABASE_OWNER} TO ${DATABASE_OWNER};"
docker-compose exec -T db psql -c "GRANT CONNECT ON DATABASE ${DATABASE_OWNER} TO ${DATABASE_AUTHENTICATOR};"
docker-compose exec -T db psql --dbname "${DATABASE_OWNER}" -c "ALTER SCHEMA public OWNER TO ${DATABASE_OWNER};"
docker-compose exec -T db psql -c "GRANT ${DATABASE_VISITOR} TO ${DATABASE_AUTHENTICATOR};"

echo "Installing Worker dependencies and generating types, worker migrations must be present first."
docker-compose run --rm --no-deps worker yarn --frozen-lockfile
docker-compose run --rm --no-deps worker yarn graphile-worker --schema-only

echo "Loading data into database"
docker-compose run --rm --no-deps migrations yarn load

echo "Installing GraphQL dependencies and starting GraphQL server to generate schema"
docker-compose run --rm --no-deps gql yarn --frozen-lockfile
docker-compose up -d gql
docker-compose exec -T gql yarn gqlgen

