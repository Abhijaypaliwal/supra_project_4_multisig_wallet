// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title multisig wallet
 * @notice multisignature wallet where payments can be made after the confirmation of
 * specified admins
 * @author Abhijay Paliwal
 */

contract multiSig {
    receive() external payable {}

    struct transactionDetails {
        address to;
        uint256 amount;
        bool isExecuted;
        uint256 confirmationsRecieved;
        uint256 txnExpiry;
    }

    /**
     * @notice address array of owners or admin
     */
    address[] public owners;

    /**
     * @notice minimum confirmations required to execute transaction
     */
    uint256 public minConfirmationRequired;

    /**
     * @notice winner of the election. only used when admin declares result
     */
    uint256 public transactionCount;

    /**
     * @notice mapping of addresses to confirm their status of admin
     * @dev used to check if call is made by owner or not
     */
    mapping(address => bool) public isOwner;

    /**
     * @notice mapping of txn number to the confirmation status of admin
     * @dev used to check if specified txn num is approved by admin or not
     */
    mapping(uint256 => mapping(address => bool)) public isTxnConfirmedByAdmin;

    /**
     * @notice mapping of txn number to the struct of details of transaction
     */
    mapping(uint256 => transactionDetails) public transactionMapping;

    /**
     * @notice modifier to check if call is made by owner or not
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true, "not called by either of owners");
        _;
    }

    /**
     * @notice modifier to check if txn exists in system or not
     */
    modifier isTxnExists(uint256 _txnNum) {
        require(transactionMapping[_txnNum].to != address(0), "txn does not exists");
        _;
    }

    /**
     * @notice modifier to check if transaction is previously executed or not
     */
    modifier isTxnExecuted(uint256 _txnNum) {
        require(transactionMapping[_txnNum].isExecuted == false, "txn is already confirmed");
        _;
    }

    /**
     * @notice modifier to check if transaction as expired or not
     */
    modifier isTxnExpired(uint256 _txnNum) {
        require(block.timestamp < transactionMapping[_txnNum].txnExpiry, "transaction is being expired");
        _;
    }

    /**
     * @notice Emitted when admin adds voter and its detailsfor election.
     * @param _to address address to be transferred
     * @param _adminAddr address address of admin who initiated transaction
     * @param _amount uint256 amount to be transferred
     * @param _txnExpiry uint256 transaction expiry timestamp
     */
    event initiateNewTransaction(address indexed _to, address indexed _adminAddr, uint256 _amount, uint256 _txnExpiry);

    /**
     * @notice Emitted when admin confirms transaction
     * @param _adminAddr address address of admin who initiated transaction
     * @param _transactionNum uint256 trasnaction num to be confirmed
     * @param _confirmationTimestamp uint256 timestamp of the confirmation
     */
    event confirmTransactionAdmin(address indexed _adminAddr, uint256 _transactionNum, uint256 _confirmationTimestamp);

    /**
     * @notice Emitted when admin executes transaction
     * @param _adminAddr address address of admin who initiated transaction
     * @param _transactionNum uint256 trasnaction num to be confirmed
     * @param _confirmationTimestamp uint256 timestamp of the confirmation
     */
    event executeTransactionEvent(address indexed _adminAddr, uint256 _transactionNum, uint256 _confirmationTimestamp);

    /**
     * @dev contract constructor
     * @param  _owners address[] memory array of addresses of owners
     * @param _minConfirmationRequired uint256 min confirmation required to approve transaction
     */
    constructor(address[] memory _owners, uint256 _minConfirmationRequired) {
        minConfirmationRequired = _minConfirmationRequired;
        require(
            _owners.length > 0 && _minConfirmationRequired > 0,
            "either of number of owners or confirmation count is invalid"
        );
        require(
            _minConfirmationRequired <= _owners.length, "confirmations should be less than or equal to number of owners"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "invalid address");
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
    }

    /**
     * @notice function to initiate transaction to be approved by admins
     * @dev can only be called by one of the owners.
     * @param _to address address to be transferred
     * @param _amount uint256 amount to be transferred
     * @param _txnExpiry uint256 transaction expiry timestamp
     */
    function initiateTransaction(address _to, uint256 _amount, uint256 _txnExpiry) external onlyOwner {
        require(_amount > 0 && _to != address(0), "amount should be greater than zero");
        transactionCount++;
        transactionDetails memory txn;
        txn.to = _to;
        txn.amount = _amount;
        txn.isExecuted = false;
        txn.confirmationsRecieved = 0;
        txn.txnExpiry = _txnExpiry;
        transactionMapping[transactionCount] = txn;
        emit initiateNewTransaction(_to, msg.sender, _amount, _txnExpiry);
    }

    /**
     * @notice function to confirm transaction by one of the admin
     * @dev can only be called by one of the owners.
     * @param _transactionNum uint256 transaction number to be confirmed
     */
    function confirmTransaction(uint256 _transactionNum)
        external
        onlyOwner
        isTxnExists(_transactionNum)
        isTxnExecuted(_transactionNum)
        isTxnExpired(_transactionNum)
    {
        require(isTxnConfirmedByAdmin[_transactionNum][msg.sender] == false, "txn is already confirmed by admin");
        transactionMapping[_transactionNum].confirmationsRecieved += 1;
        isTxnConfirmedByAdmin[_transactionNum][msg.sender] = true;
        emit confirmTransactionAdmin(msg.sender, _transactionNum, block.timestamp);
    }

    /**
     * @notice function to execute transaction by one of the admin
     * @dev can only be called by one of the owners and after the min number of
     * confirmations are reached
     */
    function executeTransaction(uint256 _transactionNum)
        external
        onlyOwner
        isTxnExists(_transactionNum)
        isTxnExecuted(_transactionNum)
        isTxnExpired(_transactionNum)
    {
        require(
            transactionMapping[_transactionNum].confirmationsRecieved >= minConfirmationRequired,
            "txn not got enough confirmations"
        );
        transactionMapping[_transactionNum].isExecuted = true;
        (bool success,) =
            transactionMapping[_transactionNum].to.call{value: transactionMapping[_transactionNum].amount}("");
        require(success, "tx failed");
        emit executeTransactionEvent(msg.sender, _transactionNum, block.timestamp);
    }

    /**
     * @notice function to return array of owners
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice function to return transaction details
     * @param _transactionNum uint256 transaction number
     */
    function getTxnDetails(uint256 _transactionNum) external view returns (address, uint256, bool, uint256, uint256) {
        return (
            transactionMapping[_transactionNum].to,
            transactionMapping[_transactionNum].amount,
            transactionMapping[_transactionNum].isExecuted,
            transactionMapping[_transactionNum].confirmationsRecieved,
            transactionMapping[_transactionNum].txnExpiry
        );
    }
}
