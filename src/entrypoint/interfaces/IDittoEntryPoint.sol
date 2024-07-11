// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the DittoEntryPoint DEP contract
interface IDittoEntryPoint {

    // Defines the structure for tracking workflows in the system
    struct Workflow {
        address vaultAddress;    // Address of the vault (SCA) associated with the workflow
        uint256 workflowId;      // Unique identifier for the workflow
    }

    // Registers a workflow associated with a vault
    function registerWorkflow(uint256 workflowId) external;

    // Executes a workflow
    function runWorkflow(address vaultAddress, uint256 workflowId) external;

    // Cancels a workflow and removes it from active workflows
    function cancelWorkflow(uint256 workflowId) external;
}