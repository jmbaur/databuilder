package cmd

import (
	"context"
	"flag"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/jmbaur/databuilder/logg"
	"github.com/jmbaur/databuilder/mocker"
)

func Execute() {
	connection := flag.String("connection", "postgres://localhost:5432", "connection string to the database") // connection string to database
	ignoreTables := flag.String("ignore", "", "tables to skip when creating mock data")                       // gets parsed as regexp
	outFile := flag.String("out", "", "where to write output")                                                // used to write SQL expressions to file
	amount := flag.Int("amount", 10, "how many rows to insert for each table")
	flag.Parse()

	args := flag.Args()
	if len(args) > 1 {
		logg.Printf(logg.Fatal, "Cannot accept more than 1 arg\n")
		os.Exit(1)
	}
	var reader io.Reader
	if len(args) > 0 {
		full, err := filepath.Abs(args[0])
		if err != nil {
			logg.Printf(logg.Fatal, "Could not get full path to file: %v\n", args[0])
			os.Exit(1)
		}
		sqlFile, err := os.Open(full)
		if err != nil {
			logg.Printf(logg.Fatal, "Could not open file: %v\n", args[0])
			os.Exit(1)
		}
		reader = sqlFile
	} else {
		fs, _ := os.Stdin.Stat()
		if (fs.Mode() & os.ModeNamedPipe) == 0 {
			logg.Printf(logg.Fatal, "No SQL passed through standard input\n")
			os.Exit(1)
		}
		reader = os.Stdin
	}

	m := &mocker.Mocker{}
	m.Parse(reader) // builds the Mocker object with tables and enums

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

	conn, err := pgxpool.Connect(context.Background(), *connection)
	if err != nil {
		logg.Printf(logg.Fatal, "Unable to connect to database: %v\n", err)
		os.Exit(2)
	}
	defer conn.Close()

	m.Config = mocker.Config{
		Db:           conn,
		IgnoreTables: strings.Split(*ignoreTables, ","),
		Amount:       *amount,
	}
	if err := m.Mock(writer); err != nil {
		logg.Printf(logg.Fatal, "Unable to mock the database: %v\n", err)
		os.Exit(3)
	}
}
