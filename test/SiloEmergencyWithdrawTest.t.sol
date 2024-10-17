// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SiloEmergencyWithdrawTest is Test {
    function test_silo_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address siloWbtc = 0xE82D060687C014B280b65df24AcD94A77251C784;
        address siloWstEth = 0xA4B8873B4629c20f2167c0A2bC33B6AF8699dDc1;
        address siloArb = 0xb739AE19620f7ECB4fb84727f205453aa5bc1AD2;
        address siliWstEth2 = 0x127A7F610cc704Be6122dfa76eb61E84C9cb0Efd;
        verifyEmergencyExit(siloWbtc);
        verifyEmergencyExit(siloWstEth);
        verifyEmergencyExit(siloArb);
        verifyEmergencyExit(siliWstEth2);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
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
    }
}
