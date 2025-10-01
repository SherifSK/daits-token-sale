# DAITS Token Sale

A secure ERC20 token implementation with Safe multisig governance for the DAITS project, built with Foundry.

## 🌟 Features

- **ERC20 Compliant**: Standard token functionality with minting capabilities
- **Safe Multisig Governance**: All admin functions require multisig approval
- **Role-Based Access Control**: Separate roles for administration and minting
- **Transparent Operations**: All admin actions emit events for monitoring
- **Gradual Decentralization**: Admin role can be transferred or renounced
- **Enhanced Security**: Input validation and comprehensive error handling

## 🏗️ Architecture

### Smart Contracts

- **`DaitsToken.sol`**: Main ERC20 token contract with governance features
- **`DeployDaitsToken.s.sol`**: Foundry deployment script

### Key Components

1. **Access Control Roles**:
   - `DEFAULT_ADMIN_ROLE`: Can manage all roles and admin functions (Safe multisig)
   - `MINTER_ROLE`: Can mint new tokens (token sale contract)

2. **Security Features**:
   - Multisig-controlled admin functions
   - Zero address validation
   - Amount validation on minting
   - Event emission for transparency

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)
- A deployed [Safe multisig wallet](https://safe.global/)

### Installation

```bash
git clone https://github.com/SherifSK/daits-token-sale.git
cd daits-token-sale
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

## 🔧 Deployment

### 1. Configuration Requirements

#### Create Environment File

**IMPORTANT**: You must create a `.env` file before deployment. Copy the example and fill in your values:

```bash
cp .env.example .env
```

#### Required Configuration Variables

Edit your `.env` file with these **mandatory** values:

```bash
# REQUIRED - Deployment will fail without these
MULTISIG_ADMIN_ADDRESS=0x1234567890123456789012345678901234567890  # Your Safe multisig address
PRIVATE_KEY=0xabc123...  # Deployer private key (64 hex characters)
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID  # RPC endpoint for your target network

# REQUIRED for contract verification
ETHERSCAN_API_KEY=ABC123DEF456...  # Your Etherscan API key
```

#### Optional Configuration Variables

```bash
# Optional - defaults will be used if not specified
TOKEN_NAME="DAITS Token"           # Default: "DAITS Token"
TOKEN_SYMBOL="DAITS"              # Default: "DAITS"
```

#### Configuration Validation

The deployment script validates all required configurations:

- ✅ **MULTISIG_ADMIN_ADDRESS**: Must be a valid Ethereum address (not zero address)
- ✅ **PRIVATE_KEY**: Must be a valid private key with sufficient ETH for gas
- ✅ **RPC_URL**: Must be accessible and point to correct network
- ❌ **Missing .env**: Deployment will fail if `.env` file doesn't exist

#### Security Notes for Configuration

⚠️ **CRITICAL SECURITY REQUIREMENTS**:

1. **Never commit `.env` to git** - it contains sensitive private keys
2. **Use different keys** for testnet vs mainnet deployments  
3. **Verify multisig address** - double-check it's your actual Safe wallet
4. **Test on testnet first** - always deploy to Sepolia before mainnet
5. **Backup your configuration** - keep secure copies of keys and addresses

### 2. Deploy to Testnet

```bash
# Deploy to Sepolia testnet
forge script script/DeployDaitsToken.s.sol:DeployDaitsToken \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### 3. Deploy to Mainnet

```bash
# Deploy to Ethereum mainnet
forge script script/DeployDaitsToken.s.sol:DeployDaitsToken \
    --rpc-url $MAINNET_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### 4. Verify Deployment

The deployment script will automatically verify:
- Token name and symbol
- Admin role assignment
- Multisig wallet configuration
- Initial token supply (should be 0)

## 🔐 Security Model

### Multisig Integration

The DAITS token uses a **Safe multisig wallet** for all administrative functions, providing these security benefits:

- **No Single Point of Failure**: Requires multiple signatures for admin actions
- **Transparent Governance**: All transactions are visible on-chain
- **Configurable Threshold**: Set up N-of-M signature requirements
- **Time-delay Options**: Can add timelock for additional security

### Recommended Multisig Setup

For production deployment:

1. **Create Safe Multisig**: Deploy a Safe wallet with appropriate signers
2. **Set Threshold**: Recommend 3-of-5 or 2-of-3 minimum
3. **Add Signers**: Include trusted team members and advisors
4. **Test Operations**: Verify multisig functionality before mainnet

### Admin Functions (Multisig Only)

- `grantMinterRole(address)`: Grant minting privileges to addresses
- `revokeMinterRole(address)`: Revoke minting privileges
- `transferAdmin(address)`: Transfer admin role to new multisig
- `renounceAdminRole()`: Permanently renounce admin privileges

## 📋 Post-Deployment Checklist

### Immediate Steps

- [ ] Verify contract on Etherscan
- [ ] Test admin functions via Safe multisig
- [ ] Grant `MINTER_ROLE` to token sale contract
- [ ] Test minting functionality
- [ ] Set up monitoring for admin events

### Token Sale Integration

1. Deploy token sale contract
2. Grant `MINTER_ROLE` to sale contract via multisig
3. Configure sale parameters
4. Test end-to-end token purchase flow

### Monitoring Setup

Monitor these events for transparency:
- `AdminTransferred`: Admin role changes
- `MinterRoleGranted`: New minters added  
- `MinterRoleRevoked`: Minters removed
- `Transfer`: Token transfers (including mints)

## 🧪 Testing

### Run All Tests

```bash
forge test -vv
```

### Run Specific Test

```bash
forge test --match-test testMinting -vv
```

### Coverage Report

```bash
forge coverage
```

## 📁 Project Structure

```
daits-token-sale/
├── src/
│   └── daitsToken.sol          # Main token contract
├── script/
│   └── DeployDaitsToken.s.sol  # Deployment script
├── test/
│   └── DaitsToken.t.sol        # Test suite
├── lib/                        # Dependencies
├── foundry.toml               # Foundry configuration
└── README.md                  # This file
```

## 🔧 Configuration

### Foundry Configuration (`foundry.toml`)

The project is configured for maximum compatibility:

- **Solidity Version**: 0.8.30 (specified)
- **EVM Version**: London (avoids PUSH0 opcode issues)
- **Remappings**: OpenZeppelin contracts mapped correctly

### Network Compatibility

The token is compatible with:
- Ethereum Mainnet
- All major L2s (Arbitrum, Optimism, Polygon)
- Testnets (Sepolia, Goerli)

## 🚨 Security Considerations

### Centralization Risk Mitigation

The contract addresses centralization risks through:

1. **Multisig Governance**: No single admin key
2. **Role Separation**: Admin and minter roles are separate
3. **Transparency**: All actions are logged via events
4. **Renunciation Option**: Admin can permanently give up control

### Best Practices Implemented

- ✅ Specific Solidity pragma (no version ranges)
- ✅ Named imports for clarity
- ✅ Input validation on all functions
- ✅ Zero address checks
- ✅ Comprehensive event emission
- ✅ Clear function documentation
- ✅ London EVM compatibility

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔧 Troubleshooting

### Common Configuration Issues

#### "MULTISIG_ADMIN_ADDRESS must be set" Error

```bash
# Problem: Missing or invalid multisig address
# Solution: Check your .env file has the correct address
MULTISIG_ADMIN_ADDRESS=0x1234567890123456789012345678901234567890
```

#### "failed to get gas price" Error

```bash
# Problem: Invalid or inaccessible RPC URL
# Solution: Verify your RPC endpoint is correct and accessible
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
```

#### "insufficient funds for gas" Error

```bash
# Problem: Deployer account has insufficient ETH
# Solution: Fund your deployer address with ETH for gas fees
# Testnet: Get free ETH from Sepolia faucet
# Mainnet: Ensure sufficient ETH balance
```

#### Contract Verification Failed

```bash
# Problem: Invalid Etherscan API key or network mismatch
# Solution: Check your API key and ensure it matches the deployment network
ETHERSCAN_API_KEY=ABC123DEF456...  # Must be valid for the target network
```

### Configuration File Checklist

Before deploying, verify your `.env` file:

- [ ] `.env` file exists (copied from `.env.example`)
- [ ] `MULTISIG_ADMIN_ADDRESS` is set to your Safe wallet address
- [ ] `PRIVATE_KEY` is valid and has sufficient ETH balance
- [ ] `RPC_URL` points to correct network (testnet vs mainnet)
- [ ] `ETHERSCAN_API_KEY` is valid for contract verification
- [ ] File permissions are secure (`chmod 600 .env`)

### Deployment Validation

The script performs these checks automatically:

1. **Environment Variables**: All required variables are present
2. **Address Validation**: Multisig address is valid Ethereum address
3. **Contract Deployment**: Token deploys successfully
4. **Role Assignment**: Admin role granted to multisig correctly
5. **Initial State**: Token starts with zero supply

## 🆘 Support

For questions and support:

- Create an [issue](https://github.com/SherifSK/daits-token-sale/issues)
- Contact the development team
- Check [Foundry documentation](https://book.getfoundry.sh/)
- Review [Safe multisig documentation](https://docs.safe.global/)

## 🔗 Links

- [Safe Multisig](https://safe.global/)
- [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)
- [Foundry Framework](https://book.getfoundry.sh/)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)
