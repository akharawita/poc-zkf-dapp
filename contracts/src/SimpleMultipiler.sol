// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPlonkVerifier {
    function verifyProof(
        bytes memory proof,
        uint[] memory pubSignals
    ) external view returns (bool);
}

contract SimpleMultiplier {
    address public verifierAddress;

    event ProofResult(bool result);

    constructor(address _verifierAddress) {
        verifierAddress = _verifierAddress;
    }

    function submitProof(
        bytes memory proof,
        uint[] memory pubSignals
    ) public returns (bool result) {
        IPlonkVerifier verifier = IPlonkVerifier(verifierAddress);
        result = verifier.verifyProof(proof, pubSignals);
        emit ProofResult(result);

        return result;
    }
}
