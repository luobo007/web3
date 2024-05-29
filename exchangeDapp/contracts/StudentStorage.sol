// SPDX-License-Identifier: GPL-3.0 
// 源码遵循协议， MIT...
pragma solidity >=0.4.16 <0.9.0; //限定solidity编译器版本

contract StudentStorage{

    //创建 两个变量 username ,age
    uint public age;
    string public name;

    // struct ,动态数组， 映射， string
    function setData(string memory _name,uint _age) public{
        // string memory a; //局部变量
        name = _name;
        age = _age;
    }

    // function test(uint x ,uint y) public pure returns (uint){
    //     return x+y;
    // }

    // view(视图函数，只访问不修改 状态) , pure （纯函数， 不访问，也不修改）
    function getData() public view returns (string memory,uint) {
        return (name,age);
    }

}