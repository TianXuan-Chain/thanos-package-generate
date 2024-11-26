**天玄一键部署脚本，详细教程见：[快速搭建天玄链](https://tianxuan.blockchain.163.com/quick-start/depoly-tianxaun-chain/)**
# 使用
## 要求
运行 “节点安装包构建” 脚本需要
- Oracle JDK[1.8]
- Maven[3.3.9]
- Git
- Crudini
运行 “节点安装与启动” 脚本需要
- Oracle JDK[1.8]
- Crudini

## 配置
在 chain-nodes 部分，配置天玄链的起始节点信息 (一台服务器上可以运行多个节点 eg. 可以在一台服务器上部署具备三个节点的天玄链)
```
[chain-nodes]
# 格式为 : nodeIDX=p2p_ip listen_ip num agent
# IDX为索引, 从0开始增加.
# p2p_ip     => 服务器上用于p2p通信的网段的ip.
# listen_ip  => 服务器上的监听端口, 用来接收rpc、channel的链接请求, 建议默认值为"0.0.0.0".
# num        => 在服务器上需要启动的节点的数目.
# agent      => 机构名称, 若是不关心机构信息, 值可以随意, 但是不可以为空.
node0=101.35.234.160  0.0.0.0  2  agency
node1=43.130.226.84  0.0.0.0  1  agency1
```
注意查看 chain-ports 和 gateway-ports 部分，并在服务器上打开相应端口

## 生成节点安装包
运行脚本生成节点安装包
```
bash build_chain.sh build
```
执行成功后会在当前目录下生成build目录
```
$tree -L 1 build
build
├── 101.35.234.160_agency.tar.gz
├── 43.130.226.84_agency.tar.gz
└── follow
```
其中，101.35.234.160_agency.tar.gz 和 43.130.226.84_agency.tar.gz 即为节点的安装包。

## 运行节点
在对应服务器上解压后，进入node/thanos-chain 目录，启动节点
```
# 以node0为例
$cd node0/thanos-chain
$bash start_chain.sh
```
启动网关
```
# 以node0为例
$cd node0/thanos-chain
$bash start_gateway.sh
```
启动后，相应日志可以在 log 目录下查看
