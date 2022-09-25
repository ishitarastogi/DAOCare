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
              <Link to="/volunteerReg">Volunteer Registration</Link>
            </p>
          </div>
        </div>

        <div class="card 3">
          <div class="card_image">
            <img src="https://media.giphy.com/media/DIfoRO9bp2hriB0e6f/giphy.gif" />
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/plannerReg">Stratagic Planner Registration</Link>
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
            <img src="https://media.giphy.com/media/xT5LMUk6qCU7hbIf7y/giphy.gif" />
          </div>
          <div class="card_title title-white">
            <p>
              <Link to="/volunteerList">Volunteer List</Link>
            </p>
          </div>
        </div>

        <div class="card 4">
          <div class="card_image">
            <img src="https://media.giphy.com/media/L4fB9di7ekn3F5PXaW/giphy.gif" />
          </div>
          <div class="card_title title-black">
            <p>
              <Link to="/plannerList">Planner List</Link>
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
