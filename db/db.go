package db

import (
	"context"
	"log"

	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
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
		log.Println(err)
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
