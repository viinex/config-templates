OSName = $(shell uname -o)

JSONNETS = $(wildcard *.jsonnet)
YAMLS = $(wildcard *.yaml)
JSONS = $(patsubst %.yaml,%.json,$(YAMLS))

all: ${JSONS}

clean:
	rm -rf ${JSONS}

$(JSONS): %.json: %.yaml $(JSONNETS)
	jsonnet --ext-str CID=${CID} --ext-str-file confYaml=$< main.jsonnet --ext-str OSName=${OSName} -o $@

etcdclean:
	etcdctl del /templates --prefix --user root --password "${ETCDPASS}"

etcdupload:
	for i in ${JSONNETS}; do etcdctl put /templates/jsonnet/$${i} --user root --password "${ETCDPASS}" < $${i}; done
