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
        (bytes memory proofData, bytes memory publicSignals) = abi.decode(
            data,
            (bytes, bytes)
        );

        // Decode publicSignals data
        (
            bytes32 _nullifierHash,
            bytes32 _commitment,
            uint256 x,
            uint256 y,
            uint256 _amount,
            uint256 _tokenId,
            uint256 z
        ) = abi.decode(
                publicSignals,
                (bytes32, bytes32, uint256, uint256, uint256, uint256, uint256)
            );

        PublicSignals memory publicSignalsData = PublicSignals(
            _nullifierHash,
            _commitment,
            x,
            y,
            _amount,
            _tokenId,
            z
        );

        (bytes memory proof, bytes memory proof1, bytes memory proof2) = abi
            .decode(proofData, (bytes, bytes, bytes));

        bytes memory proofPacked = abi.encodePacked(proof, proof1, proof2);
        uint256[24] memory _proof = abi.decode(proofPacked, (uint256[24]));

        _commitment = bytes32(
            keccak256(abi.encode(publicSignalsData.commitment))
        );

        require(!nullifierHashes[_nullifierHash], "Nullifier already exists");
        require(deposits[_commitment].isDeposited, "Commitment does not exist");
        require(
            publicSignalsData.amount <= deposits[_commitment].amount,
            "[0]: Insufficient balance"
        );
        require(
            publicSignalsData.amount <=
                token.balanceOf(address(this), publicSignalsData.tokenId),
            "[1]: Insufficient balance"
        );

        nullifierHashes[_nullifierHash] = true;

        uint256[7] memory prepairPublicSignals = [
            convertToUint256(publicSignalsData.nullifierHash),
            convertToUint256(publicSignalsData.commitment),
            publicSignalsData.x,
            publicSignalsData.y,
            publicSignalsData.amount,
            publicSignalsData.tokenId,
            publicSignalsData.z
        ];

        require(
            verifier.verifyProof(_proof, prepairPublicSignals),
            "Invalid proof"
        );

        token.transfer(
            msg.sender,
            publicSignalsData.tokenId,
            publicSignalsData.amount
        );

        emit WithdrawalMade(_nullifierHash, _amount);
    }

    function convertToUint256(
        bytes32 _nullifierHash
    ) public pure returns (uint256) {
        return uint256(_nullifierHash);
    }
}
