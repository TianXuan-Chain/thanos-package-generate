#!/usr/bin/env bash

#nohup java  -Xmx2g -Xms2g -Xmn1536M -Xss4M -XX:SurvivorRatio=8  -jar thanos-gateway.jar >/dev/null &
nohup java  -Xmx1g -Xms1g -Xmn750M -Xss4M -XX:SurvivorRatio=8  -jar thanos-gateway.jar >/dev/null &
