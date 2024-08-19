import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { holesky } from "@wagmi/core/chains";

export const config = getDefaultConfig({
  appName: "My RainbowKit App",
  projectId: "123",
  chains: [holesky],
  ssr: true,
});
