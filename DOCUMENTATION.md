# DAITS Token Documentation

## Overview

The DAITS Token (DaitsToken.sol) is a secure ERC20 implementation with role-based access control, designed for the DAITS ecosystem. This documentation is auto-generated from NatSpec comments in the contract.

**Contract Address**: *To be deployed*  
**Author**: DAITS Team  
**License**: MIT  
**Solidity Version**: 0.8.30  

## Contract Architecture

The contract inherits from OpenZeppelin's `ERC20` and `AccessControl` contracts, providing:

- Standard ERC20 token functionality
- Role-based access control system  
- Safe multisig governance integration
- Supply cap enforcement
- Transparent admin operations

## State Variables

### Constants

#### MINTER_ROLE
```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```
**Purpose**: Role identifier for addresses allowed to mint tokens  
**Usage**: Granted to token sale contracts and other authorized minting mechanisms

#### PAUSER_ROLE  
```solidity
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```
**Purpose**: Role identifier for addresses allowed to pause token operations  
**Note**: Currently defined but not implemented in contract logic

### Immutable Variables

#### MAX_SUPPLY
```solidity
uint256 public immutable MAX_SUPPLY;
```
**Purpose**: Maximum supply cap for tokens  
**Behavior**:
- `0` = Unlimited supply
- `>0` = Capped supply at specified amount  
**Set**: During construction and cannot be changed afterwards

### State Variables

#### multisigWallet
```solidity
address public multisigWallet;
```
**Purpose**: Address of the Safe multisig wallet controlling admin functions  
**Permissions**: Has `DEFAULT_ADMIN_ROLE` and can manage all roles  
**Security**: Should always be a multisig wallet, never an EOA

## Functions

### Constructor

```solidity
constructor(
    string memory name_, 
    string memory symbol_, 
    address initialAdmin, 
    uint256 maxSupply_
)
```

**Purpose**: Creates a new DAITS token with specified parameters  
**Access**: Public (deployment only)

**Parameters**:
- `name_`: Token name (e.g., "DAITS Token")
- `symbol_`: Token symbol (e.g., "DAITS")  
- `initialAdmin`: Address receiving admin role (must be Safe multisig)
- `maxSupply_`: Supply cap (0 for unlimited, >0 for capped)

**Requirements**:
- `initialAdmin` must not be zero address

**Events Emitted**:
- `AdminTransferred(address(0), initialAdmin)`
- `SupplyCapSet(maxSupply_)`

**Security Notes**:
- Validates initial admin address
- Sets immutable supply cap
- Grants admin role to multisig wallet

### Core Functions

#### mint()
```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE)
```

**Purpose**: Mints new tokens to specified address  
**Access**: Only accounts with `MINTER_ROLE`

**Parameters**:
- `to`: Recipient address for minted tokens
- `amount`: Number of tokens to mint (in wei units)

**Requirements**:
- Caller must have `MINTER_ROLE`
- `to` address must not be zero
- `amount` must be greater than zero  
- Must not exceed `MAX_SUPPLY` if set

**Security Features**:
- Role-based access control
- Zero address validation
- Amount validation
- Supply cap enforcement
- Transparent on-chain logging

**Centralization Risk Mitigation**:
- `MINTER_ROLE` granted only to specific contracts
- Admin role controlled by Safe multisig
- All operations transparent and logged
- Admin can revoke roles or renounce privileges

### Admin Functions (Multisig Only)

#### grantMinterRole()
```solidity
function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE)
```

**Purpose**: Grants minter role to specified address  
**Access**: Only admin (multisig)

**Parameters**:
- `account`: Address to grant minter role to

**Requirements**:
- Caller must have `DEFAULT_ADMIN_ROLE`
- `account` must not be zero address

**Events Emitted**:
- `MinterRoleGranted(account, msg.sender)`

**Security Features**:
- Multisig-controlled access
- Zero address validation
- Transparent event logging

#### revokeMinterRole()
```solidity
function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE)
```

**Purpose**: Revokes minter role from specified address  
**Access**: Only admin (multisig)

**Parameters**:
- `account`: Address to revoke minter role from

**Requirements**:
- Caller must have `DEFAULT_ADMIN_ROLE`

**Events Emitted**:
- `MinterRoleRevoked(account, msg.sender)`

**Security Features**:
- Emergency mechanism to remove compromised minters
- Multisig approval required
- Transparent logging

#### transferAdmin()
```solidity
function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE)
```

**Purpose**: Transfers admin role to new multisig address  
**Access**: Only current admin

**Parameters**:
- `newAdmin`: Address of new admin (should be new Safe multisig)

**Requirements**:
- Caller must have `DEFAULT_ADMIN_ROLE`
- `newAdmin` must not be zero address
- `newAdmin` must differ from current admin

**Events Emitted**:
- `AdminTransferred(oldAdmin, newAdmin)`

**Process**:
1. **Checks**: Validates new admin address
2. **Effects**: Updates `multisigWallet` state variable
3. **Interactions**: Revokes old admin role, grants new admin role

**Security Features**:
- Enables governance transitions
- Supports multisig upgrades
- Allows gradual decentralization
- Follows Checks-Effects-Interactions pattern

#### renounceAdminRole()
```solidity
function renounceAdminRole() external onlyRole(DEFAULT_ADMIN_ROLE)
```

**Purpose**: Permanently renounces admin role making contract immutable  
**Access**: Only current admin

**Requirements**:
- Caller must have `DEFAULT_ADMIN_ROLE`

**Events Emitted**:
- `AdminTransferred(currentAdmin, address(0))`

**⚠️ WARNING**: This action is **IRREVERSIBLE**
- Makes contract fully immutable
- Eliminates all admin capabilities
- No future role management possible
- Ultimate decentralization mechanism

## Events

### AdminTransferred
```solidity
event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
```
**Emitted When**: Admin role is transferred or renounced  
**Parameters**:
- `previousAdmin`: Address of previous admin
- `newAdmin`: Address of new admin (or zero for renouncement)

### MinterRoleGranted
```solidity
event MinterRoleGranted(address indexed account, address indexed admin);
```
**Emitted When**: Minter role is granted to an address  
**Parameters**:
- `account`: Address receiving minter role
- `admin`: Address of admin who granted the role

### MinterRoleRevoked
```solidity
event MinterRoleRevoked(address indexed account, address indexed admin);
```
**Emitted When**: Minter role is revoked from an address  
**Parameters**:
- `account`: Address losing minter role
- `admin`: Address of admin who revoked the role

### SupplyCapSet
```solidity
event SupplyCapSet(uint256 maxSupply);
```
**Emitted When**: Supply cap is set during construction  
**Parameters**:
- `maxSupply`: Maximum supply cap (0 for unlimited)

## Security Model

### Role-Based Access Control

The contract implements a hierarchical role system:

1. **DEFAULT_ADMIN_ROLE** (Multisig Wallet)
   - Can grant/revoke `MINTER_ROLE`
   - Can transfer admin role
   - Can permanently renounce admin privileges
   - Should always be a Safe multisig wallet

2. **MINTER_ROLE** (Token Sale Contracts)
   - Can mint new tokens up to supply cap
   - Granted by admin to authorized contracts
   - Can be revoked by admin if compromised

### Centralization Risk Mitigation

The contract addresses centralization concerns through:

#### Multi-Signature Governance
- Admin functions require multisig approval
- No single point of failure
- Transparent on-chain governance

#### Role Separation
- Admin and minter roles are distinct
- Limits blast radius of compromised keys
- Enables granular permission management

#### Transparency Mechanisms
- All admin actions emit events
- On-chain audit trail
- Public monitoring capabilities

#### Decentralization Path
- Admin role can be transferred
- Ultimate renouncement option
- Gradual community ownership transition

#### Supply Cap Protection
- Immutable maximum supply
- Limits damage from role misuse
- Protects token economics

### Security Best Practices Implemented

#### Input Validation
- Zero address checks on all functions
- Amount validation for minting
- Role existence verification

#### Checks-Effects-Interactions Pattern
- All functions follow CEI pattern
- State changes before external calls
- Reentrancy protection

#### Event Emission
- Comprehensive event logging
- Transparent state changes
- Monitoring and alerting capabilities

#### Access Control
- OpenZeppelin AccessControl integration
- Battle-tested role management
- Modifier-based protection

## Integration Guide

### Token Sale Integration

1. **Deploy Token Contract**
   ```solidity
   DaitsToken token = new DaitsToken(
       "DAITS Token",
       "DAITS", 
       multisigAddress,
       maxSupply
   );
   ```

2. **Deploy Token Sale Contract**
   ```solidity
   TokenSale sale = new TokenSale(
       address(token),
       pricePerToken,
       saleStartTime,
       saleEndTime
   );
   ```

3. **Grant Minter Role** (via Multisig)
   ```solidity
   token.grantMinterRole(address(sale));
   ```

4. **Configure Sale Parameters**
   ```solidity
   sale.configureSale(parameters);
   ```

### Monitoring Setup

Monitor these events for operational transparency:

- `AdminTransferred`: Admin role changes
- `MinterRoleGranted`: New minters added
- `MinterRoleRevoked`: Minters removed  
- `Transfer`: Token transfers (including mints)
- `SupplyCapSet`: Supply cap configuration

### Multisig Operational Procedures

1. **Role Management**
   - Use Safe multisig for all admin functions
   - Require minimum 3-of-5 signatures
   - Document all transactions

2. **Emergency Procedures**
   - Revoke compromised minter roles immediately
   - Transfer admin to new multisig if needed
   - Consider renouncement for full decentralization

3. **Regular Operations**
   - Review minter role assignments monthly
   - Monitor token supply vs cap
   - Audit admin transaction history

## Technical Specifications

### Compiler Configuration
- **Solidity Version**: 0.8.30 (exact version)
- **EVM Version**: London (PUSH0 compatibility)
- **Optimization**: Enabled for gas efficiency
- **License**: MIT

### Dependencies
- **OpenZeppelin ERC20**: v4.9.0+
- **OpenZeppelin AccessControl**: v4.9.0+
- **Foundry Framework**: Latest stable

### Gas Usage Estimates
- **Deployment**: ~1,500,000 gas
- **Minting**: ~70,000 gas per mint
- **Role Management**: ~50,000 gas per operation
- **Admin Transfer**: ~100,000 gas

### Network Compatibility
- Ethereum Mainnet ✅
- Ethereum Testnets (Sepolia, Goerli) ✅  
- Layer 2 Networks (Arbitrum, Optimism, Polygon) ✅
- EVM Compatible Chains ✅

## Audit Considerations

### Security Review Checklist

#### Access Control
- [ ] Admin role properly protected by multisig
- [ ] Role hierarchy correctly implemented
- [ ] No privilege escalation vulnerabilities

#### Minting Logic  
- [ ] Supply cap enforcement works correctly
- [ ] Zero address validation prevents token loss
- [ ] Amount validation prevents zero mints

#### State Management
- [ ] CEI pattern followed in all functions
- [ ] No reentrancy vulnerabilities
- [ ] State transitions are atomic

#### Event Emission
- [ ] All state changes emit appropriate events
- [ ] Event parameters are correctly indexed
- [ ] No sensitive information leaked in events

### Common Vulnerability Patterns Avoided

- **Reentrancy**: CEI pattern implementation
- **Integer Overflow**: Solidity 0.8+ built-in protection
- **Access Control**: OpenZeppelin battle-tested implementation
- **Zero Address**: Comprehensive validation
- **Role Confusion**: Clear role separation and documentation

## Deployment Checklist

### Pre-Deployment
- [ ] Set up Safe multisig wallet with appropriate signers
- [ ] Configure multisig threshold (recommend 3-of-5 minimum)
- [ ] Test deployment on testnet
- [ ] Verify contract source code

### Deployment
- [ ] Deploy with correct constructor parameters
- [ ] Verify admin role assigned to multisig
- [ ] Confirm initial supply is zero
- [ ] Validate supply cap configuration

### Post-Deployment
- [ ] Verify contract on Etherscan
- [ ] Test admin functions via multisig
- [ ] Set up event monitoring
- [ ] Document deployed addresses
- [ ] Grant minter roles as needed

### Production Readiness
- [ ] All tests passing (77+ test cases)
- [ ] Security audit completed
- [ ] Documentation reviewed
- [ ] Monitoring systems active
- [ ] Emergency procedures documented

## Conclusion

The DAITS Token contract provides a secure, well-documented implementation of an ERC20 token with role-based governance. The comprehensive NatSpec documentation ensures transparency and maintainability, while the security model addresses centralization concerns through multisig governance and transparent operations.

Key strengths:
- **Security**: Role-based access control with multisig governance
- **Transparency**: Comprehensive event emission and documentation
- **Flexibility**: Supply cap configuration and role management
- **Decentralization Path**: Admin renouncement for community ownership

The contract is production-ready with extensive testing, security considerations, and clear operational procedures.

---

*This documentation was generated from NatSpec comments in DaitsToken.sol*  
*Last Updated: October 1, 2025*  
*Contract Version: Latest*