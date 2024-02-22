// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MulticallUpgradeable} from "./libraries/Multicall.sol";

contract HalbornToken is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    MulticallUpgradeable
{
    address public halbornLoans;

    modifier onlyLoans() {
        require(msg.sender == halbornLoans, "Caller is not HalbornLoans");
        _;
    }

    function initialize() external initializer {
        __ERC20_init("HalbornToken", "HT");
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Multicall_init();
    }

    function setLoans(address halbornLoans_) external onlyOwner {
        require(halbornLoans_ != address(0), "Zero Address");
        halbornLoans = halbornLoans_;
    }

    function mintToken(address account, uint256 amount) external onlyLoans {
        _mint(account, amount);
    }

    function burnToken(address account, uint256 amount) external onlyLoans {
        _burn(account, amount);
    }
    
    // @audit this lacks an access modifier, so the contract could be upgraded to a malicious implementation
    // https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-:~:text=The%20_authorizeUpgrade%20function%20must%20be%20overridden%20to%20include%20access%20restriction%20to%20the%20upgrade%20mechanism.
    function _authorizeUpgrade(address) internal override {}
}
