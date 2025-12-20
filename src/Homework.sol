// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Homework {
    function proof() external pure returns (bytes32) {
        return keccak256("I have done this homework myself");
    }
}