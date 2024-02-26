// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract Selfdestructor {
    function selfdestruct() public {
        // selfdestruct(address(0xdeadbea7));
    }

}

contract HalbornTestFreeLoans is Test {
    address public immutable ALICE = makeAddr("ALICE");

    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoans public loans;

    function setUp() public {
        nft = new HalbornNFT();
        nft.initialize("", 1 ether);
        token = new HalbornToken();
        token.initialize();
        loans = new HalbornLoans(2 ether); // incentivize reentrancy
        loans.initialize(address(token), address(nft));
        token.setLoans(address(loans));
    }

    function testMulticallSelfdestruct() public {

    }
}
