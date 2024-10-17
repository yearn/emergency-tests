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
    function test_aave_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address aaveUsdc = 0xf766c7293f4e0265dDfA8369F78a808dF8AC70c1;
        address aaveUsdt = 0xe5baF8b6Be442811211e9339d9fbC1B8fb7D66dF;
        address aaveCrv = 0xb0154f71912866Bb69fE26fFc44779D99B9CAE85;
        address aaveDai = 0xEed00e00236cD7F36F2558D8b5fD05046449599D;
        address aaveUsds = 0x832c30802054F60f0CeDb5BE1F9A0e3da2a0Cab4;
        address aaveWeth = 0x90759801579208B28D2D36D13b1ED7443D1b717F;
        verifyEmergencyExit(aaveUsdc);
        verifyEmergencyExit(aaveUsdt);
        verifyEmergencyExit(aaveCrv);
        verifyEmergencyExit(aaveDai);
        verifyEmergencyExit(aaveUsds);
        verifyEmergencyExit(aaveWeth);

        // Lido market
        address aaveLidoWeth = 0xC7baE383738274ea8C3292d53AfBB3b42B348DF0;
        verifyEmergencyExit(aaveLidoWeth);
    }

    function test_aave_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address aaveUsdt = 0x4aE5CE819e7D678b07E8D0f483d351E2c8e8B8D3;
        address aaveUsdc = 0xd89ee1E95f7728f6964CF321E2648cCd29a881f1;
        address aaveUsdc3 = 0x85968BF0f1f110C707fEF10a59f80118F349c058;
        verifyEmergencyExit(aaveUsdt);
        verifyEmergencyExit(aaveUsdc);
        verifyEmergencyExit(aaveUsdc3);
    }

    function test_aave_polygon() public {
        uint256 mainnetFork = vm.createFork("polygon");
        vm.selectFork(mainnetFork);

        address aaveWeth = 0xBEDA9A5300393e00229dc15cC54D5185E7646c56;
        address aaveUsdt = 0x3bd8C987286D8Ad00c05fdb2Ae3E8C9a0f054734;
        address aaveUsdc = 0x52367C8E381EDFb068E9fBa1e7E9B2C847042897;
        address aaveUsdce = 0xdB92B89Ca415c0dab40Dc96E99Fc411C08F20780;
        address aaveWmatic = 0x12c3Ad898e8eB1C0ec0Bb74f9748F36C46593F68;
        verifyEmergencyExit(aaveWeth);
        verifyEmergencyExit(aaveUsdt);
        verifyEmergencyExit(aaveUsdc);
        verifyEmergencyExit(aaveUsdce);
        verifyEmergencyExit(aaveWmatic);
    }

    // TODO: fix emergency for this strategy
    // function test_aave_dai_polygon() public {
    //     uint256 mainnetFork = vm.createFork("polygon");
    //     vm.selectFork(mainnetFork);

    //     address aaveDai = 0xf4F9d5697341B4C9B0Cc8151413e05A90f7dc24F;
    //     verifyEmergencyExit(aaveDai);
    // }

    function test_spark_dai_mainnet() public {
        // Spark is the fork of Aave
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address sparkDai = 0x1fd862499e9b9402DE6c599b6C391f83981180Ab;
        verifyEmergencyExit(sparkDai);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IAaveStrategy strategy = IAaveStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // uint256 aTokens = ERC20(strategy.aToken()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        // assertNotEq(admin, address(0), "emergencyAdmin not set"); // TODO: enable when emergencyAdmin is set
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy has recovered all funds
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");
        assertEq(ERC20(strategy.aToken()).balanceOf(address(strategy)), 0, "atokens not all burned");
        // assertLt(ERC20(strategy.aToken()).balanceOf(address(strategy)), aTokens, "atokens not burned");
    }
}
