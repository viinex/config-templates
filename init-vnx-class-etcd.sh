#!/bin/bash

set -e

FLAVOR="$1"
TENANT="$2"
PROJECT="$3"
PUBKEY="$4"

# uncomment or comment this out
export ETCDPREFIX="/viinex"

AUTHID=vnxworker

case "$FLAVOR" in
    nvr)
        export MAIN_JSONNET=main.jsonnet
        export SAMPLE_YAML=sample-home.yaml
        export DEPLOY_TYPE=systemd
        ;;
    conntour)
        export MAIN_JSONNET=main-conntour.jsonnet
        export SAMPLE_YAML=sample-conntour-poc.yaml
        export DEPLOY_TYPE=docker
        ;;
    *)
        echo "Unrecognized flavor"
        exit 1
        ;;
esac

# This script is to be run once

if test -z `which etcdctl` ; then
    echo "etcdctl is needed to run this script."
    echo "please run 'apt install -y etcd-client'"
    exit 1
fi

if test -z "$TENANT" || test -z "$PROJECT" ; then
    echo "TENANT and PROJECT should be specified as 2nd and 3rd positional arguments"
    exit 1
fi

if test -z "$PUBKEY" ; then
    cat <<EOF
ed25519 public key (in hex format) should be specified as 4th positional argument.
It should match the private key which is specified as PRIVATE_KEY environment variable
for viinex container.

./keygen-ed25519.sh or wick utility can be used to generate a new key pair.

Alternatively you may use
872adcb43578ebe9a5436d7f27a1af48fb4e34cc51af8c65d7a7c979a41f7786
as a public key.
(Corresponding private key is
f4aa5571471ef77161f48281b61d92c2f86a822aba30617756a8cc20b5a97fbf
-- this can be specified as PRIVATE_KEY env var in compose.yaml).
Don't use these anywhere except in isolated test or development setups.
EOF
    exit 1
fi


if ! test -z `etcdctl get "$ETCDPREFIX/config/$TENANT/$PROJECT/recipe.yaml" --keys-only` ; then
    echo "recipe.yaml is already present. Refusing to proceed."
    exit 1
fi

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

# upload recipe.yaml in last place to make sure everything else is ready when vnx-class
# realizes that there's a new realm
cat <<EOF | etcdctl put "$ETCDPREFIX/config/$TENANT/$PROJECT/recipe.yaml"
main: $MAIN_JSONNET

ext-str:
  deploy: $DEPLOY_TYPE
EOF
