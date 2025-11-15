// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

/// @title Minimal CCIP receiver for string payloads (demo-only)
contract MockCCIPReceiver is CCIPReceiver {
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string text
    );

    bytes32 private s_lastReceivedMessageId;
    string private s_lastReceivedText;

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string));

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            abi.decode(any2EvmMessage.data, (string))
        );
    }

    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, string memory text) {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }
}
