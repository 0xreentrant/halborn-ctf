// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";
import {MulticallUpgradeable} from "./libraries/Multicall.sol";

contract HalbornNFT is
    Initializable,
    ERC721Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    MulticallUpgradeable
{
    bytes32 public merkleRoot;

    uint256 public price;
    uint256 public idCounter;

    // @audit initializers aren't disabled, anyone can call initialize on the implementation contract

    // @audit-ok the initialize function be called by anyone, thus `token` and `nft` can be set by anyone
    // - only an issue if the deploy mechanics are run non-atomically
    // - ex: 
    function initialize(
        bytes32 merkleRoot_,
        uint256 price_
    ) external initializer {
        __ERC721_init("Halborn NFT", "HNFT");
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Multicall_init();

        setMerkleRoot(merkleRoot_);
        setPrice(price_);
    }

    function setPrice(uint256 price_) public onlyOwner {
        require(price_ != 0, "Price cannot be 0");
        price = price_;
    }

    // @audit-issue anyone can set the merkle root
    function setMerkleRoot(bytes32 merkleRoot_) public {
        merkleRoot = merkleRoot_;
    }

    function mintAirdrops(uint256 id, bytes32[] calldata merkleProof) external {
        // @audit-issue nobody can mint their airdrop because _exists(id) is false for unminted ids
        require(_exists(id), "Token already minted");

        // @follow-up collisions occur here w/ encodePacked -> msg.sender + id? 
        // @follow-up if mintAirdrops is frontrun, does this fail?
        bytes32 node = keccak256(abi.encodePacked(msg.sender, id));
        bool isValidProof = MerkleProofUpgradeable.verifyCalldata(
            merkleProof,
            merkleRoot,
            node
        );
        require(isValidProof, "Invalid proof.");

        _safeMint(msg.sender, id, "");
    }

    function mintBuyWithETH() external payable {
        require(msg.value == price, "Invalid Price");

        unchecked {
            idCounter++;
        }

        _safeMint(msg.sender, idCounter, "");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }
   
    // @audit-issue this lacks an access modifier, so the contract could be upgraded to a malicious implementation
    // https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-:~:text=The%20_authorizeUpgrade%20function%20must%20be%20overridden%20to%20include%20access%20restriction%20to%20the%20upgrade%20mechanism.
    function _authorizeUpgrade(address) internal override {}

    // @follow-up who can renounce ownership? (also the other contracts)
    // ex: https://solodit.xyz/issues/contract-admin-can-revoke-and-renounce-himself-halborn-seascape-ninja-spin-pdf

    // @follow-up can ownership be transferred?
    // @follow-up can anyone call selfdestruct?
}
