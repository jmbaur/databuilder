package config

import (
	"io"
	"io/ioutil"
	"log"

	"gopkg.in/yaml.v2"
)

type Config struct {
	Tables []Table `yaml:"tables"`
}

type Table struct {
	Name    string   `yaml:"name"`
	Ignore  bool     `yaml:"ignore"`
	Amount  int      `yaml:"amount"`
	Columns []Column `yaml:"columns"`
}

type Column struct {
	Name     string   `yaml:"name"`
	MockType string   `yaml:"mock_type"`
	Prefix   []string `yaml:"prefix"`
	Suffix   []string `yaml:"suffix"`
	Min      int      `yaml:"min"`
	Max      int      `yaml:"max"`
}

func Parse(reader io.Reader) *Config {
	var cfg Config
	data, err := ioutil.ReadAll(reader)
	if err != nil {
		log.Fatal("failed to read config data: %v\n", err)
	}
	yaml.Unmarshal(data, &cfg)
	return &cfg
}
