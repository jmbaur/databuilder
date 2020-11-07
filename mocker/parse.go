package mocker

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/jmbaur/databuilder/logg"
	pg_query "github.com/lfittl/pg_query_go"
	nodes "github.com/lfittl/pg_query_go/nodes"
)

// Parse uses the io.Reader to parse SQL statements and make the AST
func (m *Mocker) Parse(input io.Reader) {
	data, err := ioutil.ReadAll(input)

	if err != nil {
		logg.Printf(logg.Fatal, "Could not read from stdin: %v\n", err)
		os.Exit(4)
	}
	tree, err := pg_query.Parse(string(data))
	if err != nil {
		logg.Printf(logg.Fatal, "Could not parse SQL: %v\n", err)
		os.Exit(5)
	}

	for _, v := range tree.Statements {
		stmt, ok := v.(nodes.RawStmt)
		if !ok {
			logg.Printf(logg.Fatal, "%v\n", fmt.Errorf("Could not parse statement: %s", v))
			os.Exit(6)
		}

		switch stmt.Stmt.(type) {
		case nodes.CreateStmt:
			create := stmt.Stmt.(nodes.CreateStmt)
			m.createTable(create, create.IfNotExists)
		case nodes.InsertStmt:
			insert := stmt.Stmt.(nodes.InsertStmt)
			if err := m.dropTable(*insert.Relation.Relname); err != nil {
				logg.Printf(logg.Info, "Could not drop table \"%s\": %v\n", *insert.Relation.Relname, err)
			}
		case nodes.AlterTableStmt:
			alter := stmt.Stmt.(nodes.AlterTableStmt)
			if err := m.alterTable(alter); err != nil {
				logg.Printf(logg.Info, "Could not alter table \"%s\": %v\n", *alter.Relation.Relname, err)
			}
		case nodes.CreateEnumStmt:
			enum := stmt.Stmt.(nodes.CreateEnumStmt)
			if err := m.createEnum(enum); err != nil {
				logg.Printf(logg.Info, "Could not create enum: %v\n", err)
			}
		case nodes.DropStmt:
			drop := stmt.Stmt.(nodes.DropStmt)
			switch drop.RemoveType {
			case nodes.OBJECT_EXTENSION:
				continue
			case nodes.OBJECT_TABLE:
				for _, v := range drop.Objects.Items {
					list, ok := v.(nodes.List)
					if !ok {
						continue
					}
					for _, w := range list.Items {
						str, ok := w.(nodes.String)
						if !ok {
							continue
						}
						if err := m.dropTable(str.Str); err != nil && !drop.MissingOk {
							logg.Printf(logg.Info, "Could not drop table \"%s\": %v\n", str.Str, err)
						}
					}
				}
			case nodes.OBJECT_TYPE:
				for _, item := range drop.Objects.Items {
					typename, ok := item.(nodes.TypeName)
					if !ok {
						continue
					}
					for _, item := range typename.Names.Items {
						str, ok := item.(nodes.String)
						if !ok {
							continue
						}
						if err := m.dropEnum(str.Str); err != nil && !drop.MissingOk {
							logg.Printf(logg.Info, "Could not drop enum \"%s\": %v\n", str.Str, err)
						}
					}
				}
			default:
				continue
			}
		default:
			continue
		}
	}
}
