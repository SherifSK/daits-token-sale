// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "@forge-std/Test.sol";
import {StdInvariant} from "@forge-std/StdInvariant.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title DAITS Token Invariant Tests
 * @dev Property-based testing for critical invariants
 */
contract DaitsTokenInvariantTest is StdInvariant, Test {
    DaitsToken public token;
    TokenHandler public handler;

    address public admin = makeAddr("admin");
    uint256 constant MAX_SUPPLY = 1000000e18;

    function setUp() public {
        token = new DaitsToken("DAITS Token", "DAITS", admin, MAX_SUPPLY);
        handler = new TokenHandler(token, admin);

        // Set up the handler as the target for invariant testing
        targetContract(address(handler));

        // Define selectors that can be called
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = TokenHandler.mint.selector;
        selectors[1] = TokenHandler.grantMinterRole.selector;
        selectors[2] = TokenHandler.revokeMinterRole.selector;
        selectors[3] = TokenHandler.transferAdmin.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @dev Total supply should never exceed MAX_SUPPLY
    function invariant_totalSupplyNeverExceedsCap() public view {
        assertLe(token.totalSupply(), MAX_SUPPLY);
    }

    /// @dev Sum of all balances should equal total supply
    function invariant_sumOfBalancesEqualsTotalSupply() public view {
        uint256 sumOfBalances = handler.sumOfBalances();
        assertEq(sumOfBalances, token.totalSupply());
    }

    /// @dev At least one admin should exist unless explicitly renounced
    function invariant_adminExistsUnlessRenounced() public view {
        if (!handler.adminRenounced()) {
            assertTrue(handler.hasAdmin());
        }
    }

    /// @dev Token should maintain ERC20 invariants
    function invariant_erc20Properties() public view {
        // Total supply should never decrease (no burning implemented)
        assertGe(token.totalSupply(), handler.minTotalSupply());

        // Token name and symbol should remain constant
        assertEq(token.name(), "DAITS Token");
        assertEq(token.symbol(), "DAITS");
        assertEq(token.decimals(), 18);
    }

    /// @dev MAX_SUPPLY should be immutable
    function invariant_maxSupplyImmutable() public view {
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
    }
}

/**
 * @title Token Handler for Invariant Testing
 * @dev Handles random operations on the token for property-based testing
 */
contract TokenHandler is Test {
    DaitsToken public token;
    address public currentAdmin;

    // Track state for invariants
    mapping(address => uint256) public balances;
    address[] public allUsers;
    uint256 public minTotalSupply;
    bool public adminRenounced;

    // Test users
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public minter1 = makeAddr("minter1");
    address public minter2 = makeAddr("minter2");

    modifier useCurrentAdmin() {
        vm.prank(currentAdmin);
        _;
    }

    constructor(DaitsToken _token, address _admin) {
        token = _token;
        currentAdmin = _admin;

        // Initialize users array
        allUsers.push(user1);
        allUsers.push(user2);
        allUsers.push(user3);

        // Grant initial minter roles
        vm.startPrank(_admin);
        token.grantMinterRole(minter1);
        token.grantMinterRole(minter2);
        vm.stopPrank();
    }

    function mint(uint256 amount, uint256 userIndex, uint256 minterIndex) public {
        // Bound inputs
        amount = bound(amount, 1, 100000e18);
        userIndex = bound(userIndex, 0, allUsers.length - 1);

        address minter = minterIndex % 2 == 0 ? minter1 : minter2;
        address user = allUsers[userIndex];

        // Check if minter has role
        if (!token.hasRole(token.MINTER_ROLE(), minter)) {
            return;
        }

        // Try to mint
        vm.prank(minter);
        try token.mint(user, amount) {
            balances[user] += amount;
            minTotalSupply = token.totalSupply();
        } catch {
            // Minting failed (probably hit supply cap)
        }
    }

    function grantMinterRole(address account) public useCurrentAdmin {
        if (account == address(0) || adminRenounced) return;

        try token.grantMinterRole(account) {
            // Role granted successfully
        } catch {
            // Failed to grant role
        }
    }

    function revokeMinterRole(address account) public useCurrentAdmin {
        if (adminRenounced) return;

        try token.revokeMinterRole(account) {
            // Role revoked successfully
        } catch {
            // Failed to revoke role
        }
    }

    function transferAdmin(address newAdmin) public useCurrentAdmin {
        if (newAdmin == address(0) || newAdmin == currentAdmin || adminRenounced) {
            return;
        }

        try token.transferAdmin(newAdmin) {
            currentAdmin = newAdmin;
        } catch {
            // Transfer failed
        }
    }

    function renounceAdmin() public useCurrentAdmin {
        if (adminRenounced) return;

        try token.renounceAdminRole() {
            adminRenounced = true;
            currentAdmin = address(0);
        } catch {
            // Renunciation failed
        }
    }

    // Helper functions for invariants
    function sumOfBalances() public view returns (uint256 sum) {
        for (uint256 i = 0; i < allUsers.length; i++) {
            sum += token.balanceOf(allUsers[i]);
        }
    }

    function hasAdmin() public view returns (bool) {
        return token.hasRole(token.DEFAULT_ADMIN_ROLE(), currentAdmin);
    }
}
