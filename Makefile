OSName = $(shell uname -o)

JSONNETS = $(wildcard *.jsonnet)
YAMLS = $(wildcard *.yaml)
JSONS = $(patsubst %.yaml,%.json,$(YAMLS))

all: ${JSONS}

clean:
	rm -rf ${JSONS}

ifeq (${ETCDPASS},)
	ETCDAUTH =
else
	ETCDAUTH =  --user root --password "${ETCDPASS}"
endif

$(JSONS): %.json: %.yaml $(JSONNETS)
	jsonnet --ext-str CID=${CID} --ext-str-file confYaml=$< main.jsonnet --ext-str OSName=${OSName} -o $@

etcdclean:
	etcdctl del ${ETCDPREFIX}/templates --prefix $(ETCDAUTH)

etcdupload:
	for i in ${JSONNETS}; do etcdctl put ${ETCDPREFIX}/templates/jsonnet/$${i} $(ETCDAUTH) < $${i}; done
