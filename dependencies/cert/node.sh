#!/bin/bash

if [ "" = "`openssl ecparam -list_curves | grep secp256k1`" ];
then
    echo "Current Openssl Don't Support secp256k1 ! Please Upgrade Openssl To  OpenSSL 1.0.2k-fips"
    exit;
fi

source ./openssl_conf.sh

function genEC(){
    gmssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:secp256k1 -out node.key
    gmssl req -new -key node.key -config cert.cnf  -out node.csr -subj $NODE_SUBJECT
    gmssl x509 -req -days 3650 -in node.csr -CAkey agency.key -CA agency.crt -out node.crt -CAcreateserial -extensions v3_req -extfile cert.cnf
    gmssl x509  -text -in node.crt | sed -n '5p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | sed 's/[a-z]/\u&/g' | cat >node.serial
}

function genGM(){
    gmssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:sm2p256v1 -out node.key
    gmssl req -new -sm3 -key node.key -config cert.cnf -out node.csr -subj $NODE_SUBJECT
    gmssl x509 -req -days 3650 -in node.csr -CAkey agency.key -CA agency.crt -out node.crt -CAcreateserial -sm3 -extensions v3_req -extfile cert.cnf
    gmssl x509  -text -in node.crt | sed -n '5p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | sed 's/[a-z]/\u&/g' | cat >node.serial
}

agency=$1
node=$2

if [ -z "$agency" ];  then
    echo "Usage:node.sh   agency_name node_name "
elif [ -z "$node" ];  then
    echo "Usage:node.sh   agency_name node_name "
elif [ ! -d "$agency" ]; then
    echo "$agency DIR Don't exist! please Check DIR!"
elif [ ! -f "$agency/agency.key" ]; then
    echo "$agency/agency.key  Don't exist! please Check DIR!"
elif [  -d "$agency/$node" ]; then
    echo "$agency/$node DIR exist! please clean all old DIR!"
else
    cd  $agency
    mkdir -p $node

    if [ "${GM_TLS_OPEN}" = "true" ];then
        genGM
    else
        genEC
    fi

    cp ca.crt agency.crt $node
    mv node.key node.csr node.crt node.serial $node

    cd $node

    cat ca.crt agency.crt  node.crt > chain.crt

    echo "Build  $node Crt suc!!!"
fi


