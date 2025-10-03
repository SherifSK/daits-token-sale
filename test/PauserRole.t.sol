// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title PauserRoleTest
 * @notice Comprehensive test suite for PAUSER_ROLE functionality
 * @dev Tests pauser role management, pause/unpause operations, and access controls
 */
contract PauserRoleTest is Test {
    DaitsToken public token;
    address public admin = address(0x1);
    address public pauser = address(0x2);
    address public minter = address(0x3);
    address public user = address(0x4);

    /// @notice Events to test
    event PauserRoleGranted(address indexed account, address indexed admin);
    event PauserRoleRevoked(address indexed account, address indexed admin);
    event MintingPauseChanged(bool indexed isPaused, address indexed pauser);

    function setUp() public {
        // Deploy token with admin
        token = new DaitsToken("Test Token", "TEST", admin, 1000000 ether);

        // Setup roles
        vm.startPrank(admin);
        token.grantMinterRole(minter);
        token.grantPauserRole(pauser);
        vm.stopPrank();
    }

    // ============ PAUSER ROLE MANAGEMENT TESTS ============

    function test_GrantPauserRole_Success() public {
        address newPauser = address(0x5);

        vm.expectEmit(true, true, false, false);
        emit PauserRoleGranted(newPauser, admin);

        vm.prank(admin);
        token.grantPauserRole(newPauser);

        assertTrue(token.hasRole(token.PAUSER_ROLE(), newPauser));
    }

    function test_GrantPauserRole_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(user);
        token.grantPauserRole(address(0x5));
    }

    function test_GrantPauserRole_RevertZeroAddress() public {
        vm.expectRevert(DaitsToken.ZeroAddressNotAllowed.selector);
        vm.prank(admin);
        token.grantPauserRole(address(0));
    }

    function test_RevokePauserRole_Success() public {
        vm.expectEmit(true, true, false, false);
        emit PauserRoleRevoked(pauser, admin);

        vm.prank(admin);
        token.revokePauserRole(pauser);

        assertFalse(token.hasRole(token.PAUSER_ROLE(), pauser));
    }

    function test_RevokePauserRole_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(user);
        token.revokePauserRole(pauser);
    }

    // ============ PAUSE FUNCTIONALITY TESTS ============

    function test_PauseMinting_ByAdmin() public {
        vm.expectEmit(true, true, false, false);
        emit MintingPauseChanged(true, admin);

        vm.prank(admin);
        token.pauseMinting();

        assertTrue(token.mintingPaused());
    }

    function test_PauseMinting_ByPauser() public {
        vm.expectEmit(true, true, false, false);
        emit MintingPauseChanged(true, pauser);

        vm.prank(pauser);
        token.pauseMinting();

        assertTrue(token.mintingPaused());
    }

    function test_PauseMinting_RevertUnauthorized() public {
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(user);
        token.pauseMinting();
    }

    function test_UnpauseMinting_ByAdmin() public {
        // First pause
        vm.prank(admin);
        token.pauseMinting();

        vm.expectEmit(true, true, false, false);
        emit MintingPauseChanged(false, admin);

        vm.prank(admin);
        token.unpauseMinting();

        assertFalse(token.mintingPaused());
    }

    function test_UnpauseMinting_ByPauser() public {
        // First pause
        vm.prank(pauser);
        token.pauseMinting();

        vm.expectEmit(true, true, false, false);
        emit MintingPauseChanged(false, pauser);

        vm.prank(pauser);
        token.unpauseMinting();

        assertFalse(token.mintingPaused());
    }

    function test_UnpauseMinting_RevertUnauthorized() public {
        vm.prank(admin);
        token.pauseMinting();

        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(user);
        token.unpauseMinting();
    }

    // ============ INTEGRATION TESTS ============

    function test_PauseBlocksMinting() public {
        vm.prank(pauser);
        token.pauseMinting();

        vm.expectRevert(DaitsToken.MintingPaused.selector);
        vm.prank(minter);
        token.mint(user, 100 ether);
    }

    function test_UnpauseRestoresMinting() public {
        // Pause minting
        vm.prank(pauser);
        token.pauseMinting();

        // Try to mint (should fail)
        vm.expectRevert(DaitsToken.MintingPaused.selector);
        vm.prank(minter);
        token.mint(user, 100 ether);

        // Unpause minting
        vm.prank(pauser);
        token.unpauseMinting();

        // Now minting should work
        vm.prank(minter);
        token.mint(user, 100 ether);

        assertEq(token.balanceOf(user), 100 ether);
    }

    function test_MultiplePausersCanPause() public {
        address pauser2 = address(0x6);

        vm.prank(admin);
        token.grantPauserRole(pauser2);

        // First pauser pauses
        vm.prank(pauser);
        token.pauseMinting();
        assertTrue(token.mintingPaused());

        // Unpause
        vm.prank(pauser2);
        token.unpauseMinting();
        assertFalse(token.mintingPaused());

        // Second pauser can pause
        vm.prank(pauser2);
        token.pauseMinting();
        assertTrue(token.mintingPaused());
    }

    function test_RevokedPauserCannotPause() public {
        // Revoke pauser role
        vm.prank(admin);
        token.revokePauserRole(pauser);

        // Should not be able to pause
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(pauser);
        token.pauseMinting();
    }

    function test_AdminCanAlwaysPauseEvenWithoutPauserRole() public {
        // Admin doesn't have PAUSER_ROLE by default, only DEFAULT_ADMIN_ROLE
        assertFalse(token.hasRole(token.PAUSER_ROLE(), admin));
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));

        // Admin can still pause
        vm.prank(admin);
        token.pauseMinting();
        assertTrue(token.mintingPaused());

        // Admin can still unpause
        vm.prank(admin);
        token.unpauseMinting();
        assertFalse(token.mintingPaused());
    }

    // ============ ROLE HIERARCHY TESTS ============

    function test_OnlyAdminCanGrantPauserRole() public {
        address newPauser = address(0x7);

        // Pauser cannot grant pauser role to others
        vm.expectRevert();
        vm.prank(pauser);
        token.grantPauserRole(newPauser);

        // Minter cannot grant pauser role
        vm.expectRevert();
        vm.prank(minter);
        token.grantPauserRole(newPauser);

        // Only admin can grant pauser role
        vm.prank(admin);
        token.grantPauserRole(newPauser);
        assertTrue(token.hasRole(token.PAUSER_ROLE(), newPauser));
    }

    function test_OnlyAdminCanRevokePauserRole() public {
        // Pauser cannot revoke their own role
        vm.expectRevert();
        vm.prank(pauser);
        token.revokePauserRole(pauser);

        // Only admin can revoke pauser role
        vm.prank(admin);
        token.revokePauserRole(pauser);
        assertFalse(token.hasRole(token.PAUSER_ROLE(), pauser));
    }

    // ============ EMERGENCY SCENARIOS ============

    function test_EmergencyPauseScenario() public {
        // Simulate emergency: minter goes rogue, pauser quickly pauses
        vm.prank(pauser);
        token.pauseMinting();

        // Rogue minter cannot mint
        vm.expectRevert(DaitsToken.MintingPaused.selector);
        vm.prank(minter);
        token.mint(user, 1000000 ether); // Try to mint max supply

        // Admin investigates and removes compromised minter
        vm.prank(admin);
        token.revokeMinterRole(minter);

        // Admin adds new trusted minter and unpauses
        address newMinter = address(0x8);
        vm.prank(admin);
        token.grantMinterRole(newMinter);

        vm.prank(admin);
        token.unpauseMinting();

        // New minter can now mint safely
        vm.prank(newMinter);
        token.mint(user, 100 ether);
        assertEq(token.balanceOf(user), 100 ether);
    }

    function test_PauserCannotMint() public {
        // Pauser should not have minting privileges
        vm.expectRevert();
        vm.prank(pauser);
        token.mint(user, 100 ether);
    }

    function test_MinterCannotPauseWithoutPauserRole() public {
        // Minter should not be able to pause without PAUSER_ROLE
        vm.expectRevert("AccessControl: account is missing role");
        vm.prank(minter);
        token.pauseMinting();
    }

    // ============ GAS OPTIMIZATION TESTS ============

    function test_PauseGasEfficiency() public {
        uint256 gasBefore = gasleft();
        vm.prank(pauser);
        token.pauseMinting();
        uint256 gasUsed = gasBefore - gasleft();

        // Should be gas efficient (less than 50k gas)
        assertLt(gasUsed, 50000);
    }

    function test_UnpauseGasEfficiency() public {
        vm.prank(pauser);
        token.pauseMinting();

        uint256 gasBefore = gasleft();
        vm.prank(pauser);
        token.unpauseMinting();
        uint256 gasUsed = gasBefore - gasleft();

        // Should be gas efficient (less than 50k gas)
        assertLt(gasUsed, 50000);
    }
}