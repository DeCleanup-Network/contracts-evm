# Error Codes Documentation

This document provides an overview of the standardized error codes used throughout the smart contracts in the DeCleanup Network project.

## Error Code Format

Error codes follow a standardized format:

```
CONTRACT__ErrorType(parameters)
```

Where:
- `CONTRACT` is a prefix indicating which contract the error originated from (e.g., `NFT`, `REWARD`, `TOKEN`)
- `ErrorType` is a descriptive name of the error
- `parameters` are optional values providing context to the error

## Benefits Over String Errors

1. **Gas Efficiency**: Custom errors consume less gas than string-based error messages
2. **Structured Data**: Errors can include parameters to provide context
3. **Better Parsing**: Frontends can easily parse and display meaningful error messages
4. **Consistency**: Standardized naming makes the codebase more maintainable

## Error Codes by Contract

### DipNft Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `NFT__TokenNotExists` | The specified token ID does not exist | `tokenId`: The queried token ID |
| `NFT__NotVerifiedPOI` | User is not verified as a POI | `user`: The user's address |
| `NFT__RewardsContractNotSet` | The rewards contract address is not set | None |
| `NFT__TransferRestricted` | NFT transfer is restricted (soulbound token) | `tokenId`: The token ID someone tried to transfer |
| `NFT__InvalidRewardsContract` | Invalid rewards contract address (zero address) | `contractAddress`: The invalid address |
| `NFT__InvalidAddress` | Invalid address (typically zero address) | `invalidAddress`: The invalid address |
| `NFT__AlreadyMinted` | User has already minted an NFT | `user`: The user's address |
| `NFT__NotTokenOwner` | User is not the owner of the token | `user`: The user's address, `tokenId`: The token ID, `owner`: The actual owner |
| `NFT__MaxLevelReached` | Token has reached the maximum level | `tokenId`: The token ID, `currentLevel`: The current level, `maxLevel`: The maximum level |
| `NFT__InvalidLevelRange` | Level is outside the valid range | `level`: The provided level, `maxLevel`: The maximum level |
| `NFT__UserHasNoNFT` | User has not minted an NFT | `user`: The user's address |
| `NFT__TransferNotAuthorized` | Transfer is not authorized for the token | `tokenId`: The token ID |

### DCURewardManager Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `REWARD__InvalidLevel` | Level is outside the valid range | `level`: The provided level, `maxLevel`: The maximum level |
| `REWARD__InvalidAddress` | Invalid address (typically zero address) | `invalidAddress`: The invalid address |
| `REWARD__PoiNotVerified` | User's POI is not verified | `user`: The user's address |
| `REWARD__LevelAlreadyClaimed` | Level has already been claimed by the user | `user`: The user's address, `level`: The level that was claimed |
| `REWARD__SelfReferralNotAllowed` | Self-referral is not allowed | `user`: The user's address |
| `REWARD__ReferralAlreadyRegistered` | Referral relationship already exists | `invitee`: The invitee address, `existingReferrer`: The existing referrer |
| `REWARD__InsufficientBalance` | User has insufficient balance for the operation | `user`: The user's address, `amount`: The requested amount, `balance`: The actual balance |
| `REWARD__ZeroAmount` | Zero amount provided where non-zero is required | None |
| `REWARD__ExcessiveRewardAmount` | Reward amount exceeds the maximum allowed | `amount`: The requested amount, `maxAmount`: The maximum allowed amount |
| `REWARD__RewardDistributionFailed` | Failed to distribute rewards | `to`: The recipient address, `amount`: The reward amount |

### DCUToken Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `TOKEN__InvalidRewardLogicAddress` | Invalid reward logic contract address | `invalidAddress`: The invalid address |
| `TOKEN__OnlyRewardLogicCanMint` | Only the reward logic contract can mint tokens | `caller`: The caller's address, `rewardLogic`: The reward logic contract address |
| `TOKEN__SupplyCapExceeded` | Attempted mint would exceed the supply cap | `attemptedSupply`: The attempted total supply, `supplyCap`: The maximum allowed supply |
| `TOKEN__CapTooLow` | Requested supply cap is lower than current supply | `requestedCap`: The requested cap value, `currentSupply`: The current token supply |

### DCUAccounting Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `ACCOUNTING__ReentrancyDetected` | Reentrancy detected during an operation | None |
| `ACCOUNTING__TransfersRestrictedBeforeTGE` | Transfers are restricted before TGE completion | `account`: The restricted account |
| `ACCOUNTING__ZeroAmount` | Zero amount provided where non-zero is required | None |
| `ACCOUNTING__InvalidAddress` | Invalid address (typically zero address) | None |
| `ACCOUNTING__InsufficientBalance` | User has insufficient balance for the operation | `user`: The user's address, `amount`: The requested amount, `balance`: The actual balance |
| `ACCOUNTING__TransferFailed` | Token transfer failed | None |
| `ACCOUNTING__AddressNotWhitelisted` | Address is not on the whitelist | `account`: The non-whitelisted account |
| `ACCOUNTING__NoTokensToWithdraw` | No tokens available for withdrawal | None |

### DCUStorage Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `STORAGE__TransfersRestrictedBeforeTGE` | Transfers are restricted before TGE completion | `account`: The restricted account |
| `STORAGE__InvalidAddress` | Invalid address (typically zero address) | None |
| `STORAGE__AddressNotWhitelisted` | Address is not on the whitelist | `account`: The non-whitelisted account |
| `STORAGE__ZeroAmount` | Zero amount provided where non-zero is required | None |
| `STORAGE__ZeroDuration` | Zero duration provided where non-zero is required | None |
| `STORAGE__InsufficientBalance` | User has insufficient balance for the operation | `user`: The user's address, `amount`: The requested amount, `balance`: The actual balance |
| `STORAGE__InsufficientClaimableBalance` | User has insufficient claimable balance | `user`: The user's address, `amount`: The requested amount, `balance`: The actual claimable balance |
| `STORAGE__InsufficientStakedBalance` | User has insufficient staked balance | `user`: The user's address, `amount`: The requested amount, `balance`: The actual staked balance |
| `STORAGE__NoLockedTokens` | User has no locked tokens | `user`: The user's address |
| `STORAGE__TokensStillLocked` | Tokens are still locked and cannot be unlocked yet | `user`: The user's address, `releaseTime`: The token release time, `currentTime`: The current block timestamp |

### Lock Contract Errors

| Error Code | Description | Parameters |
|------------|-------------|------------|
| `LOCK__UnlockTimeNotInFuture` | Unlock time must be in the future | `requestedTime`: The requested unlock time, `currentTime`: The current block timestamp |
| `LOCK__WithdrawalTooEarly` | Withdrawal attempted before unlock time | `unlockTime`: The unlock time, `currentTime`: The current block timestamp |
| `LOCK__NotOwner` | Caller is not the owner of the lock | `caller`: The caller's address, `owner`: The owner's address |

## Example Usage in Contract Code

### 1. Defining Custom Errors

```solidity
// At the top of the contract
error NFT__TokenNotExists(uint256 tokenId);
error NFT__NotVerifiedPOI(address user);
```

### 2. Using Custom Errors in Functions

```solidity
function upgradeNFT(uint256 tokenId) external onlyVerifiedPOI nonReentrant validTokenId(tokenId) {
    if (!hasMinted[msg.sender]) revert NFT__UserHasNoNFT(msg.sender);
    
    if (!_isAuthorized(_ownerOf(tokenId), msg.sender, tokenId))
        revert NFT__NotTokenOwner(msg.sender, tokenId, _ownerOf(tokenId));
        
    if (nftLevel[tokenId] >= MAX_LEVEL)
        revert NFT__MaxLevelReached(tokenId, nftLevel[tokenId], MAX_LEVEL);

    // Function logic continues...
}
```

## Handling Custom Errors in Frontend Applications

Frontend applications can catch and interpret these custom errors to provide meaningful user messages:

```javascript
try {
    await contract.upgradeNFT(tokenId);
} catch (error) {
    if (error.code === 'NFT__MaxLevelReached') {
        const { tokenId, currentLevel, maxLevel } = error.errorArgs;
        showUserMessage(`NFT #${tokenId} has already reached the maximum level (${maxLevel})`);
    } else if (error.code === 'NFT__NotTokenOwner') {
        showUserMessage('You do not own this NFT');
    } else {
        showUserMessage('An error occurred');
    }
}
```

## Error Handling Best Practices

1. Always use custom errors instead of string-based require statements for gas efficiency
2. Include relevant parameters in errors to provide context
3. Follow the naming convention `CONTRACT__ErrorType` for all custom errors
4. Document all error codes for developers and frontend teams 