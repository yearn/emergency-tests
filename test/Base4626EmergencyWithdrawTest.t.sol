// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {RolesVerification} from "./RolesVerification.sol";

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

contract Base4626EmergencyWithdrawTest is RolesVerification {
    function test_gearbox_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address gearboxWeth = 0xe92ade9eE76681f96C8BB0b352d5410ca5b35D70;
        address gearboxCrv = 0xbf2e5BeD692C09aF8B39677e315F36aDF39bD685;
        address gearboxUsdc = 0xf6E2d36c489e5B361CdC962D4568ceA663AD5ddC;

        console.log("gearboxWeth", gearboxWeth);
        verifyGearboxEmergencyExit(gearboxWeth);
        console.log("gearboxCrv", gearboxCrv);
        verifyGearboxEmergencyExit(gearboxCrv);
        console.log("gearboxUsdc", gearboxUsdc);
        verifyGearboxEmergencyExit(gearboxUsdc);
    }

    function test_sturdy_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address sturdyCrvCompounder = 0x05329AAb081B125eEF7FbbC8b857428D478E692B;
        address sturdyWeth = 0x5f76526390d9cd9944d65C605C5006480FA1bFcB;
        address sturdyPxEth = 0xC40dC53931cd184F782f3602d95C7e3609706004;

        console.log("sturdyCrvCompounder", sturdyCrvCompounder);
        verifySturdyEmergencyExit(sturdyCrvCompounder);
        console.log("sturdyWeth", sturdyWeth);
        verifySturdyEmergencyExit(sturdyWeth);
        console.log("sturdyPxEth", sturdyPxEth);
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

        console.log("morphoYearnOgWeth", morphoYearnOgWeth);
        verifyEmergencyExit(morphoYearnOgWeth);
        console.log("morphoYearnOgDai", morphoYearnOgDai);
        verifyEmergencyExit(morphoYearnOgDai);
        console.log("morphoUsdcSteakhouse", morphoUsdcSteakhouse);
        verifyEmergencyExit(morphoUsdcSteakhouse);
        console.log("morphoUsdcGauntletPrime", morphoUsdcGauntletPrime);
        verifyEmergencyExit(morphoUsdcGauntletPrime);
        console.log("morphoUsdtGauntletPrime", morphoUsdtGauntletPrime);
        verifyEmergencyExit(morphoUsdtGauntletPrime);
        console.log("morphoDaiGauntletCore", morphoDaiGauntletCore);
        verifyEmergencyExit(morphoDaiGauntletCore);
        console.log("morphoWethGauntletLrt", morphoWethGauntletLrt);
        verifyEmergencyExit(morphoWethGauntletLrt);
        console.log("morphoWethGauntletPrime", morphoWethGauntletPrime);
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

        console.log("morphoYearnOgWeth", morphoYearnOgWeth);
        verifyEmergencyExit(morphoYearnOgWeth);
        console.log("morphoYearnOgUsdc", morphoYearnOgUsdc);
        verifyEmergencyExit(morphoYearnOgUsdc);
        console.log("morphoUsdcMoonwell", morphoUsdcMoonwell);
        verifyEmergencyExit(morphoUsdcMoonwell);
        console.log("morphoEurcMoonwell", morphoEurcMoonwell);
        verifyEmergencyExit(morphoEurcMoonwell);
        console.log("morphoWethMoonwell", morphoWethMoonwell);
        verifyEmergencyExit(morphoWethMoonwell);
    }

    function test_morpho_katana() public {
        uint256 katanaFork = vm.createFork("katana");
        vm.selectFork(katanaFork);
        console.log("Current block number on katana:", block.number);

        address usdcStakehousePrime = 0x58B369aEC52DD904f70122cF72ed311f7AAe3bAc;
        address usdcGauntlet = 0xD46dFDAA7cAA8739B0e3274e2C085dFFc8d4776A;
        address usdcYearnOG = 0x78EC25FBa1bAf6b7dc097Ebb8115A390A2a4Ee12;

        address usdtGauntlet = 0x543CC24962b540430DD1121E83E8564770Da6810;
        address usdtYearnOG = 0x156C729C78076b7cd815D01Ca6967c00c5ac8D9C;

        address wbtcGauntlet = 0x0a1937F0D7f15B9ADee5d96616f269a0C6749C6d;

        address wethGauntlet = 0xEA79C91540C7E884e6E0069Ce036E52f7BbB1194;
        address wethYearnOG = 0x37a79Bfb9F645F8Ed0a9ead9c722710D8f47C431;

        address ausdGauntlet = 0xF7EDe5332c6b4A235be4aA3c019222CFe72e984F;
        address ausdStakehouse = 0xC1Ec6d26902949Bf6cbb0c9859dbEAD1E87FB243;

        console.log("usdcStakehousePrime", usdcStakehousePrime);
        verifyEmergencyExit(usdcStakehousePrime);
        console.log("usdcGauntlet", usdcGauntlet);
        verifyEmergencyExit(usdcGauntlet);
        console.log("usdcYearnOG", usdcYearnOG);
        verifyEmergencyExit(usdcYearnOG);
        console.log("usdtGauntlet", usdtGauntlet);
        verifyEmergencyExit(usdtGauntlet);
        console.log("usdtYearnOG", usdtYearnOG);
        verifyEmergencyExit(usdtYearnOG);
        console.log("wbtcGauntlet", wbtcGauntlet);
        verifyEmergencyExit(wbtcGauntlet);
        console.log("wethGauntlet", wethGauntlet);
        verifyEmergencyExit(wethGauntlet);
        console.log("wethYearnOG", wethYearnOG);
        verifyEmergencyExit(wethYearnOG);
        console.log("ausdGauntlet", ausdGauntlet);
        verifyEmergencyExit(ausdGauntlet);
        console.log("ausdStakehouse", ausdStakehouse);
        verifyEmergencyExit(ausdStakehouse);
    }

    function test_compound_blue_polygon() public {
        uint256 polygonFork = vm.createFork("polygon");
        vm.selectFork(polygonFork);
        console.log("Current block number on polygon:", block.number);

        address compoundBlueWeth = 0xD4a0AA006e0f70580Aaa7ee1FD04Fa447c36B259;
        // address compoundBlueUsdc = 0x6E9ac188DbCC14632a253aA9Ce2783cD712aB3cA;
        address compoundBlueUsdt = 0x9d1046ceCB0662037b13dECF1CD125C4Aa3fb65B;

        console.log("compoundBlueWeth", compoundBlueWeth);
        verifyEmergencyExit(compoundBlueWeth);
        // verifyEmergencyExit(compoundBlueUsdc);
        console.log("compoundBlueUsdt", compoundBlueUsdt);
        verifyEmergencyExit(compoundBlueUsdt);
    }

    function test_euler_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address eulerPrimeWeth = 0xaf48f006e75AF050c4136F5a32B69e3FE1C4140f;

        console.log("eulerPrimeWeth", eulerPrimeWeth);
        verifyEmergencyExit(eulerPrimeWeth);
    }

    function test_fluid_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address fluidUsdt = 0x4Bd05E6ff75b633F504F0fC501c1e257578C8A72;
        address fluidUsdc = 0x00C8a649C9837523ebb406Ceb17a6378Ab5C74cF;

        console.log("fluidUsdt", fluidUsdt);
        verifyEmergencyExit(fluidUsdt);
        console.log("fluidUsdc", fluidUsdc);
        verifyEmergencyExit(fluidUsdc);
    }

    function test_fluid_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);
        console.log("Current block number on base:", block.number);

        address fluidUsdc = 0x70ffFbacB53EF74903ac074aAE769414a70970d1;

        console.log("fluidUsdc", fluidUsdc);
        verifyEmergencyExit(fluidUsdc);
    }

    function verifyGearboxEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 valueOfVault = strategy.valueOfVault();

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
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
        assertApproxEqAbs(
            currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, roundingError, "strategy lost value"
        );
    }

    function verifySturdyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 valueOfVault = strategy.valueOfVault();

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
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
        assertApproxEqAbs(
            currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, roundingError, "strategy lost value"
        );
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

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
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
        assertApproxEqAbs(
            currentBalance + currentValueOfVault, balanceOfAsset + valueOfVault, 10, "strategy lost value"
        );
    }
}
