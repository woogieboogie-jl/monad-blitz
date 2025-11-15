// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMockVRFCoordinator {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint16 numWords
    ) external returns (uint256);
}

interface IChainlinkVRFConsumer {
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

/// @title MockVRFConsumer
/// @notice Example consumer contract that works out-of-the-box with `MockVRFCoordinator`.
contract MockVRFConsumer is IChainlinkVRFConsumer {
    IMockVRFCoordinator public immutable coordinator;
    bytes32 public immutable keyHash;
    uint64 public immutable subId;
    uint16 public immutable minimumRequestConfirmations;
    uint32 public immutable callbackGasLimit;
    uint16 public immutable numWords;

    uint256 public lastRequestId;
    uint256[] public lastRandomWords;
    uint8 public lastDiceRoll; // value between 1-6 derived from the latest fulfillment

    event RequestedRandomness(uint256 indexed requestId);
    event FulfilledRandomness(uint256 indexed requestId, uint256[] randomWords);

    modifier onlyCoordinator() {
        require(msg.sender == address(coordinator), "MockVRFConsumer: caller not coordinator");
        _;
    }

    constructor(
        address _coordinator,
        bytes32 _keyHash,
        uint64 _subId,
        uint16 _minimumRequestConfirmations,
        uint32 _callbackGasLimit,
        uint16 _numWords
    ) {
        coordinator = IMockVRFCoordinator(_coordinator);
        keyHash = _keyHash;
        subId = _subId;
        minimumRequestConfirmations = _minimumRequestConfirmations;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    function requestRandomness() external returns (uint256 requestId) {
        requestId = coordinator.requestRandomWords(
            keyHash,
            subId,
            minimumRequestConfirmations,
            callbackGasLimit,
            numWords
        );
        lastRequestId = requestId;
        emit RequestedRandomness(requestId);
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external onlyCoordinator {
        delete lastRandomWords;
        for (uint256 i = 0; i < randomWords.length; i++) {
            lastRandomWords.push(randomWords[i]);
        }
        lastDiceRoll = _deriveDiceRoll(randomWords);
        emit FulfilledRandomness(requestId, randomWords);
    }

    function latestRandomWord(uint256 index) external view returns (uint256) {
        require(index < lastRandomWords.length, "MockVRFConsumer: index oob");
        return lastRandomWords[index];
    }

    function latestDiceRollResult() external view returns (uint8) {
        require(lastDiceRoll != 0, "MockVRFConsumer: dice roll not set");
        return lastDiceRoll;
    }

    function _deriveDiceRoll(uint256[] memory randomWords) private pure returns (uint8) {
        require(randomWords.length > 0, "MockVRFConsumer: empty randomness");
        return uint8((randomWords[0] % 6) + 1);
    }
}

