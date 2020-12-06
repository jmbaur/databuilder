package mocker

import (
	"context"
	"fmt"
	"io"
	"log"

	"github.com/jackc/pgx/v4/pgxpool"
)

func work(worker <-chan []record, done chan<- bool, tableName string, desiredAmount int, db *pgxpool.Pool, writer io.Writer) {
	var records []record
	for i := 0; i < desiredAmount; i++ {
		recs := <-worker

		insertOne, err := buildInsertStmt(recs, tableName)
		if err != nil {
			log.Printf("Failed to build insert statement for table '%s': %v\n", tableName, err)
			continue
		}

		_, err = db.Query(context.Background(), *insertOne)
		if err != nil {
			log.Printf("Failed to insert record into %s table: %v\n", tableName, err)
			continue
		}

		// append to records if no error from DB call
		records = append(records, recs...)
	}
	done <- true

	insertMany, err := buildInsertStmt(records, tableName)
	if err != nil {
		log.Printf("failed to build insert statement for table '%s': %v\n", tableName, err)
	}
	writer.Write([]byte(*insertMany))
}

func buildInsertStmt(records []record, table string) (*string, error) {
	if len(records) == 0 {
		return nil, fmt.Errorf("no records to insert")
	}

	var stmt string
	stmt += "INSERT INTO " + table + " ("

	firstRec := records[0]
	cols := []string{}
	for col := range firstRec {
		cols = append(cols, col)
		stmt += col + ", "
	}
	stmt = stmt[:len(stmt)-2] + ") VALUES "

	for _, r := range records {
		stmt += "("
		for i := 0; i < len(r); i++ {
			stmt += fmt.Sprintf("%s", r[cols[i]]) + ","
		}
		stmt = stmt[:len(stmt)-1] + "), "
	}
	stmt = stmt[:len(stmt)-2] + ";"

	return &stmt, nil
}
