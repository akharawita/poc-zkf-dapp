// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

import "./ERC6909.sol";
import "./WithdrawVerifier.sol";

contract BasicTornado {
    struct Deposit {
        uint256 amount;
        uint256 id;
        bytes32 commitment;
        bool isDeposited;
    }

    struct PublicSignals {
        bytes32 nullifierHash;
        bytes32 commitment;
        uint256 x;
        uint256 y;
        uint256 amount;
        uint256 tokenId;
        uint256 z;
    }

    mapping(bytes32 => Deposit) public deposits;

    mapping(bytes32 => bool) public nullifierHashes;

    // Event to log deposits
    event DepositMade(bytes32 indexed commitment, uint256 id, uint256 amount);
    // Event to log withdrawals
    event WithdrawalMade(bytes32 indexed nullifierHash, uint256 amount);

    ERC6909 public token;
    PlonkVerifier public verifier;

    constructor(ERC6909 _token, PlonkVerifier _verifier) {
        token = _token;
        verifier = _verifier;
    }

    function deposit(
        bytes32 _commitment,
        uint256 _id,
        uint256 _amount
    ) external returns (bytes32) {
        require(
            !deposits[_commitment].isDeposited,
            "Commitment already exists"
        );
        require(
            token.balanceOf(msg.sender, _id) >= _amount,
            "Insufficient balance"
        );

        deposits[_commitment] = Deposit(_amount, _id, _commitment, true);
        token.transferFrom(msg.sender, address(this), _id, _amount);

        emit DepositMade(_commitment, _id, _amount);

        return _commitment;
    }

    function withdraw(bytes calldata data) external {
        // Decode the input data
        (bytes memory proofData, bytes memory publicSignals) = abi.decode(
            data,
            (bytes, bytes)
        );

        // Decode publicSignals data
        (
            bytes32 nullifierHash,
            bytes32 commitment,
            uint256 x,
            uint256 y,
            uint256 amount,
            uint256 tokenId,
            uint256 z
        ) = abi.decode(
                publicSignals,
                (bytes32, bytes32, uint256, uint256, uint256, uint256, uint256)
            );

        // Create a struct for public signals
        PublicSignals memory publicSignalsData = PublicSignals(
            nullifierHash,
            commitment,
            x,
            y,
            amount,
            tokenId,
            z
        );

        // Decode proof data
        (bytes memory proof, bytes memory proof1, bytes memory proof2) = abi
            .decode(proofData, (bytes, bytes, bytes));
        bytes memory proofPacked = abi.encodePacked(proof, proof1, proof2);
        uint256[24] memory proofArray = abi.decode(proofPacked, (uint256[24]));

        // Recompute commitment hash
        bytes32 recomputedCommitment = bytes32(
            keccak256(abi.encode(publicSignalsData.commitment))
        );

        // Check if the nullifier hash has already been used
        require(
            !nullifierHashes[publicSignalsData.nullifierHash],
            "Nullifier already exists"
        );

        // Check if the commitment exists and has sufficient balance
        Deposit storage depositData = deposits[recomputedCommitment];
        require(depositData.isDeposited, "Commitment does not exist");
        require(
            publicSignalsData.amount <= depositData.amount,
            "[0]: Insufficient balance"
        );
        require(
            publicSignalsData.amount <=
                token.balanceOf(address(this), publicSignalsData.tokenId),
            "[1]: Insufficient balance"
        );

        // Mark the nullifier hash as used
        nullifierHashes[publicSignalsData.nullifierHash] = true;

        // Prepare public signals for proof verification
        uint256[7] memory preparedPublicSignals = [
            convertToUint256(publicSignalsData.nullifierHash),
            convertToUint256(publicSignalsData.commitment),
            publicSignalsData.x,
            publicSignalsData.y,
            publicSignalsData.amount,
            publicSignalsData.tokenId,
            publicSignalsData.z
        ];

        // Verify the proof
        require(
            verifier.verifyProof(proofArray, preparedPublicSignals),
            "Invalid proof"
        );

        // Transfer the tokens
        token.transfer(
            msg.sender,
            publicSignalsData.tokenId,
            publicSignalsData.amount
        );

        // Emit the withdrawal event
        emit WithdrawalMade(nullifierHash, amount);
    }

    function convertToUint256(bytes32 data) public pure returns (uint256) {
        return uint256(data);
    }
}
