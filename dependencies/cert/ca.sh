#!/bin/bash

source ./openssl_conf.sh

function genRSA(){
    gmssl genrsa -out ca.key 2048
    gmssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj $CHAIN_SUBJECT
}

function genGM(){
    gmssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:sm2p256v1 -out ca.key
    gmssl req -new -x509 -days 3650 -key ca.key -sm3 -out ca.crt -subj $CHAIN_SUBJECT
}

if [  -f "ca.key" ]; then
    echo "ca.key exist! please clean all old file!"
elif [  -f "ca.crt" ]; then
    echo "ca.crt exist! please clean all old file!"
else
    if [ "${GM_TLS_OPEN}" = "true" ];then
        genGM
    else
        genRSA
    fi
    echo "Build Ca suc!!!"
fi

