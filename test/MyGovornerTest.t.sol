//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MyGovorner} from "../src/MyGovorner.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/Timelock.sol";   
import {GovToken} from "../src/GovToken.sol";

contract MyGovornerTest is Test {
    MyGovorner myGovorner;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 constant public INITIAL_SUPPLY = 100 ether;

    uint256 constant public MIN_DELAY = 3600;
    uint256 constant public VOTING_DELAY = 1;
    uint256 constant public VOTING_PERIOD = 50400;

    address[] public proposers;
    address[] public executors;
    uint256[] public values;
    bytes[] calldatas;
    address[] targets;


    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        govToken.delegate(USER);

        timeLock = new TimeLock(MIN_DELAY, proposers, executors);
        myGovorner = new MyGovorner(govToken, timeLock);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(myGovorner));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));


    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGoveranceUpdatesBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 1 in box";   
        bytes memory data = abi.encodeWithSignature( "store(uint256)", valueToStore);
        values.push(0);
        calldatas.push(data);
        targets.push(address(box));

        uint256 proposalId = myGovorner.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);   

        string memory reason = "execute proposals";

        uint8 voteWay = 1; //voting yes
        vm.prank(USER);
        myGovorner.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);   

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        myGovorner.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);   

        myGovorner.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);

    }
}