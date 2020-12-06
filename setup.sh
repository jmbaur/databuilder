#!/bin/bash

set -e

podman run -d --rm --name databuilder -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=test_db -p 5432:5432 postgres:10
sleep 5
psql postgres://user:password@localhost:5432/test_db < ./assets/test_dump.sql
