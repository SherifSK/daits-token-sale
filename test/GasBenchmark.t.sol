// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "@forge-std/Test.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title Gas Optimization Benchmark Tests
 * @notice Measures gas consumption for all DaitsToken functions to establish optimization baselines
 * @dev Run with: forge test --match-contract GasBenchmark --gas-report
 */
contract GasBenchmarkTest is Test {
    DaitsToken public token;
    address public admin = address(0x1);
    address public minter = address(0x2); 
    address public user = address(0x3);
    
    function setUp() public {
        // Deploy token with supply cap for consistent measurements
        token = new DaitsToken("DAITS Token", "DAITS", admin, 1_000_000 * 10**18);
        
        // Grant minter role for testing
        vm.prank(admin);
        token.grantMinterRole(minter);
    }

    /// @notice Benchmark: Token deployment gas cost
    function test_GasBenchmark_Deployment() public {
        uint256 gasStart = gasleft();
        new DaitsToken("Test Token", "TEST", admin, 1_000_000 * 10**18);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Deployment Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Minting tokens gas cost
    function test_GasBenchmark_Mint() public {
        uint256 amount = 1000 * 10**18;
        
        vm.prank(minter);
        uint256 gasStart = gasleft();
        token.mint(user, amount);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Mint Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Grant minter role gas cost  
    function test_GasBenchmark_GrantMinterRole() public {
        address newMinter = address(0x4);
        
        vm.prank(admin);
        uint256 gasStart = gasleft();
        token.grantMinterRole(newMinter);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Grant Minter Role Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Revoke minter role gas cost
    function test_GasBenchmark_RevokeMinterRole() public {
        vm.prank(admin);
        uint256 gasStart = gasleft();
        token.revokeMinterRole(minter);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Revoke Minter Role Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Transfer admin role gas cost
    function test_GasBenchmark_TransferAdmin() public {
        address newAdmin = address(0x5);
        
        vm.prank(admin);
        uint256 gasStart = gasleft();
        token.transferAdmin(newAdmin);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Transfer Admin Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Renounce admin role gas cost
    function test_GasBenchmark_RenounceAdminRole() public {
        // Deploy separate token for this destructive test
        DaitsToken testToken = new DaitsToken("Test", "TEST", admin, 0);
        
        vm.prank(admin);
        uint256 gasStart = gasleft();
        testToken.renounceAdminRole();
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("Renounce Admin Role Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Standard ERC20 transfer gas cost
    function test_GasBenchmark_Transfer() public {
        // First mint tokens to user
        vm.prank(minter);
        token.mint(user, 1000 * 10**18);
        
        vm.prank(user);
        uint256 gasStart = gasleft();
        token.transfer(address(0x6), 100 * 10**18);
        uint256 gasUsed = gasStart - gasleft();
        
        emit log_named_uint("ERC20 Transfer Gas Cost", gasUsed);
    }

    /// @notice Benchmark: Multiple operations workflow
    function test_GasBenchmark_FullWorkflow() public {
        uint256 gasStart = gasleft();
        
        // Deploy new token
        DaitsToken newToken = new DaitsToken("Workflow Test", "WFT", admin, 1_000_000 * 10**18);
        
        // Grant minter role
        vm.prank(admin);
        newToken.grantMinterRole(minter);
        
        // Mint tokens
        vm.prank(minter);
        newToken.mint(user, 1000 * 10**18);
        
        // Transfer tokens
        vm.prank(user);
        newToken.transfer(address(0x7), 500 * 10**18);
        
        uint256 gasUsed = gasStart - gasleft();
        emit log_named_uint("Full Workflow Gas Cost", gasUsed);
    }
}