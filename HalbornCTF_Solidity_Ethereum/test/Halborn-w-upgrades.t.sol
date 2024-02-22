// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {HalbornLoans} from "../src/HalbornLoans.sol";
import {HalbornLoansUpgrade} from "../src/HalbornLoans-upgrade.sol";

contract HalbornTestUpgrades is Test {
    HalbornLoans public loans;

    function setUp() public {
        HalbornLoans impl = new HalbornLoans(2 ether); // w/ same original constructor param
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), 
            abi.encodeWithSignature("initialize(address,address)", address(1), address(2))
        );

        loans = HalbornLoans(address(proxy));

        console.log(loans.collateralPrice());
    }

    function testUpgradeLoans() public {
        HalbornLoansUpgrade newImpl = new HalbornLoansUpgrade(1337 ether);
        loans.upgradeTo(address(newImpl));
        console.log(loans.collateralPrice());
        assertTrue(newImpl.isSuccessfulUpgrade());
    }
}
