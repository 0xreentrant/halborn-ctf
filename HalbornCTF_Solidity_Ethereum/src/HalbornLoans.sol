// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HalbornToken} from "./HalbornToken.sol";
import {HalbornNFT} from "./HalbornNFT.sol";

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {MulticallUpgradeable} from "./libraries/Multicall.sol";

contract HalbornLoans is Initializable, UUPSUpgradeable, MulticallUpgradeable {
    HalbornToken public token;
    HalbornNFT public nft;

    uint256 public immutable collateralPrice;

    mapping(address => uint256) public totalCollateral;
    mapping(address => uint256) public usedCollateral;
    mapping(uint256 => address) public idsCollateral;
    
    // @follow-up will the constructor be called as normal, and will collateralPrice_ actually be set?
    // - if not, the price will be the default value of 0
    constructor(uint256 collateralPrice_) {
        collateralPrice = collateralPrice_;
    }

    // @audit the initialize function be called by anyone, thus `token` and `nft` can be set by anyone
    function initialize(address token_, address nft_) public initializer {
        __UUPSUpgradeable_init();
        __Multicall_init();

        token = HalbornToken(token_);
        nft = HalbornNFT(nft_);
    }

    // @follow-up will it revert if the id is already deposited, no reentrancy?
    function depositNFTCollateral(uint256 id) external {
        require(
            nft.ownerOf(id) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // @follow-up CEI violation - reentrancy?
        // - onERC721Received is called, which could be from a malicious contract
        // - could the same id be deposited multiple times?
        nft.safeTransferFrom(msg.sender, address(this), id);

        totalCollateral[msg.sender] += collateralPrice;
        idsCollateral[id] = msg.sender;
    }

    function withdrawCollateral(uint256 id) external {
        require(
            totalCollateral[msg.sender] - usedCollateral[msg.sender] >=
                collateralPrice,
            "Collateral unavailable"
        );
        require(idsCollateral[id] == msg.sender, "ID not deposited by caller");

        // @follow-up CEI violation - reentrancy?
        // - onERC721Received is called, which could be from a malicious contract
        nft.safeTransferFrom(address(this), msg.sender, id);

        totalCollateral[msg.sender] -= collateralPrice;
        delete idsCollateral[id];
    }

    function getLoan(uint256 amount) external {
        require(
            totalCollateral[msg.sender] - usedCollateral[msg.sender] < amount,
            "Not enough collateral"
        );
        usedCollateral[msg.sender] += amount;
        token.mintToken(msg.sender, amount);
    }

    function returnLoan(uint256 amount) external {
        require(usedCollateral[msg.sender] >= amount, "Not enough collateral"); // only allow up to the amount of collateral used
        require(token.balanceOf(msg.sender) >= amount); // prevent more than the balance being burned
        
        // @audit looks like this should be -=
        // @follow-up can this brick loans for a user?
        usedCollateral[msg.sender] += amount;
        token.burnToken(msg.sender, amount);
    }

    // @audit this lacks an access modifier, so the contract could be upgraded to a malicious implementation
    // https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-:~:text=The%20_authorizeUpgrade%20function%20must%20be%20overridden%20to%20include%20access%20restriction%20to%20the%20upgrade%20mechanism.
    function _authorizeUpgrade(address) internal override {}
}
