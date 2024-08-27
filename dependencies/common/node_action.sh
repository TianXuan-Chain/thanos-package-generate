#!/bin/bash

#public config
nodeAction_ini_path=$PWD/nodeAction.ini

function register()
{
    notice
    java -jar thanos-web3j-sdk.jar 'registerNode' $nodeAction_ini_path
}

function cancel()
{
    notice
    java -jar thanos-web3j-sdk.jar 'cancelNode' $nodeAction_ini_path
}

function notice()
{
    print_dash
    echo "Please make sure your gateway and chain node is connected to others successfully. "
    echo "If connect failed, please update below files with the latest ip list."
    echo "   1) 'thanos-chain.conf' and 'thanos-gateway.conf' in this server."
    echo "   2)  'build/follow/bootstrap.node' in the server for package-generate."
    print_dash
}

function print_dash()
{
    local columns=$(tput cols)
    for((j=0;j<${columns};j++))
    do
        echo -n "-";
    done
}

case "$1" in
    'register')
        register
        ;;
    'cancel')
        cancel
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {register|cancel}"
        #exit 1
esac
