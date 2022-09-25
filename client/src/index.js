import React from "react";
import ReactDOM from "react-dom";
import reportWebVitals from "./reportWebVitals";
import { BrowserRouter } from "react-router-dom";

import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultWallets, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { chain, configureChains, createClient, WagmiConfig } from "wagmi";
import { alchemyProvider } from "wagmi/providers/alchemy";
import { publicProvider } from "wagmi/providers/public";
import App from "./App";
import "./index.css";

import { DAppProvider } from "@usedapp/core";
// import { library } from "@fortawesome/fontawesome-svg-core";
// import {faXmarkSquare} from "@fortawesome/free-solid-svg-icons";

// library.add(faXmarkSquare);

const { chains, provider, webSocketProvider } = configureChains(
  [
    chain.polygonMumbai,
    chain.polygon,
    chain.optimism,
    chain.arbitrum,
    ...(process.env.REACT_APP_ENABLE_TESTNETS === "true"
      ? [chain.polygonMumbai, chain.kovan, chain.rinkeby, chain.ropsten]
      : []),
  ],
  [alchemyProvider({ alchemyId: process.env.ALCHEMY_ID }), publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: "RainbowKit demo",
  chains,
});

const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
  webSocketProvider,
});
ReactDOM.render(
  <React.StrictMode>
    <WagmiConfig client={wagmiClient}>
      <RainbowKitProvider chains={chains}>
        <BrowserRouter>
          <App />
        </BrowserRouter>{" "}
      </RainbowKitProvider>
    </WagmiConfig>
  </React.StrictMode>,
  document.getElementById("root")
);

reportWebVitals();
