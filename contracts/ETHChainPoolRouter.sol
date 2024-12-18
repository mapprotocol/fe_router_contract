// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IButterRouterV3.sol";
import "./interfaces/IRouter.sol";

contract ETHChainPoolRouter is
    AccessControlEnumerable,
    ReentrancyGuard,
    IRouter
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint56 public nonce;
    uint8 public poolId;
    address public butterRouter;
    uint256 public delivered;
    mapping(address => bool) public keepers;

    // feeReceiver => token => amount
    mapping(address => mapping(address => uint256)) public fees;

    event SetPoolId(uint8 _poolId);
    event SetButterRouter(address _butterRouter);
    event UpdateKeepers(address _keeper, bool _flag);
    event CollectFee(bytes32 orderId, address token, uint256 fee);
    event WithdrawFee(address receiver, address token, uint256 amount);
    event Withdraw(address _token,address _receiver,uint256 _amount);

    error NOT_CONTRACT();
    error ZERO_ADDRESS();
    error KEEPER_ONLY();
    error ALREADY_DELIVERED();
    error INVALID_FEE();
    error ONLY_BUTTER();
    error NATIVE_TRANSFER_FAILED();
    error TOKEN_TRANSFER_FAILED();
    error RECERVER_TOO_LOW();

    constructor(address _admin,address _butterRouter, uint8 _poolId) {
        if (_butterRouter.code.length == 0) revert NOT_CONTRACT();
        poolId = _poolId;
        butterRouter = _butterRouter;
        _grantRole(MANAGER_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function setButterRouter(
        address _butterRouter
    ) external onlyRole(MANAGER_ROLE) {
        if (_butterRouter.code.length == 0) revert NOT_CONTRACT();
        butterRouter = _butterRouter;
        emit SetButterRouter(_butterRouter);
    }

    function setPoolId(uint8 _poolId) external onlyRole(MANAGER_ROLE) {
        require(_poolId != 0);
        poolId = _poolId;
        emit SetPoolId(_poolId);
    }

    function updateKeepers(
        address _keeper,
        bool _flag
    ) external onlyRole(MANAGER_ROLE) {
        if (_keeper == address(0)) revert ZERO_ADDRESS();
        keepers[_keeper] = _flag;
        emit UpdateKeepers(_keeper, _flag);
    }

    function withdrawFee(address token) external {
        address receiver = msg.sender;
        uint256 fee = fees[receiver][token];
        fees[receiver][token] = 0;
        require(fee != 0);
        _transferOut(token, receiver, fee);
        emit WithdrawFee(receiver, token, fee);
    }

    function withdraw(address _token,address _recerver,uint256 _amount) external onlyRole(MANAGER_ROLE) {
         if(_recerver == address(0)) revert ZERO_ADDRESS();
         _transferOut(_token, _recerver, _amount); 
         emit Withdraw(_token,_recerver,_amount);
    }

    function deliverAndSwap(
        DeliverParam memory param
    ) external payable override nonReentrant {
        if (!keepers[msg.sender]) revert KEEPER_ONLY();
        if (param.fee >= param.amount) revert INVALID_FEE();
        uint64 orderId_64 = uint64(uint256(param.orderId));
        if(isDelivered(orderId_64)) revert ALREADY_DELIVERED();
        delivered = (delivered << 64) | uint256(orderId_64);
        uint256 afterFee = param.amount;
        if ((param.fee != 0) && (param.feeReceiver != address(0))) {
            _collectFee(
                param.orderId,
                param.token,
                param.feeReceiver,
                param.fee
            );
            afterFee = param.amount - param.fee;
        }
        address dstToken;
        bytes32 bridgeId;
        if (param.butterData.length == 0) {
            param.toChain = block.chainid;
            dstToken = param.token;
            bridgeId = 0x0000000000000000000000000000000000000000000000000000000000000001;
            _transferOut(param.token, param.receiver, afterFee);
        } else {
            (bridgeId, dstToken) = _swapAndbridge(
                param.orderId,
                param.token,
                afterFee,
                param.butterData
            );
        }
        emit DeliverAndSwap(
            param.fromChain,
            param.toChain,
            param.receiver,
            param.orderId,
            bridgeId,
            param.from,
            param.token,
            param.amount,
            dstToken
        );
    }

    function _swapAndbridge(
        bytes32 orderId,
        address token,
        uint256 amount,
        bytes memory butterData
    ) private returns (bytes32 bridgeId, address dstToken) {
        address initiator;
        bytes memory swapData;
        bytes memory bridgeData;
        bytes memory feeData;
        uint256 value;
        if (token == address(0)) {
            value = amount;
        } else {
            IERC20(token).approve(butterRouter, amount);
        }
        (initiator, dstToken, swapData, bridgeData, feeData) = abi.decode(
            butterData,
            (address, address, bytes, bytes, bytes)
        );
        bridgeId = IButterRouterV3(butterRouter).swapAndBridge{value: amount}(
            orderId,
            initiator,
            token,
            amount,
            swapData,
            bridgeData,
            bytes(""),
            feeData
        );
    }

    struct Temp {
        uint256 amount;
        uint64 bridgeId;
        ReceiverParam param;
    }

    function onReceived(
        uint256 _amount,
        ReceiverParam calldata _param
    ) external payable override nonReentrant {
        // Stack too deep.
        Temp memory temp;
        temp.param = _param;
        temp.amount = _amount;

        temp.bridgeId = (uint64(poolId) << 56) | ++nonce;
        _transferIn(temp.param.chainPoolToken, msg.sender, temp.amount);
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

    function _transferIn(
        address _token,
        address _from,
        uint256 _amount
    ) private {
        if (address(_token) == address(0)) {
            if (_amount > msg.value) revert RECERVER_TOO_LOW();
        } else {
            (bool success, bytes memory data) = _token.call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    _from,
                    address(this),
                    _amount
                )
            );
            if (!success || (data.length != 0 && !abi.decode(data, (bool))))
                revert TOKEN_TRANSFER_FAILED();
        }
    }

    function _transferOut(
        address _token,
        address _receiver,
        uint256 _amount
    ) private {
        if (address(_token) == address(0)) {
            (bool result, ) = _receiver.call{value: _amount}("");
            if (!result) revert NATIVE_TRANSFER_FAILED();
        } else {
            (bool success, bytes memory data) = _token.call(
                abi.encodeWithSelector(0xa9059cbb, _receiver, _amount)
            );
            if (!success || (data.length != 0 && !abi.decode(data, (bool))))
                revert TOKEN_TRANSFER_FAILED();
        }
    }

    function _collectFee(
        bytes32 _orderId,
        address _token,
        address _feeReceiver,
        uint256 _fee
    ) private {
        fees[_feeReceiver][_token] += _fee;
        emit CollectFee(_orderId, _token, _fee);
    }

    function isDelivered(uint64 orderId) public view returns(bool) {
        uint256 _delivered = delivered;
        for (uint i = 0; i < 4; i++) {
            if(orderId == uint64(_delivered >> ( 64 * i))) return true;  
        }
        return false;
    }


    function deliverAndSwap(
        bytes32 orderId,
        address initiator,
        address token,
        uint256 amount,
        bytes calldata swapData,
        bytes calldata bridgeData,
        bytes calldata feeData,
        uint256 fee,
        address feeReceiver
    ) external payable override nonReentrant {}

    function deliver(
        bytes32 orderId,
        address token,
        uint256 amount,
        address receiver,
        uint256 fee,
        address feeReceiver
    ) external override {}
}