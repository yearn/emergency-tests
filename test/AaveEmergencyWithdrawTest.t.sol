// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IAaveStrategy is ITokenizedStrategy {
    function aToken() external view returns (address);
}

contract AaveEmergencyWithdrawTest is Test {

    function test_aave_usdc_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address aaveUsdc = 0xbDb97eC319c41c6FA383E94eCE6Bdf383dFC7BE4;
        verifyEmergencyExit(aaveUsdc);
    }

    function test_aave_usdt_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address aaveUsdt = 0x4aE5CE819e7D678b07E8D0f483d351E2c8e8B8D3;
        verifyEmergencyExit(aaveUsdt);
    }

    function test_aave_weth_polygon() public {
        uint256 mainnetFork = vm.createFork("polygon");
        vm.selectFork(mainnetFork);

        address aaveWeth = 0xBEDA9A5300393e00229dc15cC54D5185E7646c56;
        verifyEmergencyExit(aaveWeth);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IAaveStrategy strategy = IAaveStrategy(strategyAddress);
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        uint256 aTokens = ERC20(strategy.aToken()).balanceOf(address(strategy));
        assertGt(assets, 0, "!totalAssets");
        address admin = strategy.emergencyAdmin();
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        strategy.emergencyWithdraw(type(uint256).max);
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertLt(ERC20(strategy.aToken()).balanceOf(address(strategy)), aTokens, "atokens not burned");
        // TODO: think about monitoring aave utilization
    }
}
