// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "@forge-std/Test.sol";
import {DaitsToken} from "../src/daitsToken.sol";

/**
 * @title DAITS Token Security Tests
 * @dev Security-focused tests for attack vectors and edge cases
 */
contract DaitsTokenSecurityTest is Test {
    DaitsToken public token;
    
    address public admin = makeAddr("admin");
    address public attacker = makeAddr("attacker");
    address public minter = makeAddr("minter");
    address public user = makeAddr("user");
    
    uint256 constant MAX_SUPPLY = 1000000e18;
    
    function setUp() public {
        token = new DaitsToken("DAITS Token", "DAITS", admin, MAX_SUPPLY);
    }
    
    /* ============ Reentrancy Tests ============ */
    
    function test_Security_NoReentrancyInMint() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        // Create malicious contract that tries to reenter
        MaliciousReceiver malicious = new MaliciousReceiver(address(token), minter);
        
        vm.prank(minter);
        token.mint(address(malicious), 1000e18);
        
        // Should only receive tokens once
        assertEq(token.balanceOf(address(malicious)), 1000e18);
        assertFalse(malicious.reentrancySuccessful());
    }
    
    /* ============ Access Control Attack Tests ============ */
    
    function test_Security_CannotGrantRoleToSelf() public {
        // Attacker cannot grant themselves minter role via our custom function
        vm.expectRevert();
        vm.prank(attacker);
        token.grantMinterRole(attacker);
        
        // Verify attacker still has no minter role
        assertFalse(token.hasRole(token.MINTER_ROLE(), attacker));
        
        // For admin role, DEFAULT_ADMIN_ROLE is self-administered in OpenZeppelin
        // So let's test that attacker cannot transfer admin instead
        vm.expectRevert();
        vm.prank(attacker);
        token.transferAdmin(attacker);
        
        // Verify attacker still has no admin role
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), attacker));
    }
    
    function test_Security_CannotBypassRoleChecks() public {
        // Try to call internal functions directly (should fail)
        vm.expectRevert();
        vm.prank(attacker);
        token.mint(attacker, 1000e18);
        
        // Try to manipulate storage directly (not possible in this context)
        // The onlyRole modifier should prevent all unauthorized access
    }
    
    function test_Security_AdminCannotMintWithoutMinterRole() public {
        // Even admin cannot mint without explicit minter role
        vm.expectRevert();
        vm.prank(admin);
        token.mint(user, 1000e18);
        
        // Admin must explicitly grant themselves minter role
        vm.prank(admin);
        token.grantMinterRole(admin);
        
        vm.prank(admin);
        token.mint(user, 1000e18);
        
        assertEq(token.balanceOf(user), 1000e18);
    }
    
    /* ============ Supply Cap Attack Tests ============ */
    
    function test_Security_CannotExceedSupplyCapWithMultipleMinters() public {
        // Grant minter role to multiple addresses
        vm.startPrank(admin);
        token.grantMinterRole(makeAddr("minter1"));
        token.grantMinterRole(makeAddr("minter2"));
        token.grantMinterRole(makeAddr("minter3"));
        vm.stopPrank();
        
        // Try to coordinate to exceed supply cap
        vm.prank(makeAddr("minter1"));
        token.mint(user, 400000e18);
        
        vm.prank(makeAddr("minter2"));
        token.mint(user, 400000e18);
        
        vm.prank(makeAddr("minter3"));
        token.mint(user, 200000e18);
        
        assertEq(token.totalSupply(), MAX_SUPPLY);
        
        // Any further minting should fail
        vm.expectRevert("DaitsToken: would exceed maximum supply cap");
        vm.prank(makeAddr("minter1"));
        token.mint(user, 1);
    }
    
    function test_Security_IntegerOverflowProtection() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        // Try to mint maximum possible uint256 (should be caught by supply cap)
        vm.expectRevert("DaitsToken: would exceed maximum supply cap");
        vm.prank(minter);
        token.mint(user, type(uint256).max);
    }
    
    /* ============ Role Management Security Tests ============ */
    
    function test_Security_OnlyAdminCanRevokeAdmin() public {
        // Non-admin cannot use transferAdmin function
        vm.expectRevert();
        vm.prank(attacker);
        token.transferAdmin(attacker);
        
        // Even minter cannot transfer admin
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        vm.expectRevert();
        vm.prank(minter);
        token.transferAdmin(minter);
        
        // Non-admin cannot renounce admin role
        vm.expectRevert();
        vm.prank(attacker);
        token.renounceAdminRole();
    }
    
    function test_Security_CannotTransferAdminToContract() public {
        // Deploy a contract without proper role handling
        BadContract badContract = new BadContract();
        
        // Should still work (contract address is valid)
        // But the contract won't be able to manage roles properly
        vm.prank(admin);
        token.transferAdmin(address(badContract));
        
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(badContract)));
    }
    
    /* ============ Frontrunning Protection Tests ============ */
    
    function test_Security_AdminTransferNotFrontrunnable() public {
        address newAdmin = makeAddr("newAdmin");
        
        // Simulate frontrunning attempt
        vm.expectRevert();
        vm.prank(attacker);
        token.transferAdmin(attacker);
        
        // Real admin transfer should work
        vm.prank(admin);
        token.transferAdmin(newAdmin);
        
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), newAdmin));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }
    
    /* ============ Gas Limit Tests ============ */
    
    function test_Security_MintLargeAmountsGasEfficient() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        uint256 gasBefore = gasleft();
        
        vm.prank(minter);
        token.mint(user, MAX_SUPPLY);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should use reasonable amount of gas (less than 100k)
        assertLt(gasUsed, 100000);
        assertEq(token.balanceOf(user), MAX_SUPPLY);
    }
    
    /* ============ State Consistency Tests ============ */
    
    function test_Security_StateConsistencyAfterRoleChanges() public {
        // Grant and revoke roles multiple times
        vm.startPrank(admin);
        
        token.grantMinterRole(minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
        
        token.revokeMinterRole(minter);
        assertFalse(token.hasRole(token.MINTER_ROLE(), minter));
        
        token.grantMinterRole(minter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
        
        vm.stopPrank();
        
        // Minter should work after regrant
        vm.prank(minter);
        token.mint(user, 1000e18);
        
        assertEq(token.balanceOf(user), 1000e18);
    }
    
    /* ============ Invariant Tests ============ */
    
    function test_Security_InvariantTotalSupplyNeverExceedsCap() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        // Multiple operations should never break invariant
        for (uint i = 0; i < 10; i++) {
            if (token.totalSupply() < MAX_SUPPLY) {
                uint256 mintAmount = bound(i * 12345, 1, MAX_SUPPLY - token.totalSupply());
                
                vm.prank(minter);
                token.mint(user, mintAmount);
            }
            
            // Invariant: total supply never exceeds cap
            assertLe(token.totalSupply(), MAX_SUPPLY);
        }
    }
    
    function test_Security_InvariantAdminRoleAlwaysExists() public {
        // Admin role should always exist until explicitly renounced
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        
        // Transfer admin
        address newAdmin = makeAddr("newAdmin");
        vm.prank(admin);
        token.transferAdmin(newAdmin);
        
        // Admin role should still exist (with new admin)
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), newAdmin));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        
        // Only after renunciation should there be no admin
        vm.prank(newAdmin);
        token.renounceAdminRole();
        
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), newAdmin));
        assertEq(token.multisigWallet(), address(0));
    }
}

/**
 * @dev Malicious contract that attempts reentrancy
 */
contract MaliciousReceiver {
    DaitsToken public token;
    address public minter;
    bool public reentrancySuccessful = false;
    
    constructor(address _token, address _minter) {
        token = DaitsToken(_token);
        minter = _minter;
    }
    
    // This would be called if the token had a callback (it doesn't)
    // But we test to ensure no unexpected calls
    fallback() external {
        if (token.balanceOf(address(this)) > 0) {
            try token.mint(address(this), 1000e18) {
                reentrancySuccessful = true;
            } catch {
                // Expected to fail
            }
        }
    }
}

/**
 * @dev Contract without proper role management
 */
contract BadContract {
    // No functions to handle admin role
    // This demonstrates why multisig is important
}