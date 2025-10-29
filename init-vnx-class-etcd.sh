#!/bin/bash

set -e

TENANT="$1"
PROJECT="$2"
PUBKEY="$3"

# uncomment or comment this out
export ETCDPREFIX="/viinex"

AUTHID=vnxworker

MAIN_JSONNET=main-conntour.jsonnet
SAMPLE_YAML=sample-conntour-poc.yaml

# This script is to be run once

if test -z `which etcdctl` ; then
    echo "etcdctl is needed to run this script."
    echo "please run 'apt install -y etcd-client'"
    exit 1
fi

if test -z "$TENANT" || test -z "$PROJECT" ; then
    echo "TENANT and PROJECT should be specified as 1st and 2nd positional arguments"
    exit 1
fi

if test -z "$PUBKEY" ; then
    cat <<EOF
ed25519 public key (in hex format) should be specified as 3rd positional argument.
It should match the private key which is specified as PRIVATE_KEY environment variable
for viinex container.

./keygen-ed25519.sh or wick utility can be used to generate a new key pair.

Alternatively you may use 872adcb43578ebe9a5436d7f27a1af48fb4e34cc51af8c65d7a7c979a41f7786
as a public key.
Corresponding private key is f4aa5571471ef77161f48281b61d92c2f86a822aba30617756a8cc20b5a97fbf.
EOF
    exit 1
fi


if ! test -z `etcdctl get "$ETCDPREFIX/config/$TENANT/$PROJECT/recipe.yaml" --keys-only` ; then
    echo "recipe.yaml is already present. Refusing to proceed."
    exit 1
fi

echo "main: $MAIN_JSONNET" | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/recipe.yaml"
cat <<EOF | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/mapping.yaml"
type: static

cluster-to-instance:
  demo01: vnxworker01
EOF

cat $SAMPLE_YAML | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/clusters/demo01.yaml"

echo -n viinex | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/wamp/$AUTHID/role"
echo -n "$PUBKEY" | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/wamp/$AUTHID/cryptosign"

# upload templates
make etcdupload
