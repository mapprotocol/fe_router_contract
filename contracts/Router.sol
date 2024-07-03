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
    event SetPool(address _pool);
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

    function initialize(address _owner) external initializer {
         __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable2Step_init_unchained();
        _transferOwnership(_owner);
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

    function onReceived(bytes32 _orderId,address _token,address _from,bytes calldata _to,uint256 _amount) external override nonReentrant{
        assert(address(pool) != address(0));
        if(!pool.isSupport(_token)) revert NOT_SUPPORT(_token);
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender,address(pool),_amount);
        emit OnReceived(_orderId,_token,_from,_to,_amount,msg.sender);
    }

   /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}