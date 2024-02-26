// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HalbornNFT} from "../src/HalbornNFT.sol";

contract HalbornTestCheapNFT is Test {
    HalbornNFT public nft;

    function setUp() public {
        nft = new HalbornNFT();
        nft.initialize("", 1 ether);
    }

    function testMulticallPurchase() public {
        uint start = address(this).balance;
        uint end;

        // use mullticall for mintBuyWithETH to purchase 10 NFTs
        bytes[] memory data = new bytes[](10);
        for (uint256 i = 0; i < 10; i++) {
            data[i] = abi.encodeWithSignature("mintBuyWithETH()");
        }
        nft.multicall{value: 1 ether}(data);

        // check that we only paid 1 ether for 10 NFTs
        end = address(this).balance;
        assertTrue(start - end == 1 ether);
        assertEq(nft.balanceOf(address(this)), 10);

        console.log("NFTs minted:", nft.balanceOf(address(this)));
        console.log("Minted for", (start - end) / 1e18, "ether");
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
