// SPDX-License-Identifier: GPL-3.0 
// 源码遵循协议， MIT...
pragma solidity >=0.4.16 <0.9.0; //限定solidity编译器版本

contract StudentListStorage{
    //结构体
    struct Student {
        uint id;
        string name;
        uint age;
        address account;
    }
    //动态数组
    Student[] public StudentList; //自动getter()

    // struct ,动态数组， 映射， string
    function addList(string memory _name,uint _age) public returns (uint){
        uint count = StudentList.length;
        uint index = count+1;
        StudentList.push(Student(index,_name,_age,msg.sender));
        return StudentList.length;
    }

   
    // view(视图函数，只访问不修改 状态) , pure （纯函数， 不访问，也不修改）
    function getList() public view returns (Student[] memory) {
       Student[] memory list = StudentList;
       return list;
    }
}