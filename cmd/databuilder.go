package cmd

import (
	"flag"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/jmbaur/databuilder/db"
	"github.com/jmbaur/databuilder/logg"
	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	fs, _ := os.Stdin.Stat()
	if (fs.Mode() & os.ModeNamedPipe) == 0 {
		logg.Printf(logg.Fatal, "No SQL passed through standard input\n")
		os.Exit(1)
	}

	// TODO: allow for SQL schema source to be something other than Stdin
	m := &mocker.Mocker{}
	m.Parse(os.Stdin) // builds the Mocker object with tables and enums

	connection := flag.String("connection", "postgres://localhost:5432", "connection string to the database") // connection string to database
	ignoreTables := flag.String("ignore", "", "tables to skip when creating mock data")                       // gets parsed as regexp
	outFile := flag.String("out", "", "where to write output")                                                // used to write SQL expressions to file
	amount := flag.Int("amount", 10, "how many rows to insert for each table")
	flag.Parse()

	var writer io.Writer
	if outFile == nil {
		writer = os.Stdout
	} else {
		full, err := filepath.Abs(*outFile)
		if err != nil {
			logg.Printf(logg.Fatal, "Could not get full path to file: %v\n", *outFile)
			os.Exit(2)
		}
		os.Remove(full)
		writer, err := os.Create(full)
		if err != nil {
			logg.Printf(logg.Fatal, "Unable to create file: %v\n", *outFile)
			os.Exit(2)
		}
		defer writer.Close()
	}

	conn, err := db.GetConnection(*connection)
	if err != nil {
		logg.Printf(logg.Fatal, "Unable to connect to database: %v\n", err)
		os.Exit(2)
	}
	defer conn.Close()

	m.Config = mocker.Config{
		Db:           conn,
		IgnoreTables: strings.Split(*ignoreTables, ","),
		Amount:       *amount,
		Writer:       writer,
	}
	if err := m.Mock(); err != nil {
		logg.Printf(logg.Fatal, "Unable to mock the database: %v\n", err)
		os.Exit(3)
	}
}
