// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title Storage Optimization Tests
 * @notice Tests for Phase 2 storage optimization features
 */
contract StorageOptimizationTest is Test {
    DaitsToken public token;

    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public alice = makeAddr("alice");

    uint256 public constant MAX_SUPPLY = 1_000_000e18;

    function setUp() public {
        token = new DaitsToken("Test Token", "TEST", admin, MAX_SUPPLY);
    }

    /* ============ Pause Functionality Tests ============ */

    function test_PauseMinting_Success() public {
        vm.prank(admin);
        token.pauseMinting();

        assertTrue(token.mintingPaused());
    }

    function test_PauseMinting_RevertNotAdmin() public {
        vm.expectRevert();
        vm.prank(alice);
        token.pauseMinting();
    }

    function test_UnpauseMinting_Success() public {
        vm.startPrank(admin);
        token.pauseMinting();
        token.unpauseMinting();
        vm.stopPrank();

        assertFalse(token.mintingPaused());
    }

    function test_Mint_RevertWhenPaused() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(admin);
        token.pauseMinting();

        vm.expectRevert(abi.encodeWithSignature("MintingPaused()"));
        vm.prank(minter);
        token.mint(alice, 1000e18);
    }

    function test_Mint_SuccessWhenUnpaused() public {
        vm.startPrank(admin);
        token.grantMinterRole(minter);
        token.pauseMinting();
        token.unpauseMinting();
        vm.stopPrank();

        vm.prank(minter);
        token.mint(alice, 1000e18);

        assertEq(token.balanceOf(alice), 1000e18);
    }

    /* ============ Admin Transfer Cooldown Tests ============ */

    function test_TransferAdmin_RevertTooSoon() public {
        address newAdmin = makeAddr("newAdmin");

        // First transfer should work
        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // Second transfer within 24 hours should fail
        vm.expectRevert(abi.encodeWithSignature("AdminTransferTooSoon()"));
        vm.prank(newAdmin);
        token.transferAdmin(admin);
    }

    function test_TransferAdmin_SuccessAfterCooldown() public {
        address newAdmin = makeAddr("newAdmin");
        address finalAdmin = makeAddr("finalAdmin");

        // First transfer
        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // Fast forward 24 hours + 1 second
        vm.warp(block.timestamp + 1 days + 1);

        // Second transfer should now work
        vm.prank(newAdmin);
        token.transferAdmin(finalAdmin);

        assertEq(token.multisigWallet(), finalAdmin);
    }

    /* ============ Counter Tests ============ */

    function test_TotalMintersGranted_Increments() public {
        assertEq(token.totalMintersGranted(), 0);

        vm.startPrank(admin);
        token.grantMinterRole(minter);
        assertEq(token.totalMintersGranted(), 1);

        token.grantMinterRole(alice);
        assertEq(token.totalMintersGranted(), 2);
        vm.stopPrank();
    }

    function test_TotalMintersGranted_NoDoubleCount() public {
        vm.startPrank(admin);
        token.grantMinterRole(minter);
        assertEq(token.totalMintersGranted(), 1);

        // Granting same role again shouldn't increment
        token.grantMinterRole(minter);
        assertEq(token.totalMintersGranted(), 1);
        vm.stopPrank();
    }

    function test_AdminTransferCount_Increments() public {
        assertEq(token.adminTransferCount(), 0);

        address newAdmin = makeAddr("newAdmin");
        vm.prank(admin);
        token.transferAdmin(newAdmin);

        assertEq(token.adminTransferCount(), 1);
    }

    function test_AdminTransferCount_IncrementsOnRenounce() public {
        assertEq(token.adminTransferCount(), 0);

        vm.prank(admin);
        token.renounceAdminRole();

        assertEq(token.adminTransferCount(), 1);
    }

    /* ============ View Function Tests ============ */

    function test_GetContractAge() public {
        uint256 initialAge = token.getContractAge();
        assertTrue(initialAge < 10); // Should be very small initially

        vm.warp(block.timestamp + 3600); // 1 hour later

        uint256 laterAge = token.getContractAge();
        assertEq(laterAge, initialAge + 3600);
    }

    function test_GetAdminTransferCooldown_Fresh() public {
        // Should be able to transfer immediately on fresh deployment
        assertEq(token.getAdminTransferCooldown(), 0);
    }

    function test_GetAdminTransferCooldown_AfterTransfer() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(admin);
        token.transferAdmin(newAdmin);

        uint256 cooldown = token.getAdminTransferCooldown();
        assertTrue(cooldown > 0);
        assertTrue(cooldown <= 1 days);
    }

    function test_GetAdminTransferCooldown_AfterCooldownPassed() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(admin);
        token.transferAdmin(newAdmin);

        // Fast forward past cooldown
        vm.warp(block.timestamp + 1 days + 1);

        assertEq(token.getAdminTransferCooldown(), 0);
    }

    /* ============ Gas Optimization Verification Tests ============ */

    function test_StoragePacking_SingleSlotAccess() public {
        // This test verifies that our packed variables share storage slots
        // We can't directly test storage layout, but we can verify the variables exist

        assertTrue(token.DEPLOYMENT_TIMESTAMP() > 0);
        assertEq(token.lastAdminTransferTime(), 0); // Starts at 0 until first transfer
        assertEq(token.adminTransferCount(), 0);
        assertEq(token.totalMintersGranted(), 0);
        assertFalse(token.mintingPaused());
    }

    function test_Events_MintingPauseChanged() public {
        vm.expectEmit(true, true, false, true);
        emit DaitsToken.MintingPauseChanged(true, admin);

        vm.prank(admin);
        token.pauseMinting();

        vm.expectEmit(true, true, false, true);
        emit DaitsToken.MintingPauseChanged(false, admin);

        vm.prank(admin);
        token.unpauseMinting();
    }
}
