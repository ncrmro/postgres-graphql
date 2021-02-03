# Postgres GraphQL

This is an example project using the following technologies to provide a GraphQL
server.

- [Postgres](https://www.postgresql.org)
- [PostGraphile](https://www.graphile.org)
- [graphile-migrate](https://github.com/graphile/migrate)

The main benefit here is our GraphQL API types come directly from the Database,
furthermore in our frontend applications we can automatically generate
Typescript Types and Typed requests to interact with our API improving
development agility and our application's integrity.

This README contains the following sections.

- [Getting Started](#getting-started)
  - [Database](#database)
    - [Schema and Migrations](#schema-and-migrations)
  - [GraphQL](#graphql)
    - [GraphiQL](#graphiql)

## Getting Started

The only hard requirement is that you have `docker` and `docker-compose`
installed, although naturally, you could install everything locally.

### .env

First, let's copy the `.env.example` to `.env`. This file used by
`docker-compose` will pass these environment variables into designated
containers.

```bash
cp .env.example .env
```

Pull the images

```bash
docker-compose pull
```

And then we can build our services.

```bash
docker-compose build
```

### Database

Initialize and ensure the database is ready to go.

```bash
docker-compose up database
```

#### Schema and Migrations

Install the dependencies

```bash
docker-compose run migrations yarn
```

Initialize graphile-migrate

```bash
docker-compose run migrations yarn graphile-migrate init
```

At this point, we are ready to start the migrations watch service. Kill our
existing docker-compose process with `control + c`. Then start up the migration
watcher.

```bash
docker-compose up database migrations
```

Write some migrations in `current.sql`, once you're ready to commit.

Note I like to keep the minimum amount of logic in a specific commit to make
your schema easier to read in the future, this also keeps your agility up in
regards to developing new features.

```bash
docker-compose exec migrations yarn graphile-migrate commit -m "my commit message"
```

If you need to reset the database and rerun committed migrations.

```bash
docker-compose exec migrations yarn graphile-migrate reset --erase
```

### GraphQL

Once we have our database up and running with a schema we can go ahead and start
the GraphQL server.

```bash
docker-compose up database migrations gql
```

Or using up without and other parameters would start all available
docker-compose services

```bash
docker-compose up database migrations gql
```

Note that because GraphQL specifies migrations as a dependency and migrations
specify database as a dependency we could also start everything up with the
following command, although this would only output logs from the gql service
hiding other crucial logs.

```bash
docker-compose up database migrations gql
```

#### GraphiQL

Postgraphile comes with a nifty interface to aid in development called GraphiQL,
this allows us to inspect our current GraphQL schema at the following URL.

```
http://localhost:5000/graphiql
```
