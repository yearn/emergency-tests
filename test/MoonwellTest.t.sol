// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RolesVerification} from "./RolesVerification.sol";

contract MoonwellTest is RolesVerification {
    function test_moonwell_lender_borrower_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);

        address moonwellUsdcToWeth = 0xfdB431E661372fA1146efB70bf120ECDed944a78;
        address moonwellcbBtcToWeth = 0x03c5AfF0cd5e40889d689fD9D9Caff286b1BD7Fb;
        // address moonwellWethTocbBtc = 0x8436027a799Ac6c8B512E68b4d3852217c63647d;
        address moonwellcbEthToWeth = 0xd89A4f020C8d256a2A4B0dC40B36Ee0b27680776;

        console.log("moonwellUsdcToWeth", moonwellUsdcToWeth);
        verifyEmergencyExitLenderBorrower(moonwellUsdcToWeth);
        console.log("moonwellcbBtcToWeth", moonwellcbBtcToWeth);
        verifyEmergencyExitLenderBorrower(moonwellcbBtcToWeth);
        // console.log("moonwellWethTocbBtc", moonwellWethTocbBtc);
        // verifyEmergencyExitLenderBorrower(moonwellWethTocbBtc);
        console.log("moonwellcbEthToWeth", moonwellcbEthToWeth);
        verifyEmergencyExitLenderBorrower(moonwellcbEthToWeth);
    }

    function test_moonwell_farmer_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);

        address levMoonwellWeth = 0x7c0Fa3905B38D44C0F29150FD61f182d1e097EC2;
        // address levMoonwellWstEth = 0x44da1202285eD9678dAB99B55AaDB2fA549fDFDC;
        // address levMoonwellcbEth = 0xDd120ded7c1c9E4978f92847bcb24847A9dBb071;
        address levMoonwellcbBtc = 0xBb808A822dD7aEd1635956b85ca5e55478cCa957;

        console.log("levMoonwellWeth", levMoonwellWeth);
        verifyEmergencyExitFarmer(levMoonwellWeth);
        // console.log("levMoonwellWstEth", levMoonwellWstEth);
        // verifyEmergencyExitFarmer(levMoonwellWstEth);
        // console.log("levMoonwellcbEth", levMoonwellcbEth);
        // verifyEmergencyExitFarmer(levMoonwellcbEth);
        console.log("levMoonwellcbBtc", levMoonwellcbBtc);
        verifyEmergencyExitFarmer(levMoonwellcbBtc);
    }

    function verifyEmergencyExitLenderBorrower(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(type(uint256).max);

        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(strategyAddress);
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // verify strategy has recovered all assets or maximum possible
        uint256 minRecovered = Math.min(assets, maxWithdrawAmount) * 995 / 1000; // 0.5% can be left in the strategy until the rewards are sold
        assertGe(strategyBalance, Math.min(assets, minRecovered), "strategy didn't recover all asset");
        assertGe(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(strategyAddress), balanceOfAsset, "strategy balance not increased");
    }

    function verifyEmergencyExitFarmer(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(strategyAddress);

        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(type(uint256).max);

        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(strategyAddress);
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // verify strategy has recovered all assets or maximum possible
        uint256 minRecovered = Math.min(assets, maxWithdrawAmount) * 99 / 100; // 1% can be left in the strategy
        assertGe(strategyBalance, Math.min(assets, minRecovered), "strategy didn't recover all asset");
        assertGe(strategy.totalAssets(), assets, "emergency withdraw lost money"); // accept 1% loss
        assertGt(ERC20(strategy.asset()).balanceOf(strategyAddress), balanceOfAsset, "strategy balance not increased");
    }
}
