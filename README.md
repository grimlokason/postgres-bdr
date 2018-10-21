This is a specialised Docker container to run a ["bi-directional
replication"](http://bdr-project.org/docs/stable/index.html) ("BDR")
PostgreSQL server.  BDR is an experimental replication mode, developed by
[2ndquadrant](http://www.2ndquadrant.com/), which allows multi-master
replication amongst a group of co-operating PostgreSQL servers.  It is not
available in PostgreSQL core, and thus requires a separate Docker image.

As part of the initial startup, this image will create a database and create
or join a BDR group.  It will also create a user with a specified password
with full rights over the database that is created.


# Usage

Run it like any other docker container, more or less.  All configuration is
via environment variables, no command line arguments are required.

On one machine in the replication group, start the container *without* the
`RENDEZVOUS_DSN` environment variable.  This will configure the database by
creating a new BDR group:

    docker run --name bdr0 -e PG_DATABASE=bdr_test -e PG_USERNAME=bdr \
      -e PG_PASSWORD=s3kr1t discourse/postgres-bdr

Once you've got one server up and running, you can tell the other database
servers you want in the cluster to join this server, by specifying the
`RENDEZVOUS_DSN` environment variable, with the details of the first server
you created:

    docker run --name bdr1 \
      -e PG_DATABASE=bdr_test \
      -e PG_USERNAME=bdr \
      -e PG_PASSWORD=s3kr1t \
      -e RENDEZVOUS_DSN="host=192.0.2.42 port=5432 dbname=bdr_test user=bdr password=s3kr1t" \
      discourse/postgres-bdr

If all goes well, these additional database servers should connect to the
specified remote server, synchronize their data, and you're off to the
races.

## Volumes

All your PostgreSQL data is stored under `/var/lib/postgresql`.  While there
is a volume declared for that path, you probably want to mount a host
filesystem on there, for safety:

    docker run -v /srv/docker/postgres-bdr/data:/var/lib/postgresql ...


# Configuration

All behaviour of this image are controlled via environment variables.


## Required environment variables

The following environment variables must be set in order for setup of the
PostgreSQL database to complete successfully.

* **`PG_DATABASE`** (required) -- the name of the database to create as part
  of the initial setup.

* **`PG_USERNAME`** (required) -- the name of the user to create as part of
  the initial setup, and who will own the created database.

* **`PG_PASSWORD`** (required) -- the password of the user specified in
  `PG_USERNAME`.

* **`PG_POSTGRES_PASSWORD`** (required) -- the password to set for the
  `postgres` (superuser) account.  This is the account tht is used for
  replication between nodes (because BDR requires a superuser account for
  reasons which don't bear thinking about).

## Optional environment variables

These environment variables are all optional, in the sense that the
container will boot without these being specified.  However, some of them
will need to be set on some machines in order for the replication cluster to
be formed correctly.

* **`RENDEZVOUS_DSN`** -- if specified, then rather than the database being
  configured with a new replication group, the database will be told to join
  an existing replication group at the specified
  [DSN](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING).
  Note that this DSN must give access to a superuser account.

* **`EXTERNAL_DSN`** -- override the default
  [DSN](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING)
  (constructed from the node's hostname, port, and the username/password
  details given in `PG_USERNAME` and `PG_PASSWORD`) with an alternative DSN
  of your own choice.  This is necessary if, for some reason, the default
  DSN doesn't represent reality.  Note that this DSN must give access to a
  superuser account.

* **`PG_CONF_<setting>`** -- set any variable in the `postgresql.conf` file. 
  Very handy.  You will almost certainly have to set `listen_addresses`, at
  the very least.
