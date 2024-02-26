// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract HalbornTestFailNFTReceiver is Test {
    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoans public loans;

    function setUp() public {
        nft = new HalbornNFT();
        nft.initialize("", 1 ether);
        token = new HalbornToken();
        token.initialize();
        loans = new HalbornLoans(2 ether);
        loans.initialize(address(token), address(nft));
        token.setLoans(address(loans));
    }

    function testFailHalbornLoansERC721Receiver() public {
        address attacker = address(this);
        nft.mintBuyWithETH{value: 1 ether}();
        assertTrue(nft.balanceOf(attacker) == 1); 

        uint256 id = nft.idCounter();
        assertTrue(nft.ownerOf(1) == attacker);

        nft.approve(address(loans), id);
        assertTrue(nft.getApproved(id) == address(loans));

        // this will fail because HalbornLoans is not an ERC721Receiver
        loans.depositNFTCollateral(id);
    }
}
