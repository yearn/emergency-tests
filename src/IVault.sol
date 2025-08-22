// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IVault is IERC4626 {
    function default_queue(uint256 index) external view returns (address);
    function role_manager() external view returns (address);
    function get_default_queue() external view returns (address[] memory);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
