package mock

import (
	"context"
	"fmt"
	"log"
	"math/rand"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/jmbaur/databuilder/db"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

// Mock traverses the Postgres AST and creates fake records
func Mock(queryChan chan db.Query, resultChan chan db.Result, insertChan chan db.Record, schema *Schema) {
	// gofakeit.Seed(time.Now().UnixNano())

	// for _, table := range schema.Tables {
	// 	for {
	// 		r := db.Record{}
	// 		for _, tableElement := range table.TableElts.Items {

	// 			column, okColumn := tableElement.(nodes.ColumnDef)
	// 			if !okColumn {
	// 				continue
	// 			}

	// 			if column.TypeName == nil {
	// 				continue
	// 			}

	// 			columnName := *column.Colname
	// 			var columnType string
	// 			var foreigncolumn, foreigntable *string
	// 			for _, t := range column.TypeName.Names.Items {
	// 				columnType = t.(nodes.String).Str
	// 				if columnType == "pg_catalog" {
	// 					constraints := column.Constraints.Items
	// 					constrIndex := findForeignConstraint(constraints)
	// 					if constrIndex < 0 {
	// 						continue
	// 					}
	// 					tmpForCol := constraints[constrIndex].(nodes.Constraint).PkAttrs.Items[0].(nodes.String).Str
	// 					foreigncolumn = &tmpForCol
	// 					foreigntable = constraints[constrIndex].(nodes.Constraint).Pktable.Relname
	// 					break
	// 				}
	// 			}

	// 			var columnValue interface{}
	// 			switch columnType {
	// 			case "serial":
	// 				fallthrough
	// 			case "uuid":
	// 				continue
	// 			case "int4": // "signed 4-byte integer "https://www.postgresql.org/docs/8.1/datatype.html
	// 				columnValue = fmt.Sprintf("%d", gofakeit.Uint32())
	// 			case "bool":
	// 				fallthrough
	// 			case "boolean":
	// 				columnValue = strconv.FormatBool(gofakeit.Bool())
	// 			case "varchar":
	// 				fallthrough
	// 			case "text":
	// 				columnValue = fmt.Sprintf("'%s'", generateText(columnName, column.IsNotNull))
	// 			case "date":
	// 				columnValue = fmt.Sprintf("'%s'", gofakeit.Date().Format(time.RFC3339))
	// 			case "timestamp":
	// 				columnValue = fmt.Sprintf("'%s'", gofakeit.Date().Format(time.RFC3339))
	// 			case "daterange":
	// 				date1 := gofakeit.Date()
	// 				date2 := date1.Add(time.Duration(gofakeit.Number(1, 10000)) * time.Hour)
	// 				columnValue = fmt.Sprintf("'[%s,%s]'", date1.Format(time.RFC3339), date2.Format(time.RFC3339))
	// 			case "pg_catalog":
	// 				columnValue = getRandomForeignRefValue(schema.Config.Db, *foreigntable, *foreigncolumn)
	// 			case "json":
	// 				json, _ := json.Marshal(struct {
	// 					Status string `json:"status"`
	// 				}{Status: "JSON is not yet implemented."})
	// 				columnValue = fmt.Sprintf("'%s'", json)
	// 			case "bytea":
	// 				fallthrough
	// 			case "jsonb":
	// 				continue
	// 			default:
	// 				// is most likely an enum type
	// 				enumIndex := findEnumDef(schema.Enums, columnType)
	// 				if enumIndex < 0 {
	// 					log.Printf("Could not find enum %s\n", columnType)
	// 					continue
	// 				}
	// 				columnValue = fmt.Sprintf("'%s'", getRandomEnumValue(schema.Enums, enumIndex))
	// 			}
	// 			r[columnName] = columnValue
	// 		}
	// 	}
	// }
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
			log.Printf("Not a constraint: %v\n", c)
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
		log.Printf("%v\n", err)
	}
	return val
}

func passesConstraints(widget interface{}, constraints []nodes.Constraint) bool {
	return true
}
