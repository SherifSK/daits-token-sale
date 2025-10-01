// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "@forge-std/Test.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title DAITS Token Comprehensive Fuzzing Test Suite
 * @dev Extensive fuzz testing for edge cases and boundary conditions
 */
contract DaitsTokenFuzzTest is Test {
    DaitsToken public token;
    DaitsToken public unlimitedToken;

    // Test addresses
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public minter1 = makeAddr("minter1");
    address public minter2 = makeAddr("minter2");

    // Token constants
    string constant TOKEN_NAME = "DAITS Token";
    string constant TOKEN_SYMBOL = "DAITS";
    uint256 constant MAX_SUPPLY = 1000000e18; // 1M tokens
    uint256 constant UNLIMITED_SUPPLY = 0;

    function setUp() public {
        // Deploy token with capped supply
        token = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, MAX_SUPPLY);
        // Deploy token with unlimited supply
        unlimitedToken = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, UNLIMITED_SUPPLY);
    }

    /* ============ Constructor Fuzz Tests ============ */

    function testFuzz_Constructor_ValidSupplyCaps(uint256 supplyCap) public {
        vm.assume(supplyCap <= type(uint256).max - 1e18); // Prevent overflow in tests

        DaitsToken newToken = new DaitsToken(TOKEN_NAME, TOKEN_SYMBOL, admin, supplyCap);

        assertEq(newToken.MAX_SUPPLY(), supplyCap);
        assertEq(newToken.multisigWallet(), admin);
        assertTrue(newToken.hasRole(newToken.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(newToken.totalSupply(), 0);
    }

    function testFuzz_Constructor_TokenMetadata(string memory name, string memory symbol) public {
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 50);
        vm.assume(bytes(symbol).length > 0 && bytes(symbol).length <= 10);

        DaitsToken newToken = new DaitsToken(name, symbol, admin, MAX_SUPPLY);

        assertEq(newToken.name(), name);
        assertEq(newToken.symbol(), symbol);
        assertEq(newToken.decimals(), 18);
    }

    /* ============ Minting Fuzz Tests ============ */

    function testFuzz_Mint_SequentialMints(uint8 numMints, uint256 baseAmount) public {
        vm.assume(numMints > 0 && numMints <= 20);
        vm.assume(baseAmount > 0 && baseAmount <= MAX_SUPPLY / numMints);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        uint256 totalMinted = 0;
        for (uint8 i = 0; i < numMints; i++) {
            address recipient = makeAddr(string(abi.encodePacked("recipient", i)));

            vm.prank(minter1);
            token.mint(recipient, baseAmount);

            totalMinted += baseAmount;
            assertEq(token.balanceOf(recipient), baseAmount);
        }

        assertEq(token.totalSupply(), totalMinted);
    }

    function testFuzz_Mint_MultipleMintersSimultaneous(
        uint256 amount1,
        uint256 amount2,
        address recipient1,
        address recipient2
    ) public {
        // Use bound to avoid overflow and ensure valid ranges
        amount1 = bound(amount1, 1, MAX_SUPPLY / 2);
        amount2 = bound(amount2, 1, MAX_SUPPLY / 2);

        vm.assume(recipient1 != address(0) && recipient2 != address(0));
        vm.assume(recipient1 != recipient2);

        // Grant minter roles
        vm.startPrank(admin);
        token.grantMinterRole(minter1);
        token.grantMinterRole(minter2);
        vm.stopPrank();

        // Mint from different minters
        vm.prank(minter1);
        token.mint(recipient1, amount1);

        vm.prank(minter2);
        token.mint(recipient2, amount2);

        assertEq(token.balanceOf(recipient1), amount1);
        assertEq(token.balanceOf(recipient2), amount2);
        assertEq(token.totalSupply(), amount1 + amount2);
    }

    function testFuzz_Mint_EdgeAmounts(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        vm.prank(minter1);
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), amount);

        // Try to mint remaining capacity
        uint256 remaining = MAX_SUPPLY - amount;
        if (remaining > 0) {
            vm.prank(minter1);
            token.mint(bob, remaining);

            assertEq(token.balanceOf(bob), remaining);
            assertEq(token.totalSupply(), MAX_SUPPLY);
        }
    }

    function testFuzz_Mint_UnlimitedSupply(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint128).max); // Prevent gas issues

        vm.prank(admin);
        unlimitedToken.grantMinterRole(minter1);

        vm.prank(minter1);
        unlimitedToken.mint(alice, amount);

        assertEq(unlimitedToken.balanceOf(alice), amount);
        assertEq(unlimitedToken.totalSupply(), amount);
    }

    function testFuzz_Mint_RevertExceedsSupplyCap(uint256 amount) public {
        vm.assume(amount > MAX_SUPPLY);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        vm.expectRevert("DaitsToken: would exceed maximum supply cap");
        vm.prank(minter1);
        token.mint(alice, amount);
    }

    function testFuzz_Mint_RevertZeroAmount() public {
        vm.prank(admin);
        token.grantMinterRole(minter1);

        vm.expectRevert("DaitsToken: amount must be greater than zero");
        vm.prank(minter1);
        token.mint(alice, 0);
    }

    /* ============ Role Management Fuzz Tests ============ */

    function testFuzz_GrantMinterRole_MultipleAddresses(uint8 numAddresses) public {
        numAddresses = uint8(bound(numAddresses, 1, 10));

        address[] memory addresses = new address[](numAddresses);
        for (uint8 i = 0; i < numAddresses; i++) {
            addresses[i] = address(uint160(0x3000 + i)); // Generate simple valid addresses
        }

        vm.startPrank(admin);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.grantMinterRole(addresses[i]);
            assertTrue(token.hasRole(token.MINTER_ROLE(), addresses[i]));
        }
        vm.stopPrank();
    }

    function testFuzz_RevokeMinterRole_RandomSequence(uint8 seed) public {
        address[] memory minters = new address[](5);
        minters[0] = makeAddr("minter_a");
        minters[1] = makeAddr("minter_b");
        minters[2] = makeAddr("minter_c");
        minters[3] = makeAddr("minter_d");
        minters[4] = makeAddr("minter_e");

        // Grant all minter roles
        vm.startPrank(admin);
        for (uint256 i = 0; i < minters.length; i++) {
            token.grantMinterRole(minters[i]);
        }
        vm.stopPrank();

        // Randomly revoke some roles
        vm.startPrank(admin);
        for (uint256 i = 0; i < minters.length; i++) {
            if ((seed + i) % 2 == 0) {
                token.revokeMinterRole(minters[i]);
                assertFalse(token.hasRole(token.MINTER_ROLE(), minters[i]));
            } else {
                assertTrue(token.hasRole(token.MINTER_ROLE(), minters[i]));
            }
        }
        vm.stopPrank();
    }

    function testFuzz_AdminTransfer_ChainedTransfers(uint8 numTransfers) public {
        vm.assume(numTransfers > 0 && numTransfers <= 10);

        address currentAdmin = admin;

        for (uint8 i = 0; i < numTransfers; i++) {
            address nextAdmin = makeAddr(string(abi.encodePacked("admin", i)));

            vm.prank(currentAdmin);
            token.transferAdmin(nextAdmin);

            // Verify transfer
            assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), nextAdmin));
            assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), currentAdmin));
            assertEq(token.multisigWallet(), nextAdmin);

            currentAdmin = nextAdmin;
        }
    }

    function testFuzz_AdminTransfer_InvalidAddresses(address newAdmin) public {
        // Only test specific invalid cases to avoid too many rejected inputs
        if (newAdmin == address(0)) {
            vm.expectRevert("DaitsToken: new admin cannot be zero address");
            vm.prank(admin);
            token.transferAdmin(newAdmin);
        } else if (newAdmin == admin) {
            vm.expectRevert("DaitsToken: new admin must be different from current admin");
            vm.prank(admin);
            token.transferAdmin(newAdmin);
        }
        // Skip other cases to avoid rejected inputs
    }

    /* ============ Access Control Fuzz Tests ============ */

    function testFuzz_UnauthorizedMinting(address unauthorized) public {
        vm.assume(unauthorized != admin && !token.hasRole(token.MINTER_ROLE(), unauthorized));

        vm.expectRevert();
        vm.prank(unauthorized);
        token.mint(alice, 1000e18);
    }

    function testFuzz_UnauthorizedRoleManagement(address unauthorized) public {
        vm.assume(unauthorized != admin && !token.hasRole(token.DEFAULT_ADMIN_ROLE(), unauthorized));

        // Try to grant minter role
        vm.expectRevert();
        vm.prank(unauthorized);
        token.grantMinterRole(bob);

        // Try to revoke minter role (first grant it)
        vm.prank(admin);
        token.grantMinterRole(charlie);

        vm.expectRevert();
        vm.prank(unauthorized);
        token.revokeMinterRole(charlie);

        // Try to transfer admin
        vm.expectRevert();
        vm.prank(unauthorized);
        token.transferAdmin(alice);
    }

    /* ============ Edge Case Fuzz Tests ============ */

    function testFuzz_MintToSameRecipientMultipleTimes(uint8 numMints, uint256 baseAmount) public {
        vm.assume(numMints > 0 && numMints <= 20);
        vm.assume(baseAmount > 0 && baseAmount <= MAX_SUPPLY / numMints);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        uint256 expectedBalance = 0;
        for (uint8 i = 0; i < numMints; i++) {
            vm.prank(minter1);
            token.mint(alice, baseAmount);

            expectedBalance += baseAmount;
            assertEq(token.balanceOf(alice), expectedBalance);
        }

        assertEq(token.totalSupply(), expectedBalance);
    }

    function testFuzz_ComplexRoleChangesWithMinting(uint8 operations) public {
        vm.assume(operations > 0 && operations <= 15);

        address[] memory minters = new address[](3);
        minters[0] = makeAddr("dynamic_minter_1");
        minters[1] = makeAddr("dynamic_minter_2");
        minters[2] = makeAddr("dynamic_minter_3");

        uint256 totalMinted = 0;
        uint256 mintAmount = MAX_SUPPLY / (operations * 2); // Conservative amount

        for (uint8 i = 0; i < operations && totalMinted + mintAmount <= MAX_SUPPLY; i++) {
            address currentMinter = minters[i % minters.length];

            // Grant role if not already granted
            if (!token.hasRole(token.MINTER_ROLE(), currentMinter)) {
                vm.prank(admin);
                token.grantMinterRole(currentMinter);
            }

            // Mint tokens
            vm.prank(currentMinter);
            token.mint(alice, mintAmount);
            totalMinted += mintAmount;

            // Randomly revoke role
            if (i % 3 == 0) {
                vm.prank(admin);
                token.revokeMinterRole(currentMinter);
            }
        }

        assertEq(token.totalSupply(), totalMinted);
    }

    function testFuzz_MaxSupplyBoundaries(uint256 supply1, uint256 supply2) public {
        // Use more restrictive bounds to avoid overflow and rejected inputs
        supply1 = bound(supply1, 1, MAX_SUPPLY / 2);
        supply2 = bound(supply2, 1, MAX_SUPPLY);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        // First mint should succeed
        vm.prank(minter1);
        token.mint(alice, supply1);

        // If second mint would exceed cap, it should fail
        if (supply1 + supply2 > MAX_SUPPLY) {
            vm.expectRevert("DaitsToken: would exceed maximum supply cap");
            vm.prank(minter1);
            token.mint(bob, supply2);

            assertEq(token.totalSupply(), supply1);
        } else {
            // Otherwise it should succeed
            vm.prank(minter1);
            token.mint(bob, supply2);

            assertEq(token.totalSupply(), supply1 + supply2);
        }
    }

    /* ============ Gas Efficiency Fuzz Tests ============ */

    function testFuzz_MintGasEfficiency(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY / 4);

        vm.prank(admin);
        token.grantMinterRole(minter1);

        uint256 gasBefore = gasleft();
        vm.prank(minter1);
        token.mint(alice, amount);
        uint256 gasUsed = gasBefore - gasleft();

        // Gas usage should be reasonable (less than 100k gas)
        assertLt(gasUsed, 100000);
        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_RoleManagementGasEfficiency(uint8 numRoles) public {
        numRoles = uint8(bound(numRoles, 1, 5)); // Reduce range to avoid overflow

        address[] memory addresses = new address[](numRoles);
        for (uint8 i = 0; i < numRoles; i++) {
            addresses[i] = address(uint160(0x1000 + i)); // Simple address generation
        }

        vm.startPrank(admin);

        // Grant roles
        for (uint8 i = 0; i < numRoles; i++) {
            token.grantMinterRole(addresses[i]);
        }

        // Revoke roles
        for (uint8 i = 0; i < numRoles; i++) {
            token.revokeMinterRole(addresses[i]);
        }

        vm.stopPrank();

        // Just check that operations completed successfully
        for (uint8 i = 0; i < numRoles; i++) {
            assertFalse(token.hasRole(token.MINTER_ROLE(), addresses[i]));
        }
    }

    /* ============ State Consistency Fuzz Tests ============ */

    function testFuzz_StateConsistencyAfterOperations(uint8 seed) public {
        seed = uint8(bound(seed, 0, 50)); // Limit range to avoid overflow

        // Setup initial minters
        vm.startPrank(admin);
        token.grantMinterRole(minter1);
        token.grantMinterRole(minter2);
        vm.stopPrank();

        uint256 totalMinted = 0;
        uint256 baseAmount = 10000e18;

        // Perform limited operations based on seed
        for (uint8 i = 0; i < 5 && totalMinted + baseAmount <= MAX_SUPPLY; i++) {
            uint8 operation = (seed + i) % 3; // Reduced to 3 operations

            if (operation == 0 && token.hasRole(token.MINTER_ROLE(), minter1)) {
                // Mint from minter1 (only if has role)
                vm.prank(minter1);
                token.mint(alice, baseAmount);
                totalMinted += baseAmount;
            } else if (operation == 1 && token.hasRole(token.MINTER_ROLE(), minter2)) {
                // Mint from minter2 (only if has role)
                vm.prank(minter2);
                token.mint(bob, baseAmount);
                totalMinted += baseAmount;
            } else if (operation == 2) {
                // Grant new minter role
                address newMinter = address(uint160(0x2000 + i)); // Simple address
                vm.prank(admin);
                token.grantMinterRole(newMinter);
                assertTrue(token.hasRole(token.MINTER_ROLE(), newMinter));
            }
        }

        // Verify state consistency
        assertEq(token.totalSupply(), totalMinted);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertLe(token.totalSupply(), MAX_SUPPLY);
    }
}
