network {
    peer.rpc.ip = ${CHAIN_PEER_RPC_IP_TPL}
    peer.bind.ip = ${CHAIN_PEER_BIND_IP_TPL}
    peer.listen.discoveryPort = ${CHAIN_PEER_LISTEN_DISCOVERY_PORT_TPL}
    peer.listen.rpcPort = ${CHAIN_PEER_LISTEN_RPC_PORT_TPL}
    peer.channel.read.timeout = 60
    peer.discovery = {
        # List of the seed peers to start
        # the search for online peers
        ip.list = [
            ${CHAIN_PEER_DISCOVERY_IP_LIST_TPL}
        ]
    }
    // need consistency pattern of each node
    transferDataEncrypt = 1

    // default false
    epollSupport = false

    nettyPoolByteBuf = false

    gateway {
        localListenAddress = ${CHAIN_LISTEN_GATEWAY_PORT_TPL}
        remoteServiceAddress = ${GATEWAY_LISTEN_CHAIN_IPPORT_TPL}
        pushTxsQueueSize = 6
    }
}

consensus {
    // 1 = MultipleOrderedProposers;
    // 2 = RotatingProposer;
    proposerType = 2
    contiguousRounds = 1
    maxPackSize = 50000
    maxCommitEventNumInMemory = 100
    maxPrunedEventsInMemory = 4
    //    reimportUnCommitEvent = true
    poolLimit = 3000
    roundTimeoutBaseMS = 5000
    parallelProcessorNum = 8
}

state {
    checkTimeoutMS = 1500
    maxCommitBlockInMemory = 5
}

resource {
    database {
        needEncrypt = false
        encryptAlg = ${CIPHER_KEY_TPL}
        # place to save physical livenessStorage files
        # must use absolute path
        dir = ${DATABASE_DIR_TPL}
    }
    logConfigPath = ${LOG_CONFIG_PATH_TPL}
}

vm.structured {
    trace = false
    dir = vmtrace
    initStorageLimit = 10000
}

#tls settings, such as path of keystore,truststore,etc
tls {
    keyPath= ${KEY_PATH_TPL}
    certsPath= ${CERTS_PATH_TPL}
}

