// SPDX-License-Identifier: GPL-3.0
// 源码遵循协议， MIT...
pragma solidity >=0.4.16 <0.9.0; //限定solidity编译器版本
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol"; 
contract KerwinToken {  
    using SafeMath for uint256; //为了uint256后面使用 sub ,add方法，，

    string public name = "KerwinToken";
    string public symbol = "KWT";

    uint256 public decimals = 18; //1kerwintokn  = 10**decimals
    uint256 public totalSupply;
    //自动生成getter方法 

    // mapping
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address=>uint256)) public allowance;
    
    constructor(){
        totalSupply = 1000000 * (10 ** decimals);
        //部署账号
        balanceOf[msg.sender] = totalSupply;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to!=address(0));
        _tranfer(msg.sender, _to, _value);
        return true;
    }

    function _tranfer(address _from,address _to, uint256 _value) internal {
        require(balanceOf[_from]>=_value);
        //从哪个账号发起的调用者
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        //触发事件

        emit Transfer(_from,_to,_value);
    }


    function approve(address _spender, uint256 _value) public returns (bool success){
        //msg.sender  当前网页登录得账号
        //_spender 第三方得交易所得账号地址
        // _value授权得钱数
        require(_spender!=address(0));
        
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
        /*
            {
                "kerwin":{
                    A:100,
                    B:200
                },
                "xiaoming":{
                    A:200,
                    B:100
                }
            }
        
        */
    }

    //被授权得交易所调用
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //_from 某个放款账号
        //_to   收款账户
        //msg.sender 交易所账户地址
        require(balanceOf[_from]>=_value);
        require(allowance[_from][msg.sender]>=_value);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _tranfer(_from, _to, _value);
        return true;
    }



}
