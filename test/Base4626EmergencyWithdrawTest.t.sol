// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBase4626Compounder is ITokenizedStrategy {
    function vault() external view returns (address);

    function balanceOfAsset() external view returns (uint256);

    function balanceOfVault() external view returns (uint256);

    function balanceOfStake() external view returns (uint256);

    function valueOfVault() external view returns (uint256);

    function vaultsMaxWithdraw() external view returns (uint256);
}

contract Base4626EmergencyWithdrawTest is Test {
    // TODO: fix emergency for this strategy
    function test_gearbox_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address gearboxWeth = 0xe92ade9eE76681f96C8BB0b352d5410ca5b35D70;
        address gearboxCrv = 0xbf2e5BeD692C09aF8B39677e315F36aDF39bD685;
        verifyEmergencyExit(gearboxWeth);
        verifyEmergencyExit(gearboxCrv);
    }

    // TODO: fix emergency for this strategy
    function test_sturdy_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address sturdyCrvCompounder = 0x05329AAb081B125eEF7FbbC8b857428D478E692B;
        verifyEmergencyExit(sturdyCrvCompounder);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IBase4626Compounder strategy = IBase4626Compounder(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 valueOfVault = strategy.valueOfVault();

        // shutdown the strategy
        address admin = strategy.emergencyAdmin();
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertEq(strategy.balanceOfStake(), 0, "balanceOfStake not zero");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(strategy.valueOfVault(), valueOfVault, "vaule of vault decreased");
        // assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");
    }
}
