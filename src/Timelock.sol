//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController{

    //
    constructor(uint minDelay, address[] memory proposers, address[] memory executors ) TimelockController( minDelay, proposers, executors, msg.sender) {}
}