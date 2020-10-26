# DataBuilder

## Installation

`go get -u github.com/jmbaur/databuilder`

## Usage

`echo "CREATE TABLE temp_table(id SERIAL PRIMARY KEY, name VARCHAR(60));" | databuilder --connection=postgres://localhost:5432`
