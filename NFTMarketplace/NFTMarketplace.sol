// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//为了执行transfer函数并转移NFT，我们需要与NFT合约进行交互
import "./NFT.sol";

// 定义一个NFT交易市场合约
contract NFTMarketplace {

// 以定义一个名为Order的结构体来表示NFT商品信息。
// tokenId（NFT的TokenId）、seller（售卖者）、price（价格）
    struct Order {
        uint256 tokenId;
        address seller;
        uint256 price;
    }
// 该结构体存储的是已上架的商品信息，而我们希望能够通过tokenId来检索到其对应的NFT商品信息。
    mapping(uint256 => Order) public tokenOrders;

    //定义为一个变量，以便在后续的功能中能够与NFT合约进行交互。
    NFT nftContract;
    //通过触发一个事件，我们可以告知所有人某个商品何时上架，以及它的价格是多少。这样做可以显著提升用户体验，让大家更清楚地了解市场上的商品情况。
    // 1.NFT的tokenId
    // 2.该NFT的售卖者是谁
    // 3.该NFT的售卖价格
    event NewOrder(uint256 indexed tokenId, address indexed seller, uint256 price);
    //定义一个购买事件OrderBought该事件应该记录发生购买的NFT的TokenId，购买者以及成交价格。
    event OrderBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
	event OrderCanceled(uint256 indexed tokenId);
    
    //定义一个新的 NFT 合约实例时，并不知道 NFT 的地址。所以在这个时候需要一个构造函数来给这个实例赋值。
    constructor(address _nftContractAddress) {
        nftContract = NFT(_nftContractAddress);
    }

    //通过传入的TokenId去查询商品信息
    function getOrder(uint256 _tokenId) public view returns (uint256 tokenId, address seller, uint256 price) {
        //通过入参给出的_tokenId在tokenOrders映射中查询到Order信息，并将其存储在memory中。
        Order memory order = tokenOrders[_tokenId];
        return (order.tokenId, order.seller, order.price);
    }

// 这个函数需要完成的是将用户指定的NFT以其想要售卖的价格，上架到交易市场的“货架”上。
// 一是TokenId，二是价格。其中TokenId是为了我们能够找到售卖者要出售的NFT是哪一个，价格是为了在上架时给该NFT定价。
    function listNFT(uint256 _tokenId, uint256 _price) public {
        //判断调用者是否是NFT的持有者，才可以将此NFT上架。
        require(msg.sender == nftContract.ownerOf(_tokenId));
        //交易市场不允许价格为0的商品出现
        require(_price > 0);
        
        //我们的交易市场相当于是一个“代售”的功能，所以第一步我们需要先将用户的NFT“回收”，使NFT的主人变为交易市场。
        //transferFrom:指定转账者是谁,允许第三方将NFT从A地址转移到B地址.
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        //在完成了NFT的“回收”后，我们就可以把它放到我们的“货架”上了。
        tokenOrders[_tokenId] = Order(_tokenId, msg.sender, _price);

        //只有提交了事件，别人才会知道该NFT已经在市场上架了。
        emit NewOrder(_tokenId, msg.sender, _price);
    }

    //购买指定的NFT，所以我们需要一个入参来表示TokenId。
    function buyNFT(uint256 _tokenId) external payable {
        //根据入参_tokenId在“货架上”查询到指定的商品信息
        Order memory order = tokenOrders[_tokenId];
        //通过msg.value语句获取购买者在调用该函数时发送的金额，然后将这个值和商品的售卖价格进行比较即可
        require(msg.value == order.price, "Incorrect price");
        //1.将NFT发送给购买者
        //直接使用NFT合约的transfer函数就可以实现这一点，因为该NFT目前是属于交易市场合约的，所以我们没有必要使用transferFrom来进行转账。
        nftContract.transfer(msg.sender, _tokenId);
        //2.把购买者支付的钱，打给出售者
        //因为购买者通过调用buyNFT函数传入的ETH其实是发送给交易市场合约的。
        payable(order.seller).transfer(msg.value);
        //3.把NFT从“货架上”删除。
        delete tokenOrders[_tokenId];
        emit OrderBought(_tokenId, msg.sender, msg.value);
    }
    
    //用于下架某个NFT。
    function cancelOrder(uint256 _tokenId) public {
        //首先我们需要获得这个售卖者的信息，售卖者的信息是保存在商品信息Order中的，所以我们要先从tokenOrders映射中获取到入参_tokenId对应的商品信息。
        Order memory order = tokenOrders[_tokenId];
        //那么现在就可以开始进行权限控制了，我们需要调用者地址必须是order对应的出售者地址。
        require(msg.sender == order.seller, "You are not the seller");
        //首先需要将 NFT 退还给出售者，所以我们调用 NFT 合约的 transfer 方法，将该 _tokenId 对应的 NFT 转给出售者
        nftContract.transfer(order.seller, _tokenId);
        //还需要把该NFT从“货架上”删除，也就是在tokenOrders中把该NFT的TokenId信息删除。
        delete tokenOrders[_tokenId];			
        emit OrderCanceled(_tokenId);
    }

}