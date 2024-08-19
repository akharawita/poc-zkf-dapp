// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

import "./ERC6909.sol";
import "./WithdrawVerifier.sol";

contract BasicTornado {
    struct Deposit {
        uint256 amount;
        uint256 id;
        uint256 commitment;
        bool isDeposited;
    }

    struct ProofData {
        uint256 a1;
        uint256 a2;
        uint256 b1;
        uint256 b2;
        uint256 c1;
        uint256 c2;
        uint256 z1;
        uint256 z2;
        uint256 t1_1;
        uint256 t1_2;
        uint256 t2_1;
        uint256 t2_2;
        uint256 t3_1;
        uint256 t3_2;
        uint256 wxi1;
        uint256 wxi2;
        uint256 wxiw1;
        uint256 wxiw2;
        uint256 evala;
        uint256 evalb;
        uint256 evalc;
        uint256 evals1;
        uint256 evals2;
        uint256 evalzw;
    }
    struct PublicSignals {
        uint256 nullifier;
        uint256 commitment;
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
        uint256 _commitment,
        uint256 _id,
        uint256 _amount
    ) external returns (bytes32) {
        bytes32 recomputedCommitment = bytes32(
            keccak256(abi.encode(_commitment))
        );

        require(
            !deposits[recomputedCommitment].isDeposited,
            "Commitment already exists"
        );
        require(
            token.balanceOf(msg.sender, _id) >= _amount,
            "Insufficient balance"
        );

        deposits[recomputedCommitment] = Deposit(
            _amount,
            _id,
            _commitment,
            true
        );
        token.transferFrom(msg.sender, address(this), _id, _amount);

        emit DepositMade(recomputedCommitment, _id, _amount);

        return recomputedCommitment;
    }

    function withdraw(bytes calldata data) external {
        (ProofData memory proofData, PublicSignals memory publicSignals) = abi
            .decode(data, (ProofData, PublicSignals));

        uint256[24] memory proofArray = [
            proofData.a1,
            proofData.a2,
            proofData.b1,
            proofData.b2,
            proofData.c1,
            proofData.c2,
            proofData.z1,
            proofData.z2,
            proofData.t1_1,
            proofData.t1_2,
            proofData.t2_1,
            proofData.t2_2,
            proofData.t3_1,
            proofData.t3_2,
            proofData.wxi1,
            proofData.wxi2,
            proofData.wxiw1,
            proofData.wxiw2,
            proofData.evala,
            proofData.evalb,
            proofData.evalc,
            proofData.evals1,
            proofData.evals2,
            proofData.evalzw
        ];

        // Recompute commitment hash
        bytes32 recomputedCommitment = bytes32(
            keccak256(abi.encode(publicSignals.commitment))
        );
        bytes32 recomputedNullifer = bytes32(
            keccak256(abi.encode(publicSignals.nullifier))
        );

        // Check if the nullifier hash has already been used
        require(
            !nullifierHashes[recomputedNullifer],
            "Nullifier already exists"
        );

        // Check if the commitment exists and has sufficient balance
        Deposit storage depositData = deposits[recomputedCommitment];
        require(depositData.isDeposited, "Commitment does not exist");
        require(
            publicSignals.amount <= depositData.amount,
            "[0]: Insufficient balance"
        );
        require(
            publicSignals.amount <=
                token.balanceOf(address(this), publicSignals.tokenId),
            "[1]: Insufficient balance"
        );

        // Mark the nullifier hash as used
        nullifierHashes[recomputedNullifer] = true;

        // Prepare public signals for proof verification
        uint256[7] memory preparedPublicSignals = [
            publicSignals.nullifier,
            publicSignals.commitment,
            publicSignals.x,
            publicSignals.y,
            publicSignals.amount,
            publicSignals.tokenId,
            publicSignals.z
        ];

        // Verify the proof
        require(
            verifier.verifyProof(proofArray, preparedPublicSignals),
            "Invalid proof"
        );

        // Transfer the tokens
        token.transfer(msg.sender, publicSignals.tokenId, publicSignals.amount);

        // Emit the withdrawal event
        emit WithdrawalMade(recomputedNullifer, publicSignals.amount);
    }

    function convertToUint256(bytes32 data) public pure returns (uint256) {
        return uint256(data);
    }
}
