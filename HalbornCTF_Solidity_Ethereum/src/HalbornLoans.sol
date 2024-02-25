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
    
    // @audit-ok using the constructor to set collateralPrice with the proxy will not update the value
    // - use the initialize function to set the collateralPrice
    constructor(uint256 collateralPrice_) {
        // @audit-ok there is no way to update the collateral price after deployment
        // - protocol operators cannot adjust to market changes in case of supply/demand changes
        collateralPrice = collateralPrice_;
    }


    // @audit-ok if the example in test/Halborn.t.sol is how these contracts are expected deployed (ie. using `forge script`), 
    // without deploying/configuring the proxy contract, then:
    // - the initialize function can be front-run, and since the initialize function be called by anyone, 
    //   `token` and `nft` can be set by anyone
    function initialize(address token_, address nft_) public initializer {
        __UUPSUpgradeable_init();
        __Multicall_init();

        token = HalbornToken(token_);
        nft = HalbornNFT(nft_);
    }

    function depositNFTCollateral(uint256 id) external {
        require(
            nft.ownerOf(id) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // @audit-issue this contract is not an ERC721Receiver, so the transfer will fail
        // @audit-ok CEI violation - no reentrancy (onERC721Received is controlled by this contract)
        // @audit-ok will revert if the id is already deposited & transferred
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

        // @audit-issue CEI violation - reentrancy (onERC721Received is called)
        nft.safeTransferFrom(address(this), msg.sender, id);

        totalCollateral[msg.sender] -= collateralPrice;
        delete idsCollateral[id];
    }

    function getLoan(uint256 amount) external {
        // @audit the equality is reversed, making it "what is left of total collateral must be less than the amount being requested"
        // - should be >= 
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
        
        // @audit-issue Repaying loans locks collateral into the protocol
        // - this should be -=
        // - this locks collateral into the protocol
        // - user can only retrieve their initial collateral by depositing subsequent collateral
        usedCollateral[msg.sender] += amount;
        token.burnToken(msg.sender, amount);
    }

    // @audit-issue this lacks an access modifier, so the contract could be upgraded to a malicious implementation
    // https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-:~:text=The%20_authorizeUpgrade%20function%20must%20be%20overridden%20to%20include%20access%20restriction%20to%20the%20upgrade%20mechanism.
    function _authorizeUpgrade(address) internal override {}
}
