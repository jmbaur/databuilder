package db

import (
	"context"
	"io"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/jmbaur/databuilder/logg"
)

func GetConnection(connString string) (*pgxpool.Pool, error) {
	db, err := pgxpool.Connect(context.Background(), connString)
	if err != nil {
		return nil, err
	}
	return db, nil
}

func MakeInsert(writer io.Writer, done chan<- error, query string, params ...interface{}) {
	// TODO: build query with params
	_, err := writer.Write([]byte(query))
	if err != nil {
		logg.Printf(logg.Info, "%v\n", err)
		done <- err
		return
	}
	done <- nil
}
