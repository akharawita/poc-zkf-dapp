import { Address } from "viem";

export const CONTRACT_ADDRESSES = {
  //https://holesky.etherscan.io/address/0x4ee25e693723F9385E2cDF5C98374Aad1e584080#readContract
  multiToken: "0x4ee25e693723F9385E2cDF5C98374Aad1e584080",
  //https://holesky.etherscan.io/address/0x2cD3420b9ffFC0eB5B93Ea8ebDB4EF20184B17F7#readContract
  verifier: "0x2cD3420b9ffFC0eB5B93Ea8ebDB4EF20184B17F7",
  //https://holesky.etherscan.io/address/0x44B48669f556Ca9607c6F0e7cB487e19eD45D44B#readContract
  basicTornado: "0x44B48669f556Ca9607c6F0e7cB487e19eD45D44B",
};

export const getContractAddress = (contract: keyof typeof CONTRACT_ADDRESSES): Address => {
  if (!CONTRACT_ADDRESSES[contract]) {
    throw new Error(`Contract ${contract} not found`);
  }

  return CONTRACT_ADDRESSES[contract] as Address;
};
