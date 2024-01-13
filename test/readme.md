
# 2. Test Cases:

## 2.1 Test Flow (`testMultiSig`):

1. **Setup:**
   - The `setUp` function initializes a `multiSig` wallet with four owners and a minimum confirmation requirement of 3.

2. **Successful Transaction:**
   - The `testMultiSig` function simulates a successful transaction flow.
   - The multiSigWallet contract is funded with 10 Ether.
   - Address 10 initiates a transaction to transfer 1 Ether to address 4.
   - Address 10 confirms the transaction.
   - Two other administrators (addresses 11 and 12) also confirm the transaction.
   - Address 12, one of the admins, executes the transaction.
   - 1 Ether successfully transfers from the contract.

### 2.2 Unsuccessful Conditions (`testUnsuccessfulConditions`):

1. **TEST 1: Confirming Transaction by Non-Admin:**
   - Confirms that attempting to confirm a transaction by a non-admin address (address 100) reverts with the message "not called by either of owners."

2. **TEST 2: Execute Transaction Before Minimum Confirmations:**
   - Ensures that attempting to execute a transaction before obtaining the minimum required confirmations reverts with the message "txn not got enough confirmations."

3. **TEST 3: Confirming Transaction After Expiry:**
   - Verifies that attempting to confirm a transaction after its expiry reverts with the message "transaction is being expired."

4. **TEST 4: Execute Transaction After Expiry:**
   - Validates that attempting to execute a transaction after its expiry reverts with the message "transaction is being expired."

