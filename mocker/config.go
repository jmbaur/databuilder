package mocker

import (
	"context"
	"io"
	"os"
	"regexp"

	"github.com/jackc/pgx/v4/pgxpool"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

type Config struct {
	Db           *pgxpool.Pool
	IgnoreTables []string
	ignoreTables []*regexp.Regexp
	OutFile      os.File
	Amount       int // amount of widgets to make for each table
	Writer       io.Writer
}

type Mocker struct {
	Tables []nodes.CreateStmt
	Enums  []nodes.CreateEnumStmt
	Config Config
}

// prep finds tables to ignore & initializes the writer
func (m *Mocker) prep() error {
	for _, tableMatch := range m.Config.IgnoreTables {
		re, err := regexp.Compile(".*" + tableMatch + ".*")
		if err != nil {
			return err
		}
		m.Config.ignoreTables = append(m.Config.ignoreTables, re)
	}
	return nil
}

func (m *Mocker) tableSkip(tableName string) bool {
	var skip bool
	for _, re := range m.Config.ignoreTables {
		if re.MatchString(tableName) {
			skip = true
		}
	}
	return skip
}

func (m *Mocker) Write(p []byte) (n int, err error) {
	rows, err := m.Config.Db.Query(context.Background(), string(p))
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	return len(p), nil
}
