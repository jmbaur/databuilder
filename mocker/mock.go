package mocker

import (
	"regexp"

	"github.com/brianvoe/gofakeit/v5"
	"github.com/jackc/pgx/v4"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

type Config struct {
	IgnoreTables []string
	ignoreTables []*regexp.Regexp
}

func (c *Config) prep() error {
	for _, tableMatch := range c.IgnoreTables {
		re, err := regexp.Compile(tableMatch)
		if err != nil {
			return err
		}
		c.ignoreTables = append(c.ignoreTables, re)
	}
	return nil
}

func (c *Config) tableSkip(tableName string) bool {
	var skip bool
	for _, re := range c.ignoreTables {
		if re.MatchString(tableName) {
			skip = true
		}
	}
	return skip
}

func (m *Mocker) Mock(conn *pgx.Conn, config *Config) error {
	gofakeit.Seed(0)

	if err := config.prep(); err != nil {
		return err
	}

	for _, table := range m.Tables {

		if config.tableSkip(*table.Relation.Relname) {
			continue
		}

		widget := make(map[string]interface{})
		for _, tableElement := range table.TableElts.Items {
			column, okColumn := tableElement.(nodes.ColumnDef)
			_, okConstraint := tableElement.(nodes.Constraint)

			if okColumn {
				if column.TypeName == nil {
					continue
				}

				columnName := *column.Colname
				columnType := column.TypeName.Names.Items[0].(nodes.String).Str

				var columnValue interface{}

				switch columnType {
				case "text":
					// fmt.Println(*table.Relation.Relname, columnName)
					columnValue = gofakeit.LoremIpsumSentence(10)
				case "date":
					columnValue = gofakeit.Date()
				case "timestamp":
					columnValue = gofakeit.Date()
				case "daterange":
					// daterange := gofakeit.DateRange(gofakeit.Date(), gofakeit.Date())
					// fmt.Println(columnType, daterange)
				case "pg_catalog":
					continue
				case "serial":
					continue
				case "json":
				default:
					// fmt.Println(columnType)
					// try to find enum
				}
				widget[columnName] = columnValue
			}
			if okConstraint {
				// fmt.Println(constraint)
			}
		}
		// fmt.Println("widget", widget)
	}
	return nil
}
