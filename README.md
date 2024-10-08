# Emergency Withdraw Tests

This repository contains tests that call the function `emergencyWithdraw()` on Yearn V3 strategies. The tests are organized by the protocol that the strategy is using. If the protocol is forked, it will be in the same file as the original protocol, e.g. `Spark` is forked from `Aave`, so the tests for both are in `AaveEmergencyWithdrawTest.t.sol`.

## Getting Started

First, check if the `.env` file is set up correctly. See the `.env.example` file for an example.

To run all tests use:

```sh
forge test
```

## Strategies Failing

Some of them are reverting on emergencyWithdraw(uint256.max):

⁃ [AaveV3 DAI Lender](https://polygonscan.com/address/0xf4f9d5697341b4c9b0cc8151413e05a90f7dc24f) on Polygon which currently has over 1M TVL
⁃ [StrategyGearboxLenderWETH](https://etherscan.io/address/0xe92ade9eE76681f96C8BB0b352d5410ca5b35D70) on mainnet, over 1.6M
⁃ [Gearbox crvUSD Lender](https://etherscan.io/address/0xbf2e5BeD692C09aF8B39677e315F36aDF39bD685) on mainnet, 363k
⁃ [Sturdy crvUSD Compounder](https://etherscan.io/address/0x05329AAb081B125eEF7FbbC8b857428D478E692B) on mainnet 259k

Here are the simulations of reverts on Tenderly:

⁃ Aave DAI - https://dashboard.tenderly.co/yearn/sam/fork/485126d4-9252-4a88-9f94-8389acc5f65c/simulation/531845d2-0b19-4f03-953e-1cc4b4e9f044?trace=0.0.7.1.2.0.2.0.3.24.2
⁃ Gearbox WETH - https://dashboard.tenderly.co/yearn/sam/fork/47e59d28-9e69-4f13-bc90-1434545c7381/simulation/13c4d148-6e44-4b51-9a22-f4ea9c502d1d
⁃ Gearbox crv lender - https://dashboard.tenderly.co/yearn/sam/fork/47e59d28-9e69-4f13-bc90-1434545c7381/simulation/a7415832-af9d-49a1-9f4a-0b4722782f21
⁃ Sturdy crv lender - https://dashboard.tenderly.co/yearn/sam/fork/47e59d28-9e69-4f13-bc90-1434545c7381/simulation/aeee74f4-c3f9-45dc-a09e-91ad18d11d25

Emergency admin is not set for following strategies:

- mainnet crvusd aave v3 lender: https://etherscan.io/address/0x27ffA71dBB25A7C52A3Da74C6eED8C94c9A43E0d#readProxyContract#F11
- arbitrum usdt aave v3 lender: https://arbiscan.io/address/0x4ae5ce819e7d678b07e8d0f483d351e2c8e8b8d3#readProxyContract#F12
- polygon usdc aave v3: https://polygonscan.com/address/0x52367C8E381EDFb068E9fBa1e7E9B2C847042897#readProxyContract#F12
- mainnet crv sturdy: https://etherscan.io/address/0x05329AAb081B125eEF7FbbC8b857428D478E692B#readProxyContract#F11
