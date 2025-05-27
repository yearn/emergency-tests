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
        console.log("Current block number on mainnet:", block.number);

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
        console.log("Current block number on mainnet:", block.number);

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
        console.log("Current block number on mainnet:", block.number);

        address morphoYearnOgWeth = 0xd9BA99D93ea94a65b5BC838a0106cA3AbC82Ec4F;
        address morphoYearnOgDai = 0x75f35498E0D053d0DBd2472BC06e7CbA1f0c7d3a;
        address morphoUsdcSteakhouse = 0x074134A2784F4F66b6ceD6f68849382990Ff3215;
        address morphoUsdcGauntletPrime = 0x694E47AFD14A64661a04eee674FB331bCDEF3737;
        address morphoUsdtGauntletPrime = 0x6D2981FF9b8d7edbb7604de7A65BAC8694ac849F;
        address morphoDaiGauntletCore = 0x09580f2305a335218bdB2EB828387d52ED8Fc2F4;
        address morphoWethGauntletLrt = 0x70E75D8053e3Fb0Dda35e80EB16f208c7e4D54F4;
        address morphoWethGauntletPrime = 0xeEB6Be70fF212238419cD638FAB17910CF61CBE7;
        verifyEmergencyExit(morphoYearnOgWeth);
        verifyEmergencyExit(morphoYearnOgDai);
        verifyEmergencyExit(morphoUsdcSteakhouse);
        verifyEmergencyExit(morphoUsdcGauntletPrime);
        verifyEmergencyExit(morphoUsdtGauntletPrime);
        verifyEmergencyExit(morphoDaiGauntletCore);
        verifyEmergencyExit(morphoWethGauntletLrt);
        verifyEmergencyExit(morphoWethGauntletPrime);

        // NOTE: not used anymore
        // address morphoUsdcGauntletCore = 0x4A77913d07b4154600A1E37234336f8273409c96;
        // address morphoUsdcUsualBoosted = 0xb6da41D4BDb484BDaD0BfAa79bC8E182E5095F7e;
        // verifyEmergencyExit(morphoUsdcGauntletCore);
        // verifyEmergencyExit(morphoUsdcUsualBoosted);
    }

    function test_morpho_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);
        console.log("Current block number on base:", block.number);

        address morphoYearnOgWeth = 0xBDD79a7DF622E9d9e19a7d92Bc7ea212FA0D2F3E;
        address morphoYearnOgUsdc = 0xF115C134c23C7A05FBD489A8bE3116EbF54B0D9f;
        address morphoUsdcMoonwell = 0xd5428B889621Eee8060fc105AA0AB0Fa2e344468;
        address morphoEurcMoonwell = 0x985CC9c306Bfe075F7c67EC275fb0b80F0b21976;
        address morphoWethMoonwell = 0xEF34B4Dcb851385b8F3a8ff460C34aDAFD160802;
        verifyEmergencyExit(morphoYearnOgWeth);
        verifyEmergencyExit(morphoYearnOgUsdc);
        verifyEmergencyExit(morphoUsdcMoonwell);
        verifyEmergencyExit(morphoEurcMoonwell);
        verifyEmergencyExit(morphoWethMoonwell);
    }

    function test_compound_blue_polygon() public {
        uint256 polygonFork = vm.createFork("polygon");
        vm.selectFork(polygonFork);
        console.log("Current block number on polygon:", block.number);

        address compoundBlueWeth = 0xD4a0AA006e0f70580Aaa7ee1FD04Fa447c36B259;
        // address compoundBlueUsdc = 0x6E9ac188DbCC14632a253aA9Ce2783cD712aB3cA;
        address compoundBlueUsdt = 0x9d1046ceCB0662037b13dECF1CD125C4Aa3fb65B;
        verifyEmergencyExit(compoundBlueWeth);
        // verifyEmergencyExit(compoundBlueUsdc);
        verifyEmergencyExit(compoundBlueUsdt);
    }

    function test_euler_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address eulerPrimeWeth = 0xaf48f006e75AF050c4136F5a32B69e3FE1C4140f;
        verifyEmergencyExit(eulerPrimeWeth);
    }

    function verifyGearboxEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 valueOfVault = strategy.valueOfVault();

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
        if (maxWithdrawAmount < 100) {
            return; // skip dust
        }
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 currentValueOfVault = strategy.valueOfVault();
        uint256 roundingError = 10;

        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(currentBalance, balanceOfAsset, "strategy balance not increased");
        // verify strategy has recovered all assets or maximum possible
        assertGe(currentBalance + roundingError, maxWithdrawAmount, "strategy didn't recover all asset");
        // valut value is both staked and asset value: https://github.com/yearn/tokenized-strategy-periphery/blob/f139be6286cb3d630b0bce6d6db812c709e5bb47/src/Bases/4626Compounder/Base4626Compounder.sol#L165
        assertLt(currentValueOfVault, valueOfVault, "all value stayed in the vault");
        assertGt(currentBalance, balanceOfAsset, "strategy balance not increased");
        assertApproxEqAbs(currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, roundingError, "strategy lost value");
    }

    function verifySturdyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 valueOfVault = strategy.valueOfVault();

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
        if (maxWithdrawAmount < 100) {
            return; // skip dust
        }
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // study strategy has some rounding error because of converting assets to shares
        uint256 roundingError = 10;
        // verify strategy has recovered all assets or maximum possible
        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 currentValueOfVault = strategy.valueOfVault();

        assertGe(currentBalance + roundingError, maxWithdrawAmount, "strategy didn't recover all asset");
        assertLt(currentValueOfVault, valueOfVault, "all value stayed in the vault");
        assertGt(currentBalance, balanceOfAsset, "strategy balance not increased");
        assertApproxEqAbs(currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, roundingError, "strategy lost value");
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
        uint256 valueOfVault = strategy.valueOfVault();
        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        if (maxWithdrawAmount < 100) {
            return; // skip dust
        }
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy didn't lose any funds
        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 currentValueOfVault = strategy.valueOfVault();

        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(currentBalance, balanceOfAsset, "strategy balance not increased");
        assertGe(currentBalance, maxWithdrawAmount, "strategy didn't recover all asset");
        assertApproxEqAbs(currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, 10, "strategy lost value");
    }
}
