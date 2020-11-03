package mocker

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/brianvoe/gofakeit/v5"
	"github.com/jackc/pgx/v4"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

var foreignkeys = make(map[string][]interface{})

type Config struct {
	IgnoreTables []string // tables to ignore
	ignoreTables []*regexp.Regexp
	Amount       int // amount of widgets to make for each table
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

type widget map[string]interface{}

func (m *Mocker) Mock(conn *pgx.Conn, config *Config) error {
	gofakeit.Seed(0)

	if err := config.prep(); err != nil {
		return err
	}

	for _, table := range m.Tables {

		if config.tableSkip(*table.Relation.Relname) {
			continue
		}

		var widgets []widget
		for i := 0; i < config.Amount; i++ {
			w := make(widget)
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

					getConstraints(conn, column.Constraints.Items)

					switch columnType {
					case "text":
						columnValue = generateText(columnName, column.IsNotNull)
					case "date":
						columnValue = gofakeit.Date()
					case "timestamp":
						columnValue = gofakeit.Date()
					case "daterange":
						date1 := gofakeit.Date()
						date2 := date1.Add(time.Duration(gofakeit.Number(1, 10000)) * time.Hour)
						columnValue = "[" + date1.Format(time.RFC3339) + "," + date2.Format(time.RFC3339) + "]"
					case "pg_catalog":
						// foreign table reference
						// columnValue = getRandomForeignRefValue(conn, column.Constraints.Items)
						// fmt.Println(columnValue)
						continue
					case "serial":
						continue
					case "json":
						json, _ := json.Marshal(struct {
							Status string `json:"status"`
						}{Status: "JSON is not yet implemented."})
						columnValue = json
					default:
						// fmt.Println(columnType)
						// try to find enum
					}
					w[columnName] = columnValue
				}
				if okConstraint {
					// fmt.Println(constraint)
				}
			}
			widgets = append(widgets, w)

		}
	}
	return nil
}

func generateText(column string, isNotNull bool) string {
	column = strings.ToLower(column)

	if strings.HasPrefix(column, "id") || strings.HasSuffix(column, "id") {
		return strconv.Itoa(gofakeit.Number(0, 5000))
	}

	if strings.Contains(column, "name") {
		if strings.Contains(column, "first") {
			return gofakeit.FirstName()
		}
		if strings.Contains(column, "last") {
			return gofakeit.LastName()
		}
		return gofakeit.Name()
	}

	if strings.Contains(column, "email") {
		return gofakeit.Email()
	}

	if strings.HasPrefix(column, "ip") || strings.HasSuffix(column, "ip") {
		return gofakeit.IPv4Address()
	}

	if strings.Contains(column, "address") {
		return gofakeit.Street()
	}

	if strings.Contains(column, "city") {
		return gofakeit.City()
	}

	if strings.Contains(column, "zip") {
		return gofakeit.Zip()
	}

	if strings.Contains(column, "state") {
		return gofakeit.StateAbr()
	}

	if strings.Contains(column, "country") {
		return gofakeit.CountryAbr()
	}

	if strings.Contains(column, "phone") {
		return gofakeit.Phone()
	}

	if strings.Contains(column, "gender") {
		return gofakeit.Gender()
	}

	if strings.Contains(column, "language") {
		return gofakeit.Language()
	}

	if strings.Contains(column, "note") {
		return gofakeit.LoremIpsumSentence(10)
	}

	// if strings.Contains(column, "hash") {
	// 	return gofakeit.Password()
	// }

	if isNotNull {
		return gofakeit.LoremIpsumWord()
	}

	return ""
}

func getConstraints(conn *pgx.Conn, constraints []nodes.Node) error {
	// var constrs []nodes.ConstrType
	for _, c := range constraints {
		constraint, ok := c.(nodes.Constraint)
		if !ok {
			return fmt.Errorf("not a constraint")
		}
		switch constraint.Contype {
		case nodes.CONSTR_NOTNULL:
			// fmt.Println("not null")
			continue
		case nodes.CONSTR_FOREIGN:
			foreigncolumn := constraint.PkAttrs.Items[0].(nodes.String).Str
			foreigntable := *constraint.Pktable.Relname
			if _, ok := foreignkeys[foreigntable+foreigncolumn]; ok {
				// already has values
				continue
			} else {
				// get & set values
				query := "SELECT" + foreigncolumn + "FROM" + foreigntable
				var vals []interface{}
				conn.Query(context.Background(), query, &vals)
				foreignkeys[foreigntable+foreigncolumn] = vals
			}
		default:
			return fmt.Errorf("constraint %d not supported", constraint.Contype)
		}
	}
	return nil
}

func getRandomForeignRefValue(conn *pgx.Conn) interface{} {
	var val interface{}
	conn.Query(context.Background(), "select now()", &val)
	return val
}
