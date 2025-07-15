// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RolesVerification} from "./RolesVerification.sol";

contract SiloEmergencyWithdrawTest is RolesVerification {
    function test_silo_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address siloWbtc = 0xE82D060687C014B280b65df24AcD94A77251C784;
        address siloWstEth = 0xA4B8873B4629c20f2167c0A2bC33B6AF8699dDc1;
        address siloArb = 0xb739AE19620f7ECB4fb84727f205453aa5bc1AD2;
        verifyEmergencyExit(siloWbtc);
        verifyEmergencyExit(siloWstEth);
        verifyEmergencyExit(siloArb);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ITokenizedStrategy strategy = ITokenizedStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        // verify strategy has recovered all assets or maximum possible
        assertGe(
            ERC20(strategy.asset()).balanceOf(address(strategy)),
            Math.min(assets, maxWithdrawAmount),
            "strategy didn't recover all asset"
        );
    }
}
