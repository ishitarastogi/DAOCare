// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "https://github.com/unlock-protocol/unlock/blob/master/smart-contracts/contracts/interfaces/IPublicLock.sol";
import {ISuperfluid, ISuperToken, ISuperApp} from "https://github.com/superfluid-finance/protocol-monorepo/blob/089010c1403a930c392435ec173dc37c76689cfc/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "https://github.com/superfluid-finance/protocol-monorepo/blob/089010c1403a930c392435ec173dc37c76689cfc/packages/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

//create update and delete streams in solidity
import {CFAv1Library} from "https://github.com/superfluid-finance/protocol-monorepo/blob/089010c1403a930c392435ec173dc37c76689cfc/packages/ethereum-contracts/contracts/apps/CFAv1Library.sol";

//implement callbacks that run on certain events
import {SuperAppBase} from "https://github.com/superfluid-finance/protocol-monorepo/blob/089010c1403a930c392435ec173dc37c76689cfc/packages/ethereum-contracts/contracts/apps/SuperAppBase.sol";

contract DAOCare is SuperAppBase {
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 grantRequired;
        bool active;
        bool voted;
        VoteType vote;
    }

    enum VoteType {
        YES,
        NO,
        Notvoted
    }
    mapping(address => mapping(bool => bool)) votedI;

    struct VolunteerHelp {
        address proposer;
        string description;
        bool completed;
    }

    struct Volunteer {
        string name;
        address volunteer;
        bool completed;
        uint256 proposalId;
    }

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        uint256 grantRequired
    );
    address[] public volunteers;
    VolunteerHelp[] public Volunter;
    Proposal[] public Proposals;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => VolunteerHelp) VolunteerHelps;
    mapping(address => Volunteer) Volunteers;
    uint256 public proposalCount;

    function createProposal(uint256 _grant, string memory _description)
        external
    {
        require(_grant > 0);
        proposalCount++;
        Proposals.push(
            Proposal(
                Proposals.length - 1,
                msg.sender,
                _description,
                0,
                0,
                _grant,
                false,
                false,
                VoteType.Notvoted
            )
        );

        emit ProposalCreated(proposalCount - 1, msg.sender, _grant);
    }

    function castVote(uint256 proposalId, VoteType _voteType) external {
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.active == false,
            "You cannot vote for completed proposals!"
        );
        require(
            votedI[newProposals.proposer][newProposals.voted] == false,
            "You have already voted"
        );
        if (_voteType == VoteType.YES) {
            votedI[newProposals.proposer][newProposals.voted] = true;
            newProposals.yesVotes += 1;
        } else if (_voteType == VoteType.NO) {
            votedI[newProposals.proposer][newProposals.voted] = true;
            newProposals.noVotes += 1;
        }
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.active == false,
            "You cannot vote for completed proposals!"
        );
        uint256 totalVotes = newProposals.yesVotes + newProposals.noVotes;
        uint256 votePercentageEligiblity = (totalVotes *
            newProposals.yesVotes) / 100;
        require(votePercentageEligiblity > 50);
        newProposals.active = true;
    }

    function listVolunteerNeed(string memory _description, uint256 proposalId)
        external
    {
        Proposal storage newProposals = proposals[proposalId];
        Volunter.push(
            VolunteerHelp(newProposals.proposer, _description, false)
        );
    }

    function VolunteerRegister(uint256 _proposalId, string memory _name)
        external
    {
        Volunteer storage newVolunteer = Volunteers[msg.sender];
        newVolunteer.name = _name;
        newVolunteer.volunteer = msg.sender;
        newVolunteer.completed = false;
        newVolunteer.proposalId = _proposalId;
        volunteers.push(msg.sender);
    }

    function _isVolunteerCompleted(uint256 proposalId, address _volunteerAddr)
        external
    {
        Proposal storage newProposals = proposals[proposalId];
        require(newProposals.proposer == msg.sender);
        Volunteers[_volunteerAddr].completed = true;
    }

    function PlannerRegister(uint256 _proposalId, string memory _description)
        external
    {
        Planner storage newPlanner = planners[msg.sender];
        newPlanner.planner = msg.sender;
        newPlanner.description = _description;
        newPlanner.accepted = false;
        newPlanner.proposalId = _proposalId;
        plannersAddr.push(msg.sender);
    }

    function bookPlanner(uint256 proposalId, address _planner) external {
        Proposal storage newProposals = proposals[proposalId];
        Planner storage newPlanner = planners[_planner];

        require(newProposals.proposer == msg.sender);
        newPlanner.ProposersAccepted.push(msg.sender);
    }

    function acceptedProposal(address _proposer) external {
        Planner storage newPlanner = planners[msg.sender];
        newPlanner.ProposersAccepted.push(_proposer);
    }

    function executePlannerProposal(uint256 roposalId) external {}

    struct Planner {
        address planner;
        string description;
        address[] ProposersRequested;
        address[] ProposersAccepted;
        uint256 proposalId;
        bool accepted;
    }
    mapping(address => Planner) planners;
    address[] public plannersAddr;
}
