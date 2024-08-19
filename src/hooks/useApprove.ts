import { getContractAddress } from "@/utils/constants";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useMemo } from "react";
import { useAccount } from "wagmi";

import { abi as ZKFTokenAbi } from "@/lib/abis/ZKFToken.json";
import { createPublicClient, formatEther, http } from "viem";

import { useToast } from "@chakra-ui/react";
import { ethers } from "ethers";
import { holesky } from "viem/chains";
import { useWrite, UseWriteCallbacks } from "./useWrite";

export const publicClient = (network?: number) => {
  return createPublicClient({
    chain: holesky,
    transport: http(),
  });
};

async function getAllowance({
  tokenId,
  address,
  spender,
}: {
  tokenId?: number;
  chain: string;
  address?: `0x${string}`;
  spender?: `0x${string}`;
}) {
  if (!spender || !tokenId || !address) {
    return null;
  }

  try {
    const provider = publicClient();
    const multiTokenAddress = getContractAddress("multiToken");

    const data = await provider.readContract({
      abi: ZKFTokenAbi,
      address: multiTokenAddress as `0x${string}`,
      functionName: "allowance",
      args: [address, spender, tokenId],
    });

    return data;
  } catch (error) {
    throw new Error(error instanceof Error ? `[Allowance]:${error.message}` : "[Allowance]: Failed to fetch allowance");
  }
}

const useGetAllowance = ({
  tokenId,
  spender,
  chain,
  address,
}: {
  spender?: `0x${string}`;
  tokenId?: number;
  chain: string;
  address?: `0x${string}`;
}) => {
  const {
    data: allowance,
    refetch,
    isLoading,
    error: errorFetchingAllowance,
  } = useQuery({
    queryKey: ["allowance", spender, chain, tokenId, address],
    queryFn: () => getAllowance({ address, spender, chain, tokenId }),
    enabled: !!tokenId && !!spender && !!address,
  });

  return { allowance, refetch, isLoading, errorFetchingAllowance };
};

type UseApproveParams = {
  tokenId?: number;
  spender?: `0x${string}`;
  amount?: BigInt;
  enabled?: boolean;
};

export const useApprove = ({ tokenId, spender, amount, enabled }: UseApproveParams) => {
  const { address, chainId } = useAccount();

  const { allowance, refetch, isLoading, errorFetchingAllowance } = useGetAllowance({
    spender,
    chain: `${chainId}`,
    tokenId,
    address,
  });

  const { write, ...rest } = useWriteApprove({ tokenId, spender, amount, enabled });

  return useMemo(() => {
    if (!address) return { isApproved: false, errorFetchingAllowance };

    if (allowance?.toString() === ethers.MaxUint256.toString())
      return {
        isApproved: true,
        allowance: formatEther(allowance as bigint),
        approve: {
          write,
          ...rest,
        },
      };

    if (amount && allowance && allowance >= amount)
      return {
        isApproved: true,
        allowance: formatEther(allowance as bigint),
        approve: {
          write,
          ...rest,
        },
      };

    return {
      isApproved: false,
      allowance: formatEther(BigInt(0)),
      refetch,
      isLoading,
      approve: {
        write,
        ...rest,
      },
    };
  }, [address, allowance, rest, errorFetchingAllowance, isLoading, amount, refetch, write]);
};

export function useWriteApprove(
  { tokenId, spender }: UseApproveParams,
  callbacks: UseWriteCallbacks = {}
): ReturnType<typeof useWrite> {
  const toast = useToast();

  const multiTokenAddress = getContractAddress("multiToken");

  const result = useWrite(
    {
      address: multiTokenAddress as `0x${string}`,
      abi: ZKFTokenAbi as any,
      functionName: "approve",
      args: [spender, tokenId, ethers.MaxUint256],
      // enabled: Number(amount) > 0 && enabled,
    },
    {
      ...callbacks,
      onTransactionSettled: () => {
        // void client.invalidateQueries({
        //   queryKey: allowance({ wagmiConfig, token, spender, account, chainId }).queryKey,
        // });

        callbacks.onTransactionSettled?.();
      },
    }
  );

  useEffect(() => {
    if (result.status.kind === "error" && result.status.error) {
      toast({
        title: "User rejected the request.",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
    }
  }, [result.status.kind]);

  return result;
}
