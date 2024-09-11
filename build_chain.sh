#!/bin/bash

installPWD=$PWD
scriptPWD=$installPWD/dependencies/scripts
source $scriptPWD/utils.sh
source $scriptPWD/public_config.sh
source $scriptPWD/os_version_check.sh
source $scriptPWD/dependencies_install.sh
source $scriptPWD/dependencies_check.sh
source $scriptPWD/parser_config_ini.sh

function version()
{
    VERSION=$(cat release_note.txt 2>/dev/null)
    echo "                                                     "
    echo "##### thanos-chain-build-tool VERSION=$VERSION #####"
    echo "                                                     "
}

# initial
function initial()
{
    # version print.
    version


    # sudo permission check
    request_sudo_permission

    #check java and maven install
    dependencies_pre_check

    # dependencies install
    dependencies_install

    # check if dependencies install success
    build_dependencies_check

    # parser config.ini file，解析配置文件，将配置字段放入shell环境变量中
    cd $installPWD
    parser_ini config.ini

    # config.ini param check，检查配置字段是否合法（格式检查）
    ini_param_check

    #clone from github for thanos-chain source and check if need compile thanos-chain
    #安装包
    clone_and_build

    print_dash
}

function clone_and_build()
{
    echo "clone and build jar start..."
    #check if jar package already exist
    jar_local_path=${THANOS_JAR_LOCAL_PATH}
#    if [ -z "${jar_local_path}" ];then
#        jar_local_path=$installPWD
#    fi

    chain_local_path=${THANOS_CHAIN_LOCAL_PATH}
    if [ -z "${chain_local_path}" ];then
        chain_local_path=$installPWD/../  #Parent Directory
    fi

    #check thanos-common jar if exist
    check_file_exist ${jar_local_path}/thanos-common.jar
    if [ $? -eq 0  ];then
        echo "thanos-common.jar has already exist."
    else
        #git clone thanos-common and build
        echo "start clone and build thanos-common..."

        #deploy bctls-gm-jdk15on.jar to private maven repository.
        deploy_maven_repository 'bctls-gm-jdk15on.jar' ${DEPENDENCIES_GMTLS_DIR} ${DEPENDENCIES_GMTLS_DIR}/pom.properties ${MAVEN_RELEASE_URL} ${MAVEN_RELEASE_REPO_ID}

        common_github_url=${THANOS_COMMON_GIT}
        if [ -z "${common_github_url}" ];then
            common_github_url="https://github.com/netease-blockchain/thanos-common.git"
        fi

        cd ${chain_local_path}
        git clone ${common_github_url} thanos-common
        if [ ! -d thanos-common ];then
            error_message "git clone thanos-common failed!"
        fi
        cd thanos-common
        mvn clean install -Dmaven.test.skip=true
        local target_path=$PWD/target
        cp $target_path/thanos-common.jar $jar_local_path
        #deploy thanos-common.jar to private maven repository.
        deploy_maven_repository 'thanos-common.jar' $target_path $target_path/maven-archiver/pom.properties ${MAVEN_SNAPSHOT_URL} ${MAVEN_SNAPSHOT_REPO_ID}
    fi

    #check thanos-gateway jar if exist
    check_file_exist ${jar_local_path}/thanos-gateway.jar
    if [ $? -eq 0 ];then
        echo "thanos-gateway.jar has already exist."
    else
        #git clone thanos-gateway and build
        echo "start clone and build thanos-gateway..."
        gateway_github_url=${THANOS_GATEWAY_GIT}
            if [ -z "${gateway_github_url}" ];then
            gateway_github_url="https://github.com/netease-blockchain/thanos-gateway.git"
        fi

        cd ${chain_local_path}
        git clone ${gateway_github_url} thanos-gateway
        if [ ! -d thanos-gateway ];then
            error_message "git clone thanos-gateway failed!"
        fi
        cd thanos-gateway
        git checkout dev
        mvn clean install -Dmaven.test.skip=true
        cp target/thanos-gateway.jar $jar_local_path
    fi

    #check thanos-chain jar if exist
    check_file_exist ${jar_local_path}/thanos-chain.jar
    if [ $? -eq 0 ];then
        echo "thanos-chain.jar has already exist."
    else
        #git clone thanos-chain and build
        echo "start clone and build thanos-chain..."

        #deploy solc*.jar to private maven repository.
        deploy_maven_repository 'solcJ-all-0.4.25.jar' ${DEPENDENCIES_SOLC_DIR} ${DEPENDENCIES_SOLC_DIR}/pom.properties ${MAVEN_RELEASE_URL} ${MAVEN_RELEASE_REPO_ID}

        chain_github_url=${THANOS_CHAIN_GIT}
            if [ -z "${chain_github_url}" ];then
            chain_github_url="https://github.com/netease-blockchain/thanos-chain.git"
        fi

        cd ${chain_local_path}
        git clone ${chain_github_url} thanos-chain
        if [ ! -d thanos-chain ];then
            error_message "git clone thanos-chain failed!"
        fi
        cd thanos-chain
        git checkout dev
        mvn clean install -Dmaven.test.skip=true
        cp target/thanos-chain.jar $jar_local_path
    fi


    echo "clone and build jar finish."
}

function deploy_maven_repository()
{
    local jar_name=$1
    local jar_path=$2
    local properties_path=$3
    local maven_url=$4
    local maven_repoId=$5

    local version=$(crudini --get $properties_path '' "version")
    local groupId=$(crudini --get $properties_path '' "groupId")
    local artifactId=$(crudini --get $properties_path '' "artifactId")
    cd $jar_path

    mvn install:install-file -Dfile=$jar_name -DgroupId=$groupId -DartifactId=$artifactId -Dversion=$version -Dpackaging=jar
    # mvn deploy:deploy-file -DgroupId=$groupId -DartifactId=$artifactId -Dversion=$version -Dpackaging=jar -Dfile=$jar_name  -Durl=$maven_url -DrepositoryId=$maven_repoId
}

function build()
{

    #check if build dir is exist.
    if [ -d $buildPWD ];then
        error_message "build directory already exist, please remove it first."
    fi

    # init
    initial

    mkdir -p ${CHAIN_CERT_DIR}
    cp -r ${DEPENDENCIES_CERT_DIR}/. ${CHAIN_CERT_DIR}

    #build install package for every server
    for((i=0;i<${NODE_COUNT};i++))
    do
    	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
    	    local public_ip=${sub_arr[0]}
            local private_ip=${sub_arr[1]}
            local listen_ip=${sub_arr[2]}
            local node_num_per_host=${sub_arr[3]}
            local agency_info=${sub_arr[4]}

            build_node_installation_package $public_ip $private_ip $listen_ip  $node_num_per_host $agency_info $i
    done
    #create genesis.json
    create_genesis_json ${DEPENDENCIES_TPL_DIR} ${FOLLOW_DIR}
    #create bootstrap.node
    local bootstrap_path=${FOLLOW_DIR}/bootstrap.node
    crudini --set $bootstrap_path '' "chain_peer_discovery_ip_list" ${CHAIN_PEER_DISCOVERY_IP_LIST}
    crudini --set $bootstrap_path '' "gateway_peer_rpc_ip_list" ${GATEWAY_BROADCAST_IPLIST}
    #complete file of each node
    for((i=0;i<${NODE_COUNT};i++))
    do
    	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
    	    local public_ip=${sub_arr[0]}
            local private_ip=${sub_arr[1]}
            local listen_ip=${sub_arr[2]}
            local node_num_per_host=${sub_arr[3]}
            local agency_info=${sub_arr[4]}

            complete_node_install_package $public_ip $private_ip $listen_ip $node_num_per_host $agency_info $i
    done
}


function expand()
{

    #check if build dir is exist.
    if [! -d $buildPWD/follow ];then
        error_message "build/follow directory not exist, please build it first."
    fi

    # init
    initial

    local bootstrap_node_path=${FOLLOW_DIR}/bootstrap.node
    local chain_peer_discovery_ip_list=$(crudini --get $bootstrap_node_path '' "chain_peer_discovery_ip_list")
    local gateway_peer_rpc_ip_list=$(crudini --get $bootstrap_node_path '' "gateway_peer_rpc_ip_list")

    #build install package for every server
    for((i=0;i<${NODE_COUNT};i++))
    do
    	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
    	    local public_ip=${sub_arr[0]}
            local private_ip=${sub_arr[1]}
            local listen_ip=${sub_arr[2]}
            local node_num_per_host=${sub_arr[3]}
            local agency_info=${sub_arr[4]}

            build_node_installation_package $public_ip $private_ip $listen_ip $node_num_per_host $agency_info $i

            export CHAIN_PEER_DISCOVERY_IP_LIST=${chain_peer_discovery_ip_list}
            export GATEWAY_BROADCAST_IPLIST=${gateway_peer_rpc_ip_list}

            complete_node_install_package $public_ip $private_ip $listen_ip $node_num_per_host $agency_info $i
    done
}

#create install package for every node of the server
function build_node_installation_package()
{
    local public_ip=$1
    local private_ip=$2
    local listen_ip=$3
    local node_num_per_host=$4
    local agency_info=$5
    local node_index=$6
    echo "Building package => p2p_ip=$public_ip , private_id=$private_ip listen_ip=$listen_ip ,node_num=$node_num_per_host ,agent=$agency_info"

    public_ip_underline=$(replace_dot_with_underline $public_ip)

    node_dir_name=$(get_node_dir_name $public_ip_underline $agency_info)
    current_node_path=$buildPWD/$node_dir_name
    if [ -d $current_node_path ]
    then
        echo "$current_node_path is already exist, it means the installation package for ip($public_ip) have already build. "
        return 0
    fi

    mkdir -p $current_node_path/
    #for each node on the server, make ca and config
    local entity_index=0
    while [ $entity_index -lt $node_num_per_host ]
    do
        local current_entity_name=$node_dir_name"_node"$entity_index
        local current_entity_dir=$current_node_path/node$entity_index
        mkdir -p $current_entity_dir/
         #create cert info to $node_dir/tls/
        local current_entity_cert_path=$current_entity_dir/tls
        mkdir -p $current_entity_cert_path
        create_node_cert $agency_info $current_entity_name $CHAIN_CERT_DIR $current_entity_cert_path
        #create key pair to $node_dir/database/nodeInfo.properties
        local current_entity_database=$current_entity_dir/database
        mkdir -p $current_entity_database
        local nodeinfo_path=$current_entity_database/nodeInfo.properties

        create_node_key ${SECURE_KEY_TYPE} ${SHARDING_NUMBER} ${CIPHER_KEY_TYPE} $installPWD $nodeinfo_path

        # complete nodeinfo.properties
        local node_cert_serial=$(cat $current_entity_cert_path/node.serial)
        local current_entity_privkey=$(crudini --get $nodeinfo_path '' "nodeIdPrivateKey")
        local current_entity_nodeid=$(crudini --get $nodeinfo_path '' "nodeId")
        local current_entity_pubkey=$(crudini --get $nodeinfo_path '' "publicKey")
        local current_entity_encryptkey=$(crudini --get $nodeinfo_path '' "nodeEncryptKey")
        create_node_info $current_entity_name $agency_info  $node_cert_serial $current_entity_privkey $current_entity_encryptkey $current_entity_nodeid $current_entity_pubkey ${DEPENDENCIES_TPL_DIR} ${nodeinfo_path}

        #chain_validator
        local is_last=0
        if [ $node_index -eq $((${NODE_COUNT}-1)) ] && [ $entity_index -eq $((${node_num_per_host}-1)) ]
        then
            is_last=1
        fi
        local current_validator_info=$(get_validator_info $current_entity_pubkey ${SHARDING_NUMBER} $current_entity_name $agency_info $node_cert_serial $is_last);
        export CHAIN_VALIDATORS_TPL=${CHAIN_VALIDATORS_TPL}${current_validator_info}

        #create thanos-chain.conf and thanos-gateway.conf
        create_node_config $public_ip $private_ip $listen_ip $entity_index ${DEPENDENCIES_TPL_DIR} ${current_entity_dir} $is_last

        #complete nodeAction.ini for registerNode
        local nodeAction_ini_path=$current_entity_dir/nodeAction.ini
        crudini --set $nodeAction_ini_path '' "publicKey" ${current_entity_pubkey}
        crudini --set $nodeAction_ini_path '' "name" ${current_entity_name}
        crudini --set $nodeAction_ini_path '' "agency" ${agency_info}
        crudini --set $nodeAction_ini_path '' "caHash" ${node_cert_serial}
        crudini --set $nodeAction_ini_path '' "privateKey" ${current_entity_privkey}

        entity_index=$(($entity_index+1))

    done
}

function create_genesis_json(){
    local src=$1
    local dst=$2

    MYVARS='${CHAIN_VALIDATORS_TPL}'
    envsubst $MYVARS < $src/genesis.json.tpl > $dst/genesis.json

}

function complete_node_install_package()
{
    local public_ip=$1
    local private_ip=$2
    local listen_ip=$3
    local node_num_per_host=$4
    local agency_info=$5
    local node_index=$6

    public_ip_underline=$(replace_dot_with_underline $public_ip)

    node_dir_name=$(get_node_dir_name $public_ip_underline $agency_info)
    current_node_path=$buildPWD/$node_dir_name
    if [ ! -d $current_node_path ]
    then
        error_message "complete_node_install_package failed. $current_node_path not exist, maybe build failed."
    fi

    #for each node on the server, complete package
    local entity_index=0
    while [ $entity_index -lt $node_num_per_host ]
    do
        local current_entity_dir=$current_node_path/node$entity_index


        local is_last=0
        if [ $node_index -eq $((${NODE_COUNT}-1)) ] && [ $entity_index -eq $((${node_num_per_host}-1)) ]
        then
            is_last=1
        fi
        #complete thanos-chain.conf/thanos-gateway-conf
        complete_node_conf ${current_entity_dir}
        #clear temp file
        rm -rf ${current_entity_dir}/tmp*

        entity_index=$(($entity_index+1))
    done

    #add common file to each node,such as logback.xml, jar package etc
    complete_node_dependencies ${current_node_path}

    #create tar package
    cd $buildPWD
    tar_tool $node_dir_name
    echo "Build package complete. => p2p_ip=$public_ip, private_ip=$private_ip, listen_ip=$listen_ip ,node_num=$node_num_per_host ,agent=$agency_info"
}

#create cert for node of the server
function create_node_cert()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "Create ca, agency=$agency, node=$node, src=$src, dst=$dst"

    cd $src

    bash ca.sh 1>/dev/null #ca for chain
    if [ ! -f "ca.key" ]; then
        error_message "ca.key is not exist, maybe \" bash chain.sh \" failed."
    elif [ ! -f "ca.crt" ]; then
        error_message "ca.crt is not exist, maybe \" bash chain.sh \" failed."
    fi

    bash agency.sh $agency 1>/dev/null #ca for agent
    if [ ! -d $agency ]; then
        error_message "$agency dir is not exist, maybe \" bash agency.sh $agency\" failed."
    fi

    bash node.sh $agency $node 1>/dev/null #ca for node
    if [ ! -d $agency/$node ]; then
        error_message "$agency/$node dir is not exist, maybe \" bash node.sh $agency $node \" failed."
    fi

    mkdir -p $dst
    mv $agency/$node/* $dst

    return 0
}

function create_node_key()
{
    secure_key_alg=$1
    shardingNum=$2
    cipher_key_alg=$3
    src=$4
    dst=$5
    echo "Create node keypair, algorithm=$secure_key_alg, shardingNum=$shardingNum, src=$src, dst=$dst"
    java -jar $src/thanos-common.jar $secure_key_alg $shardingNum 1>>$dst
    java -jar $src/thanos-common.jar $cipher_key_alg 1>>$dst
}

function create_node_info(){

    export CHAIN_NODE_NAME_TPL=$1
    export CHAIN_NODE_AGENCY_TPL=$2
    export CHAIN_NODE_CAHASH_TPL=$3
    export CHAIN_NODE_PRIVKEY_TPL=$4
    export CHAIN_NODE_ENCRYPT_KEY_TPL=$5
    export CHAIN_NODE_ID_TPL=$6
    export CHAIN_NODE_PUBKEY_TPL=$7
    local src=$8
    local dst=$9
    export SECURE_KEY_TPL=${SECURE_KEY_TYPE}
    export CIPHER_KEY_TPL=${CIPHER_KEY_TYPE}

    MYVARS='${CHAIN_NODE_NAME_TPL}:${CHAIN_NODE_AGENCY_TPL}:${CHAIN_NODE_CAHASH_TPL}:${CHAIN_NODE_PRIVKEY_TPL}:${CHAIN_NODE_ENCRYPT_KEY_TPL}:${CHAIN_NODE_ID_TPL}:${CHAIN_NODE_PUBKEY_TPL}:${SECURE_KEY_TPL}:${CIPHER_KEY_TPL}'
    envsubst $MYVARS < $src/nodeInfo.properties.tpl > $dst

}
function create_node_config()
{
    local public_ip=$1
    local private_ip=$2
    local listen_ip=$3
    local entity_index=$4
    local src=$5
    local dst=$6
    local is_last=$7

    #=====create thanos-chain.conf=====
    chain_peer_discovery_port=$((${CHAIN_PEER_DISCOVERY_PORT}+$entity_index))
    chain_peer_rpc_port=$((${CHAIN_PEER_RPC_PORT}+$entity_index))
    chain_listen_gateway_port=$((${CHAIN_LISTEN_GATEWAY_PORT}+$entity_index))
    gateway_listen_chain_port=$((${GATEWAY_LISTEN_CHAIN_PORT}+$entity_index))

    export CHAIN_PEER_RPC_IP_TPL=$private_ip
    export CHAIN_PEER_BIND_IP_TPL=$listen_ip

    export CIPHER_KEY_TPL=${CIPHER_KEY_TYPE}

    export CHAIN_PEER_LISTEN_DISCOVERY_PORT_TPL=$chain_peer_discovery_port
    export CHAIN_PEER_LISTEN_RPC_PORT_TPL=$chain_peer_rpc_port
    export CHAIN_LISTEN_GATEWAY_PORT_TPL=$chain_listen_gateway_port
    gateway_listen_chain_ipport="\""$public_ip":"$gateway_listen_chain_port"\""
    export GATEWAY_LISTEN_CHAIN_IPPORT_TPL=$gateway_listen_chain_ipport
    MYVARS='${CHAIN_PEER_RPC_IP_TPL}:${CHAIN_PEER_BIND_IP_TPL}:${CHAIN_PEER_LISTEN_DISCOVERY_PORT_TPL}:${CHAIN_PEER_LISTEN_RPC_PORT_TPL}:${CHAIN_LISTEN_GATEWAY_PORT_TPL}:${GATEWAY_LISTEN_CHAIN_IPPORT_TPL}:${CIPHER_KEY_TPL}'
    envsubst $MYVARS < $src/thanos-chain.conf.tpl > $dst/tmp.thanos-chain.conf

    #=====create thanos-gateway.conf======
    #node.myself
    uuid=$(get_randomid)
    gateway_peer_rpc_ipport="\""$uuid":"$public_ip":"$((${GATEWAY_PEER_RPC_PORT}+$entity_index))"\""
    export GATEWAY_PEER_RPC_IPPORT_TPL=$gateway_peer_rpc_ipport
    #rpc.address
    gateway_web3_rpc_address="\""$private_ip":"$((${GATEWAY_WEB3_RPC_PORT}+$entity_index))"\""
    export GATEWAY_WEB3_RPC_ADDRESS_TPL=$gateway_web3_rpc_address
    #http.port
    gateway_web3_http_port=$((${GATEWAY_WEB3_HTTP_PORT}+$entity_index))
    export GATEWAY_WEB3_HTTP_PORT_TPL=$gateway_web3_http_port
    #push.address
    chain_listen_gateway_ipport=$public_ip:$chain_listen_gateway_port
    export CHAIN_LISTEN_GATEWAY_IPPORT_TPL="\""$chain_listen_gateway_ipport"\""
    #sync.address
    export GATEWAY_LISTEN_CHAIN_PORT_TPL=$gateway_listen_chain_port
    #database.needTls
    export NEED_TLS_TPL=${GATEWAY_NEED_TLS}
    MYVARS='${GATEWAY_PEER_RPC_IPPORT_TPL}:${GATEWAY_WEB3_RPC_ADDRESS_TPL}:${GATEWAY_WEB3_HTTP_PORT_TPL}:${CHAIN_LISTEN_GATEWAY_IPPORT_TPL}:${GATEWAY_LISTEN_CHAIN_PORT_TPL}:${NEED_TLS_TPL}'
    envsubst $MYVARS < $src/thanos-gateway.conf.tpl > $dst/tmp.thanos-gateway.conf

    #export CHAIN_PEER_DISCOVERY_IP_LIST and GATEWAY_BROADCAST_IPLIST
     local prefix=""
     local postfix=","
    if [ $is_last -eq 1 ]
    then
        postfix=""
        prefix=","
        #entity is the only one?
        if  [ ${NODE_COUNT} -eq 1 ] && [ $entity_index -eq 0 ]
        then
            prefix=""
        fi
    fi

    chain_peer_discovery_ipport="\""$public_ip":"$chain_peer_discovery_port"\""
    export CHAIN_PEER_DISCOVERY_IP_LIST=${CHAIN_PEER_DISCOVERY_IP_LIST}${chain_peer_discovery_ipport}$postfix
    export GATEWAY_BROADCAST_IPLIST=${GATEWAY_BROADCAST_IPLIST}${gateway_peer_rpc_ipport}$postfix

    #tmp store chain and gateway rpc_ipport str, for create ip.list exception self.
    local tmp_ini_path=$dst/tmp.ini
    crudini --set $tmp_ini_path '' "chain_peer_discovery_ipport" ${prefix}${chain_peer_discovery_ipport}${postfix}
    crudini --set $tmp_ini_path '' "gateway_peer_rpc_ipport" ${prefix}${gateway_peer_rpc_ipport}${postfix}

    #create nodeAction.ini
    export GATEWAY_WEB3_RPC_IPPORT_TPL=$public_ip":"$((${GATEWAY_WEB3_RPC_PORT}+$entity_index))
    MYVARS='${GATEWAY_WEB3_RPC_IPPORT_TPL}:${NEED_TLS_TPL}'
    envsubst $MYVARS < $src/nodeAction.ini.tpl > $dst/nodeAction.ini

}

function get_validator_info()
{
    local pubkey=$1
    local sharding_number=$2
    local name=$3
    local agency=$4
    local ca_hash=$5
    local is_last=$6
    if [ $is_last -eq 1 ]
    then
        delim_str=""
    else
        delim_str=","
    fi
    echo "\"$pubkey\": {
      \"consensusVotingPower\": 1,
      \"shardingNum\": $sharding_number,
      \"name\": \"$name\",
      \"agency\": \"$agency\",
      \"caHash\": \"$ca_hash\"
      }"$delim_str"
      "
}

function get_node_dir_name()
{
    local public_ip_underline=$1
    local agency=$2


    node_dir_name_local=${public_ip_underline}"_$agency"

    echo $node_dir_name_local
}

function complete_node_conf()
{
    local src=$1

    local tmp_ini_path=$src/tmp.ini
    #complete thanos-chain.conf
    local chain_peer_discovery_ipport=$(crudini --get $tmp_ini_path '' "chain_peer_discovery_ipport")
    local chain_peer_discovery_ip_list=$(echo ${CHAIN_PEER_DISCOVERY_IP_LIST} |sed 's/'$chain_peer_discovery_ipport'//g')
    export CHAIN_PEER_DISCOVERY_IP_LIST_TPL=$chain_peer_discovery_ip_list
    MYVARS='${CHAIN_PEER_DISCOVERY_IP_LIST_TPL}'
    envsubst $MYVARS < $src/tmp.thanos-chain.conf > $src/thanos-chain.conf

    #complete thanos-gateway.conf
    local gateway_peer_rpc_ipport=$(crudini --get $tmp_ini_path '' "gateway_peer_rpc_ipport")
    local gateway_peer_rpc_ip_list=$(echo ${GATEWAY_BROADCAST_IPLIST} |sed 's/'$gateway_peer_rpc_ipport'//g')
    export GATEWAY_BROADCAST_IPLIST_TPL=$gateway_peer_rpc_ip_list
    MYVARS='${GATEWAY_BROADCAST_IPLIST_TPL}'
    envsubst $MYVARS < $src/tmp.thanos-gateway.conf > $src/thanos-gateway.conf
}

function complete_node_dependencies()
{
    current_node_path=$1
    local node_dependencies_dir=$current_node_path/dependencies
    local node_depend_common_dir=$node_dependencies_dir/common
    mkdir -p $node_depend_common_dir
    #copy common
    cp ${FOLLOW_DIR}/genesis.json ${node_depend_common_dir}

    cp ${THANOS_JAR_LOCAL_PATH}/thanos-chain.jar ${node_depend_common_dir}
    cp ${THANOS_JAR_LOCAL_PATH}/thanos-gateway.jar ${node_depend_common_dir}
    cp ${THANOS_JAR_LOCAL_PATH}/thanos-common.jar ${node_depend_common_dir}

    cp ${DEPENDENCIES_JAR_DIR}/thanos-web3j-sdk.jar ${node_depend_common_dir}
    cp ${DEPENDENCIES_JAR_DIR}/bcprov-jdk15on-1.66.jar ${node_depend_common_dir}

    cp ${DEPENDENCIES_COMMON_DIR}/* ${node_depend_common_dir}

    cp ${DEPENDENCIES_DIR}/install_node.sh ${current_node_path}
    #copy scripts
    cp -r $scriptPWD $node_dependencies_dir
}


case "$1" in
    'build')
        build
        ;;
    'expand')
        expand
        ;;
    'version')
        version
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {build|expand|version}"
        #exit 1
esac

