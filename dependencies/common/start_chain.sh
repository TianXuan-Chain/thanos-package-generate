#!/usr/bin/env bash

#nohup java  -Xmx5g -Xms5g -Xmn2g -Xss4M -jar thanos-chain.jar >/dev/null &
nohup java  -Xmx1g -Xms1g -Xmn750m -Xss4M -jar thanos-chain.jar >/dev/null &
