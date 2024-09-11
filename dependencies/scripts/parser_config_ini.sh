#!/bin/bash

#set -e
# init function , install crudini
function parser_ini_init()
{
    local myname="parser config ini"
    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

    case $(uname -s) in

    #------------------------------------------------------------------------------
    # macOS
    #------------------------------------------------------------------------------
    Darwin)
        case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
            *)

            ;;
        esac #case $(sw_vers

        ;; #Darwin)

    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
            error_message "Unsupported or unidentified Linux distro."
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        # echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                    sudo apt-get -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)

                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*)

                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                error_message "Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        error_message "Unsupported or unidentified operating system."
        ;;
    esac
}



#ini file get opr
function ini_get()
{
    local file=$1
    local section=$2
    local param=$3
    local no_exit=$4

    local value=$(crudini --get $file $section $param)
    if [ $? -ne 0 ];then
        if [ "${no_exit}" = "true" ];then
            #{ echo >&2 "ERROR - ini config get failed, section is $section param is $param."; exit 1; }
	    echo ""
        else
            error_message "ini config get failed, section is $section param is $param."
        fi
    fi

    echo "$value"
}

#env set
function env_set()
{
    local env="$1"
    local value="$2"
    export $env="$value"
}

#parser config.ini file
function parser_ini()
{
    local file=$1

    if [ ! -f $file ];then
        error_message "build ini config is not exist ,config file is $file"
    fi
    #[common]
    #chain_github_url=https://g.hz.netease.com/netease-blockchain/netease-chain2.0.git
    #gateway_github_url=https://g.hz.netease.com/netease-blockchain/netease-chain2.0.git
    #chain_src_local=../

    # [common] section parser
    local section="common"

    local param="common_github_url"
    local common_github_url=$(ini_get $file $section $param)
    echo "===>>> common_github_url = "${common_github_url}
    env_set "THANOS_COMMON_GIT" ${common_github_url}

    local param="chain_github_url"
    local chain_github_url=$(ini_get $file $section $param)
    echo "===>>> chain_github_url = "${chain_github_url}
    env_set "THANOS_CHAIN_GIT" ${chain_github_url}

    local param="gateway_github_url"
    local gateway_github_url=$(ini_get $file $section $param)
    echo "===>>> gateway_github_url = "${gateway_github_url}
    env_set "THANOS_GATEWAY_GIT" ${gateway_github_url}

    local param="chain_src_local"
    local chain_src_local=$(ini_get $file $section $param "true")
    echo "===>>> chain_src_local = "${chain_src_local}
    env_set "THANOS_CHAIN_LOCAL_PATH" ${chain_src_local}

    local param="jar_local_path"
    local jar_local_path=$(ini_get $file $section $param "true")
    if [ -z "${jar_local_path}" ];then
        jar_local_path=$installPWD
    fi
    echo "===>>> jar_local_path = "${jar_local_path}
    env_set "THANOS_JAR_LOCAL_PATH" ${jar_local_path}

    # [tls]
    # need_tls = false

    # [tls] section
    local section="tls"

    local param="gateway_need_tls"
    local need_tls=$(ini_get $file $section $param)
    echo "===>>> gateway_need_tls = "${need_tls}
    env_set "GATEWAY_NEED_TLS" ${need_tls}

    local param="gm_tls_open"
    local gm_tls_open=$(ini_get $file $section $param)
    echo "===>>> gm_tls_open = "${gm_tls_open}
    env_set "GM_TLS_OPEN" ${gm_tls_open}

    # [chain-nodes]
    # node0= 127.0.0.1  0.0.0.0  4  agent
    # [chain-nodes] section
    local section="chain-nodes"
    local max_node=9999999
    local node_index=0
    while [ $node_index -lt $max_node ]
    do
        local param="node"$node_index
        local node_info=$(ini_get $file $section $param "true")
        if [ -z "${node_info}" ];then
            break
        fi

        env_set "NODE_INFO_"$node_index "${node_info}"

        node_index=$(($node_index+1))
    done

    env_set "NODE_COUNT" ${node_index}


    #[chain-ports]
    #peer_discovery_port=30303
    #peer_rpc_port=8888
    #listen_gateway_port=7007

    # [chain-ports] section
    local section="chain-ports"

    local param="peer_discovery_port"
    local peer_discovery_port=$(ini_get $file $section $param)
    echo "===>>> chain_peer_discovery_port = "${peer_discovery_port}
    env_set "CHAIN_PEER_DISCOVERY_PORT" ${peer_discovery_port}

    local param="peer_rpc_port"
    local chain_peer_rpc_port=$(ini_get $file $section $param)
    echo "===>>> chain_peer_rpc_port = "${chain_peer_rpc_port}
    env_set "CHAIN_PEER_RPC_PORT" ${chain_peer_rpc_port}

    local param="listen_gateway_port"
    local listen_gateway_port=$(ini_get $file $section $param)
    echo "===>>> chain_listen_gateway_port = "${listen_gateway_port}
    env_set "CHAIN_LISTEN_GATEWAY_PORT" ${listen_gateway_port}

    #[gateway-ports]
    #peer_rpc_port = 100
    #web3_rpc_port = 8180
    #web3_http_port = 8580
    #listen_chain_port = 7180

    # [gateway-ports] section
    local section="gateway-ports"

    local param="peer_rpc_port"
    local gateway_peer_rpc_port=$(ini_get $file $section $param)
    echo "===>>> gateway_peer_rpc_port = "${gateway_peer_rpc_port}
    env_set "GATEWAY_PEER_RPC_PORT" ${gateway_peer_rpc_port}

    local param="web3_rpc_port"
    local web3_rpc_port=$(ini_get $file $section $param)
    echo "===>>> gateway_web3_rpc_port = "${web3_rpc_port}
    env_set "GATEWAY_WEB3_RPC_PORT" ${web3_rpc_port}

    local param="web3_http_port"
    local web3_http_port=$(ini_get $file $section $param)
    echo "===>>> gateway_web3_http_port = "${web3_http_port}
    env_set "GATEWAY_WEB3_HTTP_PORT" ${web3_http_port}

    local param="listen_chain_port"
    local listen_chain_port=$(ini_get $file $section $param)
    echo "===>>> gateway_listen_chain_port = "${listen_chain_port}
    env_set "GATEWAY_LISTEN_CHAIN_PORT" ${listen_chain_port}

    #[crypto]
    #secure_key_type = ECDSA
    #sharding_number = 1

    # [crypto] section
    local section="crypto"

    local param="secure_key_type"
    local secure_key_type=$(ini_get $file $section $param)
    echo "===>>> secure_key_type = "${secure_key_type}
    env_set "SECURE_KEY_TYPE" ${secure_key_type}

    local param="sharding_number"
    local sharding_number=$(ini_get $file $section $param)
    echo "===>>> sharding_number = "${sharding_number}
    env_set "SHARDING_NUMBER" ${sharding_number}

    local param="cipher_key_type"
    local cipher_key_type=$(ini_get $file $section $param)
    echo "===>>> cipher_key_type = "${cipher_key_type}
    env_set "CIPHER_KEY_TYPE" ${cipher_key_type}
    #[maven]
    #url=https://epaymvn.hz.netease.com/nexus/content/groups/public/
    #repositoryId=netease-public

    # [maven] section
    local section="maven"    
    #release
    local param="release_url"
    local maven_release_url=$(ini_get $file $section $param)
    echo "===>>> maven_release_url = "${maven_release_url}
    env_set "MAVEN_RELEASE_URL" ${maven_release_url}

    local param="release_repositoryId"
    local maven_release_repositoryId=$(ini_get $file $section $param)
    echo "===>>> maven_release_repositoryId = "${maven_release_repositoryId}
    env_set "MAVEN_RELEASE_REPO_ID" ${maven_release_repositoryId}

    #snapshot
    local param="snapshot_url"
    local maven_snapshot_url=$(ini_get $file $section $param)
    #echo "===>>> maven_snapshot_url = "${maven_snapshot_url}
    env_set "MAVEN_SNAPSHOT_URL" ${maven_snapshot_url}

    local param="snapshot_repositoryId"
    local maven_snapshot_repositoryId=$(ini_get $file $section $param)
    #echo "===>>> maven_snapshot_repositoryId = "${maven_snapshot_repositoryId}
    env_set "MAVEN_SNAPSHOT_REPO_ID" ${maven_snapshot_repositoryId}
}

# check all env
function ini_param_check()
{
    # [common] section
    # env THANOS_CHAIN_GIT
    local chain_github_url=${THANOS_CHAIN_GIT}
    if [ -z "${chain_github_url}" ];then
        error_message "[common] chain_github_url not set."
    fi

    # env THANOS_GATEWAY_GIT
    local gateway_github_url=${THANOS_GATEWAY_GIT}
    if [ -z "${gateway_github_url}" ];then
        error_message "[common] gateway_github_url not set."
    fi

    # env THANOS_COMMON_GIT
    local common_github_url=${THANOS_COMMON_GIT}
    if [ -z "${common_github_url}" ];then
        error_message "[common] common_github_url not set ."
    fi

#    # env THANOS_CHAIN_LOCAL_PATH
#    local chain_src_local=${THANOS_CHAIN_LOCAL_PATH}
#    if [ -z "${chain_src_local}" ];then
#        error_message "[common] chain_src_local not set ."
#    fi

    # [maven] section
    # env MAVEN_RELEASE_REPO_ID
    local maven_url=${MAVEN_RELEASE_URL}
    if [ -z "${maven_url}" ];then
        error_message "[maven] release_url not set."
    fi

    # env MAVEN_RELEASE_REPO_ID
    local maven_repositoryId=${MAVEN_RELEASE_REPO_ID}
    if [ -z "${maven_repositoryId}" ];then
        error_message "[maven] release_repositoryId not set ."
    fi

    # [tls] section
    # env GATEWAY_NEED_TLS
    local need_tls=${GATEWAY_NEED_TLS}
    if [ -z "${need_tls}" ];then
        error_message "[tls] need_tls not set ."
    fi

    # env GM_TLS_OPEN
    local gm_tls_open=${GM_TLS_OPEN}
    if [ -z "${gm_tls_open}" ];then
        error_message "[tls] gm_tls_open not set ."
    fi
    # [crypto] section
    # env SECURE_KEY_TYPE
    local secure_key_type=${SECURE_KEY_TYPE}
    if [ -z "secure_key_type" ];then
        error_message "[crypto] secure_key_type not set."
    fi

    # env SHARDING_NUMBER
    local sharding_number=${SHARDING_NUMBER}
    if [ -z "$sharding_number" ];then
        error_message "[crypto] sharding_number not set."
    fi

    if [ $sharding_number -le 0 ];then
        error_message "[crypto] sharding_number invalid => ${SHARDING_NUMBER} ."
    fi

    # [crypto] section
    # env CIPHER_KEY_TYPE
    local cipher_key_type=${CIPHER_KEY_TYPE}
    if [ -z "cipher_key_type" ];then
        error_message "[crypto] cipher_key_type not set."
    fi

    # [chain-ports] section
    # env CHAIN_PEER_DISCOVERY_PORT
    local peer_discovery_port=${CHAIN_PEER_DISCOVERY_PORT}
    if [ -z "${peer_discovery_port}" ];then
        error_message "[chain-ports] peer_discovery_port not set ."}
    fi
    if [ ${peer_discovery_port} -le 0 ] || [ ${peer_discovery_port} -ge 65536 ];then
        error_message "[chain-ports] peer_discovery_port invalid => ${CHAIN_PEER_DISCOVERY_PORT} ."
    fi

    # env CHAIN_PEER_RPC_PORT
    local chain_peer_rpc_port=${CHAIN_PEER_RPC_PORT}
    if [ -z "${chain_peer_rpc_port}" ];then
        error_message "[chain-ports] peer_rpc_port may not set ."
    fi
    if [ ${chain_peer_rpc_port} -le 0 ] || [ ${chain_peer_rpc_port} -ge 65536 ];then
        error_message "[chain-ports] peer_rpc_port invalid => ${CHAIN_PEER_RPC_PORT} ."
    fi

    # env CHAIN_LISTEN_GATEWAY_PORT
    local listen_gateway_port=${CHAIN_LISTEN_GATEWAY_PORT}
    if [ -z "${listen_gateway_port}" ];then
        error_message "[chain-ports] listen_gateway_port not set ."
    fi
    if [ ${listen_gateway_port} -le 0 ] || [ ${listen_gateway_port} -ge 65536 ];then
        error_message "[chain-ports] listen_gateway_port invalid => ${CHAIN_LISTEN_GATEWAY_PORT} ."
    fi

    # [gateway-ports] section
    # env GATEWAY_PEER_RPC_PORT
    local gateway_peer_rpc_port=${GATEWAY_PEER_RPC_PORT}
    if [ -z "${gateway_peer_rpc_port}" ];then
        error_message "[gateway-ports] peer_rpc_port may not set ."
    fi
    if [ ${gateway_peer_rpc_port} -le 0 ] || [ ${gateway_peer_rpc_port} -ge 65536 ];then
        error_message "[gateway-ports] peer_rpc_port invalid => ${GATEWAY_PEER_RPC_PORT} ."
    fi

    # env GATEWAY_WEB3_RPC_PORT
    local web3_rpc_port=${GATEWAY_WEB3_RPC_PORT}
    if [ -z "${web3_rpc_port}" ];then
        error_message "[gateway-ports] web3_rpc_port may not set ."
    fi
    if [ ${web3_rpc_port} -le 0 ] || [ ${web3_rpc_port} -ge 65536 ];then
        error_message "[gateway-ports] web3_rpc_port invalid => ${GATEWAY_WEB3_RPC_PORT} ."
    fi

    #env_set "GATEWAY_WEB3_HTTP_PORT" ${web3_http_port}
    local web3_http_port=${GATEWAY_WEB3_HTTP_PORT}
    if [ -z "${web3_http_port}" ];then
        error_message "[gateway-ports] web3_http_port may not set ."
    fi
    if [ ${web3_http_port} -le 0 ] || [ ${web3_http_port} -ge 65536 ];then
        error_message "[gateway-ports] web3_http_port invalid => ${GATEWAY_WEB3_HTTP_PORT} ."
    fi

    # env GATEWAY_LISTEN_CHAIN_PORT
    local listen_chain_port=${GATEWAY_LISTEN_CHAIN_PORT}
    if [ -z "${listen_chain_port}" ];then
        error_message "[gateway-ports] listen_chain_port not set ."
    fi
    if [ ${listen_chain_port} -le 0 ] || [ ${listen_chain_port} -ge 65536 ];then
        error_message "[gateway-ports] listen_chain_port invalid => ${CHAIN_LISTEN_GATEWAY_PORT} ."
    fi

    # [gateway-ports] section
    local node_count=${NODE_COUNT}
    if [ -z "$node_count" ];then
        error_message "node_count null ,[nodes] empty ."
    fi

    if [ $node_count -le 0 ];then
        error_message "node_count invalid ,[nodes] empty ."
    fi

    #[chain-nodes] section
    #env NODE_INFO_$i
    declare -A map=()

    local node_index=0
    while [ $node_index -lt $node_count ]
    do
        local node_name=NODE_INFO_${node_index}
        local node_info=`eval echo '$'"$node_name"`
        valid_node "$node_info"
        local node=($node_info)
        local ip=${node[0]}
        if [ ! -z ${map["$ip"]} ];then
            error_message "server repeat , ip: "$ip
        fi
        map["$ip"]="exist"

        env_set "NODE_INFO_"$node_index "${node_info}"

        node_index=$(($node_index+1))
    done
}

#check if ip valid
function is_valid_ip()
{
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# is node valid
function valid_node()
{
    local node=($1)

    # node0= 127.0.0.1  0.0.0.0  4  agent
    local p2pip=${node[0]}
    local listenip=${node[1]}
    local count=${node[2]}
    local agent=${node[3]}

    if [ -z "${p2pip}" ];then
        error_message "[nodes] p2pip null . node => "$1
    fi

    if [ -z "${listenip}" ];then
        error_message "[nodes] listenip null . node => "$1
    fi

    if [ -z "${count}" ];then
        error_message "[nodes] count null . node => "$1
    fi

    if [ -z "${agent}" ];then
        error_message "[nodes] agent null . node => "$1
    fi

    is_p2pip_valid=$(is_valid_ip $p2pip)
    is_listenip_ip_valid=$(is_valid_ip $listenip)

    if [ "$is_p2pip_valid" = "false" ];then
        error_message "[nodes] p2pip invalid, p2pip => ${p2pip} ."
    elif [ "$is_listenip_ip_valid" = "false" ];then
        error_message "[nodes] listenip invalid, listenip => ${listenip} ."
    fi

    if [ $count -le 0 ];then
         error_message "[nodes] count invalid, count => ${count} ."
    fi

    echo "${p2pip}"
}
