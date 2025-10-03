# DaitsToken Storage Layout Analysis

## Current Storage Layout

### Inherited from ERC20:
- Slot 0: `mapping(address => uint256) _balances`
- Slot 1: `mapping(address => mapping(address => uint256)) _allowances` 
- Slot 2: `uint256 _totalSupply`
- Slot 3: `string _name`
- Slot 4: `string _symbol`

### Inherited from AccessControl:
- Slot 5: `mapping(bytes32 => RoleData) _roles`

### DaitsToken Storage:
- Slot 6: `uint256 MAX_SUPPLY` (immutable - not in storage)
- Slot 6: `address multisigWallet` (20 bytes)

## Optimization Opportunities

### 1. Storage Packing Potential
Current usage:
- Slot 6: `address multisigWallet` (20 bytes) + 12 bytes unused

### 2. Additional State Variables for Optimization
We can add complementary variables that pack well with existing ones:

1. **Token metadata flags** (booleans - 1 byte each)
2. **Numeric counters** (uint32, uint64, uint96)
3. **Timestamps** (uint32 for timestamps until 2106)

### 3. Proposed Optimizations

#### Option A: Add useful state variables that pack with multisigWallet
- `bool public isPaused` (1 byte)
- `bool public transfersEnabled` (1 byte) 
- `uint32 public deploymentTimestamp` (4 bytes)
- `uint32 public lastAdminTransfer` (4 bytes)
- `uint32 public totalMinterCount` (4 bytes)
- Total: 20 + 1 + 1 + 4 + 4 + 4 = 34 bytes (fits in 2 slots)

#### Option B: Optimize with commonly used patterns
- Pack address with timestamp for admin transfer cooldown
- Pack address with boolean flags for operational states
- Add version number for contract versioning

## Gas Impact Estimation
- Reading packed variables: Same gas cost (still SLOAD)
- Setting multiple packed variables: Potential gas increase (SSTORE with masking)
- Net benefit: Depends on usage patterns

## Recommendation
Focus on adding useful functionality that naturally packs well, rather than artificial packing.