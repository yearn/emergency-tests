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

    function test_pendle_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        IVault weETHVault = IVault(0xe5175a2EB7C40bC5f0E9DE4152caA14eab0fFCb7);
        verifyAllQueuedStrategies(weETHVault);
        IVault enaVault = IVault(0x2F2BBc50DB252eeADD2c9B9197beb6e5Aef87e48);
        verifyAllQueuedStrategies(enaVault);
        IVault rswETHVault = IVault(0xdc0B53cC326B692a4D89e5F4CadC29a6B7265749);
        verifyAllQueuedStrategies(rswETHVault);
        IVault sUSDeVault = IVault(0x57fC2D9809F777Cd5c8C433442264B6E8bE7Fce4);
        verifyAllQueuedStrategies(sUSDeVault);
        IVault agEthVault = IVault(0xDDa02A2FA0bb0ee45Ba9179a3fd7e65E5D3B2C90);
        verifyAllQueuedStrategies(agEthVault);
        IVault lbtcVault = IVault(0x57a8b4061AA598d2Bb5f70C5F931a75C9F511fc8);
        verifyAllQueuedStrategies(lbtcVault);
        IVault rswVault = IVault(0xf1ce36c9C0dB95A052Eb4b075BC334e1f5a21Ef0);
        verifyAllQueuedStrategies(rswVault);
        IVault pufVault = IVault(0x66017371c032Cd5a67Fec6913A9e37d5bd1C690c);
        verifyAllQueuedStrategies(pufVault);
    }

    function test_pendle_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        IVault weEthVault = IVault(0x044E75fCbF7BD3f8f4577FF317554e9c0037F145);
        verifyAllQueuedStrategies(weEthVault);
        IVault usdeVault = IVault(0x34a2b066AF16409648eF15d239E656edB8790ca0);
        verifyAllQueuedStrategies(usdeVault);
        IVault ezETHVault = IVault(0x0F2ae7531A83982F15ff1D26B165E2bF3D7566da);
        verifyAllQueuedStrategies(ezETHVault);
        IVault rsETH = IVault(0x1Dd930ADD968ff5913C3627dAA1e6e6FCC9dc544);
        verifyAllQueuedStrategies(rsETH);
        IVault rETH = IVault(0xC40DA6a01Ac36F39736731ee50fb3b1B8204e2D3);
        verifyAllQueuedStrategies(rETH);
    }

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
