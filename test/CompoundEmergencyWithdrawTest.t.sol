// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";

interface ICompStrategy is ITokenizedStrategy {
    function comet() external view returns (address);
}

contract CompoundEmergencyWithdrawTest is Test {
    function test_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address compUsdc = 0x7eE351aA702C8fC735D77Fb229b7676AC15D7c79;
        address compUsdt = 0x206db0A0Af10Bec57784045e089A418771D20227;
        address compWeth = 0x23eE3D14F09946A084350CC6A7153fc6eb918817;
        verifyEmergencyExit(compUsdc);
        verifyEmergencyExit(compUsdt);
        verifyEmergencyExit(compWeth);
    }

    function test_aribtrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address compUsdc = 0xCACc53bAcCe744ac7b5C1eC7eb7e3Ab01330733b;
        address compUsdce = 0x1bd173F9a1186A1AbE680071E0F57d4D83c18430;
        verifyEmergencyExit(compUsdc);
        verifyEmergencyExit(compUsdce);
    }

    function test_polygon() public {
        uint256 mainnetFork = vm.createFork("polygon");
        vm.selectFork(mainnetFork);

        address compUsdt = 0x0fEFEe13864c431717f5B2678607b6ce532a170C;
        verifyEmergencyExit(compUsdt);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ICompStrategy strategy = ICompStrategy(strategyAddress);
        // verify that the strategy has assets
        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // uint256 balanceOfBase = ERC20(strategy.comet()).balanceOf(address(strategy));

        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy has recovered all assets
        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.asset()).balanceOf(address(strategy)), balanceOfAsset, "strategy balance not increased");
        assertGe(ERC20(strategy.asset()).balanceOf(address(strategy)), assets, "strategy didn't recover all asset");
        assertEq(ERC20(strategy.comet()).balanceOf(address(strategy)), 0, "cToken not zero");
        // assertLt(ERC20(strategy.comet()).balanceOf(address(strategy)), balanceOfBase, "cToken not decreased");
    }
}
