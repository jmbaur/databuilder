package cmd

import (
	"context"
	"flag"
	"log"
	"os"
	"strings"

	"github.com/jmbaur/databuilder/db"
	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	m := mocker.New("tmp")
	m.Parse(os.Stdin)

	connString := flag.String("connection", "postgres://localhost:5432", "connection string to the database")
	ignoreTables := flag.String("ignoreTables", "", "tables to skip when creating mock data")
	flag.Parse()

	conn, err := db.GetConnection(*connString)
	if err != nil {
		log.Fatalf("unable to connect to database: %v", err)
	}
	defer conn.Close(context.Background())

	mockConfig := &mocker.Config{
		IgnoreTables: strings.Split(*ignoreTables, ","),
	}

	if err := m.Mock(conn, mockConfig); err != nil {
		log.Fatalf("unable to mock the database: %v", err)
	}
}
