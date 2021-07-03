
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

### Development and Debugging

A chart can be linted for errors (much faster than running `reset` for surfacing templating errors)

```bash
helm lint charts/postgres
```
