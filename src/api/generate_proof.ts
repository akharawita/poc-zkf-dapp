const snarkjs = require("snarkjs");
const fs = require("fs");

export async function proof_generator(a: number, b: number): Promise<{ proof: any; publicSignals: any }> {
  const { proof, publicSignals } = await snarkjs.plonk.fullProve(
    { a, b },
    "../circuits/build/swap_multiplier_js/swap_multiplier.wasm",
    "../circuits/build/proving_key.zkey"
  );

  fs.writeFileSync("./build/proof.json", JSON.stringify(proof));
  fs.writeFileSync("./build/public.json", JSON.stringify(publicSignals));
  console.log("Proof & Public Generated!");

  return { proof, publicSignals };
}

// proof_generator(10, 21).then(() => {
//   process.exit(0);
// });
