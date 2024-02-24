// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {HalbornNFT} from "../src/HalbornNFT.sol";

contract HalbornBrickProtocol {
    function initialize() external initializer {
        selfdestruct(payable(address(0x0)));
    }
}

contract HalbornTestUpgrades is Test {
    HalbornNFT public nft;

    function setUp() public {
        HalbornNFT impl = new HalbornNFT();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), 
            abi.encodeWithSignature("initialize(bytes32,uint256)", "", 1 ether)
        );

        nft = HalbornNFT(address(proxy));
    }

    function testUpgradeLoans() public {
        vm.startPrank(address(0xdeadbea7));
        // run the initializer on impl
        vm.stopPrank();
    }
}
