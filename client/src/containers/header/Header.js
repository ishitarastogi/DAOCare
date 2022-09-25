import React from "react";
import people from "../../assets/peoples.png";
import "./header.css";
import { Link } from "react-router-dom";
import Section from "../Section";

const Header = () => (
  <div className="gpt3__header section__padding" id="home">
    <div className="gpt3__header-content">
      <h1 className="gradient__text">DAO CARE 🫂</h1>

      <p>
        Dao Care is a platform that allows NGOs to raise create the proposal and
        raise funds for the social cause. To mimimise the fake propsal as much
        as possible the grant will be provided to those NGOs who are majorly
        upvoted by the community.
      </p>
    </div>

    <div className="gpt3__header-image">
      <img src={people} />
    </div>
  </div>
);

export default Header;
