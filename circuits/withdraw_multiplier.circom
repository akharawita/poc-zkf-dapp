pragma circom 2.1.9;

include "./pedersen_hash.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template Withdraw() {
    signal input secret;
    signal input amount;
    signal input tokenId;

    signal input nullifier;

    signal output commitment; 
    signal output nullifierHash[2];

    component poseidonAmount = Poseidon(3);
    poseidonAmount.inputs[0] <== amount;
    poseidonAmount.inputs[1] <== secret;
    poseidonAmount.inputs[2] <== tokenId;

    component pedersenNullifier = PedersenHash();
    pedersenNullifier.message[0] <== nullifier;
    pedersenNullifier.message[1] <== secret;

    commitment <== poseidonAmount.out;
    nullifierHash <== pedersenNullifier.out;
}

component main { public [secret, amount, tokenId, nullifier] } = Withdraw();