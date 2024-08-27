#!/bin/bash

#public config
installPWD=$PWD
DEPENDENCIES_DIR=$installPWD/dependencies
DEPENDENCIES_COMMON_DIR=$DEPENDENCIES_DIR/common
source $DEPENDENCIES_DIR/scripts/utils.sh
source $DEPENDENCIES_DIR/scripts/os_version_check.sh
source $DEPENDENCIES_DIR/scripts/dependencies_install.sh
source $DEPENDENCIES_DIR/scripts/dependencies_check.sh

function install()
{
    echo "Install thanos-chain/gateway start."
    initial

    local depends_common_dir=$DEPENENCIES_DIR/common

    local install_dir_name=$(get_dir_name $installPWD)
    #constrcut dir of thanos-chain/gateway for each entity
    local max_node=9999
    local node_index=0
    while [ $node_index -lt $max_node ]
    do
        local current_node_dir_name="node"$node_index
        if [ ! -d ${current_node_dir_name} ];then
            break
        fi

        local current_node_dir=$installPWD/$current_node_dir_name
        #thanos-chain
        local current_chain_dir=$current_node_dir/thanos-chain
        if [ -d ${current_chain_dir} ];
        then
            echo "$current_chain_dir already exist. If you want to rebuild, please remove old files and reinstall node from tar package."
        else
            mkdir -p $current_chain_dir
            cp ${DEPENDENCIES_COMMON_DIR}/thanos-chain.jar $current_chain_dir
            cp ${DEPENDENCIES_COMMON_DIR}/start_chain.sh $current_chain_dir
            #database
            mv $current_node_dir/database $current_chain_dir
            local chain_database_path=$current_chain_dir/database
            cp ${DEPENDENCIES_COMMON_DIR}/genesis.json $chain_database_path
            #resource
            local chain_resource_dir=$current_chain_dir/resource
            mkdir -p $chain_resource_dir
            cp ${DEPENDENCIES_COMMON_DIR}/chain-logback.xml $chain_resource_dir
            cp -r $current_node_dir/tls $chain_resource_dir
            #complete thanos-chain.conf
            local log_config_path=$chain_resource_dir/chain-logback.xml
            local key_path=$chain_resource_dir/tls/node.key
            local certs_path=$chain_resource_dir/tls/chain.crt
            complete_chain_conf $chain_database_path $log_config_path $key_path $certs_path $current_node_dir $chain_resource_dir
            #scripts
            local chain_scripts_dir=$current_chain_dir/scripts
            mkdir -p $chain_scripts_dir
            cp ${DEPENDENCIES_COMMON_DIR}/node_action.sh $chain_scripts_dir
            cp ${DEPENDENCIES_COMMON_DIR}/thanos-web3j-sdk.jar $chain_scripts_dir
            #complete nodeAction.ini
            local nodeAction_ini_path=$current_node_dir/nodeAction.ini
            crudini --set $nodeAction_ini_path '' "keyPath" ${key_path}
            crudini --set $nodeAction_ini_path '' "certsPath" ${certs_path}
            mv $nodeAction_ini_path $chain_scripts_dir
        fi


        #thanos-gateway
        local current_gateway_dir=$current_node_dir/thanos-gateway
        if [ -d ${current_gateway_dir} ];
        then
            echo "$current_gateway_dir already exist. If you want to rebuild, please remove old files and reinstall node from tar package."
        else
            mkdir -p $current_gateway_dir
            cp ${DEPENDENCIES_COMMON_DIR}/thanos-gateway.jar $current_gateway_dir
            cp ${DEPENDENCIES_COMMON_DIR}/start_gateway.sh $current_gateway_dir
            #resource
            local gateway_resource_dir=$current_gateway_dir/resource
            mkdir -p $gateway_resource_dir
            cp ${DEPENDENCIES_COMMON_DIR}/gateway-logback.xml $gateway_resource_dir
            mv $current_node_dir/tls $gateway_resource_dir
            #complete thanos-gateway.conf
            local log_config_path=$gateway_resource_dir/gateway-logback.xml
            local key_path=$gateway_resource_dir/tls/node.key
            local certs_path=$gateway_resource_dir/tls/chain.crt
            complete_gateway_conf $log_config_path $key_path $certs_path $current_node_dir $gateway_resource_dir
        fi

        # remove useless file
        rm -rf $current_node_dir/*.conf

        echo "install node$node_index success.."
        node_index=$(($node_index+1))
    done

    echo "Install thanos-chain/gateway finish. node_num=$node_index"
}

function initial()
{
        #check sudo permission
    request_sudo_permission
    # operation system check
    os_version_check
    # java version check
    java_version_check

    sudo chown -R $(whoami) $installPWD

    check_and_install_bc_java ${DEPENDENCIES_COMMON_DIR}

    check_if_install_without_exit crudini

    if [ $? -ne 0 ];then
        simple_dependencies_install
    fi

    check_if_install crudini
}


function complete_chain_conf(){

    export DATABASE_DIR_TPL="\"$1\""
    export LOG_CONFIG_PATH_TPL="\"$2\""
    export KEY_PATH_TPL="\"$3\""
    export CERTS_PATH_TPL="\"$4\""
    local src=$5
    local dst=$6

    MYVARS='${DATABASE_DIR_TPL}:${LOG_CONFIG_PATH_TPL}:${KEY_PATH_TPL}:${CERTS_PATH_TPL}'
    envsubst $MYVARS < $src/thanos-chain.conf > $dst/thanos-chain.conf
}

function complete_gateway_conf()
{
    export LOG_CONFIG_PATH_TPL="\"$1\""
    export KEY_PATH_TPL="\"$2\""
    export CERTS_PATH_TPL="\"$3\""
    local src=$4
    local dst=$5

    MYVARS='${LOG_CONFIG_PATH_TPL}:${KEY_PATH_TPL}:${CERTS_PATH_TPL}'
    envsubst $MYVARS < $src/thanos-gateway.conf > $dst/thanos-gateway.conf
}

install
