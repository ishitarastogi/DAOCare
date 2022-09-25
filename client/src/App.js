import "./App.css";
import { Route, Switch } from "react-router-dom";
import Navbar from "./components/Navbar";
import Header from "./containers/header/Header";
import Section from "./containers/Section";
import CreateProposal from "./pages/CreateProposal";
import VolunteerReg from "./pages/VolunteerReg";
import PlannerReg from "./pages/PlannerReg";
import Stream from "./pages/Stream";
import DisplayVolunteer from "./pages/DisplayVolunteer";
import DisplayPlanner from "./pages/DisplayPlanner";
import DisplayProposals from "./pages/DisplayProposals";
function App() {
  return (
    <div className="App">
      <div className="gradient__bg">
        <Switch>
          <Route path="/" exact={true}>
            <Navbar />
            <Header />
            <Section />
          </Route>

          <Route path="/createProposal">
            <CreateProposal />
          </Route>
          <Route path="/volunteerReg">
            <VolunteerReg />
          </Route>
          <Route path="/plannerReg">
            <PlannerReg />
          </Route>
          <Route path="/stream">
            <Stream />
          </Route>
          <Route path="/volunteerList">
            <DisplayVolunteer />
          </Route>
          <Route path="/plannerList">
            <DisplayPlanner />
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
