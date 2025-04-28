OSName = $(shell uname -o)

JSONNETS = $(wildcard *.jsonnet)
YAMLS = $(wildcard *.yaml)
JSONS = $(patsubst %.yaml,%.json,$(YAMLS))

all: ${JSONS}

clean:
	rm -rf ${JSONS}

$(JSONS): %.json: %.yaml $(JSONNETS)
	jsonnet --ext-str CID=${CID} --ext-str-file confYaml=$< nvr-main.jsonnet --ext-str OSName=${OSName} -o $@
