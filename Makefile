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
	jsonnet --ext-str CID=${CID} --ext-str-file confYaml=$< main.jsonnet --ext-str OSName=${OSName} --ext-str deploy=systemd -o $@

etcdclean:
	etcdctl del ${ETCD_PREFIX}/templates --prefix $(ETCDAUTH)

etcdupload:
	for i in ${JSONNETS}; do etcdctl put ${ETCD_PREFIX}/templates/jsonnet/$${i} $(ETCDAUTH) < $${i}; done
