// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRouter {
    event OnReceived(
        bytes32 orderId,
        uint64  bridgeId,
        uint256 srcChain,
        bytes   srcToken,
        string  inAmount,
        bytes   sender,
        address chainPoolToken,
        uint256 chainPoolTokenAmount,
        uint256 dstChain,
        bytes   dstToken,
        bytes   receiver,
        uint64 slippage
    );

    event Deliver(
        bytes32 orderId,
        address token,
        uint256 amount,
        address receiver
    );

    event DeliverAndSwap(
        bytes32 orderId,
        bytes32 bridgeId,
        address token,
        uint256 amount
    );

    event DeliverAndSwap(
        uint256 srcChain,
        uint256 dstChain,
        address receiver,
        bytes32 orderId,
        bytes32 bridgeId,
        bytes from,
        address srcToken,
        uint256 srcAmount,
        address dstToken
    );

    struct DeliverParam{
        bytes32 orderId;
        address receiver;
        address token;
        uint256 amount;
        uint256 fromChain;
        uint256 toChain;
        uint256 fee;
        address feeReceiver;
        bytes  from;
        bytes  butterData;
    }

    function deliverAndSwap(DeliverParam memory param) external payable;

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
    ) external payable;

    function deliver(
        bytes32 orderId,
        address token,
        uint256 amount,
        address receiver,
        uint256 fee,
        address feeReceiver
    ) external;

    struct ReceiverParam {
        bytes32 orderId;
        uint256 srcChain;
        bytes   srcToken;
        bytes   sender;
        string  inAmount;
        address chainPoolToken;
        uint256 dstChain;
        bytes   dstToken; 
        bytes   receiver;
        uint64 slippage;
    }
    
    function onReceived(
       uint256 _amount,
       ReceiverParam calldata _param
    ) external payable;
}