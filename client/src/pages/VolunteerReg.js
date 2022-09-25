import React from "react";
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";

import "./CreateProposal.css";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import logo from "../assets/logo.png";

function VolunteerReg() {
  const [volunteerName, setVolunteerName] = useState("");
  const [volunteerDesc, setVolunteerDesc] = useState("");
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
      <div className="feedback-form">
        <h2 style={{ textAlign: "center" }}>Volunteer Registration</h2>
        <form>
          <label>Volunteer Name</label>
          <br />
          <br />
          <input
            className="names"
            id="name"
            type="text"
            placeholder="Volunteer Name"
            value={volunteerName}
          />
          <label>Volunteer Description</label> <br />
          <br />
          <input
            className="desc"
            id="name"
            type="text"
            placeholder="Volunteer Description"
            value={volunteerDesc}
          />
          <button className="sub">Register as Volunteer</button>
        </form>
      </div>
    </div>
  );
}

export default VolunteerReg;
