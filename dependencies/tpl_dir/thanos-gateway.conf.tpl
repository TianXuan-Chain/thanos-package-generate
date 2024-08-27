gateway {
    #本机节点信息，用于与其他gateway节点互连
    node.myself = ${GATEWAY_PEER_RPC_IPPORT_TPL}

    rpc {
        #本机rpc服务ip和端口，用于向sdk提供rpc服务。
        address = ${GATEWAY_WEB3_RPC_ADDRESS_TPL}
        acceptCount = 300
        maxThreads = 400
        readWriteTimeout = 60000
    }

    http {
        #本机rpc服务ip和端口，用于向sdk提供rpc服务。
        port = ${GATEWAY_WEB3_HTTP_PORT_TPL}
        acceptCount = 300
        maxThreads = 400
        readWriteTimeout = 12000
    }

    #广播节点列表
    broadcast = [${GATEWAY_BROADCAST_IPLIST_TPL}]
    push {
        #推送地址
        address = ${CHAIN_LISTEN_GATEWAY_IPPORT_TPL}
    }
    sync {
        #同步出块地址
        address = ${GATEWAY_LISTEN_CHAIN_PORT_TPL}

        cache {
            blockLimit = 10
            txPoolDSCacheSizeLimit = 2000
        }
    }
    switch {
        #是否仅广播全局节点事件
        only.broadcast.globalEvent = 0
    }
    log {
        logConfigPath = ${LOG_CONFIG_PATH_TPL}
    }
}

#tls settings, such as path of key and certs, etc
tls {
    needTLS = ${NEED_TLS_TPL}
    keyPath= ${KEY_PATH_TPL}
    certsPath= ${CERTS_PATH_TPL}
}
