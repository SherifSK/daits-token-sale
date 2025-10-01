// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "@forge-std/Test.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title DAITS Token Test Suite
 * @dev Comprehensive tests for the DAITS token contract
 */
contract DaitsTokenTest is Test {
    DaitsToken public token;

    // Test addresses
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public minter = makeAddr("minter");
    address public newAdmin = makeAddr("newAdmin");

    // Token constants
    string constant TOKEN_NAME = "DAITS Token";
    string constant TOKEN_SYMBOL = "DAITS";
    uint256 constant MAX_SUPPLY = 1000000e18; // 1M tokens
    uint256 constant UNLIMITED_SUPPLY = 0;

    // Events to test
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MinterRoleGranted(address indexed account, address indexed admin);
    event MinterRoleRevoked(address indexed account, address indexed admin);
    event SupplyCapSet(uint256 maxSupply);

    function setUp() public {
        // Deploy token with capped supply
        token = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, MAX_SUPPLY);
    }

    /* ============ Constructor Tests ============ */

    /// @dev Compiler suggests 'view' but test functions should remain non-view for Foundry framework compatibility
    function test_Constructor_Success() public {
        // Test basic token properties
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);

        // Test admin setup
        assertEq(token.multisigWallet(), admin);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));

        // Test supply cap
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
    }

    function test_Constructor_UnlimitedSupply() public {
        DaitsToken unlimitedToken = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, UNLIMITED_SUPPLY);
        assertEq(unlimitedToken.MAX_SUPPLY(), 0);
    }

    function test_Constructor_RevertZeroAdmin() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressNotAllowed()"));
        new DaitsToken("Test Token", "TEST", address(0), 0);
    }

    function test_Constructor_EmitsEvents() public {
        vm.expectEmit(true, true, false, true);
        emit AdminTransferred(address(0), admin);

        vm.expectEmit(false, false, false, true);
        emit SupplyCapSet(MAX_SUPPLY);

        new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, MAX_SUPPLY);
    }

    /* ============ Minting Tests ============ */

    function test_Mint_Success() public {
        // Grant minter role
        vm.prank(admin);
        token.grantMinterRole(minter);

        // Mint tokens
        vm.prank(minter);
        token.mint(alice, 1000e18);

        assertEq(token.balanceOf(alice), 1000e18);
        assertEq(token.totalSupply(), 1000e18);
    }

    function test_Mint_RevertNotMinter() public {
        vm.expectRevert();
        vm.prank(alice);
        token.mint(alice, 1000e18);
    }

    function test_Mint_RevertZeroAddress() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.expectRevert(abi.encodeWithSignature("ZeroAddressNotAllowed()"));
        vm.prank(minter);
        token.mint(address(0), 1000e18);
    }

    function test_Mint_RevertZeroAmount() public {
        vm.prank(admin);
        token.grantMinterRole(address(this));
        
        vm.prank(address(this));
        vm.expectRevert(DaitsToken.AmountMustBeGreaterThanZero.selector);
        token.mint(address(0x1), 0);
    }

    function test_Mint_RevertExceedsSupplyCap() public {
        vm.prank(admin);
        token.grantMinterRole(address(this));
        
        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSignature("SupplyCapExceeded()"));
        token.mint(address(0x1), MAX_SUPPLY + 1);
    }

    function test_Mint_MultipleMintsUpToCapLimit() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.startPrank(minter);
        token.mint(alice, 500000e18);
        token.mint(bob, 500000e18);
        vm.stopPrank();

        assertEq(token.totalSupply(), MAX_SUPPLY);

        // Should revert on next mint
        vm.expectRevert(abi.encodeWithSignature("SupplyCapExceeded()"));
        vm.prank(minter);
        token.mint(charlie, 1);
    }

    function test_Mint_UnlimitedSupply() public {
        // Deploy token with unlimited supply
        DaitsToken unlimitedToken = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, UNLIMITED_SUPPLY);

        vm.prank(admin);
        unlimitedToken.grantMinterRole(minter);

        // Should be able to mint any amount
        vm.prank(minter);
        unlimitedToken.mint(alice, 1e30); // Very large amount

        assertEq(unlimitedToken.balanceOf(alice), 1e30);
    }

    /* ============ Role Management Tests ============ */

    function test_GrantMinterRole_Success() public {
        vm.expectEmit(true, true, false, true);
        emit MinterRoleGranted(minter, admin);

        vm.prank(admin);
        token.grantMinterRole(minter);

        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    function test_GrantMinterRole_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(alice);
        token.grantMinterRole(minter);
    }

    function test_GrantMinterRole_RevertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressNotAllowed()"));
        vm.prank(admin);
        token.grantMinterRole(address(0));
    }

    function test_RevokeMinterRole_Success() public {
        // First grant the role
        vm.prank(admin);
        token.grantMinterRole(minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));

        // Then revoke it
        vm.expectEmit(true, true, false, true);
        emit MinterRoleRevoked(minter, admin);

        vm.prank(admin);
        token.revokeMinterRole(minter);

        assertFalse(token.hasRole(token.MINTER_ROLE(), minter));
    }

    function test_RevokeMinterRole_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(alice);
        token.revokeMinterRole(minter);
    }

    /* ============ Admin Transfer Tests ============ */

    function test_TransferAdmin_Success() public {
        vm.expectEmit(true, true, false, true);
        emit AdminTransferred(admin, newAdmin);

        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // Check old admin no longer has role
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));

        // Check new admin has role
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), newAdmin));
        assertEq(token.multisigWallet(), newAdmin);
    }

    function test_TransferAdmin_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(alice);
        token.transferAdmin(newAdmin);
    }

    function test_TransferAdmin_RevertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressNotAllowed()"));
        vm.prank(admin);
        token.transferAdmin(address(0));
    }

    function test_TransferAdmin_RevertSameAdmin() public {
        vm.expectRevert(abi.encodeWithSignature("SameAdminAddress()"));
        vm.prank(admin);
        token.transferAdmin(admin);
    }

    function test_TransferAdmin_NewAdminCanGrantRoles() public {
        // Transfer admin
        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // New admin should be able to grant roles
        vm.prank(newAdmin);
        token.grantMinterRole(minter);

        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    /* ============ Admin Renunciation Tests ============ */

    function test_RenounceAdminRole_Success() public {
        vm.expectEmit(true, true, false, true);
        emit AdminTransferred(admin, address(0));

        vm.prank(admin);
        token.renounceAdminRole();

        // Check admin no longer has role
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(token.multisigWallet(), address(0));
    }

    function test_RenounceAdminRole_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(alice);
        token.renounceAdminRole();
    }

    function test_RenounceAdminRole_MakesContractImmutable() public {
        // Renounce admin role
        vm.prank(admin);
        token.renounceAdminRole();

        // Should not be able to grant roles anymore
        vm.expectRevert();
        vm.prank(admin);
        token.grantMinterRole(minter);

        // Should not be able to transfer admin anymore
        vm.expectRevert();
        vm.prank(admin);
        token.transferAdmin(newAdmin);
    }

    /* ============ Access Control Tests ============ */

    function test_OnlyMinterCanMint() public {
        // Admin cannot mint without minter role
        vm.expectRevert();
        vm.prank(admin);
        token.mint(alice, 1000e18);

        // Regular user cannot mint
        vm.expectRevert();
        vm.prank(alice);
        token.mint(alice, 1000e18);

        // Only after getting minter role
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(alice, 1000e18);
        assertEq(token.balanceOf(alice), 1000e18);
    }

    function test_OnlyAdminCanManageRoles() public {
        // Non-admin cannot grant roles
        vm.expectRevert();
        vm.prank(alice);
        token.grantMinterRole(minter);

        // Non-admin cannot revoke roles
        vm.expectRevert();
        vm.prank(alice);
        token.revokeMinterRole(minter);

        // Non-admin cannot transfer admin
        vm.expectRevert();
        vm.prank(alice);
        token.transferAdmin(newAdmin);
    }

    /* ============ ERC20 Standard Tests ============ */

    function test_ERC20_BasicFunctionality() public {
        // Mint some tokens first
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(alice, 1000e18);

        // Test transfer
        vm.prank(alice);
        bool transferSuccess = token.transfer(bob, 500e18);
        assertTrue(transferSuccess);

        assertEq(token.balanceOf(alice), 500e18);
        assertEq(token.balanceOf(bob), 500e18);

        // Test approval and transferFrom
        vm.prank(alice);
        token.approve(bob, 200e18);

        vm.prank(bob);
        bool transferFromSuccess = token.transferFrom(alice, charlie, 200e18);
        assertTrue(transferFromSuccess);

        assertEq(token.balanceOf(alice), 300e18);
        assertEq(token.balanceOf(charlie), 200e18);
        assertEq(token.allowance(alice, bob), 0);
    }

    /* ============ Fuzz Tests ============ */

    function testFuzz_Mint_ValidAmounts(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);

        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testFuzz_Mint_InvalidAmounts(uint256 amount) public {
        vm.assume(amount > MAX_SUPPLY);

        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.expectRevert(abi.encodeWithSignature("SupplyCapExceeded()"));
        vm.prank(minter);
        token.mint(alice, amount);
    }

    function testFuzz_AdminTransfer_ValidAddresses(address newAdminAddr) public {
        vm.assume(newAdminAddr != address(0) && newAdminAddr != admin);

        vm.prank(admin);
        token.transferAdmin(newAdminAddr);

        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), newAdminAddr));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(token.multisigWallet(), newAdminAddr);
    }

    /* ============ Integration Tests ============ */

    function test_Integration_FullWorkflow() public {
        // 1. Admin grants minter role to multiple addresses
        vm.startPrank(admin);
        token.grantMinterRole(alice);
        token.grantMinterRole(bob);
        vm.stopPrank();

        // 2. Minters mint tokens
        vm.prank(alice);
        token.mint(charlie, 300000e18);

        vm.prank(bob);
        token.mint(charlie, 200000e18);

        assertEq(token.balanceOf(charlie), 500000e18);

        // 3. Admin revokes one minter
        vm.prank(admin);
        token.revokeMinterRole(alice);

        // 4. Revoked minter cannot mint anymore
        vm.expectRevert();
        vm.prank(alice);
        token.mint(charlie, 1000e18);

        // 5. Admin transfers to new admin
        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // 6. Old admin cannot manage roles
        vm.expectRevert();
        vm.prank(admin);
        token.grantMinterRole(alice);

        // 7. New admin can manage roles
        vm.prank(newAdmin);
        token.grantMinterRole(alice);

        assertTrue(token.hasRole(token.MINTER_ROLE(), alice));
    }

    /* ============ Edge Case Tests ============ */

    function test_EdgeCase_MintExactlyToSupplyCap() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(alice, MAX_SUPPLY);

        assertEq(token.totalSupply(), MAX_SUPPLY);

        // Next mint should fail
        vm.expectRevert(abi.encodeWithSignature("SupplyCapExceeded()"));
        vm.prank(minter);
        token.mint(alice, 1);
    }

    function test_EdgeCase_MultipleRoleGrants() public {
        vm.startPrank(admin);

        // Grant role first time (should succeed)
        token.grantMinterRole(minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));

        // Grant role again (should revert because role already exists)
        vm.expectRevert(abi.encodeWithSignature("RoleGrantFailed()"));
        token.grantMinterRole(minter);

        vm.stopPrank();
    }

    function test_EdgeCase_RevokeNonExistentRole() public {
        // Should revert when revoking role that was never granted (OpenZeppelin returns false)
        vm.expectRevert(abi.encodeWithSignature("RoleRevokeFailed()"));
        vm.prank(admin);
        token.revokeMinterRole(minter);
    }
}
