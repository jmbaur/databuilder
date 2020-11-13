#!/bin/bash

podman run -d --rm --name databuilder -e POSTGRES_USER=user -e POSTGRES_PASSWORD=pwd -e POSTGRES_DB=test -p 6543:5432 postgres
