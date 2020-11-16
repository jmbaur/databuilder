#!/bin/bash

set -e

podman run -d --rm --name databuilder -e POSTGRES_USER=user -e POSTGRES_PASSWORD=pwd -e POSTGRES_DB=test -p 6543:5432 postgres
sleep 5
cat ./assets/test_large.sql | psql postgres://user:pwd@localhost:6543/test
