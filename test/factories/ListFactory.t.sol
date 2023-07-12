// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IList } from "../../src/interfaces/periphery/IList.sol";

import { ListFactory } from "../../src/factories/ListFactory.sol";

import { SPOGBaseTest } from "../shared/SPOGBaseTest.t.sol";

contract ListFactoryTest is SPOGBaseTest {
    function test_listDeployWithFactory() public {
        ListFactory listFactory = new ListFactory();

        address item1 = createUser("item1");

        address[] memory items = new address[](1);
        items[0] = item1;

        IList list = IList(listFactory.deploy(address(spog), "List Name", items, 0));

        assertTrue(list.contains(item1), "item1 should be in the list");
        assertTrue(list.admin() == address(spog), "spog should be the admin");
    }

    function test_predictAddress() public {
        ListFactory listFactory = new ListFactory();

        address item1 = createUser("item1");

        address[] memory items = new address[](1);
        items[0] = item1;

        IList list = IList(listFactory.deploy(address(spog), "List Name", items, 0));

        bytes memory bytecode = listFactory.getBytecode("List Name");

        address listAddress = listFactory.predictListAddress(bytecode, 0);

        assertTrue(listAddress != address(0), "listAddress should not be 0x0");
        assertTrue(listAddress == address(list), "listAddress should be the same as the list address");
    }
}
