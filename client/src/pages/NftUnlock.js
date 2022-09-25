import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import logo from "../assets/logo.png";
import "./nft.css";
function NftUnlock() {
  const [locked, setLocked] = useState("locked");
  const checkout = () => {
    window.unlockProtocol && window.unlockProtocol.loadCheckoutModal();
  };
  useEffect(() => {
    const checkUnlock = async () => {
      try {
        await window.unlockProtocol;
        if (window.unlockProtocol) {
          setLocked(window.unlockProtocol.getState());
        }
      } catch (e) {
        console.error(e);
      }
    };

    checkUnlock();
  }, []);
  return (
    <div className="conatiners">
      <div className="header">
        <Link to="/">
          {" "}
          <img src={logo} width="200px" height="150px" />
        </Link>
        <div>
          <ConnectButton />
        </div>
      </div>
      <h2 className="headnft"> NftUnlock</h2>
      {locked === "locked" && (
        <div onClick={checkout}>
          <button className="block">Unlock me!🔒</button>
        </div>
      )}
      {locked === "unlocked" && (
        <div>
          <button className="block">
            {" "}
            Unlocked!{" "}
            <span aria-label="unlocked" role="img">
              🗝
            </span>
          </button>
        </div>
      )}
    </div>
  );
}

export default NftUnlock;
