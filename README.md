# Postgres GraphQL

This is an example project using the following technologies to provide a GraphQL server.

- Postgres
- Postgraphql
- Graphile Migrate

The main benefit here is our GraphQL API types come directly from the Database, furthermore in our frontend applications
we can automatically generate Typescript Types and Typed requests to interact with our API greatly improving development
agility and our application's integrity.

## Getting Started

The only hard requirement is that you have `docker` and `docker-compose` installed which, although naturally you could
install everything locally.

### .env

First lets copy the `.env.example` to `.env`, this file will be used by `docker-compose` which will pass these environment
variables into designated containers.

```bash
cp .env.example .env
```

### Local Docker Development

```bash
docker-compose build
```

Lets initialize and insure the database is ready to go.

```bash
docker-compose up database
```

Install the dependencies

```bash
docker-compose run migrations yarn
```

Initialize graphile-migrate

```bash
docker-compose run migrations yarn graphile-migrate init
```

Write some migrations in `current.sql`, once your ready to commit.

```bash
docker-compose exec migrations yarn graphile-migrate commit
```
