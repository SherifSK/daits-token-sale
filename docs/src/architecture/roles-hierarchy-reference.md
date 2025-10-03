# DaitsToken Roles Hierarchy & Quick Reference

## 🏗️ **Role Hierarchy Diagram**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            DEFAULT_ADMIN_ROLE                                  │
│                          (Supreme Authority)                                   │
│                         ┌─────────────────────┐                               │
│                         │    multisigWallet   │                               │
│                         │   (Safe Multisig)   │                               │
│                         └─────────────────────┘                               │
│                                     │                                         │
│  ┌──────────────────────────────────┼──────────────────────────────────────┐  │
│  │              GRANTS & REVOKES    │    EMERGENCY OVERRIDE                │  │
│  │                                  │                                      │  │
│  │  • grantMinterRole()             │  • pauseMinting()                    │  │
│  │  • revokeMinterRole()            │  • unpauseMinting()                  │  │
│  │  • grantPauserRole()             │  • transferAdmin()                   │  │
│  │  • revokePauserRole()            │  • renounceAdminRole()               │  │
│  └──────────────────────────────────┼──────────────────────────────────────┘  │
└─────────────────────────────────────┼─────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
          ┌─────────────────────┐              ┌─────────────────────┐
          │     MINTER_ROLE     │              │    PAUSER_ROLE      │
          │    (Operations)     │              │   (Emergency)       │
          │                     │              │                     │
          │ ┌─────────────────┐ │              │ ┌─────────────────┐ │
          │ │  Token Sale     │ │              │ │ Security Team   │ │
          │ │  Contract       │ │              │ │   Members       │ │
          │ └─────────────────┘ │              │ └─────────────────┘ │
          │ ┌─────────────────┐ │              │ ┌─────────────────┐ │
          │ │  Staking        │ │              │ │ DevOps Team     │ │
          │ │  Rewards        │ │              │ │  Coverage       │ │
          │ └─────────────────┘ │              │ └─────────────────┘ │
          │ ┌─────────────────┐ │              │ ┌─────────────────┐ │
          │ │  Treasury       │ │              │ │ Community       │ │
          │ │ Management      │ │              │ │ Guardians       │ │
          │ └─────────────────┘ │              │ └─────────────────┘ │
          └─────────────────────┘              └─────────────────────┘
                    │                                   │
                    ▼                                   ▼
          ┌─────────────────────┐              ┌─────────────────────┐
          │    CAPABILITIES     │              │   CAPABILITIES      │
          │                     │              │                     │
          │ • mint(to, amount)  │              │ • pauseMinting()    │
          │ • Respect supply    │              │ • unpauseMinting()  │
          │   caps & pauses     │              │ • Emergency         │
          │ • ~68k gas cost     │              │   response          │
          │                     │              │ • ~40k gas cost     │
          └─────────────────────┘              └─────────────────────┘
```

## 📊 **Role Comparison Matrix**

| Aspect            | DEFAULT_ADMIN_ROLE    | MINTER_ROLE      | PAUSER_ROLE          |
| ----------------- | --------------------- | ---------------- | -------------------- |
| **Purpose**       | Strategic Governance  | Token Operations | Emergency Response   |
| **Scope**         | Contract-wide Control | Minting Only     | Pause/Unpause Only   |
| **Holder**        | Safe Multisig         | Smart Contracts  | Security Teams       |
| **Count**         | Single (transferable) | Multiple Allowed | Multiple Recommended |
| **Gas Cost**      | 23k-60k per operation | ~68k per mint    | ~40k per pause       |
| **Criticality**   | Supreme Authority     | Economic Engine  | Safety Circuit       |
| **Risk Level**    | Highest               | Medium           | Low                  |
| **Recovery Time** | 24hr cooldown         | Immediate        | Immediate            |

## 🔑 **Key Permissions Summary**

### **DEFAULT_ADMIN_ROLE Can:**
- ✅ Grant/revoke MINTER_ROLE
- ✅ Grant/revoke PAUSER_ROLE  
- ✅ Pause/unpause minting (emergency override)
- ✅ Transfer admin to new address (24hr cooldown)
- ✅ Renounce admin role permanently (irreversible)

### **MINTER_ROLE Can:**
- ✅ Mint tokens to any address
- ❌ Cannot mint to zero address
- ❌ Cannot mint zero amounts
- ❌ Cannot exceed supply cap (if set)
- ❌ Cannot mint when paused

### **PAUSER_ROLE Can:**
- ✅ Pause all minting operations
- ✅ Unpause minting operations
- ❌ Cannot grant/revoke roles
- ❌ Cannot mint tokens
- ❌ Cannot transfer admin rights

## 🚨 **Emergency Response Chain**

```
[Threat Detected] 
       │
       ▼
[PAUSER responds] ──────────► pauseMinting() (40k gas, <30 seconds)
       │
       ▼
[ADMIN investigates] ───────► Root cause analysis
       │
       ▼
[ADMIN remediates] ─────────► revokeMinterRole() (if needed)
       │
       ▼
[PAUSER recovers] ──────────► unpauseMinting() (30k gas)
```

## 🎯 **Role Assignment Best Practices**

### **Admin Role (DEFAULT_ADMIN_ROLE)**
```solidity
// ✅ RECOMMENDED: Use Safe multisig
address multisig = 0x...; // 3/5 or 5/7 configuration
DaitsToken token = new DaitsToken("DAITS", "DAITS", multisig, 1000000e18);
```

### **Minter Role Assignment**
```solidity
// ✅ RECOMMENDED: Contract-based minters
token.grantMinterRole(tokenSaleContract);
token.grantMinterRole(stakingRewardsContract);
token.grantMinterRole(treasuryContract);

// ❌ AVOID: EOA minters (higher risk)
```

### **Pauser Role Assignment**
```solidity
// ✅ RECOMMENDED: Multiple pausers for 24/7 coverage
token.grantPauserRole(securityTeamLead);      // Americas timezone
token.grantPauserRole(devOpsEurope);          // Europe timezone  
token.grantPauserRole(communityGuardianAsia); // Asia timezone

// ✅ OPTIONAL: Automated systems
token.grantPauserRole(monitoringContract);
```

## 🔒 **Security Checklist**

### **Pre-Deployment**
- [ ] Admin set to secure multisig wallet
- [ ] Multisig threshold properly configured (3/5 recommended)
- [ ] All signers have secure key management
- [ ] Emergency response procedures documented

### **Post-Deployment**
- [ ] Minter roles granted only to audited contracts
- [ ] Pauser roles granted to trusted security team
- [ ] 24/7 monitoring systems in place
- [ ] Regular security reviews scheduled

### **Ongoing Operations**
- [ ] Monitor minting patterns for anomalies
- [ ] Regular key rotation for pausers
- [ ] Test emergency procedures quarterly
- [ ] Review and update role assignments

## 📈 **Governance Evolution Path**

### **Phase 1: Centralized (Current)**
- Admin: Founding team multisig
- Minters: Core protocol contracts
- Pausers: Security team members

### **Phase 2: Community Governed**
- Admin: DAO governance contract
- Minters: Community-approved contracts
- Pausers: Elected community guardians

### **Phase 3: Fully Decentralized**
- Admin: Renounced (contract immutable)
- Minters: Algorithmic/preset contracts only
- Pausers: Distributed community network

## 💡 **Quick Commands Reference**

### **Admin Operations**
```solidity
// Grant roles
token.grantMinterRole(newContract);
token.grantPauserRole(emergencyTeam);

// Revoke roles  
token.revokeMinterRole(compromisedContract);
token.revokePauserRole(formerTeamMember);

// Emergency control
token.pauseMinting();   // Stop all minting
token.unpauseMinting(); // Resume operations

// Governance
token.transferAdmin(newMultisig);  // 24hr cooldown
token.renounceAdminRole();         // Permanent!
```

### **Minter Operations**
```solidity
// Normal minting
token.mint(recipient, amount);

// Batch minting (example)
for(uint i = 0; i < recipients.length; i++) {
    token.mint(recipients[i], amounts[i]);
}
```

### **Pauser Operations**
```solidity
// Emergency response
token.pauseMinting();   // Immediate halt

// Recovery
token.unpauseMinting(); // Resume operations
```

## 🔍 **Role Verification**

### **Check Role Status**
```solidity
// Check if address has specific role
bool isAdmin = token.hasRole(token.DEFAULT_ADMIN_ROLE(), address);
bool isMinter = token.hasRole(token.MINTER_ROLE(), address);  
bool isPauser = token.hasRole(token.PAUSER_ROLE(), address);

// Get current admin
address currentAdmin = token.multisigWallet();

// Check pause status
bool isPaused = token.mintingPaused();
```

### **Monitor Events**
```solidity
// Role changes
event MinterRoleGranted(address indexed account, address indexed admin);
event MinterRoleRevoked(address indexed account, address indexed admin);
event PauserRoleGranted(address indexed account, address indexed admin);
event PauserRoleRevoked(address indexed account, address indexed admin);

// Admin changes  
event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

// Pause state changes
event MintingPauseChanged(bool indexed isPaused, address indexed pauser);
```

---

This quick reference provides all the essential information for understanding and operating the DaitsToken role system efficiently and securely.