// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../interfaces/IDittoEntryPoint.sol";
import "./EntryPoint.sol";
import { PackedUserOperation } from "../../account-abstraction/interfaces/PackedUserOperation.sol";
import "../../openzeppelin/access/Ownable.sol";

// Interface for the DittoEntryPoint DEP contract
contract DittoEntryPoint is IDittoEntryPoint, Ownable, EntryPoint {
    error UnregisteredWorkflow();

    struct WorkflowTemplate {
        bytes workflow;
        bool registered;
    }

    Workflow[] historyWorkflow;
    mapping(uint256 => WorkflowTemplate) workflows;

    constructor() Ownable(msg.sender) {}

    // Anyone can call
    function addWorkflow(PackedUserOperation[] memory _batch) external returns(uint256 workflowId) {
        workflowId = uint256(keccak256(abi.encode(_batch)));
        bytes memory batchData = abi.encode(_batch);
        workflows[workflowId].workflow = batchData;
    }

    // Registers a workflow associated with a vault
    function registerWorkflow(uint256 workflowId) external onlyOwner {
        workflows[workflowId].registered = true;
    }

    // Executes a workflow
    function runWorkflow(address vaultAddress, uint256 workflowId) external {
        WorkflowTemplate memory template = workflows[workflowId];
        if(!template.registered) {
            revert UnregisteredWorkflow();
        }
        uint256 nonce = getNonce(vaultAddress, 0);
        (PackedUserOperation[] memory workflowBatch) = abi.decode(template.workflow, (PackedUserOperation[]));
        for (uint i=0; i<template.workflow.length; i++) {
            workflowBatch[i].nonce = nonce + i;
            workflowBatch[i].sender = vaultAddress;
        }
        this.handleOps(workflowBatch, payable(address(0x42)));
        historyWorkflow.push(
            Workflow(
                vaultAddress,
                workflowId
            )
        );
    }
    
    // Cancels a workflow and removes it from active workflows
    function cancelWorkflow(uint256 workflowId) external onlyOwner {
        workflows[workflowId].registered = false;
    }

    // Get a certain number of items from the history
    function getWorkflowSlice(uint _start, uint _end) external view returns(Workflow[] memory slice) {// ok
        require(_end > _start, "Invalid input data");
        uint256 sliceLength = _end - _start;
        slice = new Workflow[](sliceLength);
        for(uint256 i = 0; i < sliceLength; i++) {
            uint256 sPosition = i + _start;
            slice[i] = historyWorkflow[sPosition];
        }
    }

    // Get the length of the history before requesting a slice
    function getWorkflowLength() external view returns(uint256) {
        return historyWorkflow.length;
    }
}