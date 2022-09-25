import React from "react";
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";

import "./CreateProposal.css";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import logo from "../assets/logo.png";

function VolunteerReg() {
  const [plannerName, setPlannerName] = useState("");
  const [plannerDesc, setPlannerDesc] = useState("");
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
        <h2 style={{ textAlign: "center" }}>Strtagic Planner Registration</h2>
        <form>
          <label>Strtagic Planner Name</label>
          <br />
          <br />
          <input
            className="names"
            id="name"
            type="text"
            placeholder="Stratagic Planner Name"
            value={plannerName}
          />
          <label>Strtagic Planner Description</label> <br />
          <br />
          <input
            className="desc"
            id="name"
            type="text"
            placeholder="Strtagic Planner Description"
            value={plannerDesc}
          />
          <button className="sub">Register as Volunteer</button>
        </form>
      </div>
    </div>
  );
}

export default VolunteerReg;
