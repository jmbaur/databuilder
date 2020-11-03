package db

import (
	"context"

	"github.com/jackc/pgx/v4"
)

func GetConnection(connString string) (*pgx.Conn, error) {
	conn, err := pgx.Connect(context.Background(), connString)
	if err != nil {
		return nil, err
	}
	return conn, nil
}
