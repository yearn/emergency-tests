// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import {RolesVerification} from "./RolesVerification.sol";

interface ICompStrategy is ITokenizedStrategy {
    function comet() external view returns (address);
}

contract CompoundEmergencyWithdrawTest is RolesVerification {
    function test_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address compUsdc = 0x7eE351aA702C8fC735D77Fb229b7676AC15D7c79;
        address compUsdt = 0x206db0A0Af10Bec57784045e089A418771D20227;
        address compWeth = 0x23eE3D14F09946A084350CC6A7153fc6eb918817;
        address compUsds = 0x6701DEa9809dEaf068B8445798d0E19B025480Fe;

        console.log("compUsdc", compUsdc);
        verifyEmergencyExit(compUsdc);
        console.log("compUsdt", compUsdt);
        verifyEmergencyExit(compUsdt);
        console.log("compWeth", compWeth);
        verifyEmergencyExit(compWeth);
        console.log("compUsds", compUsds);
        verifyEmergencyExit(compUsds);
    }

    function test_aribtrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address compUsdc = 0xCACc53bAcCe744ac7b5C1eC7eb7e3Ab01330733b;
        address compUsdce = 0x1bd173F9a1186A1AbE680071E0F57d4D83c18430;

        console.log("compUsdc", compUsdc);
        verifyEmergencyExit(compUsdc);
        console.log("compUsdce", compUsdce);
        verifyEmergencyExit(compUsdce);
    }

    function test_polygon() public {
        uint256 mainnetFork = vm.createFork("polygon");
        vm.selectFork(mainnetFork);

        address compUsdt = 0x0fEFEe13864c431717f5B2678607b6ce532a170C;
        address compUsdce = 0xb1403908F772E4374BB151F7C67E88761a0Eb4f1;

        console.log("compUsdt", compUsdt);
        verifyEmergencyExit(compUsdt);
        console.log("compUsdce", compUsdce);
        verifyEmergencyExit(compUsdce);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ICompStrategy strategy = ICompStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // uint256 balanceOfBase = ERC20(strategy.comet()).balanceOf(address(strategy));

        // verify roles
        verifyRoles(strategy);

        // shutdown the strategy
        vm.startPrank(strategy.emergencyAdmin());
        strategy.shutdownStrategy();
        uint256 maxWithdrawAmount = strategy.availableWithdrawLimit(address(0));
        strategy.emergencyWithdraw(maxWithdrawAmount);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");
        assertEq(ERC20(strategy.comet()).balanceOf(address(strategy)), 0, "cToken not zero");
        // assertLt(ERC20(strategy.comet()).balanceOf(address(strategy)), balanceOfBase, "cToken not decreased");
    }
}
