package mock

func buildInsertStmt() {
	// if len(records) == 0 {
	// 	return nil, fmt.Errorf("no records to insert")
	// }

	// var stmt string
	// stmt += "INSERT INTO " + table + " ("

	// firstRec := records[0]
	// cols := []string{}
	// for col := range firstRec {
	// 	cols = append(cols, col)
	// 	stmt += col + ", "
	// }
	// stmt = stmt[:len(stmt)-2] + ") VALUES "

	// for _, r := range records {
	// 	stmt += "("
	// 	for i := 0; i < len(r); i++ {
	// 		stmt += fmt.Sprintf("%s", r[cols[i]]) + ","
	// 	}
	// 	stmt = stmt[:len(stmt)-1] + "), "
	// }
	// stmt = stmt[:len(stmt)-2] + ";"

	// return &stmt, nil
}
