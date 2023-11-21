// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "evc/EthereumVaultConnector.sol";
import "../src/vaults/VaultRegularBorrowable.sol";
import "../test/mocks/IRMMock.sol";
import "../test/mocks/PriceOracleMock.sol";

contract Deployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);
        vm.startBroadcast(deployerPrivateKey);

        // deploy the EVC
        IEVC evc = new EthereumVaultConnector();

        // deploy mock ERC-20 tokens
        MockERC20 collateralAsset1 = new MockERC20("Collateral Asset 1", "CA1", 18);
        MockERC20 collateralAsset2 = new MockERC20("Collateral Asset 2", "CA2", 6);
        MockERC20 liabilityAsset = new MockERC20("Liability Asset", "LA", 18);
        MockERC20 referenceAsset = new MockERC20("Reference Asset", "RA", 18);

        // deply mock IRM
        IRMMock irm = new IRMMock();

        // setup the IRM
        irm.setInterestRate(10); // 10% APY

        // deploy mock price oracle
        PriceOracleMock oracle = new PriceOracleMock();

        // setup the price oracle
        oracle.setQuote(address(liabilityAsset), address(referenceAsset), 1e17); // 1 LA = 0.1 RA
        oracle.setQuote(address(collateralAsset1), address(referenceAsset), 1e16); // 1 CA1 = 0.01 RA
        oracle.setQuote(address(collateralAsset2), address(referenceAsset), 1e17); // 1 CA2 = 0.1 RA

        // deploy simple collateral vaults
        VaultSimple collateralVault1 = new VaultSimple(
            evc,
            collateralAsset1,
            "Collateral Vault 1",
            "CV1"
        );

        VaultSimple collateralVault2 = new VaultSimple(
            evc,
            collateralAsset2,
            "Collateral Vault 2",
            "CV2"
        );

        // deploy regular borrowable vault
        VaultRegularBorrowable liabilityVault = new VaultRegularBorrowable(
            evc,
            liabilityAsset,
            irm,
            oracle,
            referenceAsset,
            "Liability Vault",
            "LV"
        );

        // setup the liability vault
        liabilityVault.setCollateralFactor(liabilityVault, 95); // cf = 0.95, self-collateralization
        liabilityVault.setCollateralFactor(collateralVault1, 80); // cf = 0.8
        liabilityVault.setCollateralFactor(collateralVault2, 50); // cf = 0.5

        // mint some tokens to the deployer
        address deployer = vm.addr(deployerPrivateKey);
        liabilityAsset.mint(deployer, 1e6 * 1e18);
        collateralAsset1.mint(deployer, 1e6 * 1e18);
        collateralAsset2.mint(deployer, 1e6 * 1e6);

        vm.stopBroadcast();

        // display the addresses
        console.log("Deployer", deployer);
        console.log("EVC", address(evc));
        console.log("IRM", address(irm));
        console.log("Price Oracle", address(oracle));
        console.log("Collateral Asset 1", address(collateralAsset1));
        console.log("Collateral Asset 2", address(collateralAsset2));
        console.log("Liability Asset", address(liabilityAsset));
        console.log("Reference Asset", address(referenceAsset));
        console.log("Collateral Vault 1", address(collateralVault1));
        console.log("Collateral Vault 2", address(collateralVault2));
        console.log("Liability Vault", address(liabilityVault));
    }
}
