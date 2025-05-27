// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMakerStrategy is ITokenizedStrategy {
    function emergencyWithdrawDirect(uint256 _sharesSDAI, bool _usePSM, uint256 _swapAmount) external;
}

contract MakerEmergencyWithdrawTest is Test {
    address private constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;

    function test_sky_rewards() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address skyRewardsCompounder = 0x0868076663Bbc6638ceDd27704cc8F0Fa53d5b81;
        verifyEmergencyExit(skyRewardsCompounder);

        // NOTE: depricated vaults
        address skyRewardsCompounderOld = 0x4cE9c93513DfF543Bc392870d57dF8C04e89Ba0a;
        verifyEmergencyExit(skyRewardsCompounderOld);
        address usdsFarmerDai = 0x6acEDA98725505737c0F00a3dA0d047304052948;
        verifyEmergencyExit(usdsFarmerDai);
        address usdsFarmerUsdc = 0x602DA189F5aDa033E9aC7096Fc39C7F44a77e942;
        verifyEmergencyExit(usdsFarmerUsdc);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IMakerStrategy strategy = IMakerStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        address management = strategy.management();
        vm.prank(management);
        strategy.shutdownStrategy(); // TODO: remove after adding emergency admin
        vm.prank(management);
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");

        // if the strategy asset is not USDS, then all USDS should be withdrawn
        if (strategy.asset() != USDS) {
            assertEq(ERC20(USDS).balanceOf(address(strategy)), 0, "usds not zero");
        }
    }
}
