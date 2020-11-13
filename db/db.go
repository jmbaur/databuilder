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

func MakeInsert(writer DbWriter, done chan<- error, query string, params ...interface{}) {
	// TODO: build query with params
	err := writer.Write(query)
	if err != nil {
		logg.Printf(logg.Info, "%v\n", err)
		done <- err
		return
	}
	done <- nil
}

func MakeQueryRow(query string) pgx.Row {
	row := db.QueryRow(context.Background(), query)
	return row
}

func Close() {
	db.Close()
}
