// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/AutographAccessControl.sol";

contract AutographAccessControlTest is Test {
    AutographAccessControl public accessControl;
    address admin = address(0x1);
    address newAdmin = address(0x2);
    address designer = address(0x3);
    address npc = address(0x4);
    address openAction = address(0x5);
    address fulfiller = address(0x6);

    bytes32 constant EXISTING_ERROR = keccak256("Existing()");
    bytes32 constant ADDRESS_INVALID_ERROR = keccak256("AddressInvalid()");
    bytes32 constant CANT_REMOVE_SELF_ERROR = keccak256("CantRemoveSelf()");

    function setUp() public {
        vm.prank(admin);
        accessControl = new AutographAccessControl();
    }

    function testInitialAdmin() public view {
        assertTrue(accessControl.isAdmin(admin));
        assertEq(accessControl.symbol(), "AAC");
        assertEq(accessControl.name(), "AutographAccessControl");
    }

    function testAddAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);
        assertTrue(accessControl.isAdmin(newAdmin));
    }

    function testRemoveAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);
        assertTrue(accessControl.isAdmin(newAdmin));

        vm.prank(admin);
        accessControl.removeAdmin(newAdmin);
        assertFalse(accessControl.isAdmin(newAdmin));
    }

    function testAddAdminRevertsIfExisting() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);

        vm.prank(admin);
        try accessControl.addAdmin(newAdmin) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXISTING_ERROR));
        }
    }

    function testRemoveAdminRevertsIfNotAdmin() public {
        vm.prank(admin);
        try accessControl.removeAdmin(newAdmin) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_INVALID_ERROR));
        }
    }

    function testRemoveAdminRevertsIfSelf() public {
        vm.prank(admin);
        try accessControl.removeAdmin(admin) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(CANT_REMOVE_SELF_ERROR));
        }
    }

    function testAddDesigner() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);
        assertTrue(accessControl.isDesigner(designer));
    }

    function testRemoveDesigner() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);
        assertTrue(accessControl.isDesigner(designer));

        vm.prank(admin);
        accessControl.removeDesigner(designer);
        assertFalse(accessControl.isDesigner(designer));
    }

    function testAddDesignerRevertsIfExisting() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);

        vm.prank(admin);
        try accessControl.addDesigner(designer) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXISTING_ERROR));
        }
    }

    function testRemoveDesignerRevertsIfNotDesigner() public {
        vm.prank(admin);
        try accessControl.removeDesigner(designer) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_INVALID_ERROR));
        }
    }

    function testAddNPC() public {
        vm.prank(admin);
        accessControl.addNPC(npc);
        assertTrue(accessControl.isNPC(npc));
    }

    function testRemoveNPC() public {
        vm.prank(admin);
        accessControl.addNPC(npc);
        assertTrue(accessControl.isNPC(npc));

        vm.prank(admin);
        accessControl.removeNPC(npc);
        assertFalse(accessControl.isNPC(npc));
    }

    function testAddNPCRevertsIfExisting() public {
        vm.prank(admin);
        accessControl.addNPC(npc);

        vm.prank(admin);
        try accessControl.addNPC(npc) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXISTING_ERROR));
        }
    }

    function testRemoveNPCRevertsIfNotNPC() public {
        vm.prank(admin);
        try accessControl.removeNPC(npc) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_INVALID_ERROR));
        }
    }

    function testAddOpenAction() public {
        vm.prank(admin);
        accessControl.addOpenAction(openAction);
        assertTrue(accessControl.isOpenAction(openAction));
    }

    function testRemoveOpenAction() public {
        vm.prank(admin);
        accessControl.addOpenAction(openAction);
        assertTrue(accessControl.isOpenAction(openAction));

        vm.prank(admin);
        accessControl.removeOpenAction(openAction);
        assertFalse(accessControl.isOpenAction(openAction));
    }

    function testAddOpenActionRevertsIfExisting() public {
        vm.prank(admin);
        accessControl.addOpenAction(openAction);

        vm.prank(admin);
        try accessControl.addOpenAction(openAction) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXISTING_ERROR));
        }
    }

    function testRemoveOpenActionRevertsIfNotOpenAction() public {
        vm.prank(admin);
        try accessControl.removeOpenAction(openAction) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_INVALID_ERROR));
        }
    }

    function testSetFulfiller() public {
        vm.prank(admin);
        accessControl.setFulfiller(fulfiller);
        assertEq(accessControl.getFulfiller(), fulfiller);
    }
}
