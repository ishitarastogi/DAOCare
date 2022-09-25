import "./App.css";
import { Route, Switch } from "react-router-dom";
import Navbar from "./components/Navbar";
import Header from "./containers/header/Header";
import Dashboard from "./components/Dasboard";
import Section from "./containers/Section";
import CreateProposal from "./pages/CreateProposal";

import Stream from "./pages/Stream";
import NftUnlock from "./pages/NftUnlock";
import DisplayProposals from "./pages/ActiveProposals";
function App() {
  return (
    <div className="App">
      <div className="gradient__bg">
        <Switch>
          <Route path="/" exact={true}>
            <Navbar />
            <Header />
            <Section />
            <Dashboard />
          </Route>

          <Route path="/createProposal">
            <CreateProposal />
          </Route>
          <Route path="/nftMembership">
            <NftUnlock />
          </Route>

          <Route path="/stream">
            <Stream />
          </Route>

          <Route path="/activeProposal">
            <DisplayProposals />
          </Route>
        </Switch>
      </div>
    </div>
  );
}

export default App;
