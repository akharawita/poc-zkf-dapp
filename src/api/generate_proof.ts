import path from "path";
// @ts-ignore
import * as snarkjs from "snarkjs";

const FILES_URL = "http://localhost:58352";

type GenerateProofInput = {
  secret: number;
  amount: number;
  tokenId: number;
  nullifier: number;
};

export const generateProof = async ({ secret, amount, tokenId, nullifier }: GenerateProofInput): Promise<any> => {
  console.log(`Generating vote proof with inputs: ${secret}, ${amount}, ${tokenId}, ${nullifier}`);

  const inputs = {
    in: [secret, amount, tokenId, nullifier],
  };

  // Paths to the .wasm file and proving key
  const wasmPath = path.join(process.cwd(), `${FILES_URL}/withdraw_multiplier_js/withdraw_multiplier.wasm`);
  const provingKeyPath = path.join(process.cwd(), `${FILES_URL}/withdraw_multiplier_js/proving_key.zkey`);

  try {
    // Generate a proof of the circuit and create a structure for the output signals
    const { proof, publicSignals } = await snarkjs.plonk.fullProve(inputs, wasmPath, provingKeyPath);

    // Convert the data into Solidity calldata that can be sent as a transaction
    const calldataBlob = await snarkjs.plonk.exportSolidityCallData(proof, publicSignals);

    const calldata = calldataBlob.split(",");

    return {
      proof: calldata[0],
      publicSignals: JSON.parse(calldata[1]),
    };
  } catch (err) {
    console.log(`Error:`, err);
    return {
      proof: "",
      publicSignals: [],
    };
  }
};
