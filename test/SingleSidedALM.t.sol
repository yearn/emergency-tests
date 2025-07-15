// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";
import "src/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface ISingleSidedALM is ITokenizedStrategy {
    function estimatedTotalAsset() external view returns (uint256);

    function maxSwapValue() external view returns (uint256);
}


contract SingleSidedALMTest is Test {
    function test_katana() public {
        uint256 katanaFork = vm.createFork("katana");
        vm.selectFork(katanaFork);
        console.log("Current block number on katana:", block.number);

        address usdcAusd = 0x1Ea30764fF9ceaCe69E55e9bf49eB37CdBa8e1De;
        address usdcUsdt = 0xF0a8A393ABE6dC35E873FF795D013aDcc72604d2;

        address usdtAusd = 0xeeDbED5270791521969E1c693d81796b045dC483;
        address usdtUsdc = 0xb2f33a48F79cbc9d3f9b32FDA0cBC89cF67af0AC;

        address ausdUsdc = 0x3e7236AA960155159A8d3D7303896Fc2A21D2154;
        address ausdUsdt = 0x7214Dad6D78561728bcB6053d0C1bd5C9D1D53d8;

        address ethWeeth = 0x38663f9A0e89eBc29A2906d355A0ab86964A0BAd;

        address wbtcBtck = 0x4d38547d24e607C7390717F22ae373529cffF90C;
        address wbtcLbtc = 0x069B9db656f6940dC55B08E96bE33c304AC18746;

        verifyEmergencyExit(usdcAusd);
        verifyEmergencyExit(usdcUsdt);
        verifyEmergencyExit(usdtAusd);
        verifyEmergencyExit(usdtUsdc);
        verifyEmergencyExit(ausdUsdc);
        verifyEmergencyExit(ausdUsdt);
        verifyEmergencyExit(ethWeeth);
        verifyEmergencyExit(wbtcBtck);
        verifyEmergencyExit(wbtcLbtc);
    }

    function verifyEmergencyExit(address strategyAddress) internal {
        ISingleSidedALM strategy = ISingleSidedALM(strategyAddress);
        // verify that the strategy has assets
        if (strategy.totalSupply() == 0) {
            return;
        }
        uint256 assets = strategy.estimatedTotalAsset();
        assertGt(assets, 0, "!totalAssets");
        uint256 balanceOfAsset = ERC20(strategy.asset()).balanceOf(address(strategy));
        // verify that the strategy has set an emergency admin
        address admin = strategy.emergencyAdmin();
        assertNotEq(admin, address(0), "emergencyAdmin not set");
        // shutdown the strategy
        vm.startPrank(admin);
        strategy.shutdownStrategy();
        // NOTE: amount is scaled down do maximum possible
        strategy.emergencyWithdraw(type(uint256).max);

        // verify that the strategy didn't lose any funds
        uint256 currentBalance = ERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 maxSwapValue = strategy.maxSwapValue();

        // NOTE: allow loss of 0.1% because of swaps
        assertGe(strategy.estimatedTotalAsset(), assets * 999 / 1000, "emergency withdraw lost money");
        // NOTE: allow loss of 0.2% in swaps
        assertGe(currentBalance, balanceOfAsset + (maxSwapValue * 998 / 1000), "strategy balance not increased");
    }
}
