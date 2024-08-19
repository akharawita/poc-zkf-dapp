"use client";

import { ChakraProvider } from "@chakra-ui/react";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";

import { config } from "@/utils/wagmi";

const queryClient = new QueryClient();

const Provider = ({ children }: { children: React.ReactNode }) => {
  return (
    <ChakraProvider>
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <RainbowKitProvider>{children}</RainbowKitProvider>
        </QueryClientProvider>
      </WagmiProvider>
    </ChakraProvider>
  );
};

export default Provider;
