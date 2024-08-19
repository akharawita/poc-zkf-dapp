"use client";

import { SubmitHandler, useForm } from "react-hook-form";

import { executeDeposit, executeWithdraw, useGenerateProof } from "@/hooks/useProof";

import { useApprove } from "@/hooks/useApprove";
import { useGetBalance } from "@/hooks/useBalance";
import { getContractAddress } from "@/utils/constants";
import { Box, Button, Input, Select, useToast } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { parseEther } from "viem";
import { useAccount } from "wagmi";

type Inputs = {
  select_token: string;
  amount: string;
  secret: number;
  nullifier: string;
  submit_type: "deposit" | "withdraw";
};

export default function ZkfPage() {
  const [type, setType] = useState("deposit");

  const { address } = useAccount();
  const toast = useToast();

  const { balance } = useGetBalance({ address, tokenId: 1 });

  const { allowance, approve } = useApprove({
    tokenId: 1,
    spender: getContractAddress("basicTornado") as `0x${string}`,
    enabled: !!address,
  });

  const { mutate: mutateGenerateProof, isPending, data } = useGenerateProof();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<Inputs>();

  const onSubmit: SubmitHandler<Inputs> = (data) => {
    setType(data.submit_type);

    mutateGenerateProof({
      tokenId: Number(data.select_token),
      amount: parseEther(data.amount),
      secret: Number(data.secret),
      nullifier: parseInt(`${Number(data.nullifier) / 1e30}`),
    });
  };

  useEffect(() => {
    if (
      data &&
      data?.proof &&
      data?.publicSignals &&
      data?.proof?.length &&
      data?.publicSignals?.length &&
      data?.isValid &&
      type
    ) {
      const execute = async () => {
        const [, commitment, , , amount, tokenId] = data.publicSignals;

        if (type === "deposit") {
          executeDeposit(BigInt(commitment), Number(tokenId), amount)
            .then(() => {
              toast({
                title: "Deposit success",
                description: "We've deposited your funds.",
                status: "success",
                duration: 5000,
                isClosable: true,
              });
            })
            .catch((e) => {
              toast({
                title: "Deposit failed",
                description: e.message.replace(/args:.*/, ""),
                status: "error",
                duration: 5000,
                isClosable: true,
              });
            });

          return;
        }

        if (type === "withdraw") {
          executeWithdraw(data?.proof, data?.publicSignals)
            .then(() => {
              toast({
                title: "Withdraw success",
                description: "We've deposited your funds.",
                status: "success",
                duration: 5000,
                isClosable: true,
              });
            })
            .catch((e) => {
              toast({
                title: "Withdraw failed",
                description: e.message.replace(/args:.*/, ""),
                status: "error",
                duration: 5000,
                isClosable: true,
              });
            });

          return;
        }
      };

      execute();
    }

    if (data?.proof && data?.publicSignals && data?.proof?.length && data?.publicSignals?.length && !data?.isValid) {
      toast({
        title: "Proof failed",
        description: "The proof is invalid.",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
    }
  }, [data, type]);

  if (!address) return null;

  return (
    <div>
      <h1>Hello Zero-Knowledge proof</h1>

      <Box display="flex" gap="2" paddingY="15px">
        <Button
          onClick={() => {
            approve?.write();
          }}
        >
          {Number(allowance || 0) > 0 ? "Approved" : "Approve"}
        </Button>
      </Box>

      <div>
        <form onSubmit={handleSubmit(onSubmit)}>
          <div>
            Submit Types:
            <Select defaultValue="deposit" {...register("submit_type", { required: true })}>
              <option value="deposit">Deposit</option>
              <option value="withdraw">Withdraw</option>
            </Select>
          </div>
          TokenId:
          <Select defaultValue="1" {...register("select_token", { required: true })}>
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
          </Select>
          <div>Balance: {balance}</div>
          <div>
            Amount: <Input defaultValue="1" type="string" {...register("amount", { required: true })} />
            {errors.amount && <span>This field is required</span>}
          </div>
          <div>
            Secret: <Input defaultValue="123123" type="number" {...register("secret", { required: true })} />
            {errors.secret && <span>This field is required</span>}
          </div>
          <div>
            Nullifier:
            <Input value={address} type="string" {...register("nullifier", { required: true })} />
            {errors.nullifier && <span>This field is required</span>}
          </div>
          <Box paddingY="15px" display="flex" gridGap="5">
            <Button type="submit">Submit</Button> {isPending && <span>Proofing...</span>}
          </Box>
        </form>
      </div>
    </div>
  );
}
