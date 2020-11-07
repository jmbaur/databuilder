package cmd

import (
	"flag"
	"log"
	"os"
	"strings"

	"github.com/jmbaur/databuilder/db"
	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	m := mocker.New("tmp")

	filestat, _ := os.Stdin.Stat()
	if filestat.Size() <= 0 {
		log.Fatal("no data passed in through standard input")
	}
	m.Parse(os.Stdin)

	connString := flag.String("connection", "postgres://localhost:5432", "connection string to the database")
	ignoreTables := flag.String("ignoreTables", "", "tables to skip when creating mock data")
	amount := flag.Int("amount", 10, "how many rows to insert for each table")
	flag.Parse()

	err := db.GetConnection(*connString)
	if err != nil {
		log.Fatalf("unable to connect to database: %v", err)
	}
	defer db.Close()

	mockConfig := &mocker.Config{
		IgnoreTables: strings.Split(*ignoreTables, ","),
		Amount:       *amount,
	}
	if err := m.Mock(mockConfig); err != nil {
		log.Fatalf("unable to mock the database: %v", err)
	}
}
