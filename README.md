## Getting Started Write circuit with Circom

- Install the Circom [install](https://docs.circom.io/getting-started/installation/)
- Writing circuits in folder `circuits` compile to `circuites/build` folder
- Compiling `circom ./withdraw_multiplier.circom --r1cs --wasm --sym --c -o build`
- Download the "Powers of Tau trusted setup file" select `powersOfTau28_hez_final_13.ptau` file from [here](https://github.com/iden3/snarkjs#7-prepare-phase-2) and place it in the `circuites` folder
- Back to root folder and Run `yarn snarkjs plonk setup ./circuits/build/withdraw_multiplier.r1cs ./circuits/powersOfTau28_hez_final_08.ptau ./circuits/build/proving_key.zkey`to generate the`generate proving key` file that we will use to generate the proof using the R1CS and ptau

#### Export the verifier contract from the proving key

- Run `yarn snarkjs zkey export solidityverifier ./circuits/build/proving_key.zkey ./contracts/src/WithdrawVerifier.sol` to generate the `contracts/src/WithdrawVerifier.sol` file

#### Create the proof

- Run `yarn snarkjs plonk fullprove circuits/witness.json circuits/build/withdraw_multiplier_js/withdraw_multiplier.wasm circuits/build/proving_key.zkey circuits/build/proof.json circuits/build/public.json` to generate the `proof.json` and `public.json` file

`** Optional step **
We need a verification key that can be generated from the proving key to verify the proof. Here’s how to get that:`

- Run `yarn snarkjs zkey export verificationkey circuits/build/proving_key.zkey circuits/build/verification_key.json` to generate the `verification_key.json` file

#### Verify the proof

We use the this command to verify the proof, passing in the verification_key we exported earlier.

If all is well, you should see that OK has been outputted to your console. This signifies the proof is valid.

- Run `yarn snarkjs plonk verify circuits/build/verification_key.json circuits/build/public.json circuits/build/proof.json` to verify the proof

#### Similate a verification call

- Run `yarn snarkjs zkey export soliditycalldata circuits/build/public.json circuits/build/proof.json` to cut and paste the result directly in the verify function in the `WithdrawVerifier.sol` contract

And voila! That's all there is to it :)

---

## Contract Testing

```
forge install
forge test --match-path ./test/SimpleTornado.t.sol -vvv
```

---

## Refs

- https://github.com/iden3/rollup/blob/master/circuits/rollup.circom
- https://hackernoon.com/protect-yourself-from-identity-theft-by-using-zero-knowledge-proof-solidity-and-ethereum
- https://github.com/zkBob/zkbob-contracts
- https://github.com/nalinbhardwaj/snarky-sudoku/blob/main/client/lib/util.ts

---

This is a [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Getting Started

First, run the development server:

- Copy `proving_key.zkey` and `withdraw_multiplier.wasm` to the `public/zksnarks` folder

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/basic-features/font-optimization) to automatically optimize and load Inter, a custom Google Font.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js/) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/deployment) for more details.
