// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RolesVerification} from "./RolesVerification.sol";

interface IMakerStrategy is ITokenizedStrategy {
    function emergencyWithdrawDirect(uint256 _sharesSDAI, bool _usePSM, uint256 _swapAmount) external;
}

contract MakerEmergencyWithdrawTest is RolesVerification {
    address private constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;

    function test_sky_rewards() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address skyRewardsCompounder = 0x0868076663Bbc6638ceDd27704cc8F0Fa53d5b81;
        vm.label(skyRewardsCompounder, "skyRewardsCompounder");
        console.log("skyRewardsCompounder", skyRewardsCompounder);
        verifyEmergencyExit(skyRewardsCompounder);

        address daiToUsdsDepositor = 0xAeDF7d5F3112552E110e5f9D08c9997Adce0b78d;
        vm.label(daiToUsdsDepositor, "daiToUsdsDepositor");
        console.log("daiToUsdsDepositor", daiToUsdsDepositor);
        verifyEmergencyExit(daiToUsdsDepositor);

        address usdcToUsdsDepositor = 0x39c0aEc5738ED939876245224aFc7E09C8480a52;
        vm.label(usdcToUsdsDepositor, "usdcToUsdsDepositor");
        console.log("usdcToUsdsDepositor", usdcToUsdsDepositor);
        verifyEmergencyExit(usdcToUsdsDepositor);

        address sparkUsds = 0xc9f01b5c6048B064E6d925d1c2d7206d4fEeF8a3;
        vm.label(sparkUsds, "sparkUsdsCompounder");
        console.log("sparkUsdsCompounder", sparkUsds);
        verifyEmergencyExit(sparkUsds);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IMakerStrategy strategy = IMakerStrategy(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.totalAssets();
        if (assets == 0) {
            return;
        }
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
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
