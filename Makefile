.PHONY: clean

build:
	go build -o databuilder main.go

clean:
	rm -f databuilder
