import React from "react";
import "./section.css";
import { NavLink, Link } from "react-router-dom";

function Section() {
  return (
    <div>
      <div class="cards-list">
        <div class="card 1">
          <div class="card_image">
            {" "}
            <img src="https://media.giphy.com/media/3oz8xYfQd5358zpL0s/giphy.gif" />{" "}
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/createProposal"> Create Proposal</Link>
            </p>
          </div>
        </div>

        <div class="card 2">
          <div class="card_image">
            <img src="https://media.giphy.com/media/xT5LMFZDsj0AKUDYTS/giphy.gif" />
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/nftMembership">Get NFT Membership</Link>
            </p>
          </div>
        </div>

        <div class="card 4">
          <div class="card_image">
            <img src="https://media.giphy.com/media/3YX5uFD3ksn5QGhQCQ/giphy.gif" />
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/activeProposal">Active Proposals</Link>
            </p>
          </div>
        </div>

        <div class="card 4">
          <div class="card_image">
            <img src="https://media.giphy.com/media/SsTcO55LJDBsI/giphy.gif" />
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/stream">Stream Funds</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Section;
