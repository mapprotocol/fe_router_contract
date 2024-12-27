// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChainPoolRouter {
    event OnReceived(
        address referrer,
        bytes32 orderId,
        bytes32 bridgeId,
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

    event DeliverAndSwap(
        address referrer,
        bytes32 orderId,
        bytes32 bridgeId,
        uint256 srcChain,
        uint256 dstChain,
        address receiver,
        bytes from,
        address srcToken,
        uint256 srcAmount,
        address dstToken
    );

    struct DeliverParam {
        address referrer;
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

    struct ReceiverParam {
        address referrer;
        bytes32 bridgeId;
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