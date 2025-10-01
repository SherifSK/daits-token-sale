# DaitsToken
[Git Source](https://github.com/SherifSK/daits-token-sale/blob/e42eae5e9ecad95437acedaf3cabcb2b6d50542c/src/DaitsToken.sol)

**Inherits:**
ERC20, AccessControl

**Author:**
DAITS Team

ERC20 token with role-based access control for the DAITS ecosystem

*Implementation uses OpenZeppelin's ERC20 and AccessControl for security*

**Note:**
security-contact: security@daits.io


## State Variables
### MINTER_ROLE
Role identifier for addresses allowed to mint tokens


```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```


### PAUSER_ROLE
Role identifier for addresses allowed to pause token operations


```solidity
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```


### MAX_SUPPLY
Maximum supply cap - 0 means unlimited supply, >0 means capped supply

*Set during construction and cannot be changed afterwards*


```solidity
uint256 public immutable MAX_SUPPLY;
```


### multisigWallet
Address of the Safe multisig wallet that controls admin functions

*This address has DEFAULT_ADMIN_ROLE and can manage minter roles*


```solidity
address public multisigWallet;
```


## Functions
### constructor

Creates a new DAITS token with specified parameters

*Sets up ERC20 token with role-based access control and supply cap*

**Notes:**
- requires: initialAdmin must not be zero address

- emits: AdminTransferred, SupplyCapSet


```solidity
constructor(string memory name_, string memory symbol_, address initialAdmin, uint256 maxSupply_)
    ERC20(name_, symbol_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the token (e.g., "DAITS Token")|
|`symbol_`|`string`|The symbol of the token (e.g., "DAITS")|
|`initialAdmin`|`address`|Address that will receive admin role (should be Safe multisig)|
|`maxSupply_`|`uint256`|Maximum supply cap (0 for unlimited, >0 for capped supply)|


### mint

Mints new tokens to the specified address

*Only accounts with MINTER_ROLE can call this function*

**Notes:**
- requires: Caller must have MINTER_ROLE

- requires: to address must not be zero

- requires: amount must be greater than zero

- requires: Must not exceed MAX_SUPPLY if set

- security: CENTRALIZATION RISK MITIGATION:
- MINTER_ROLE granted only to specific contracts (e.g., token sale)
- Admin role controlled by Safe multisig (no single point of failure)
- All minting operations transparent and logged on-chain
- Admin can revoke MINTER_ROLE or renounce admin privileges entirely


```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address that will receive the minted tokens|
|`amount`|`uint256`|The number of tokens to mint (in wei units)|


### grantMinterRole

Grants minter role to the specified address

*Only admin (multisig) can call this function to grant minting privileges*

**Notes:**
- requires: Caller must have DEFAULT_ADMIN_ROLE

- requires: account must not be zero address

- emits: MinterRoleGranted

- security: CENTRALIZATION RISK MITIGATION:
- Admin role controlled by Safe multisig (requires multiple signatures)
- Role grants transparent via events and on-chain visibility
- Admin can be transferred to new multisig or renounced entirely
- Supply cap limits total damage even if role is misused


```solidity
function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address to grant minter role to|


### revokeMinterRole

Revokes minter role from the specified address

*Only admin (multisig) can call this function to remove minting privileges*

**Notes:**
- requires: Caller must have DEFAULT_ADMIN_ROLE

- emits: MinterRoleRevoked

- security: CENTRALIZATION RISK MITIGATION:
- Admin role controlled by Safe multisig (multiple signatures required)
- Role revocations transparent and logged via events
- Provides mechanism to remove compromised minters


```solidity
function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address to revoke minter role from|


### transferAdmin

Transfers admin role to a new multisig address

*Only current admin can call this function to transfer control*

**Notes:**
- requires: Caller must have DEFAULT_ADMIN_ROLE

- requires: newAdmin must not be zero address

- requires: newAdmin must be different from current admin

- emits: AdminTransferred

- security: CENTRALIZATION RISK MITIGATION:
- Enables transition to new governance structure
- Supports upgrading from smaller to larger multisig
- Allows gradual decentralization over time


```solidity
function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAdmin`|`address`|The address of the new admin (should be new Safe multisig)|


### renounceAdminRole

Permanently renounces admin role making the contract immutable

*Emergency function that removes all admin privileges forever*

**Notes:**
- requires: Caller must have DEFAULT_ADMIN_ROLE

- emits: AdminTransferred with newAdmin as zero address

- warning: This action is IRREVERSIBLE and makes contract non-upgradeable

- security: CENTRALIZATION RISK MITIGATION:
- Ultimate decentralization mechanism (complete admin removal)
- Makes contract fully immutable and community-owned
- Eliminates all centralization risks permanently


```solidity
function renounceAdminRole() external onlyRole(DEFAULT_ADMIN_ROLE);
```

## Events
### AdminTransferred
Emitted when admin role is transferred to a new address


```solidity
event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`previousAdmin`|`address`|Address of the previous admin|
|`newAdmin`|`address`|Address of the new admin|

### MinterRoleGranted
Emitted when minter role is granted to an address


```solidity
event MinterRoleGranted(address indexed account, address indexed admin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address that received the minter role|
|`admin`|`address`|Address of the admin who granted the role|

### MinterRoleRevoked
Emitted when minter role is revoked from an address


```solidity
event MinterRoleRevoked(address indexed account, address indexed admin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address that lost the minter role|
|`admin`|`address`|Address of the admin who revoked the role|

### SupplyCapSet
Emitted when the supply cap is set during construction


```solidity
event SupplyCapSet(uint256 maxSupply);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxSupply`|`uint256`|The maximum supply cap (0 for unlimited)|

