// import React from "react";
import "./dashboard.css";
import { useState, useEffect } from "react";

import React from "react";

function Dasboard() {
  const [items, setItems] = useState([]);
  const [address, setAddress] = useState([]);
  const [address1, setAddress1] = useState([]);

  useEffect(() => {
    getData();
  }, []);

  const getData = async () => {
    //Using fetch
    const response = await fetch(
      "https://api.covalenthq.com/v1/5/tokens/0x2631CFfd085A83e06a014dBD41fea0833931cAEA/nft_token_ids/?key=process.env.COVALENT_API_KEY"
    );
    const data = await response.json();
    setItems(data.data.items);

    const response2 = await fetch(
      "https://api.covalenthq.com/v1/5/tokens/0x2631CFfd085A83e06a014dBD41fea0833931cAEA/nft_transactions/1/?key=process.env.COVALENT_API_KEY"
    );
    const data2 = await response2.json();
    setAddress(data2.data.items);
    const response3 = await fetch(
      "https://api.covalenthq.com/v1/5/tokens/0x2631CFfd085A83e06a014dBD41fea0833931cAEA/nft_transactions/2/?key=process.env.COVALENT_API_KEY"
    );
    const data3 = await response3.json();
    setAddress1(data3.data.items);
  };
  return (
    <div className="column-main">
      <h2 className="heading">Voters details </h2>
      <div className="row">
        <div className="column">
          <h2>Addresses</h2>
          <ul className="list-1">
            <li>{address[0]?.nft_transactions[0]?.from_address}</li>
            <li>{address1[0]?.nft_transactions[0]?.from_address}</li>
          </ul>
        </div>
        <div className="column">
          <h2 className="head2">TokenId</h2>

          <ul className="list">
            {items.map((item) => (
              <li key={item.chain_id}>{item.token_id}</li>
            ))}
          </ul>
        </div>
        <div className="column">
          <h2>Vote Weight</h2>
          <p>-</p>
          <p>-</p>
        </div>
        <div className="column">
          <h2>Proposals Voted</h2>
          <p>-</p> <p>-</p>
        </div>
      </div>
    </div>
  );
}

export default Dasboard;
