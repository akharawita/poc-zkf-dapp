const snarkjs = require("snarkjs");
const fs = require("fs");

async function proof_generator() {
  const { proof, publicSignals } = await snarkjs.plonk.fullProve(
    { a: 10, b: 21 },
    "circuits/build/swap_multiplier_js/swap_multiplier.wasm",
    "circuits/build/proving_key.zkey"
  );

  fs.writeFileSync("circuits/build/proof.json", JSON.stringify(proof));
  fs.writeFileSync("circuits/build/public.json", JSON.stringify(publicSignals));
  console.log("Proof & Public Generated!");

  const calldataBlob = await snarkjs.plonk.exportSolidityCallData(proof, publicSignals);
  const calldata = calldataBlob.split(",");

  console.log({
    proof: calldata[0],
    publicSignals: JSON.parse(calldata[1]),
  });

  return {
    proof: calldata[0],
    publicSignals: JSON.parse(calldata[1]),
  };
}

proof_generator().then(() => {
  process.exit(0);
});
