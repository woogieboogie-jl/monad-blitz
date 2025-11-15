// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVRFConsumer {
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

/// @title MockVRFCoordinator
/// @notice Minimal VRF mock that immediately fulfills each request with blockhash-derived randomness. Don't use it for production!
contract MockVRFCoordinator {
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 indexed requestId,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint16 numWords,
        address sender
    );

    event RandomWordsFulfilled(uint256 indexed requestId, bool success, address indexed consumer);

    uint256 private nextRequestId = 1;

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint16 numWords
    ) external returns (uint256 requestId) {
        require(numWords > 0, "MockVRFCoordinator: numWords=0");

        requestId = nextRequestId++;
        emit RandomWordsRequested(
            keyHash,
            requestId,
            subId,
            minimumRequestConfirmations,
            callbackGasLimit,
            numWords,
            msg.sender
        );

        uint256[] memory words = _generateWords(requestId, numWords);
        bool success;
        try IVRFConsumer(msg.sender).rawFulfillRandomWords(requestId, words) {
            success = true;
        } catch {
            success = false;
        }

        emit RandomWordsFulfilled(requestId, success, msg.sender);
    }
    
    // Mock VRF only for Monad Blitz Hackathon using Block Hash (This is not safe, don't use it for production)
    function _generateWords(uint256 requestId, uint16 numWords) private view returns (uint256[] memory words) {
        bytes32 source = block.number > 1 ? blockhash(block.number - 1) : bytes32(0);
        if (source == bytes32(0)) {
            source = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, requestId));
        }

        words = new uint256[](numWords);
        for (uint256 i = 0; i < numWords; i++) {
            words[i] = uint256(keccak256(abi.encodePacked(source, requestId, i)));
        }
    }
}
