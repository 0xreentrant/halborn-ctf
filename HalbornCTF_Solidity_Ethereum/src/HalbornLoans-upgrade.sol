// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HalbornToken} from "./HalbornToken.sol";
import {HalbornNFT} from "./HalbornNFT.sol";

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {MulticallUpgradeable} from "./libraries/Multicall.sol";

contract HalbornLoansUpgrade is Initializable, UUPSUpgradeable, MulticallUpgradeable {
    HalbornToken public token;
    HalbornNFT public nft;

    uint256 public immutable collateralPrice;

    mapping(address => uint256) public totalCollateral;
    mapping(address => uint256) public usedCollateral;
    mapping(uint256 => address) public idsCollateral;
    
    constructor(uint256 collateralPrice_) {
        collateralPrice = collateralPrice_;
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Multicall_init();
    }

    function isSuccessfulUpgrade() public pure returns (bool) {
        return true;
    }

    function _authorizeUpgrade(address) internal override {}
}
