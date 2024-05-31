web3项目
/**
项目介绍：Solidity 语言来构建一个在 Linea 上实现 NFT 荷兰拍



1.在c盘安装Foundry
打开 git bash窗口输入：curl -L https://foundry.paradigm.xyz | bash

2.执行安装命令：
Foundryup

3.回到项目目录初始化新项目：
forge init linea-project --no-commit

4.使用 Infura 节点部署

https://app.infura.io/
使用 .env 存储私钥：
在根目录下，新建 .env 文件：
PRIVATE_KEY=a8da66292d175475798537c0138ce3ff27106c2e524ac6edaf79b5e6ae0aa90c
INFURA_API_KEY=052b0218c9c44d429e9aa614fe4d84d2
在git bash运行命令：source .env

在foundry.toml 文件，添加以下信息：
[rpc_endpoints]
linea-testnet = "https://linea-sepolia.infura.io/v3/${INFURA_API_KEY}"
linea-mainnet = "https://linea-mainnet.infura.io/v3/${INFURA_API_KEY}"

D:\github\web3\linea-project\src\DutchAuction.sol