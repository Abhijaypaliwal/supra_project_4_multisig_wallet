// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/multisig.sol";

contract multiSigTest is Test {
    multiSig multiSigWallet;
    address[] public owners = [address(10), address(11), address(12), address(13)];

    /**
     * @notice setting up contract with 4 owners and minimum 3 confirmations
     */
    function setUp() external {
        multiSigWallet = new multiSig(owners, 3);
    }

    /**
     * @notice the flow of transaction is as follows:
     * 1. multisigwallet contract is funded with 10 ether.
     * 2. address(10) initiate a transaction to transfer 1 ether to address(4).
     * 3. address(10) confirms transaction.
     * 4. 2 other admins also confirms the transaction.
     * 5. address(12) which is one of the admins executes transaction.
     * 6. 1 ether successfully transfers from contract.
     */
    function testMultiSig() external {
        vm.startPrank(address(10));
        vm.deal(address(multiSigWallet), 10 ether);
        multiSigWallet.initiateTransaction(address(4), 1 ether, 1704892557);
        multiSigWallet.confirmTransaction(1);
        vm.stopPrank();
        vm.prank(address(11));
        multiSigWallet.confirmTransaction(1);
        vm.startPrank(address(12));
        multiSigWallet.confirmTransaction(1);
        multiSigWallet.executeTransaction(1);
        vm.stopPrank();
        console.log("<--- balance of multisig contract is --->",address(multiSigWallet).balance);
        console.log("<--- balance of address(4() is --->",address(4).balance);
    }

    function testUnsuccessfulConditions() external {
        vm.startPrank(address(10));
        vm.deal(address(multiSigWallet), 10 ether);
        multiSigWallet.initiateTransaction(address(4), 1 ether, 1704892557);
        multiSigWallet.confirmTransaction(1);
        vm.stopPrank();
        // **TEST 1** confirming txn by non admin address
        vm.prank(address(100));
        vm.expectRevert("not called by either of owners");
        multiSigWallet.confirmTransaction(1);

        // **TEST 2** execute txn before min confirmations
        // till now only 1 confirmation is got by address 10
        vm.prank(address(10));
        vm.expectRevert("txn not got enough confirmations");
        multiSigWallet.executeTransaction(1);

        // **TEST 3** confirming txn after txn expiry
        vm.warp(1704892558);
        vm.prank(address(11));
        vm.expectRevert("transaction is being expired");
        multiSigWallet.confirmTransaction(1);

        // **TEST 4** executing txn  after txn expiry
        vm.warp(1704892556);
        vm.prank(address(11));
        multiSigWallet.confirmTransaction(1);
        vm.prank(address(12));
        multiSigWallet.confirmTransaction(1);
        vm.warp(1704892558);
        vm.prank(address(12));
        vm.expectRevert("transaction is being expired");
        multiSigWallet.executeTransaction(1);
    }
}
