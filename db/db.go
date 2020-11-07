package db

import (
	"context"

	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/jmbaur/databuilder/logg"
)

var db *pgxpool.Pool

func GetConnection(connString string) error {
	conn, err := pgxpool.Connect(context.Background(), connString)
	if err != nil {
		return err
	}
	db = conn
	return nil
}

func MakeInsert(done chan<- error, query string, queryparams ...interface{}) {
	rows, err := db.Query(context.Background(), query, queryparams...)
	if err != nil {
		logg.Printf(logg.Info, "%v\n", err)
		done <- err
	}
	defer rows.Close()
	done <- nil
}

func MakeQueryRow(query string) pgx.Row {
	row := db.QueryRow(context.Background(), query)
	return row
}

func Close() {
	db.Close()
}
