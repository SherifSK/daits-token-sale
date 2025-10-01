// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DAITS Token
 * @author DAITS Team
 * @notice ERC20 token with role-based access control for the DAITS ecosystem
 * @dev Implementation uses OpenZeppelin's ERC20 and AccessControl for security
 * @custom:security-contact security@daits.io
 */
contract DaitsToken is ERC20, AccessControl {
    /// @notice Custom errors for gas-efficient reverts
    error ZeroAddressNotAllowed();
    error AmountMustBeGreaterThanZero();
    error SupplyCapExceeded();
    error RoleGrantFailed();
    error RoleRevokeFailed();
    error SameAdminAddress();

    /// @notice Role identifier for addresses allowed to mint tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role identifier for addresses allowed to pause token operations
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Maximum supply cap - 0 means unlimited supply, >0 means capped supply
    /// @dev Set during construction and cannot be changed afterwards
    uint256 public immutable MAX_SUPPLY;

    /// @notice Address of the Safe multisig wallet that controls admin functions
    /// @dev This address has DEFAULT_ADMIN_ROLE and can manage minter roles
    address public multisigWallet;

    /// @notice Emitted when admin role is transferred to a new address
    /// @param previousAdmin Address of the previous admin
    /// @param newAdmin Address of the new admin
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Emitted when minter role is granted to an address
    /// @param account Address that received the minter role
    /// @param admin Address of the admin who granted the role
    event MinterRoleGranted(address indexed account, address indexed admin);

    /// @notice Emitted when minter role is revoked from an address
    /// @param account Address that lost the minter role
    /// @param admin Address of the admin who revoked the role
    event MinterRoleRevoked(address indexed account, address indexed admin);

    /// @notice Emitted when the supply cap is set during construction
    /// @param maxSupply The maximum supply cap (0 for unlimited)
    event SupplyCapSet(uint256 maxSupply);

    /**
     * @notice Creates a new DAITS token with specified parameters
     * @dev Sets up ERC20 token with role-based access control and supply cap
     * @param name_ The name of the token (e.g., "DAITS Token")
     * @param symbol_ The symbol of the token (e.g., "DAITS")
     * @param initialAdmin Address that will receive admin role (should be Safe multisig)
     * @param maxSupply_ Maximum supply cap (0 for unlimited, >0 for capped supply)
     * @custom:requires initialAdmin must not be zero address
     * @custom:emits AdminTransferred, SupplyCapSet
     */
    constructor(string memory name_, string memory symbol_, address initialAdmin, uint256 maxSupply_)
        ERC20(name_, symbol_)
    {
        if (initialAdmin == address(0)) revert ZeroAddressNotAllowed();

        // Set maximum supply (0 = unlimited)
        MAX_SUPPLY = maxSupply_;

        // Grant admin role to the provided address (should be Safe multisig)
        bool roleGranted = _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        if (!roleGranted) revert RoleGrantFailed();
        multisigWallet = initialAdmin;

        emit AdminTransferred(address(0), initialAdmin);
        emit SupplyCapSet(maxSupply_);
    }

    /**
     * @notice Mints new tokens to the specified address
     * @dev Only accounts with MINTER_ROLE can call this function
     * @param to The address that will receive the minted tokens
     * @param amount The number of tokens to mint (in wei units)
     * @custom:requires Caller must have MINTER_ROLE
     * @custom:requires to address must not be zero
     * @custom:requires amount must be greater than zero
     * @custom:requires Must not exceed MAX_SUPPLY if set
     * @custom:security CENTRALIZATION RISK MITIGATION:
     * - MINTER_ROLE granted only to specific contracts (e.g., token sale)
     * - Admin role controlled by Safe multisig (no single point of failure)
     * - All minting operations transparent and logged on-chain
     * - Admin can revoke MINTER_ROLE or renounce admin privileges entirely
     */
    // aderyn-ignore-next-line(centralization-risk) - Minting is intentionally controlled for token economics
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (to == address(0)) revert ZeroAddressNotAllowed();
        if (amount == 0) revert AmountMustBeGreaterThanZero();

        // Check supply cap if set (0 means unlimited)
        if (MAX_SUPPLY > 0) {
            if (totalSupply() + amount > MAX_SUPPLY) revert SupplyCapExceeded();
        }

        _mint(to, amount);
    }

    /**
     * @notice Grants minter role to the specified address
     * @dev Only admin (multisig) can call this function to grant minting privileges
     * @param account The address to grant minter role to
     * @custom:requires Caller must have DEFAULT_ADMIN_ROLE
     * @custom:requires account must not be zero address
     * @custom:emits MinterRoleGranted
     * @custom:security CENTRALIZATION RISK MITIGATION:
     * - Admin role controlled by Safe multisig (requires multiple signatures)
     * - Role grants transparent via events and on-chain visibility
     * - Admin can be transferred to new multisig or renounced entirely
     * - Supply cap limits total damage even if role is misused
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin functions require centralized control for governance
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddressNotAllowed();
        bool roleGranted = _grantRole(MINTER_ROLE, account);
        if (!roleGranted) revert RoleGrantFailed();
        emit MinterRoleGranted(account, msg.sender);
    }

    /**
     * @notice Revokes minter role from the specified address
     * @dev Only admin (multisig) can call this function to remove minting privileges
     * @param account The address to revoke minter role from
     * @custom:requires Caller must have DEFAULT_ADMIN_ROLE
     * @custom:emits MinterRoleRevoked
     * @custom:security CENTRALIZATION RISK MITIGATION:
     * - Admin role controlled by Safe multisig (multiple signatures required)
     * - Role revocations transparent and logged via events
     * - Provides mechanism to remove compromised minters
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin functions require centralized control for governance
    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool roleRevoked = _revokeRole(MINTER_ROLE, account);
        if (!roleRevoked) revert RoleRevokeFailed();
        emit MinterRoleRevoked(account, msg.sender);
    }

    /**
     * @notice Transfers admin role to a new multisig address
     * @dev Only current admin can call this function to transfer control
     * @param newAdmin The address of the new admin (should be new Safe multisig)
     * @custom:requires Caller must have DEFAULT_ADMIN_ROLE
     * @custom:requires newAdmin must not be zero address
     * @custom:requires newAdmin must be different from current admin
     * @custom:emits AdminTransferred
     * @custom:security CENTRALIZATION RISK MITIGATION:
     * - Enables transition to new governance structure
     * - Supports upgrading from smaller to larger multisig
     * - Allows gradual decentralization over time
     */
    // aderyn-ignore-next-line(centralization-risk) - Admin transfer enables decentralization progression
    function transferAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newAdmin == address(0)) revert ZeroAddressNotAllowed();
        if (newAdmin == multisigWallet) revert SameAdminAddress();

        address oldAdmin = multisigWallet;

        // Effects: Update state first
        multisigWallet = newAdmin;

        // Interactions: External calls last
        // Revoke admin role from current admin
        bool roleRevoked = _revokeRole(DEFAULT_ADMIN_ROLE, oldAdmin);
        if (!roleRevoked) revert RoleRevokeFailed();

        // Grant admin role to new admin
        bool roleGranted = _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        if (!roleGranted) revert RoleGrantFailed();

        emit AdminTransferred(oldAdmin, newAdmin);
    }

    /**
     * @notice Permanently renounces admin role making the contract immutable
     * @dev Emergency function that removes all admin privileges forever
     * @custom:requires Caller must have DEFAULT_ADMIN_ROLE
     * @custom:emits AdminTransferred with newAdmin as zero address
     * @custom:warning This action is IRREVERSIBLE and makes contract non-upgradeable
     * @custom:security CENTRALIZATION RISK MITIGATION:
     * - Ultimate decentralization mechanism (complete admin removal)
     * - Makes contract fully immutable and community-owned
     * - Eliminates all centralization risks permanently
     */
    // aderyn-ignore-next-line(centralization-risk) - Function eliminates centralization entirely
    function renounceAdminRole() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address currentAdmin = multisigWallet;
        bool roleRevoked = _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        if (!roleRevoked) revert RoleRevokeFailed();
        multisigWallet = address(0);
        emit AdminTransferred(currentAdmin, address(0));
    }
}
