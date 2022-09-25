import React from "react";
import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import "./CreateProposal.css";
import logo from "../assets/logo.png";

function CreateProposal() {
  const [proposalName, setProposalName] = useState("");
  const [proposalDescription, setProposalDescription] = useState("");
  const [proposalImage, setProposalImage] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();
    const body = {
      name: proposalName,
      description: proposalDescription,
      image: proposalImage,
    };
    try {
      const response = await fetch("../pages/api/Proposal-data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (response.status !== 200) {
        alert("Something went wrong.");
      } else {
        let responseJSON = await response.json();
        await createEvent(responseJSON.cid);
      }
    } catch (error) {
      alert(`Oops! Something went wrong. ${error}`);
    }
  }

  //TODO
  const createProposal = async (cid) => {};

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
        <h2 style={{ textAlign: "center" }}>Create Proposal</h2>
        <form onSubmit={handleSubmit}>
          <label>Proposal Name</label>
          <br />
          <br />
          <input
            className="names"
            id="name"
            type="text"
            placeholder="Enter Proposal Name"
            value={proposalName}
            onChange={(e) => setProposalName(e.target.value)}
          />
          <label>Proposal Description</label> <br />
          <br />
          <input
            className="desc"
            id="name"
            type="text"
            placeholder="Enter Proposal Description"
            value={proposalDescription}
            onChange={(e) => setProposalDescription(e.target.value)}
          />
          <label className="labels">Select Image for proposal</label> <br />
          <br />
          <input
            type="file"
            onChange={(e) => setProposalImage(e.target.files[0])}
          />
          <button className="sub">Submit</button>
        </form>
      </div>
    </div>
  );
}
export default CreateProposal;
