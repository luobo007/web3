// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
项目介绍：Solidity 语言来构建一个基本的众筹项目，模拟从发起众筹到资金申领或退款的整个过程。
**/

//IERC20 接口规范会为与代币交互提供一套标准的方法，通常可以包括转账、余额查询、授权和转账授权等功能。
interface IERC20 {
    //transfer：方法允许代币的持有者将代币直接发送到另一个地址。
    function transfer(address, uint256) external returns (bool);

    //transferFrom：方法则用于在代币持有者授权后，允许第三方（例如，我们的众筹合约）从持有者账户中转出代币到任意地址。
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

contract MockToken is IERC20 {
    string public constant name = "MockToken";
    string public constant symbol = "MCK";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_ = 1000000 ether;

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        override
        returns (bool)
    {
        require(numTokens <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[owner], "Insufficient balance");
        require(
            numTokens <= allowed[owner][msg.sender],
            "Insufficient allowance"
        );

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        return true;
    }
}

contract CrowdFund {

    //在智能合约中，事件是一种用于合约与区块链外部世界通信的机制。当特定的事件被触发时，它会被记录在区块链上，外部应用程序如前端界面或服务器后台可以监听这些事件，从而做出相应的响应或处理。

    //为了宣布新众筹活动的创建，我们首先需要在合约顶部定义一个事件,这个事件将携带所有关键的活动信息，如新活动的 ID、创建者地址、目标金额、开始和结束时间。
    event Launch(uint256 id,address indexed creator, uint256 goal, uint32 startAt,uint32 endAt);
    // 正如在发起活动时使用 launch 函数触发事件以公开宣布活动的开始一样， cancel 函数的结尾也应该触发一个事件来公开通知活动的取消。
    event Cancel(uint256 id);
    //用于在每次用户成功质押代币时发出通知。这个事件应该包含这些参数，如众筹活动的ID、质押者的地址以及质押的金额。
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    //触发一个专门用于记录取消质押操作的事件
    event UnPledge(uint256 indexed id, address indexed caller, uint256 amount);
    //定义并触发一个专门用于记录项目方已提取筹集资金的事件
    event Claim(uint256 id);
    //定义并触发一个专门用于记录退款操作的事件
    event Refund(uint256 id, address indexed caller, uint256 amount);

    //活动发起众筹
    struct Campaign {
        address creator;//项目发起者：标识谁启动了众筹活动。
        uint256 goal;//目标金额：设定的筹资目标，用以衡量众筹成功与否。
        uint256 pledged;//用户质押数目：记录参与者质押的代币数量。
        uint32 startAt;//活动起始时间：定义众筹活动开始和结束的具体时间点。
        uint32 endAt;//活动结束时间：定义众筹活动开始和结束的具体时间点。
        bool claimed;//资金申领状态：标识项目方是否已经成功申领筹集到的资金。
    }
    //用于接收这个 ERC20 代币的地址
    IERC20 public immutable token;
    //count 来记录已经发起的众筹活动数量。每次创建新的众筹活动时，count 的值增加1，这样 count 既能表示当前活动的总数，也能作为最新活动的唯一标识符。
    uint256 public count;
    //通过活动 ID 快速访问任何一个特定的众筹活动的详细信息。
    mapping(uint256 => Campaign) public campaigns;
    //为了详细记录每位用户对每个众筹活动的质押金额，我们可以定义一个双层映射来存储这些关键信息。这个映射的结构允许我们准确追踪和管理每个用户对不同众筹活动的质押情况。
    //外层映射：以众筹活动的唯一标识符（活动ID）为键，指向另一个映射。这使得我们能够快速访问到与特定众筹活动相关的所有用户质押信息。
    //内层映射：以用户的地址为键，质押金额（以代币数量表示）为值。这层映射存储了每个用户对该活动的具体质押金额，使得合约能够为每位用户和每个活动维护一个独立的质押记录。
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    //个函数允许用户创建新的众筹项目，并将相关信息记录在智能合约中。
    // 众筹的目标金额
    // 活动的开始时间
    // 活动的结束时间
    function launch(
        uint256 _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        //活动开始时间的验证：活动的开始时间必须在当前时间之后，以给予项目方和投资者准备的时间。
        //require(_startAt >= block.timestamp, "start at < now");
        //活动结束时间的验证：活动的结束时间必须大于开始时间，这样才有一个明确的、有序的众筹时间框架。
        require(_endAt >= _startAt, "end at < start at");
        //活动持续时间的验证：为了确保众筹活动有一个合理的时间范围，我们需要验证活动的持续时间不仅符合逻辑，还要满足特定的条件，比如让活动的结束时间不会超过合约调用时刻加上90天的最大持续期限。
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        //它不仅用于统计已经创建的活动总数，还作为每个新活动的唯一标识符。在每次创建新的众筹活动时，我们应该将 count 变量的值增加1，这样可以确保每个活动都有一个独特的 ID，并且能够持续追踪平台上活动的数量。
        count += 1;
        
        //生成新的众筹活动
        campaigns[count] = Campaign({
            creator: msg.sender,//发起者：通过 msg.sender 获取，函数的调用者即为众筹活动发起者的用户地址。
            goal: _goal,
            pledged: 0,//已筹集金额：用户质押的金额初始设置为 0，表示活动开始时还没有筹集到任何资金。
            startAt: _startAt,
            endAt: _endAt,
            claimed: false//资金申领状态：初始设置为 false，表示活动发起者尚未从合约中提取筹集到的资金。
        });
        // 在 launch 函数中，一旦新的众筹活动成功创建，我们就触发对应事件，以公开宣布这一消息。
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
    
    //如果在活动开始前，项目方已经成功集齐资金或因各种因素需要取消活动，那么提供一个取消活动的功能就显得尤为重要。这样的功能不仅为项目方提供了更大的灵活性和控制权，也保护了投资者的利益，确保他们的资金不会被无端占用或冻结。
    //因此，我们可以在合约中设计一个允许项目方在活动开始前取消众筹活动的 cancel 函数。为了精确执行取消操作，首先必须明确识别出待取消的活动。这可以通过提供活动的唯一 ID 来实现，利用这个 ID，我们能够在 campaigns 映射中找到相应的活动结构体。
    function cancel(uint256 _id) external {
        // 在这一步骤中，我们通常使用memory关键字创建一个临时的 Campaign 结构体副本。这种方法不仅有助于节省gas成本，因为与存储（storage）类型的变量相比，memory类型的变量在函数调用期间的生命周期结束后就会被清除，而不会永久占用链上存储空间。
        // 此外，通过在函数内部操作这个临时副本，我们可以避免对全局状态的不必要修改，从而增加合约的执行效率和安全性。
        Campaign memory campaign = campaigns[_id];
       //验证操作者身份,首先，我们需要验证调用 cancel 函数的用户是否为众筹活动的发起者，因为只有活动的发起者才有权取消自己的众筹活动。
        require(campaign.creator == msg.sender, "not creator");
       //验证活动状态,其次，我们需要确保众筹活动尚未开始。这是因为一旦活动开始，可能已经有投资者参与，取消活动将影响到这些投资者的利益。
        require(block.timestamp < campaign.startAt, "started");
       //仅仅是一个副本，存储在内存中，而非存储在区块链的永久存储中。因此，对这个副本所做的任何修改都不会影响到存储在 campaigns 映射中的原始数据。要想真正从合约的存储中移除一个众筹活动的记录，我们可以直接使用 campaigns[_id] 。
        delete campaigns[_id];
        //触发对应事件，以公开宣布这一消息
        emit Cancel(_id);
    }
    //我们继续实现众筹活动的下一重要功能：允许用户参与众筹并向众筹合约质押代币。这一环节是众筹成功的关键，它不仅让项目方有机会达成其资金目标，也为投资者提供了支持心仪项目的途径。
    //活动ID：这是用户希望支持的众筹活动的唯一标识符
    //代币数量：这是用户打算质押的代币数量。
    //访问修饰符：由于不同的用户将通过区块链交易来调用这个函数参与众筹，因此使用 external 修饰符,这表明该函数预期从合约外部被调用，优化了函数的 Gas 消耗，因为external函数能够直接访问调用数据。
    function pledge(uint256 _id, uint256 _amount) external {
        //首先需要获取用户指定要质押代币的众筹活动项目
        //storage变量指向区块链的永久存储，任何对storage变量的修改都会直接反映在链上，并且是永久性的。
        //通过使用 storage，我们对 campaign 的任何修改都会直接影响到 campaigns 映射中存储的原始 Campaign 结构体。这样，当用户执行质押操作时，我们可以直接更新活动的已筹集金额等相关状态，确保数据的一致性和准确性。
        Campaign storage campaign = campaigns[_id];
        
        //验证活动是否已开始：确保当前时间已经超过活动的开始时间，这保证了用户只能在活动开始后进行质押。
        require(block.timestamp >= campaign.startAt, "not started");
        //验证活动是否未结束：同样，我们需要确保当前时间还未到达活动的结束时间，从而保证用户不能在活动结束后进行质押。
        require(block.timestamp <= campaign.endAt, "ended");
        
        //更新活动的已筹集金额：将用户质押的代币数量累加到指定众筹活动的已筹集金额上。
        campaign.pledged += _amount;
        //记录用户的质押金额：更新用户对特定众筹活动的质押总额。这不仅有助于跟踪每个用户对各个活动的质押情况，也为后续的退款或奖励分配提供了必要的数据支持。
        pledgedAmount[_id][msg.sender] += _amount;
        //transferFrom 方法通常用于从一个账户向另一个账户转移代币，且需要事先获得代币持有者的授权。
        
        token.transferFrom(msg.sender,//发送方
         address(this),//接收方
         _amount//转移金额 
          );
        
        //将质押的详细信息广播出去。
        emit Pledge(_id, msg.sender, _amount);
    }
    // 正如项目方可以在活动开始前取消众筹活动一样，用户也应该有机会在活动结束前撤销他们对项目的质押，无论是因为他们改变了主意还是需要回收资金。设计一个 unpledge 函数来让用户取消质押.
    // _id：这个参数指定了用户希望撤销质押的指定的众筹活动。
    // _amount：表示用户希望从质押中撤回的代币数量，允许用户有选择性地撤销部分或全部质押。
    function unpledge(uint256 _id, uint256 _amount) external {
        //获取用户要取消质押的活动
        Campaign storage campaign = campaigns[_id];
        //为了我们需要确保只有在活动尚未结束时，用户才能撤销质押
        require(block.timestamp <= campaign.endAt, "ended");
        
        //更新活动的已筹集金额：我们从指定众筹活动的已筹集金额中减去用户撤销质押的代币数量。
        campaign.pledged -= _amount;
        //更新用户的质押记录：减少用户对该活动的质押总额。
        pledgedAmount[_id][msg.sender] -= _amount;
        //退还代币给用户：将指定数量的代币从众筹合约账户转移回用户账户的操作。这一步骤完成了撤销质押的过程，确保用户能够收回他们之前质押的资金。
        //transfer 方法直接从合约账户向指定的用户账户转移代币，不需要用户的事先授权。在用户撤销质押的情况下，合约已经持有了用户之前质押的代币，因此直接使用 transfer 方法将代币退还给用户更为简单和直接
        token.transfer(msg.sender, _amount);

        emit UnPledge(_id, msg.sender, _amount);
    }
    // 在众筹活动成功结束后，项目方应被允许提取筹集的资金，以便推进项目发展。为此，我们需要提供一个提款函数，使项目方在输入活动 ID 后，只要满足特定条件，能够安全地提取指定众筹活动中筹集的资金。
    function claim(uint256 _id) external {
        //获取指定活动
        Campaign storage campaign = campaigns[_id];
        //活动已结束：首先，我们需要验证众筹活动是否已经结束。
        require(campaign.creator == msg.sender, "not creator");
        //require(block.timestamp >  campaign.endAt, "not ended");
        //筹资目标已达成：其次，需要确认众筹活动是否成功达到或超过了其筹资目标。这通过比较活动的已筹集金额与筹资目标来验证。
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        //资金未被提取：为了防止资金被重复提取，我们还需要确认这些资金尚未被项目方提取。这可以通过检查活动的状态标记 campaign.claimed 来实现。
        require(!campaign.claimed, "claimed");
        //在确认众筹活动已成功结束，并且项目方满足了提取资金的所有条件之后，接下来的步骤是正式将筹集的资金转移给项目方，并更新活动的状态以反映资金已被提取:
        //标记资金已被提取：首先，我们将活动的 claimed 状态设置为 true，这表示筹集的资金已经被项目方成功提取，防止资金被重复提取。
        campaign.claimed = true;
        //执行资金转移：然后，使用 transfer 方法将筹集的资金从合约账户转移到项目方的账户。这里，campaign.creator是接收资金的项目方地址，而 campaign.pledged 是需要转移的代币数量，即众筹活动成功筹集的总金额。
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }
    //当众筹活动结束却未能达到既定的筹资目标时， 众筹合约应该提供一个退款函数允许参与质押的用户取回他们投入的资金。这一过程不仅保障了投资者的利益，也增强了平台的信誉，确保了即使在不成功的众筹尝试中，用户的资金仍然得到妥善处理。
    function refund(uint256 _id) external {
        //我们首先需要获取指定的众筹活动信息。与之前的操作不同，这里我们采用 memory 关键字来创建活动信息的临时副本。由于后续的操作不涉及到活动信息的修改，采用这种方式可以更加节省gas成本。
        Campaign memory campaign = campaigns[_id];
        //接下来，我们对活动信息进行验证，确保活动已经结束，并且筹集的金额未达到设定的目标。
        require(block.timestamp > campaign.endAt, "not ended");
        //这一步骤是退款流程中至关重要的，它保证了只有在活动未能成功达成其筹资目标时，参与者才能够申请退款。
        require(campaign.pledged < campaign.goal, "pledged >= goal");
        //我们需要通过访问 pledgedAmount 映射，我们检索出用户在特定众筹活动中的质押金额。
        uint256 bal = pledgedAmount[_id][msg.sender];
        //为了确保不会发生重复退款的情况，我们将用户在该活动中的质押记录置为零。
        pledgedAmount[_id][msg.sender] = 0;
        //我们执行代币退款操作，通过调用 transfer 函数将之前质押的代币数量退还给用户，完成整个退款流程。
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}
