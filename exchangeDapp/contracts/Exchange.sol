// SPDX-License-Identifier: GPL-3.0
// 源码遵循协议， MIT...
pragma solidity >=0.4.16 <0.9.0; //限定solidity编译器版本
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./KerwinToken.sol";

contract Exchange {
    using SafeMath for uint256; //为了uint256后面使用 sub ,add方法，，

    //收费账户地址
    address public feeAccount;
    uint256 public feePercent; //费率
    address constant ETHER = address(0);
    mapping(address => mapping(address => uint256)) public tokens;

    //订单结构体
    struct _Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;

        address tokenGive;
        uint256 amountGive;

        uint256 timestamp;
    }

    // _Order[] orderlist ;

    mapping(uint256=>_Order) public orders;

    mapping(uint256=>bool) public orderCancel;
    mapping(uint256=>bool) public orderFill;
    uint256 public orderCount;

  
    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event WithDraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );
    //创建订单事件
    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    //取消订单事件
    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    //填充订单事件
    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    //存以太币
    function depositEther() public payable {
        //msg.sender
        //msg.value
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    //存其他货币
    function depositToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        //调用某个方法强行从你账户往当前交易所账户转钱
        require(
            KerwinToken(_token).transferFrom(msg.sender, address(this), _amount)
        );
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);

        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    //提取以太币
    function withdrawEther(uint256 _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        //payable
        payable(msg.sender).transfer(_amount);
        emit WithDraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    //提取KWT
    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        require(tokens[_token][msg.sender] >= _amount);

        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);

        //
        require(KerwinToken(_token).transfer(msg.sender, _amount));

        emit WithDraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    //查余额
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }

    //makeOrder
    function makeOrder(address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive) public{

        require(balanceOf(_tokenGive,msg.sender)>=_amountGive,unicode"创建订单时余额不足");

        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount,msg.sender,_tokenGet,_amountGet,_tokenGive,_amountGive,block.timestamp);

        //发出订单

        emit Order(orderCount,msg.sender,_tokenGet,_amountGet,_tokenGive,_amountGive,block.timestamp);
    }
    //cancelOrder
    function cancelOrder(uint256 _id) public {
        _Order memory myorder = orders[_id];
        require(myorder.id == _id);
        orderCancel[_id] = true;

        emit Cancel(myorder.id,msg.sender,myorder.tokenGet,myorder.amountGet,myorder.tokenGive,myorder.amountGive,block.timestamp);
    }
    //fillOrder

    function fillOrder(uint256 _id) public {
        _Order memory myorder = orders[_id];
        require(myorder.id == _id);
        

        //账户余额 户换 && 小费收取
        /*
            xiaoming , makeorder,

            100 KWT  ==> 1ether

            xiaoming , 少了1ether
            xiaoming 多了100KWT

            msg.sender , fillOrder

            msg.sender, 多了1ether
            msg.sender ,少了100KWT
        */
        uint256 feeAmout = myorder.amountGet.mul(feePercent).div(100);

        require(balanceOf(myorder.tokenGive,myorder.user)>=myorder.amountGive,unicode"创建订单的用户的余额不足");

        require(balanceOf(myorder.tokenGet,msg.sender)>=myorder.amountGet.add(feeAmout),unicode"填充订单的用户的余额不足");


        tokens[myorder.tokenGet][msg.sender] = tokens[myorder.tokenGet][msg.sender].sub(myorder.amountGet.add(feeAmout));

        tokens[myorder.tokenGet][feeAccount] = tokens[myorder.tokenGet][feeAccount].add(feeAmout);

        tokens[myorder.tokenGet][myorder.user] = tokens[myorder.tokenGet][myorder.user].add(myorder.amountGet);

        tokens[myorder.tokenGive][msg.sender] = tokens[myorder.tokenGive][msg.sender].add(myorder.amountGive);
        tokens[myorder.tokenGive][myorder.user] = tokens[myorder.tokenGive][myorder.user].sub(myorder.amountGive);

        orderFill[_id] = true;
        emit Trade(myorder.id,myorder.user,myorder.tokenGet,myorder.amountGet,myorder.tokenGive,myorder.amountGive,block.timestamp);
    }
}
