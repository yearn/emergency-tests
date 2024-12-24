// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface IBase4626Compounder is ITokenizedStrategy {
    function vault() external view returns (address);

    function balanceOfAsset() external view returns (uint256);

    function balanceOfVault() external view returns (uint256);

    function balanceOfStake() external view returns (uint256);

    function valueOfVault() external view returns (uint256);

    function vaultsMaxWithdraw() external view returns (uint256);

    function staking() external view returns (address);
}

interface ISturdy {
    function pair() external view returns (address);
}

contract Base4626EmergencyWithdrawTest is Test {
    function test_gearbox_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address gearboxWeth = 0xe92ade9eE76681f96C8BB0b352d5410ca5b35D70;
        address gearboxCrv = 0xbf2e5BeD692C09aF8B39677e315F36aDF39bD685;
        address gearboxUsdc = 0xf6E2d36c489e5B361CdC962D4568ceA663AD5ddC;
        verifyGearboxEmergencyExit(gearboxWeth);
        verifyGearboxEmergencyExit(gearboxCrv);
        verifyGearboxEmergencyExit(gearboxUsdc);
    }

    function test_sturdy_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address sturdyCrvCompounder = 0x05329AAb081B125eEF7FbbC8b857428D478E692B;
        address sturdyWeth = 0x5f76526390d9cd9944d65C605C5006480FA1bFcB;
        address sturdyPxEth = 0xC40dC53931cd184F782f3602d95C7e3609706004;
        verifySturdyEmergencyExit(sturdyCrvCompounder);
        verifySturdyEmergencyExit(sturdyWeth);
        verifySturdyEmergencyExit(sturdyPxEth);
    }

    function test_morpho_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address morphoUsdcSteakhouse = 0x074134A2784F4F66b6ceD6f68849382990Ff3215;
        address morphoUsdcGauntletCore = 0x4A77913d07b4154600A1E37234336f8273409c96;
        address morphoUsdcGauntletPrime = 0x694E47AFD14A64661a04eee674FB331bCDEF3737;
        address morphoUsdcUsualBoosted = 0xb6da41D4BDb484BDaD0BfAa79bC8E182E5095F7e;
        address morphoDaiGauntletCore = 0x09580f2305a335218bdB2EB828387d52ED8Fc2F4;
        address morphoWethGauntletLrt = 0x70E75D8053e3Fb0Dda35e80EB16f208c7e4D54F4;
        address morphoWethGauntletPrime = 0xeEB6Be70fF212238419cD638FAB17910CF61CBE7;
        verifyEmergencyExit(morphoUsdcSteakhouse);
        verifyEmergencyExit(morphoUsdcGauntletCore);
        verifyEmergencyExit(morphoUsdcGauntletPrime);
        verifyEmergencyExit(morphoUsdcUsualBoosted);
        verifyEmergencyExit(morphoDaiGauntletCore);
        verifyEmergencyExit(morphoWethGauntletLrt);
        verifyEmergencyExit(morphoWethGauntletPrime);
    }

    function test_morpho_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);

        address morphoUsdcMoonwell = 0xd5428B889621Eee8060fc105AA0AB0Fa2e344468;
        address morphoEurcMoonwell = 0x985CC9c306Bfe075F7c67EC275fb0b80F0b21976;
        address morphoWethMoonwell = 0xEF34B4Dcb851385b8F3a8ff460C34aDAFD160802;
        verifyEmergencyExit(morphoUsdcMoonwell);
        verifyEmergencyExit(morphoEurcMoonwell);
        verifyEmergencyExit(morphoWethMoonwell);
    }

    function verifyGearboxEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 vaultValue = strategy.valueOfVault();

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        // IMPORTANT: need to override this: https://github.com/yearn/yearn-strategies/issues/642#issuecomment-2402732907
        IERC4626 vault = IERC4626(strategy.vault());
        uint256 maxWithdrawAmount =
            vault.convertToAssets(Math.min(vault.maxRedeem(strategy.staking()), strategy.balanceOfStake()));
        maxWithdrawAmount += strategy.balanceOfAsset();
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");
        // verify strategy has recovered all assets or maximum possible
        uint256 roundingError = 1;
        assertGe(strategyBalance + roundingError, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        // valut value is both staked and asset value: https://github.com/yearn/tokenized-strategy-periphery/blob/f139be6286cb3d630b0bce6d6db812c709e5bb47/src/Bases/4626Compounder/Base4626Compounder.sol#L165
        assertLt(strategy.valueOfVault(), vaultValue, "all value stayed in the vault");
    }

    function verifySturdyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 vaultValue = strategy.valueOfVault();

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        IVault vault = IVault(strategy.vault());
        ISturdy sturdy = ISturdy(vault.default_queue(0));
        address pair = sturdy.pair();
        uint256 maxWithdrawAmount =
            Math.min(strategy.availableWithdrawLimit(address(0)), ERC20(strategy.asset()).balanceOf(pair));
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // study strategy has some rounding error because of converting assets to shares
        uint256 roundingError = 3;
        // verify strategy has recovered all assets or maximum possible
        assertGe(strategyBalance + roundingError, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
        assertLt(strategy.valueOfVault(), vaultValue, "all value stayed in the vault");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        // assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        console.log("balanceOfAsset", balanceOfAsset);
        uint256 valueOfVault = strategy.valueOfVault();
        console.log("valueOfVault", valueOfVault);
        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy didn't lose any funds
        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");

        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 currentValueOfVault = strategy.valueOfVault();
        assertApproxEqAbs(currentBalance - currentValueOfVault, balanceOfAsset + valueOfVault, 10, "strategy lost value");
    }
}
