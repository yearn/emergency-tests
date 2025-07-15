# Emergency Withdraw Tests

This repository contains tests that call the function `emergencyWithdraw()` on Yearn V3 strategies. The tests are organized by the protocol that the strategy is using. If the protocol is forked, it will be in the same file as the original protocol, e.g. `Spark` is forked from `Aave`, so the tests for both are in `AaveEmergencyWithdrawTest.t.sol`. The tests also verify that the strategy has the correct roles set: `emergencyAdmin` and `management` are multisig with minimum 2/3 threshold.

## Getting Started

First, check if the `.env` file is set up correctly. See the `.env.example` file for an example.

To run all tests use:

```sh
forge test
```

## Strategies Tested

- [Aave V3](./test/AaveEmergencyWithdrawTest.t.sol) on mainnet, arbitrum and polygon
- [Across](./test/AcrossEmergencyWithdrawTest.t.sol) on mainnet
- [Compound V3](./test/CompoundEmergencyWithdrawTest.t.sol) on mainnet, arbitrum and polygon
- [Euler](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet
- [Gearbox](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet
- [Maker & Sky](./test/MakerEmergencyWithdrawTest.t.sol) on mainnet
- [Moonwell](./test/MoonwellTest.t.sol) on base
- [Morpho](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet base, polygon and katana
- [Pendle](./test/PendleEmergencyWithdrawTest.t.sol) on mainnet and arbitrum
- [Silicon Valley](./test/SingleSidedALM.t.sol) on katana
- [Silo](./test/SiloEmergencyWithdrawTest.t.sol) on arbitrum
- [Spark](./test/AaveEmergencyWithdrawTest.t.sol) on mainnet
- [Sturdy](./test/Base4626EmergencyWithdrawTest.t.sol) on mainnet
- [yBold](./test/BoldEmergencyWithdrawTest.t.sol) on mainnet
