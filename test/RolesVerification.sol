// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/Contract.sol";
import "src/ITokenizedStrategy.sol";

/// @dev Interface for Gnosis Safe multisig wallet
interface IGnosisSafe {
    function getThreshold() external view returns (uint256);

    function getOwners() external view returns (address[] memory);
}

contract RolesVerification is Test {
    address public constant SMS = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;
    address public constant SMS_BASE = 0xde9e11D8a6894D47A3b407464b58b5dB9C97a58c;
    address public constant SMS_POLYGON = 0x16388000546eDed4D476bd2A4A374B5a16125Bc1;
    address public constant Y_HAAS = 0x604e586F17cE106B64185A7a0d2c1Da5bAce711E;

    /// @dev Minimum required threshold for multisig (2/3)
    uint256 public constant MIN_THRESHOLD = 2;
    uint256 public constant MIN_OWNERS = 3;

    /// @dev Verifies that an address is a valid Safe multisig with minimum 2/3 threshold
    function isValidSafeMultisig(address multisigAddress) internal returns (bool) {
        // Check if address has code (is a contract)
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(multisigAddress)
        }
        if (codeSize == 0) {
            console.log("Multisig is not a contract");
            return false;
        }

        uint256 threshold = IGnosisSafe(multisigAddress).getThreshold();
        if (threshold < MIN_THRESHOLD) {
            console.log("Threshold is less than minimum 2/3");
            console.log("Threshold", threshold);
            return false;
        }

        address[] memory owners = IGnosisSafe(multisigAddress).getOwners();
        if (owners.length < MIN_OWNERS) {
            console.log("Owners is less than minimum 3");
            console.log("Owners", owners.length);
            return false;
        }
        return true;
    }

    /// @dev Enhanced role verification with multisig checks
    function verifyRoles(ITokenizedStrategy strategy) internal {
        address management = strategy.management();
        address emergencyAdmin = strategy.emergencyAdmin();

        // Verify management is SMS
        assertNotEq(management, address(0), "management not set");

        // Verify SMS is a valid Safe multisig
        assertTrue(isValidSafeMultisig(management), "management is not a valid Safe multisig");

        if (management != SMS && management != SMS_BASE && management != SMS_POLYGON) {
            assertNotEq(emergencyAdmin, address(0), "emergencyAdmin not set");
            assertTrue(isValidSafeMultisig(emergencyAdmin), "emergencyAdmin is not a valid Safe multisig");
        }

        // Verify keeper is Y_HAAS
        // address keeper = strategy.keeper();
        // assertEq(keeper, Y_HAAS, "keeper not set to Y_HAAS");
    }

    /// @dev Convenience function for comprehensive role verification with detailed logging
    function verifyRolesDetailed(ITokenizedStrategy strategy) internal {
        console.log("=== Role Verification ===");
        console.log("Strategy:", address(strategy));

        address management = strategy.management();
        address emergencyAdmin = strategy.emergencyAdmin();
        address keeper = strategy.keeper();

        console.log("Management:", management);
        console.log("Emergency Admin:", emergencyAdmin);
        console.log("Keeper:", keeper);

        verifyRoles(strategy);

        console.log("=== Verification Complete ===");
    }
}
