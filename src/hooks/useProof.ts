import { getContractAddress } from "@/utils/constants";
import { config } from "@/utils/wagmi";
import { useMutation } from "@tanstack/react-query";
import * as snarkjs from "snarkjs";

import { encodeAbiParameters, parseAbiParameters, TransactionReceipt } from "viem";
import { simulateContract, waitForTransactionReceipt, writeContract } from "wagmi/actions";

import { abi as BasicTornadoAbi } from "@/lib/abis/BasicTornado.json";
import { getVerificationKey } from "@/utils";

const FILES_URL = "zksnarks";

type ProofData = {
  a1: BigInt;
  a2: BigInt;
  b1: BigInt;
  b2: BigInt;
  c1: BigInt;
  c2: BigInt;
  z1: BigInt;
  z2: BigInt;
  t1_1: BigInt;
  t1_2: BigInt;
  t2_1: BigInt;
  t2_2: BigInt;
  t3_1: BigInt;
  t3_2: BigInt;
  wxi1: BigInt;
  wxi2: BigInt;
  wxiw1: BigInt;
  wxiw2: BigInt;
  evala: BigInt;
  evalb: BigInt;
  evalc: BigInt;
  evals1: BigInt;
  evals2: BigInt;
  evalzw: BigInt;
};

type PublicSignals = {
  nullifier: BigInt;
  commitment: BigInt;
  x: BigInt;
  y: BigInt;
  amount: BigInt;
  tokenId: BigInt;
  z: BigInt;
};

type useGenerateProof = {
  secret: number;
  amount: BigInt;
  tokenId: number;
  nullifier: number;
};

const useGenerateProof = () => {
  return useMutation({
    mutationFn: async (data: useGenerateProof) => {
      const { secret, amount, tokenId, nullifier } = data;
      const inputs = {
        secret,
        amount,
        tokenId,
        nullifier,
      };

      // Paths to the .wasm file and proving key
      const wasmPath = `${FILES_URL}/withdraw_multiplier.wasm`;
      const provingKeyPath = `${FILES_URL}/proving_key.zkey`;

      try {
        // Generate a proof of the circuit and create a structure for the output signals
        const { proof, publicSignals } = await snarkjs.plonk.fullProve(
          {
            ...inputs,
            amount: Number(amount),
          },
          wasmPath,
          provingKeyPath
        );

        // Convert the data into Solidity calldata that can be sent as a transaction
        const calldataBlob = await snarkjs.plonk.exportSolidityCallData(proof, publicSignals);

        const argv = calldataBlob
          .replace(/\]\[/g, '","')
          .replace(/["[\]\s]/g, "")
          .split(",")
          .map(BigInt);

        // check proof
        const vKey = await getVerificationKey();
        const isValid = await snarkjs.plonk.verify(vKey, publicSignals, proof);

        return {
          proof: argv.slice(0, 24),
          publicSignals: argv.slice(24, 31),
          isValid,
        };
      } catch (err) {
        console.log("GenerateProof Error:", err);

        return {
          proof: [],
          publicSignals: [],
          isValid: false,
        };
      }
    },
  });
};

export const executeDeposit = async (
  commitment: BigInt,
  tokenId: number,
  amount: BigInt
): Promise<TransactionReceipt> => {
  const basicTornadoAddress = getContractAddress("basicTornado");

  try {
    // Prepare the transaction data
    const { request, ...rest } = await simulateContract(config, {
      address: basicTornadoAddress as `0x${string}`,
      abi: BasicTornadoAbi,
      functionName: "deposit",
      args: [commitment, tokenId, amount],
    });

    console.log(rest, request);

    // Execute the transaction
    const hash = await writeContract(config, request);

    const transactionReceipt = await waitForTransactionReceipt(config, {
      hash,
    });

    return transactionReceipt;
  } catch (error) {
    console.error("An error occurred during the transaction:", error);
    throw error; // Re-throw the error if needed
  }
};

export const executeWithdraw = async (proof: BigInt[], publicSignals: BigInt[]): Promise<TransactionReceipt> => {
  if (proof.length < 24) {
    throw new Error("Proof array must have at least 24 elements.");
  }

  const publicSignalsData: PublicSignals = {
    nullifier: publicSignals[0] as BigInt,
    commitment: publicSignals[1] as BigInt,
    x: publicSignals[2] as BigInt,
    y: publicSignals[3] as BigInt,
    amount: publicSignals[4] as BigInt,
    tokenId: publicSignals[5] as BigInt,
    z: publicSignals[6] as BigInt,
  };

  const proofData: ProofData = {
    a1: proof[0] as BigInt,
    a2: proof[1] as BigInt,
    b1: proof[2] as BigInt,
    b2: proof[3] as BigInt,
    c1: proof[4] as BigInt,
    c2: proof[5] as BigInt,
    z1: proof[6] as BigInt,
    z2: proof[7] as BigInt,
    t1_1: proof[8] as BigInt,
    t1_2: proof[9] as BigInt,
    t2_1: proof[10] as BigInt,
    t2_2: proof[11] as BigInt,
    t3_1: proof[12] as BigInt,
    t3_2: proof[13] as BigInt,
    wxi1: proof[14] as BigInt,
    wxi2: proof[15] as BigInt,
    wxiw1: proof[16] as BigInt,
    wxiw2: proof[17] as BigInt,
    evala: proof[18] as BigInt,
    evalb: proof[19] as BigInt,
    evalc: proof[20] as BigInt,
    evals1: proof[21] as BigInt,
    evals2: proof[22] as BigInt,
    evalzw: proof[23] as BigInt,
  };

  const proofBytes = encodeAbiParameters(
    parseAbiParameters([
      "(uint256 a1, uint256 a2, uint256 b1, uint256 b2, uint256 c1, uint256 c2, uint256 z1, uint256 z2, uint256 t1_1, uint256 t1_2, uint256 t2_1, uint256 t2_2, uint256 t3_1, uint256 t3_2, uint256 wxi1, uint256 wxi2, uint256 wxiw1, uint256 wxiw2, uint256 evala, uint256 evalb, uint256 evalc, uint256 evals1, uint256 evals2, uint256 evalzw)",
      "(uint256 nullifier,  uint256 commitment, uint256 x, uint256 y, uint256 amount, uint256 tokenId, uint256 z)",
    ]),
    [proofData, publicSignalsData] as any
  );

  const basicTornadoAddress = getContractAddress("basicTornado");

  // Prepare the transaction data
  const { request, ...rest } = await simulateContract(config, {
    address: basicTornadoAddress as `0x${string}`,
    abi: BasicTornadoAbi,
    functionName: "withdraw",
    args: [proofBytes],
  });

  // Execute the transaction
  const hash = await writeContract(config, request);

  const transactionReceipt = waitForTransactionReceipt(config, {
    hash,
  });

  return transactionReceipt;
};

export { useGenerateProof };
