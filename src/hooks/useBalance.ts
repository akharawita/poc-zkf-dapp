import { abi as ZKFTokenAbi } from "@/lib/abis/ZKFToken.json";
import { getContractAddress } from "@/utils/constants";
import { useMemo } from "react";
import { Address, formatEther } from "viem";
import { useReadContract } from "wagmi";

type UseGetBalance = {
  address?: Address;
  tokenId: number;
};
type UseGetBalanceResponse = {
  balance: string | null;
  isLoading: boolean;
  error: Error | null;
};

export const useGetBalance = ({ address, tokenId }: UseGetBalance): UseGetBalanceResponse => {
  const token = getContractAddress("multiToken");

  const { data, isLoading, error } = useReadContract({
    address: token,
    abi: ZKFTokenAbi,
    functionName: "balanceOf",
    args: [address, tokenId],
  });

  return useMemo(() => {
    if (data) {
      return {
        balance: formatEther(data as bigint),
        isLoading: false,
        error: null,
      };
    }

    return {
      balance: null,
      isLoading,
      error,
    };
  }, [data, isLoading, error]);
};
