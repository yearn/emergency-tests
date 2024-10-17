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

    function test_susdc_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address susdc = 0x459F99D7c83Bc3653b1913B62D2978b1deDa01B5;
        verifyEmergencyExit(susdc);
    }

    function test_susdc_mainnet_direct() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address susdc = 0x459F99D7c83Bc3653b1913B62D2978b1deDa01B5;
        verifyEmergencyExitDirect(susdc);
    }

    function test_sky_rewards() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address skyRewardsCompounder = 0x4cE9c93513DfF543Bc392870d57dF8C04e89Ba0a;
        verifyEmergencyExit(skyRewardsCompounder);
        address skyLender = 0x91F008870eEF686b61a3775944D55a3FC53B7024;
        verifyEmergencyExit(skyLender);
    }

    function test_sky_farmer() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

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

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
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

    function verifyEmergencyExitDirect(address strategyAddress) internal {
        IMakerStrategy strategy = IMakerStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.prank(admin);
        strategy.shutdownStrategy();
        uint256 swapAmount = assets; // try to swap all assets
        address management = strategy.management();
        vm.prank(management);
        strategy.emergencyWithdrawDirect(type(uint256).max, true, swapAmount);

        // verify that the strategy has recovered all funds
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");
    }
}
