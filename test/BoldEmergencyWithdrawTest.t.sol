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

contract BoldEmergencyWithdrawTest is RolesVerification {
    function test_bold_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address styBold = 0x23346B04a7f55b8760E5860AA5A77383D63491cD;
        address[] memory strategies = getStrategyFromStakedStrategy(ITokenizedStrategy(styBold));
        for (uint256 i = 0; i < strategies.length; i++) {
            verifyEmergencyExit(strategies[i]);
        }
    }

    function getStrategyFromStakedStrategy(ITokenizedStrategy strategy) internal returns (address[] memory) {
        IVault vault = IVault(strategy.asset());
        address[] memory queue = vault.get_default_queue();
        assertGt(queue.length, 0, "Bold vault must have strategies in queue");
        assertGt(vault.totalSupply(), 0, "Bold vault must have supply");
        assertGt(vault.totalAssets(), 0, "Bold vault must have assets");
        return queue;
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        if (strategy.totalSupply() == 0) {
            console.log("Strategy has no supply, skipping", strategyAddress);
            return;
        }
        uint256 assets = strategy.totalAssets();
        if (assets == 0) {
            console.log("Strategy has no assets, skipping", strategyAddress);
            return;
        }
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        // NOTE: this strategy doesn't use input amount
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy didn't lose any funds
        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 currentAssets = strategy.totalAssets();

        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(currentBalance, balanceOfAsset, "strategy balance not increased");
        assertGe(currentBalance, assets * 995 / 1000, "strategy didn't recover more than 99.5% of assets");
        assertEq(currentAssets, assets, "strategy lost assets");
    }
}
