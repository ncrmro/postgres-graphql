# exit when any command fails
set -e

echo "Bringing down all containers"
docker-compose down --volumes

echo "Building graphql and web containers"
docker-compose build --parallel migrations # gql

echo "Bringing up database, running migrations and loading data"
docker-compose up -d db
docker-compose run --rm --no-deps migrations yarn --frozen-lockfile
docker-compose run --rm --no-deps migrations yarn graphile-migrate reset --erase
docker-compose up -d migrations
#docker-compose run --rm --no-deps migrations yarn load

echo "Installing GraphQL dependencies and starting GraphQL server to generate schema"
docker-compose run --rm  --no-deps gql yarn --frozen-lockfile
docker-compose up -d gql
docker-compose exec -T gql yarn gqlgen
