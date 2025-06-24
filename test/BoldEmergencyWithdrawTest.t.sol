// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Base4626EmergencyWithdrawTest is Test {
    function test_bold_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);
        console.log("Current block number on mainnet:", block.number);

        address styBold = 0x23346B04a7f55b8760E5860AA5A77383D63491cD;
        address strategy = getStrategyFromStakedStrategy(ITokenizedStrategy(styBold));
        address liquityV2SPStrategy = 0x2048A730f564246411415f719198d6f7c10A7961;
        // NOTE: detect if the strategy has changed and if we need to update the test
        assertEq(strategy, liquityV2SPStrategy);
        verifyEmergencyExit(liquityV2SPStrategy);
    }

    function getStrategyFromStakedStrategy(ITokenizedStrategy strategy) internal returns (address) {
        IVault vault = IVault(strategy.asset());
        address[] memory queue = vault.get_default_queue();
        assertGt(queue.length, 0, "!queue.length");
        return queue[0];
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
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
