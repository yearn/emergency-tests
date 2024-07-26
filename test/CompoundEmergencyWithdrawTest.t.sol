// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";

interface ICompStrategy is ITokenizedStrategy {
    function base() external view returns (address);
}

contract CompoundEmergencyWithdrawTest is Test {

    function test_usdc_mainnet() public {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        address compUsdc = 0x7eE351aA702C8fC735D77Fb229b7676AC15D7c79;
        verifyEmergencyExit(compUsdc);
    }

    function test_usdc_aribtrum() public {
        uint256 mainnetFork = vm.createFork("arbitrum");
        vm.selectFork(mainnetFork);

        address compUsdc = 0xCACc53bAcCe744ac7b5C1eC7eb7e3Ab01330733b;
        verifyEmergencyExit(compUsdc);
    }

    function test_weth_polygon() public {
        uint256 mainnetFork = vm.createFork("polygon");
        vm.selectFork(mainnetFork);

        address compWeth = 0x5136c2F7aB13E202eD42bc1AE82Dd63475919653;
        verifyEmergencyExit(compWeth);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ICompStrategy strategy = ICompStrategy(strategyAddress);

        assertGt(strategy.totalSupply(), 0, "!totalSupply");
        uint256 assets = strategy.totalAssets();
        uint256 balanceOfAsset = ERC20(strategy.base()).balanceOf(address(strategy));
        assertGt(assets, 0, "!totalAssets");
        address admin = strategy.emergencyAdmin();
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        strategy.emergencyWithdraw(type(uint256).max);
        assertEq(strategy.totalAssets(), assets, "emergency withdraw lost money");
        assertGt(ERC20(strategy.base()).balanceOf(address(strategy)), balanceOfAsset, "balanceOfAsset not increased");
    }
}