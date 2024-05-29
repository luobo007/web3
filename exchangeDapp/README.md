1.全局安装
npm i truffle -g

2.初始化
truffle init

3.配置truffle-config.js ，连接本地启动的ganache，并配置metamask网络创建账户
 development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 7545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
    },
  "contracts_build_directory":"./src/build"	
	
4.下载 openzeppelin-solidity 库
npm i openzeppelin-solidity

5.truffle compile 编译

6.truffle migrate --reset 部署

7.npm  start 启动react

8.安装 npm i --save web3@1.8.0

9.安装组件 npm i antd --save

9.安装组件 npm i --save moment

10.连接ganache 对应的 metaMask 对应的账号

11. 生成订单 truffle exec .\scripts\test-order.js