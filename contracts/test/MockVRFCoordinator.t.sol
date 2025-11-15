// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import "../src/mocks/MockVRFCoordinator.sol";
import "../src/mocks/MockVRFConsumer.sol";

contract MockVRFCoordinatorTest is Test {
    MockVRFCoordinator internal coordinator;
    MockVRFConsumer internal consumer;

    bytes32 internal constant KEY_HASH = keccak256("mock-key-hash");
    uint64 internal constant SUB_ID = 1;
    uint16 internal constant CONFIRMATIONS = 3;
    uint32 internal constant CALLBACK_GAS_LIMIT = 200_000;
    uint16 internal constant NUM_WORDS = 2;

    function setUp() public {
        coordinator = new MockVRFCoordinator();
        consumer = new MockVRFConsumer(
            address(coordinator),
            KEY_HASH,
            SUB_ID,
            CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    function testRequestAndFulfill() public {
        vm.prank(address(1));
        uint256 requestId = consumer.requestRandomness();
        assertEq(requestId, 1);
        assertEq(consumer.lastRequestId(), 1);
        assertEq(consumer.lastRandomWords(0) > 0 ? 1 : 0, 1); // check exists
        assertEq(consumer.lastRandomWords(1) > 0 ? 1 : 0, 1);
        uint8 diceRoll = consumer.latestDiceRollResult();
        assertTrue(diceRoll >= 1 && diceRoll <= 6);
    }
}

