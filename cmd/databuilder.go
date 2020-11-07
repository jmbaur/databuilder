package cmd

import (
	"flag"
	"os"
	"strings"

	"github.com/jmbaur/databuilder/db"
	"github.com/jmbaur/databuilder/logg"
	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	m := mocker.New("tmp")

	filestat, _ := os.Stdin.Stat()
	if filestat.Size() <= 0 {
		logg.Printf(logg.Fatal, "No SQL passed through standard input\n")
		os.Exit(1)
	}
	m.Parse(os.Stdin)

	connString := flag.String("connection", "postgres://localhost:5432", "connection string to the database")
	ignoreTables := flag.String("ignoreTables", "", "tables to skip when creating mock data")
	amount := flag.Int("amount", 10, "how many rows to insert for each table")
	flag.Parse()

	err := db.GetConnection(*connString)
	if err != nil {
		logg.Printf(logg.Fatal, "Unable to connect to database: %v\n", err)
		os.Exit(2)
	}
	defer db.Close()

	mockConfig := &mocker.Config{
		IgnoreTables: strings.Split(*ignoreTables, ","),
		Amount:       *amount,
	}
	if err := m.Mock(mockConfig); err != nil {
		logg.Printf(logg.Fatal, "Unable to mock the database: %v\n", err)
		os.Exit(3)
	}
}
