## Charts

- postgres - Bitnmai Postgres chart but also creates the secrets required for rest of stack

## Running Locally

First enable the docker-desktop kubernetes feature or have a development kube cluster deployed somewhere.

Next we need to update all the charts (this downloads any child charts such as postgres)

```bash
./dev update
```

Now we can install the charts.

```bash
./dev install
```

We can then reset our helm installs with

```bash
./dev reset
```

## Development and Debugging

A chart can be linted for errors (much faster than running `reset` for surfacing templating errors)

```bash
helm lint charts/postgres
```

### Local Postgres Access

```bash
export POSTGRES_ADMIN_PASSWORD=$(kubectl get secret --namespace postgres-graphql postgres-root-credentials -o jsonpath="{.data.postgresql-password}" | base64 --decode)
```

```bash
kubectl port-forward --namespace postgres-graphql  svc/postgres-postgresql 5432:5432
```
