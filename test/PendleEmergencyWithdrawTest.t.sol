// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPendle is ITokenizedStrategy {}

contract PendleEmergencyWithdrawTest is Test {
    uint256 private constant MAX_LOSS_BPS = 100; // 1%
    uint256 private constant BPS = 10_000;

    // NOTE: no active strategies

    function verifyAllQueuedStrategies(IVault vault) internal {
        address[] memory queues = vault.get_default_queue();
        for (uint256 i = 0; i < queues.length; i++) {
            verifyEmergencyExit(queues[i]);
        }
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        if (strategy.totalSupply() == 0) {
            // we are using vaults with 2 strategies, one of them is not active
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
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        // can be equal if the asset is not deposited to the strategy, waiting for market conditions
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        // this strategy can have losses because it needs to swap PT to YT to exit pendle
        uint256 minAmountWithLoss = balanceOfAsset * (BPS - MAX_LOSS_BPS) / BPS;
        assertGe(
            ERC20(strategy.asset()).balanceOf(address(strategy)), minAmountWithLoss, "strategy didn't recover all asset"
        );
    }
}
