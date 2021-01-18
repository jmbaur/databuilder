package mock

import (
	"strconv"
	"strings"

	"github.com/brianvoe/gofakeit/v6"
)

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

	return "not implemented"
}
