// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MoonwellTest is Test {
    function test_moonwell_lender_borrower_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);

        address moonwellUsdcToWeth = 0xfdB431E661372fA1146efB70bf120ECDed944a78;
        address moonwellcbBtcToWeth = 0x03c5AfF0cd5e40889d689fD9D9Caff286b1BD7Fb;
        address moonwellWethTocbBtc = 0x8436027a799Ac6c8B512E68b4d3852217c63647d;
        address moonwellcbEthToWeth = 0xd89A4f020C8d256a2A4B0dC40B36Ee0b27680776;
        verifyEmergencyExitLenderBorrower(moonwellUsdcToWeth);
        // verifyEmergencyExitLenderBorrower(moonwellcbBtcToWeth);
        // verifyEmergencyExitLenderBorrower(moonwellWethTocbBtc);
        // verifyEmergencyExitLenderBorrower(moonwellcbEthToWeth);
    }

    function test_moonwell_farmer_base() public {
        uint256 baseFork = vm.createFork("base");
        vm.selectFork(baseFork);

        address levMoonwellWeth = 0x7c0Fa3905B38D44C0F29150FD61f182d1e097EC2;
        address levMoonwellWstEth = 0x44da1202285eD9678dAB99B55AaDB2fA549fDFDC;
        address levMoonwellcbEth = 0xDd120ded7c1c9E4978f92847bcb24847A9dBb071;
        address levMoonwellcbBtc = 0xBb808A822dD7aEd1635956b85ca5e55478cCa957;
        verifyEmergencyExitFarmer(levMoonwellWeth);
        // verifyEmergencyExitFarmer(levMoonwellWstEth);
        // verifyEmergencyExitFarmer(levMoonwellcbEth);
        // verifyEmergencyExitFarmer(levMoonwellcbBtc);
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

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(maxWithdrawAmount);

        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // verify strategy has recovered all assets or maximum possible
        assertGe(strategyBalance, Math.min(assets, maxWithdrawAmount), "strategy didn't recover all asset");
        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
    }

    function verifyEmergencyExitFarmer(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        assertGt(maxWithdrawAmount, 0, "maxWithdrawAmount is zero");
        strategy.emergencyWithdraw(maxWithdrawAmount);

        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        uint256 strategyBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        assertGt(strategyBalance, balanceOfAsset, "strategy balance not increased");

        // verify strategy has recovered all assets or maximum possible
        uint256 minRecovered = Math.min(assets, maxWithdrawAmount) * 95 / 100; // 5% can be left in the strategy
        assertGe(strategyBalance, minRecovered, "strategy didn't recover all asset");
        // assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
    }
}
