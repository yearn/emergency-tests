// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RolesVerification} from "./RolesVerification.sol";

interface IAaveStrategy is ITokenizedStrategy {
    function aToken() external view returns (address);
}

contract AaveEmergencyWithdrawTest is RolesVerification {
    function test_aave_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address aaveUsdc = 0xf766c7293f4e0265dDfA8369F78a808dF8AC70c1;
        address aaveUsdt = 0xe5baF8b6Be442811211e9339d9fbC1B8fb7D66dF;
        address aaveCrv = 0xb0154f71912866Bb69fE26fFc44779D99B9CAE85;
        address aaveDai = 0xEed00e00236cD7F36F2558D8b5fD05046449599D;
        address aaveUsds = 0x832c30802054F60f0CeDb5BE1F9A0e3da2a0Cab4;
        address aaveWeth = 0x90759801579208B28D2D36D13b1ED7443D1b717F;

        console.log("aaveUsdc", aaveUsdc);
        verifyEmergencyExit(aaveUsdc);
        console.log("aaveUsdt", aaveUsdt);
        verifyEmergencyExit(aaveUsdt);
        console.log("aaveCrv", aaveCrv);
        verifyEmergencyExit(aaveCrv);
        console.log("aaveDai", aaveDai);
        verifyEmergencyExit(aaveDai);
        console.log("aaveUsds", aaveUsds);
        verifyEmergencyExit(aaveUsds);
        console.log("aaveWeth", aaveWeth);
        verifyEmergencyExit(aaveWeth);

        // Lido market
        address aaveLidoWeth = 0xC7baE383738274ea8C3292d53AfBB3b42B348DF0;
        console.log("aaveLidoWeth", aaveLidoWeth);
        verifyEmergencyExit(aaveLidoWeth);
    }

    function test_aave_arbitrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address aaveUsdt = 0x4aE5CE819e7D678b07E8D0f483d351E2c8e8B8D3;
        address aaveUsdc = 0xd89ee1E95f7728f6964CF321E2648cCd29a881f1;
        address aaveUsdc3 = 0x85968BF0f1f110C707fEF10a59f80118F349c058;

        console.log("aaveUsdt", aaveUsdt);
        verifyEmergencyExit(aaveUsdt);
        console.log("aaveUsdc", aaveUsdc);
        verifyEmergencyExit(aaveUsdc);
        console.log("aaveUsdc3", aaveUsdc3);
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
        address aaveDai = 0xf4F9d5697341B4C9B0Cc8151413e05A90f7dc24F;

        console.log("aaveWeth", aaveWeth);
        verifyEmergencyExit(aaveWeth);
        console.log("aaveUsdt", aaveUsdt);
        verifyEmergencyExit(aaveUsdt);
        console.log("aaveUsdc", aaveUsdc);
        verifyEmergencyExit(aaveUsdc);
        console.log("aaveUsdce", aaveUsdce);
        verifyEmergencyExit(aaveUsdce);
        console.log("aaveWmatic", aaveWmatic);
        verifyEmergencyExit(aaveWmatic);
        console.log("aaveDai", aaveDai);
        verifyEmergencyExit(aaveDai);
    }

    function test_spark_mainnet() public {
        // Spark is the fork of Aave
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address sparkDai = 0x1fd862499e9b9402DE6c599b6C391f83981180Ab;
        console.log("sparkDai", sparkDai);
        verifyEmergencyExit(sparkDai);

        // TODO: add spark USDS compounder
        // address sparkUsds = 0xc9f01b5c6048B064E6d925d1c2d7206d4fEeF8a3;
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        IAaveStrategy strategy = IAaveStrategy(strategyAddress);
        ERC20 aToken = ERC20(strategy.aToken());
        ERC20 asset = ERC20(strategy.asset());

        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = asset.balanceOf(address(strategy));
        uint256 aTokenBalanceBefore = aToken.balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        verifyRoles(strategy);
        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        if (maxWithdrawAmount < 100) {
            return; // skip dust
        }
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all funds
        assertEq(strategy.totalAssets(), assets, "emergencyWithdraw lost funds");
        assertGt(asset.balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(strategy.totalAssets(), assets, "strategy didn't recover all asset");
        assertLt(aToken.balanceOf(address(strategy)), aTokenBalanceBefore, "atokens not burned");
    }
}
