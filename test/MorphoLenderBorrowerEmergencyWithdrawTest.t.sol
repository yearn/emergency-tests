// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RolesVerification} from "./RolesVerification.sol";

contract MorphoLenderBorrowerEmergencyWithdrawTest is RolesVerification {
    uint256 private constant MAX_LOSS_BPS = 100; // 1%
    uint256 private constant BPS = 10_000;

    function test_morpho_lender_borrower_katana() public {
        uint256 katanaFork = vm.createFork("katana");
        vm.selectFork(katanaFork);

        address morphoVbWethYvUsdc = 0x2F0b01d1F36FB2c72f7DEB441a2a262e655d6888;
        vm.label(morphoVbWethYvUsdc, "morphoVbWethYvUsdc");
        address morphoVbWbtcYvUsdt = 0x3384246D42cAc0B8DD9BBDbE902A06D0814244f7;
        vm.label(morphoVbWbtcYvUsdt, "morphoVbWbtcYvUsdt");
        address morphoVbWbtcYvUsdc = 0x0432337365d89c0D73f1D0Cb263791F8f1B98D43;
        vm.label(morphoVbWbtcYvUsdc, "morphoVbWbtcYvUsdc");

        console.log("morphoVbWethYvUsdc", morphoVbWethYvUsdc);
        verifyEmergencyExit(morphoVbWethYvUsdc);
        console.log("morphoVbWbtcYvUsdt", morphoVbWbtcYvUsdt);
        verifyEmergencyExit(morphoVbWbtcYvUsdt);
        console.log("morphoVbWbtcYvUsdc", morphoVbWbtcYvUsdc);
        verifyEmergencyExit(morphoVbWbtcYvUsdc);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(strategyAddress);

        verifyRoles(strategy);

        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(type(uint256).max);

        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(strategyAddress);
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");
        uint256 minRecovered = Math.min(assets, maxWithdrawAmount) * (BPS - MAX_LOSS_BPS) / BPS;
        assertGe(strategyBalance, minRecovered, "strategy didn't recover all asset");
        assertGe(strategy.totalAssets(), assets * (BPS - MAX_LOSS_BPS) / BPS, "emergency withdraw lost money");
    }
}
