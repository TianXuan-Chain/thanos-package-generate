#!/bin/bash

source ./openssl_conf.sh

function genRSA(){
    gmssl genrsa -out agency.key 2048
    gmssl req -new -key agency.key -config cert.cnf -out agency.csr -subj $AGENT_SUBJECT
    gmssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -CAcreateserial -in agency.csr -out agency.crt  -extensions v4_req -extfile cert.cnf
}

function genGM(){
    gmssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:sm2p256v1 -out agency.key
    gmssl req -new -sm3 -key agency.key -config cert.cnf -out agency.csr -subj $AGENT_SUBJECT
    gmssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -in agency.csr -out agency.crt -CAcreateserial -sm3 -extensions v4_req -extfile cert.cnf
}

name=$1

if [ -z "$name" ];  then
    echo "Usage:agency.sh    agency_name "
elif [  -d "$name" ]; then
    echo "$name DIR exist! please clean all old DIR!"
else
    mkdir $name

    if [ "${GM_TLS_OPEN}" = "true" ];then
        genGM
    else
        genRSA
    fi

    cp ca.crt cert.cnf $name/
    mv agency.key agency.csr agency.crt  $name/
    echo "Build $name Agency Crt suc!!!"
fi

