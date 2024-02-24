// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Merkle} from "./murky/Merkle.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";

contract HalbornClaimTest is Test {
    address public immutable ALICE = makeAddr("ALICE");
    address public immutable BOB = makeAddr("BOB");

    bytes32[] public ALICE_PROOF_1;
    bytes32[] public ALICE_PROOF_2;
    bytes32[] public BOB_PROOF_1;
    bytes32[] public BOB_PROOF_2;

    HalbornNFT public nft;

    function setUp() public {
        Merkle m = new Merkle();

        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encodePacked(ALICE, uint256(15)));
        data[1] = keccak256(abi.encodePacked(ALICE, uint256(19)));
        data[2] = keccak256(abi.encodePacked(BOB, uint256(21)));
        data[3] = keccak256(abi.encodePacked(BOB, uint256(24)));

        // Get Merkle Root
        bytes32 root = m.getRoot(data);

        // Get Proofs
        ALICE_PROOF_1 = m.getProof(data, 0);
        ALICE_PROOF_2 = m.getProof(data, 1);
        BOB_PROOF_1 = m.getProof(data, 2);
        BOB_PROOF_2 = m.getProof(data, 3);

        nft = new HalbornNFT();
        nft.initialize(root, 1 ether);
    }

    function testClaimMintAirdrop() public {
        // use nft.mintAirdrops to mint the NFTs using the proofs generated in setUp()
        vm.startPrank(ALICE);
        vm.expectRevert();
        nft.mintAirdrops(15, ALICE_PROOF_1);
        vm.expectRevert();
        nft.mintAirdrops(19, ALICE_PROOF_2);
        vm.stopPrank();

        vm.startPrank(BOB);
        vm.expectRevert();
        nft.mintAirdrops(21, BOB_PROOF_1);        
        vm.expectRevert();
        nft.mintAirdrops(24, BOB_PROOF_2);  
        vm.stopPrank();

        // show that neither ALICE nor BOB have any NFTs minted
        assertEq(0, nft.balanceOf(ALICE));
        assertEq(0, nft.balanceOf(BOB));
    }
}
