// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {}

    function __Multicall_init_unchained() internal onlyInitializing {}

    // @audit can this be used to call withdraw/deposit multiple times with the same msg.value?
    // - delegatecall used internally
    // - would affect mint/burn functions
    // - this can be used to call a malicious function w/ selfdestruct
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = AddressUpgradeable.functionDelegateCall(
                address(this),
                data[i]
            );
        }
        return results;
    }
}
