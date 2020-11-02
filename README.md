# DataBuilder

## Installation

`go get -u github.com/jmbaur/databuilder`

## Usage

`echo "CREATE TABLE temp_table(id SERIAL PRIMARY KEY, name VARCHAR(60));" | databuilder --connection=postgres://localhost:5432`

## Running Postgres

`docker run -e POSTGRES_USER user -e POSTGRES_PASSWORD=pwd -p 5432:5432 -d --rm postgres`
