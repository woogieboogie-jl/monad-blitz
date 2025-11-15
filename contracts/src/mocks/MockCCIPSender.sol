// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple contract for sending string data across chains.
contract Sender is OwnerIsCreator {
  // Custom errors to provide more descriptive revert messages.
  error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough
  // balance.

  // Event emitted when a message is sent to another chain.
  // The chain selector of the destination chain.
  // The address of the receiver on the destination chain.
  // The text being sent.
  // the token address used to pay CCIP fees.
  // The fees paid for sending the CCIP message.
  event MessageSent( // The unique ID of the CCIP message.
    bytes32 indexed messageId,
    uint64 indexed destinationChainSelector,
    address receiver,
    string text,
    address feeToken,
    uint256 fees
  );

  IRouterClient private s_router;
  uint256 public callbackGasLimit = 200_000;

  /// @notice Constructor initializes the contract with the router address.
  /// @param _router The address of the router contract.
  constructor(
    address _router
  ) {
    s_router = IRouterClient(_router);
  }

  /// @notice Sends data to receiver on the destination chain.
  /// @param destinationChainSelector The identifier (aka selector) for the destination blockchain.
  /// @param receiver The address of the recipient on the destination blockchain.
  /// @param text The string text to be sent.
  /// @return messageId The ID of the message that was sent.
  function sendMessage(
    uint64 destinationChainSelector,
    address receiver,
    string calldata text
  ) external payable onlyOwner returns (bytes32 messageId) {
    // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
    Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
      receiver: abi.encode(receiver), // ABI-encoded receiver address
      data: abi.encode(text), // ABI-encoded string
      tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
      extraArgs: Client._argsToBytes(
        // Additional arguments, setting gas limit and allowing out-of-order execution.
        // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
        // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
        // and ensures compatibility with future CCIP upgrades. Read more about it here:
        // https://docs.chain.link/ccip/concepts/best-practices/evm#using-extraargs
        Client.GenericExtraArgsV2({
          gasLimit: callbackGasLimit, // Gas limit for the callback on the destination chain
          allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages
          // from
          // the same sender
        })
      ),
      // Set the feeToken  address, indicating Native Tokens will be paid for fees
      feeToken: address(0)
    });

    // Get the fee required to send the message
    uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);


    if (fees > address(this).balance) {
      revert NotEnoughBalance(address(this).balance, fees);
    }

    // Send the message through the router and store the returned message ID
    messageId = s_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);

    // Emit an event with message details
    emit MessageSent(messageId, destinationChainSelector, receiver, text, address(0), fees);

    // Return the message ID
    return messageId;
  }
  
  function setCallbackGasLimit(uint256 newLimit) external onlyOwner {
    callbackGasLimit = newLimit;
  }

  receive() external payable {}
}

