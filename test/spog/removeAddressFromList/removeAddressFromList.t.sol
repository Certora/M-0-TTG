// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "test/shared/SPOG_Base.t.sol";

contract SPOG_RemoveAddressFromList is SPOG_Base {
    address internal listToRemoveAddressFrom;
    address internal addressToRemove;

    function setUp() public override {
        super.setUp();

        addNewListToSpogAndAppendAnAddressToIt();
        listToRemoveAddressFrom = address(list);
        addressToRemove = address(0x1234);
    }

    function test_Revert_RemoveAddressFromListWhenNotCallingFromGovernance() public {
        vm.expectRevert("SPOG: Only vote governor");
        spog.remove(addressToRemove, IList(listToRemoveAddressFrom));
    }

    function test_Revert_WhenRemoveAddressFromList_BySPOGGovernorValueHolders() external {
        // create proposal to remove address from list
        address[] memory targets = new address[](1);
        targets[0] = address(spog);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("remove(address,address)", addressToRemove, listToRemoveAddressFrom);
        string memory description = "Remove address from a list";

        (bytes32 hashedDescription, uint256 proposalId) =
            getProposalIdAndHashedDescription(valueGovernor, targets, values, calldatas, description);

        // update start of next voting period
        while (block.number >= valueGovernor.startOfNextVotingPeriod()) {
            valueGovernor.updateStartOfNextVotingPeriod();
        }

        // vote on proposal
        deployScript.cash().approve(address(spog), deployScript.tax());
        spog.propose(ISPOGGovernor(address(valueGovernor)), targets, values, calldatas, description);

        // fast forward to an active voting period
        vm.roll(block.number + valueGovernor.votingDelay() + 1);

        // cast vote on proposal
        uint8 yesVote = uint8(VoteType.Yes);
        valueGovernor.castVote(proposalId, yesVote);

        vm.roll(block.number + deployScript.voteTime() + 1);

        // proposal execution is not allowed by valueGovernor holders
        vm.expectRevert("SPOG: Only vote governor");
        valueGovernor.execute(targets, values, calldatas, hashedDescription);

        assertTrue(IList(listToRemoveAddressFrom).contains(addressToRemove), "Address must still contain in list");
    }

    function test_SPOGProposalToRemoveAddressFromAList() public {
        // create proposal to remove address from list
        address[] memory targets = new address[](1);
        targets[0] = address(spog);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("remove(address,address)", addressToRemove, listToRemoveAddressFrom);
        string memory description = "Remove address from a list";

        (bytes32 hashedDescription, uint256 proposalId) =
            getProposalIdAndHashedDescription(voteGovernor, targets, values, calldatas, description);

        // vote on proposal
        deployScript.cash().approve(address(spog), deployScript.tax());
        spog.propose(ISPOGGovernor(address(voteGovernor)), targets, values, calldatas, description);

        // assert that spog has cash balance
        assertTrue(
            deployScript.cash().balanceOf(address(spog)) == deployScript.tax() * 3,
            "Balance of SPOG should be 3x tax, one from adding the list to the SPOG, one from append an address to the list,  and one from the current proposal"
        );

        // fast forward to an active voting period
        vm.roll(block.number + voteGovernor.votingDelay() + 1);

        // cast vote on proposal
        uint8 yesVote = 1;
        voteGovernor.castVote(proposalId, yesVote);
        // fast forward to end of voting period
        vm.roll(block.number + deployScript.voteTime() + 1);

        // execute proposal
        voteGovernor.execute(targets, values, calldatas, hashedDescription);

        // assert that address was added to list
        assertTrue(!IList(listToRemoveAddressFrom).contains(addressToRemove), "Address was not removed from list");
    }
}
