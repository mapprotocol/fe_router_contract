// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IButterRouterV3.sol";
import "./interfaces/IRouter.sol";

interface IPool {
    function transferTo(IERC20Upgradeable _token,address receiver,uint256 _amount) external;
    function isSupport(address _token) external view returns(bool);
}

contract Router is UUPSUpgradeable,PausableUpgradeable,ReentrancyGuardUpgradeable,Ownable2StepUpgradeable,IRouter{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IPool public pool;
    address public butterRouter;
    mapping(address => bool) public keepers;
    mapping (bytes32 => bool) public delivered;
    uint56 public nonce;
    uint8 public poolId;
    event SetPool(address _pool);
    event SetPoolId(uint8 _poolId);
    event SetButterRouter(address _butterRouter);
    event UpdateKeepers(address _keeper,bool _flag);

    error NOT_CONTRACT();
    error ZERO_ADDRESS();
    error NOT_SUPPORT(address _token);
    error KEEPER_ONLY();
    error ALREADY_DELIVERED();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
         _disableInitializers(); 
    }

    function initialize(address _owner,uint8 _poolId) external initializer {
         __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable2Step_init_unchained();
        _transferOwnership(_owner);
        require(_poolId != 0);
        poolId = _poolId;
    } 

    function setPool(address _pool) external onlyOwner {
        if(!_pool.isContract()) revert NOT_CONTRACT();
        pool = IPool(_pool);
        emit SetPool(_pool);
    }
    function setButterRouter(address _butterRouter) external onlyOwner {
        if(!_butterRouter.isContract()) revert NOT_CONTRACT();
        butterRouter = _butterRouter;
        emit SetButterRouter(_butterRouter);
    }

    function setPoolId(uint8 _poolId) external onlyOwner {
       require(_poolId != 0);
       poolId = _poolId;
       emit SetPoolId(_poolId);
    }
    
    function updateKeepers(address _keeper,bool _flag) external onlyOwner {
        if(_keeper == address(0)) revert ZERO_ADDRESS();
        keepers[_keeper] = _flag;
        emit UpdateKeepers(_keeper,_flag);
    }

    function deliverAndSwap(
        bytes32 orderId,
        address initiator,
        address token,
        uint256 amount,
        bytes calldata swapData,
        bytes calldata bridgeData,
        bytes calldata feeData
    ) external payable override nonReentrant {
        assert(address(pool) != address(0));
        if(!keepers[msg.sender]) revert KEEPER_ONLY();
        if(!pool.isSupport(token)) revert NOT_SUPPORT(token);
        if(delivered[orderId]) revert ALREADY_DELIVERED();
        delivered[orderId] = true; 
        pool.transferTo(IERC20Upgradeable(token),address(this),amount);
        IERC20Upgradeable(token).safeIncreaseAllowance(butterRouter,amount);
        bytes32 bridgeId = IButterRouterV3(butterRouter).swapAndBridge{value : msg.value}(orderId,initiator,token,amount,swapData,bridgeData,bytes(""),feeData);
        emit DeliverAndSwap(orderId,bridgeId,token,amount);
    }

    function deliver(
        bytes32 orderId,
        address token,
        uint256 amount,
        address receiver
    ) external override nonReentrant{
        assert(address(pool) != address(0));
        if(!keepers[msg.sender]) revert KEEPER_ONLY();
        if(!pool.isSupport(token)) revert NOT_SUPPORT(token);
        if(delivered[orderId]) revert ALREADY_DELIVERED();
        delivered[orderId] = true; 
        pool.transferTo(IERC20Upgradeable(token),receiver,amount);
        emit Deliver(orderId,token,amount,receiver);
    }


    struct Temp {
        uint256 amount;
        uint64  bridgeId;
        ReceiverParam param;
    }
    function onReceived(
       uint256 _amount,
       ReceiverParam calldata _param
    ) external  override nonReentrant{
        // Stack too deep.
        Temp memory temp;
        temp.param = _param;
        temp.amount = _amount;
        assert(address(pool) != address(0));
        temp.bridgeId = (uint64(poolId) << 56) | ++nonce; 
        if(!pool.isSupport(temp.param.chainPoolToken)) revert NOT_SUPPORT(temp.param.chainPoolToken);
        IERC20Upgradeable(temp.param.chainPoolToken).safeTransferFrom(msg.sender,address(pool),temp.amount);
        emit OnReceived(
            temp.param.orderId,
            temp.bridgeId,
            temp.param.srcChain,
            temp.param.srcToken,
            temp.param.inAmount,
            temp.param.sender,
            temp.param.chainPoolToken,
            temp.amount,
            temp.param.dstChain,
            temp.param.dstToken,
            temp.param.receiver,
            temp.param.slippage
        );
    }

   /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}