// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRouter {
    event OnReceived(
        bytes32 _orderId,
        uint64 _bridgeId,
        address _token,
        uint256 _tochain,
        address _from,
        bytes _to,
        uint256 _amount,
        address _caller
    );
    event Deliver(bytes32 orderId,address token,uint256 amount,address receiver);
    event DeliverAndSwap(bytes32 orderId,bytes32 bridgeId,address token,uint256 amount);
    function deliverAndSwap(
        bytes32 orderId,
        address initiator,
        address token,
        uint256 amount,
        bytes calldata swapData,
        bytes calldata bridgeData,
        bytes calldata feeData
    ) external payable;
    function deliver(
        bytes32 orderId,
        address token,
        uint256 amount,
        address receiver
    ) external;
    function onReceived(
        uint256 _amount,
        bytes32 _orderId,
        address _token,
        address _from,
        uint256 _tochain,
        bytes calldata _to
    ) external;
}