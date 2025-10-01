// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "@forge-std/Script.sol";
import {DaitsToken} from "../src/DaitsToken.sol";

/**
 * @title Deploy DAITS Token Script
 * @dev Foundry script to deploy the DAITS token with Safe multisig integration
 */
contract DeployDaitsToken is Script {
    // Default values - override with environment variables
    string constant DEFAULT_TOKEN_NAME = "DAITS Token";
    string constant DEFAULT_TOKEN_SYMBOL = "DAITS";

    function setUp() public {}

    function run() public {
        // Read configuration from environment variables
        string memory tokenName = vm.envOr("TOKEN_NAME", DEFAULT_TOKEN_NAME);
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_TOKEN_SYMBOL);
        address multisigAdmin = vm.envAddress("MULTISIG_ADMIN_ADDRESS");
        uint256 maxSupply = vm.envOr("MAX_SUPPLY", uint256(0)); // 0 = unlimited supply

        // Validate inputs
        require(multisigAdmin != address(0), "MULTISIG_ADMIN_ADDRESS must be set");

        console.log("=== DAITS Token Deployment ===");
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("Multisig Admin:", multisigAdmin);
        console.log("Max Supply:", maxSupply == 0 ? "Unlimited" : vm.toString(maxSupply));
        console.log("Deployer:", msg.sender);

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the DAITS token
        DaitsToken daitsToken = new DaitsToken(tokenName, tokenSymbol, multisigAdmin, maxSupply);

        vm.stopBroadcast();

        // Log deployment information
        console.log("=== Deployment Complete ===");
        console.log("DAITS Token deployed at:", address(daitsToken));
        console.log("Admin role granted to:", multisigAdmin);
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Verify the contract on Etherscan");
        console.log("2. Grant MINTER_ROLE to token sale contract via Safe multisig");
        console.log("3. Test minting functionality");
        console.log("4. Set up monitoring for admin actions");

        // Verify the deployment
        _verifyDeployment(daitsToken, multisigAdmin);
    }

    /**
     * @dev Verify the deployment was successful
     */
    function _verifyDeployment(DaitsToken token, address expectedAdmin) internal view {
        console.log("=== Deployment Verification ===");

        // Check token details
        require(
            keccak256(abi.encodePacked(token.name())) == keccak256(abi.encodePacked(DEFAULT_TOKEN_NAME))
                || keccak256(abi.encodePacked(token.name()))
                    == keccak256(abi.encodePacked(vm.envOr("TOKEN_NAME", DEFAULT_TOKEN_NAME))),
            "Token name mismatch"
        );

        require(
            keccak256(abi.encodePacked(token.symbol())) == keccak256(abi.encodePacked(DEFAULT_TOKEN_SYMBOL))
                || keccak256(abi.encodePacked(token.symbol()))
                    == keccak256(abi.encodePacked(vm.envOr("TOKEN_SYMBOL", DEFAULT_TOKEN_SYMBOL))),
            "Token symbol mismatch"
        );

        // Check admin role
        require(token.hasRole(token.DEFAULT_ADMIN_ROLE(), expectedAdmin), "Admin role not granted correctly");
        require(token.multisigWallet() == expectedAdmin, "Multisig wallet not set correctly");

        // Check initial supply
        require(token.totalSupply() == 0, "Initial supply should be zero");

        console.log("[OK] Token name and symbol verified");
        console.log("[OK] Admin role granted correctly");
        console.log("[OK] Multisig wallet set correctly");
        console.log("[OK] Initial supply is zero");
        console.log("[OK] Deployment verification passed");
    }
}
