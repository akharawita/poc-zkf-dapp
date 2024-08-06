import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function ZkfLayout({ children }: { children: React.ReactNode }) {
  return (
    <section className="min-h-screen p-24">
      <nav>
        <ConnectButton />
      </nav>
      {children}
    </section>
  );
}
