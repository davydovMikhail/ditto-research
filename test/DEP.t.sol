// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "./TestBaseUtil.t.sol";
import "src/interfaces/IERC7579Account.sol";
import "src/interfaces/IERC7579Module.sol";
// import {Counter} from "../src/Counter.sol";

contract DEP is TestBaseUtil {


    address MSAAccount;
    bytes initCode;

    uint256 workflowIdOne;
    uint256 workflowIdTwo;
    uint256 workflowIdThree;

    function setUp() public override {
        super.setUp();

        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 2000);
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(target), uint256(0), setValueOnTarget)
            )
        );
        (MSAAccount, initCode) = getAccountAndInitCode();
        uint256 nonce = getNonce(MSAAccount, address(defaultValidator));

        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(MSAAccount);
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = userOpCalldata;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // Send the userOp to the entrypoint
        entrypoint.handleOps(userOps, payable(address(0x69)));





        bytes memory incrementValueOnTarget = abi.encodeCall(MockTarget.incrementValue, ());
        bytes memory incrementValueTwiceOnTarget = abi.encodeCall(MockTarget.incrementValueTwice, ());

        bytes memory userOpCalldataOne = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(target), uint256(0), incrementValueOnTarget)
            )
        );
        PackedUserOperation memory userOpOne = getDefaultUserOp();
        // userOpOne.initCode = initCode;
        userOpOne.callData = userOpCalldataOne;
        bytes memory userOpCalldataTwo = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(target), uint256(0), incrementValueTwiceOnTarget)
            )
        );
        PackedUserOperation memory userOpTwo = getDefaultUserOp();
        // userOpTwo.initCode = initCode;
        userOpTwo.callData = userOpCalldataTwo;

        PackedUserOperation[] memory userOpsWorkFlowOne = new PackedUserOperation[](1);
        PackedUserOperation[] memory userOpsWorkFlowTwo = new PackedUserOperation[](2);
        PackedUserOperation[] memory userOpsWorkFlowThree = new PackedUserOperation[](1);

        userOpsWorkFlowOne[0] = userOpOne;

        userOpsWorkFlowTwo[0] = userOpOne;
        userOpsWorkFlowTwo[1] = userOpTwo;

        userOpsWorkFlowThree[0] = userOpTwo;

        workflowIdOne = entrypoint.addWorkflow(userOpsWorkFlowOne);
        workflowIdTwo = entrypoint.addWorkflow(userOpsWorkFlowTwo);
        workflowIdThree = entrypoint.addWorkflow(userOpsWorkFlowThree);

        vm.startPrank(OWNER_ENTRYPOINT.addr);
        entrypoint.registerWorkflow(workflowIdOne);
        entrypoint.registerWorkflow(workflowIdTwo);
        entrypoint.registerWorkflow(workflowIdThree);
        vm.stopPrank();

    }

    function test_workflowOne() public {
        assertTrue(target.value() == 2000);
        entrypoint.runWorkflow(MSAAccount, workflowIdOne);
        assertTrue(target.value() == 2001);
    }

    function test_workflowTwo() public {
        assertTrue(target.value() == 2000);
        entrypoint.runWorkflow(MSAAccount, workflowIdTwo);
        assertTrue(target.value() == 2003);
    }

    function test_workflowThree() public {
        assertTrue(target.value() == 2000);
        entrypoint.runWorkflow(MSAAccount, workflowIdThree);
        assertTrue(target.value() == 2002);
    }



    
}
