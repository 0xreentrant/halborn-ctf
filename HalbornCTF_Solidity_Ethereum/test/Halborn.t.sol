// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Merkle} from "./murky/Merkle.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract HalbornTest is Test {
    address public immutable ALICE = makeAddr("ALICE");
    address public immutable BOB = makeAddr("BOB");

    bytes32[] public ALICE_PROOF_1;
    bytes32[] public ALICE_PROOF_2;
    bytes32[] public BOB_PROOF_1;
    bytes32[] public BOB_PROOF_2;

    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoans public loans;

    function setUp() public {
        // Initialize
        Merkle m = new Merkle();
        // Test Data
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

        assertTrue(m.verifyProof(root, ALICE_PROOF_1, data[0]));
        assertTrue(m.verifyProof(root, ALICE_PROOF_2, data[1]));
        assertTrue(m.verifyProof(root, BOB_PROOF_1, data[2]));
        assertTrue(m.verifyProof(root, BOB_PROOF_2, data[3]));

        nft = new HalbornNFT();
        nft.initialize(root, 1 ether);

        token = new HalbornToken();
        token.initialize();

        loans = new HalbornLoans(2 ether);
        loans.initialize(address(token), address(nft));

        token.setLoans(address(loans));
    }

    function testFailHalbornLoansERC721Receiver() public {
        vm.deal(ALICE, 1 ether);
        vm.startPrank(ALICE);
        
        nft.mintBuyWithETH{value: 1 ether}();
        assertTrue(nft.balanceOf(ALICE) == 1); 

        uint256 id = nft.idCounter();
        assertTrue(nft.ownerOf(1) == ALICE);

        nft.approve(address(loans), id);
        assertTrue(nft.getApproved(id) == address(loans));

        loans.depositNFTCollateral(id);
    }

    function testRepayingFailsSimpleExample() public {
        // simulate/support only 1 depositor
        uint256 totalCollateral = 0;
        uint256 usedCollateral = 0;
        uint256 collateralPrice = 2 ether;

        // depositor provides NFT, and the totalCollateral is updated
        totalCollateral += collateralPrice;

        // despositor takes out a loan, and the usedCollateral is updated
        // getLoan() equivalent to:
        uint256 loanAmount = 1 ether;
        usedCollateral += loanAmount;

        // depositor repays the loan, but the usedCollateral grows
        // returnLoan() equivalent to:
        uint256 repayAmount = 1 ether;
        usedCollateral += repayAmount;

        // The depositor expects to have paid off their loan, but the usedCollateral has grown
        assertTrue(usedCollateral == 0);
        console.log("expecting usedCollateral to be ~0: ", usedCollateral);
    }
}
