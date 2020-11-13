package db

import (
	"context"
	"os"

	"github.com/jackc/pgx/v4/pgxpool"
)

type DbWriter interface {
	Write(query string) error
}

type PgWriter struct {
	db *pgxpool.Pool
}

func (p *PgWriter) Write(query string) error {
	rows, err := p.db.Query(context.Background(), query, queryparams...)
	if err != nil {
		return err
	}
	defer rows.Close()
	return
}

type FileWriter struct {
	file *os.File
}

func (f *FileWriter) Write(query string) error {
	_, err := f.file.Write([]byte(query))
	if err != nil {
		return err
	}
	return
}
