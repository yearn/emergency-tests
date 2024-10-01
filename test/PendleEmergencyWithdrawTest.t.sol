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

        address weETH = 0xe5175a2EB7C40bC5f0E9DE4152caA14eab0fFCb7;
        weETH = IVault(weETH).default_queue(0);
        address ena = 0x2F2BBc50DB252eeADD2c9B9197beb6e5Aef87e48;
        ena = IVault(ena).default_queue(0);
        address rswETH = 0xdc0B53cC326B692a4D89e5F4CadC29a6B7265749;
        rswETH = IVault(rswETH).default_queue(0);
        address sUSDe = 0x57fC2D9809F777Cd5c8C433442264B6E8bE7Fce4;
        sUSDe = IVault(sUSDe).default_queue(0);
        verifyEmergencyExit(weETH);
        verifyEmergencyExit(ena); // TODO: fix emergency for this strategy
        verifyEmergencyExit(rswETH);
        verifyEmergencyExit(sUSDe);
    }

    function test_pendle_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address weETH = 0x044E75fCbF7BD3f8f4577FF317554e9c0037F145;
        weETH = IVault(weETH).default_queue(1);
        verifyEmergencyExit(weETH);
        address usde = 0x34a2b066AF16409648eF15d239E656edB8790ca0;
        usde = IVault(usde).default_queue(0);
        verifyEmergencyExit(usde);
        address ezETH = 0x0F2ae7531A83982F15ff1D26B165E2bF3D7566da;
        ezETH = IVault(ezETH).default_queue(0);
        verifyEmergencyExit(ezETH);
        address rsETH = 0x1Dd930ADD968ff5913C3627dAA1e6e6FCC9dc544;
        rsETH = IVault(rsETH).default_queue(1);
        verifyEmergencyExit(rsETH);
        address rETH = 0xC40DA6a01Ac36F39736731ee50fb3b1B8204e2D3;
        rETH = IVault(rETH).default_queue(0);
        verifyEmergencyExit(rETH);
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
        // can be equal if the asset is not deposited to the strategy, waiting for market conditions
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        // this strategy can have losses because it needs to swap PT to YT to exit pendle
        uint256 minAmountWithLoss = balanceOfAsset * (BPS - MAX_LOSS_BPS) / BPS;
        assertGe(
            ERC20(strategy.asset()).balanceOf(address(strategy)), minAmountWithLoss, "strategy didn't recover all asset"
        );
    }
}
