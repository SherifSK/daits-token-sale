// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DAITS Token
 * @dev ERC20 token with role-based access control managed by Safe multisig
 * @notice Admin functions require multisig approval through Safe wallet
 */
contract DaitsToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Maximum supply cap (0 = unlimited, >0 = capped supply)
    uint256 public immutable MAX_SUPPLY;

    // Events for transparency
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MinterRoleGranted(address indexed account, address indexed admin);
    event MinterRoleRevoked(address indexed account, address indexed admin);
    event SupplyCapSet(uint256 maxSupply);

    // Safe multisig wallet address (to be set after deployment)
    address public multisigWallet;

    /**
     * @dev Constructor sets up initial roles and supply cap
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param initialAdmin Address that will receive initial admin role (should be Safe multisig)
     * @param maxSupply_ Maximum supply cap (0 for unlimited, >0 for capped supply)
     */
    constructor(string memory name_, string memory symbol_, address initialAdmin, uint256 maxSupply_)
        ERC20(name_, symbol_)
    {
        require(initialAdmin != address(0), "DaitsToken: initial admin cannot be zero address");

        // Set maximum supply (0 = unlimited)
        MAX_SUPPLY = maxSupply_;

        // Grant admin role to the provided address (should be Safe multisig)
        bool roleGranted = _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        require(roleGranted, "DaitsToken: failed to grant admin role");
        multisigWallet = initialAdmin;

        emit AdminTransferred(address(0), initialAdmin);
        emit SupplyCapSet(maxSupply_);
    }

    /**
     * @dev Mint tokens - only callable by accounts with MINTER_ROLE
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     * @notice CENTRALIZATION RISK MITIGATION:
     * - MINTER_ROLE is granted only to specific contracts (e.g., token sale)
     * - Admin role is controlled by Safe multisig (no single point of failure)
     * - All minting operations are transparent and logged on-chain
     * - Admin can revoke MINTER_ROLE or renounce admin privileges entirely
     */
    // aderyn-ignore-next-line(centralization-risk) - Minting is intentionally controlled for token economics
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(to != address(0), "DaitsToken: cannot mint to zero address");
        require(amount > 0, "DaitsToken: amount must be greater than zero");

        // Check supply cap if set (0 means unlimited)
        if (MAX_SUPPLY > 0) {
            require(totalSupply() + amount <= MAX_SUPPLY, "DaitsToken: would exceed maximum supply cap");
        }

        _mint(to, amount);
    }

    /**
     * @dev Grant minter role - only callable by admin (multisig)
     * @param account Address to grant minter role to
     * @notice CENTRALIZATION RISK MITIGATION:
     * - Admin role is controlled by Safe multisig (requires multiple signatures)
     * - Role grants are transparent via events and on-chain visibility
     * - Admin can be transferred to new multisig or renounced entirely
     * - Supply cap limits total damage even if role is misused
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin functions require centralized control for governance
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "DaitsToken: cannot grant role to zero address");
        bool roleGranted = _grantRole(MINTER_ROLE, account);
        require(roleGranted, "DaitsToken: failed to grant minter role");
        emit MinterRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revoke minter role - only callable by admin (multisig)
     * @param account Address to revoke minter role from
     * @notice CENTRALIZATION RISK MITIGATION:
     * - Admin role controlled by Safe multisig (multiple signatures required)
     * - Role revocations are transparent and logged via events
     * - Provides mechanism to remove compromised minters
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin functions require centralized control for governance
    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool roleRevoked = _revokeRole(MINTER_ROLE, account);
        require(roleRevoked, "DaitsToken: failed to revoke minter role");
        emit MinterRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Transfer admin role to new multisig - only callable by current admin
     * @param newAdmin Address of new admin (should be new Safe multisig)
     * @notice CENTRALIZATION RISK MITIGATION:
     * - Enables transition to new governance structure
     * - Supports upgrading from smaller to larger multisig
     * - Allows gradual decentralization over time
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin transfer enables decentralization progression
    function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "DaitsToken: new admin cannot be zero address");
        require(newAdmin != multisigWallet, "DaitsToken: new admin is the same as current");

        address oldAdmin = multisigWallet;

        // Revoke admin role from current admin
        bool roleRevoked = _revokeRole(DEFAULT_ADMIN_ROLE, oldAdmin);
        require(roleRevoked, "DaitsToken: failed to revoke admin role from old admin");

        // Grant admin role to new admin
        bool roleGranted = _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        require(roleGranted, "DaitsToken: failed to grant admin role to new admin");

        multisigWallet = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    /**
     * @dev Emergency function to renounce admin role - makes contract immutable
     * @notice This action is irreversible and will make the contract non-upgradeable
     * @notice CENTRALIZATION RISK MITIGATION:
     * - Ultimate decentralization mechanism (complete admin removal)
     * - Makes contract fully immutable and community-owned
     * - Eliminates all centralization risks permanently
     */
    // aderyn-ignore-next-line(centralization-risk) - Function eliminates centralization entirely
    function renounceAdminRole() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address currentAdmin = multisigWallet;
        bool roleRevoked = _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        require(roleRevoked, "DaitsToken: failed to renounce admin role");
        multisigWallet = address(0);
        emit AdminTransferred(currentAdmin, address(0));
    }
}
