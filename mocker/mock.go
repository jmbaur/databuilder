package mocker

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"time"

	"github.com/brianvoe/gofakeit/v5"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/jmbaur/databuilder/logg"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

func (m *Mocker) Mock(writer io.Writer) error {
	if err := m.prep(); err != nil {
		return err
	}

	gofakeit.Seed(time.Now().UnixNano())

	for _, table := range m.Tables {
		if m.tableSkip(*table.Relation.Relname) {
			continue
		}

		done := make(chan error)
		go func() {
			done <- nil // we do not want to block the first insert into the table
		}()

		var i, errors int
		var columns []string
		for i < m.Config.Amount {
			if errors > m.Config.Amount {
				break // stop trying to make these
			}

			var w []interface{}
			for _, tableElement := range table.TableElts.Items {

				column, okColumn := tableElement.(nodes.ColumnDef)
				if !okColumn {
					continue
				}

				if column.TypeName == nil {
					continue
				}

				columnName := *column.Colname
				var columnType string
				var foreigncolumn, foreigntable *string
				for _, t := range column.TypeName.Names.Items {
					columnType = t.(nodes.String).Str
					if columnType == "pg_catalog" {
						constraints := column.Constraints.Items
						constrIndex := findForeignConstraint(constraints)
						if constrIndex < 0 {
							continue
						}
						tmpForCol := constraints[constrIndex].(nodes.Constraint).PkAttrs.Items[0].(nodes.String).Str
						foreigncolumn = &tmpForCol
						foreigntable = constraints[constrIndex].(nodes.Constraint).Pktable.Relname
						break
					}
				}

				var columnValue interface{}
				switch columnType {
				case "serial":
				case "uuid":
					// these are created by postgres on insert
					continue
				case "int4": // "signed 4-byte integer "https://www.postgresql.org/docs/8.1/datatype.html
					columnValue = gofakeit.Uint32()
				case "bool":
					columnValue = gofakeit.Bool()
				case "varchar":
				case "text":
					columnValue = generateText(columnName, column.IsNotNull)
				case "date":
					columnValue = gofakeit.Date().Format(time.RFC3339)
				case "timestamp":
					columnValue = gofakeit.Date()
				case "daterange":
					date1 := gofakeit.Date()
					date2 := date1.Add(time.Duration(gofakeit.Number(1, 10000)) * time.Hour)
					columnValue = "[" + date1.Format(time.RFC3339) + "," + date2.Format(time.RFC3339) + "]"
				case "pg_catalog":
					columnValue = getRandomForeignRefValue(m.Config.Db, *foreigntable, *foreigncolumn)
				case "json":
					json, _ := json.Marshal(struct {
						Status string `json:"status"`
					}{Status: "JSON is not yet implemented."})
					columnValue = json
				case "bytea":
				case "jsonb":
					continue
				default:
					// is most likely an enum type
					enumIndex := findEnumDef(m.Enums, columnType)
					if enumIndex < 0 {
						logg.Printf(logg.Warn, "Could not find enum %s\n", columnType)
						continue
					}
					columnValue = getRandomEnumValue(m.Enums, enumIndex)
				}
				if i == 0 {
					columns = append(columns, columnName)
				}
				w = append(w, columnValue)
			}
			// insert into  table
			insert, err := buildInsertStmt(columns, *table.Relation.Relname, w)
			if err != nil {
				logg.Printf(logg.Warn, "Failed to build insert statement for table \"%s\": %v\n", *table.Relation.Relname, err)
				i++
				continue
			}

			prevErr := <-done
			if prevErr != nil {
				errors++
				continue // try to make again
			}
			go func() {
				_, err := writer.Write(*insert, w...)
				if err != nil {
					done <- err
					return
				}
				done <- nil
			}()
			i++
		}
	}
	return nil
}

func findEnumDef(enums []nodes.CreateEnumStmt, enumName string) int {
	idx := -1
	for i, enum := range enums {
		if enum.TypeName.Items[0].(nodes.String).Str == enumName {
			idx = i
		}
	}
	return idx
}

func getRandomEnumValue(enums []nodes.CreateEnumStmt, indexOfEnum int) interface{} {
	choices := enums[indexOfEnum].Vals.Items
	idx := rand.Intn(len(choices))
	return choices[idx].(nodes.String).Str
}

func findForeignConstraint(columnConstraints []nodes.Node) int {
	idx := -1
	for i, c := range columnConstraints {
		constraint, ok := c.(nodes.Constraint)
		if !ok {
			logg.Printf(logg.Warn, "Not a constraint: %v\n", c)
		}
		if constraint.Contype == nodes.CONSTR_FOREIGN {
			idx = i
		}
	}
	return idx
}

func getRandomForeignRefValue(db *pgxpool.Pool, foreigntable, foreigncolumn string) interface{} {
	row := db.QueryRow(context.Background(), fmt.Sprintf("SELECT %s FROM %s ORDER BY RANDOM() LIMIT 1", foreigncolumn, foreigntable))
	var val interface{}
	err := row.Scan(&val)
	if err != nil {
		logg.Printf(logg.Warn, "%v\n", err)
	}
	return val
}

func passesConstraints(widget interface{}, constraints []nodes.Constraint) bool {
	return true
}

func buildInsertStmt(columns []string, table string, w []interface{}) (*string, error) {
	if len(columns) == 0 {
		return nil, fmt.Errorf("table has no columns")
	}
	if len(columns) != len(w) {
		return nil, fmt.Errorf("number of columns and number of values do not match")
	}
	var insert string
	insert += "INSERT INTO "
	insert += table + " ("
	for i, col := range columns {
		if i == len(columns)-1 {
			insert += col + ") "
		} else {
			insert += col + ", "
		}
	}
	insert += "VALUES ("
	for i := range columns {
		if i == len(columns)-1 {
			insert += fmt.Sprintf("%s", w[i]) + ")"
			// insert += "$" + strconv.Itoa(i+1) + ")"
		} else {
			insert += fmt.Sprintf("%s", w[i]) + ", "
			// insert += "$" + strconv.Itoa(i+1) + ", "
		}
	}
	return &insert, nil
}
