// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import { IWorldID } from 'https://github.com/worldcoin/world-id-starter-hardhat/blob/main/contracts/interfaces/IWorldID.sol';
// import { ByteHasher } from 'https://github.com/worldcoin/world-id-starter-hardhat/blob/main/contracts/helpers/ByteHasher.sol';

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "https://github.com/unlock-protocol/unlock/blob/master/smart-contracts/contracts/interfaces/IPublicLock.sol";

/// @dev Constant Flow Agreement registration key, used to get the address from the host.
bytes32 constant CFA_ID = keccak256(
    "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
);

/// @dev Thrown when the receiver is the zero adress.
error InvalidReceiver();

/// @dev Thrown when receiver is also a super app.
error ReceiverIsSuperApp();

/// @dev Thrown when the callback caller is not the host.
error Unauthorized();

/// @dev Thrown when the token being streamed to this contract is invalid
error InvalidToken();

/// @dev Thrown when the agreement is other than the Constant Flow Agreement V1
error InvalidAgreement();

contract DAOCare is SuperAppBase {
    // using ByteHasher for bytes;
    /// @dev The WorldID instance that will be used for verifying proofs

    error InvalidNullifier();

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;
    // CFA library setup
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1Lib;
    using IDAv1Library for IDAv1Library.InitData;
    IDAv1Library.InitData public idaV1;
    uint32 internal constant _INDEX_ID = 0;

    /// @dev Super token that may be streamed to this contract
    ISuperToken internal immutable _acceptedToken;
    // IWorldID internal  worldId;
    /// @dev Super token that may be streamed to this contract

    IPublicLock public lock;
    address public currentProposar;

    /// @dev The WorldID group ID (1)
    // uint256 internal immutable groupId = 1;

    constructor(
        ISuperfluid host,
        ISuperToken acceptedToken,
        address receiver,
        IPublicLock _lockAddress // ,IWorldID _worldId
    ) {
        // worldId = _worldId;

        assert(address(host) != address(0));
        assert(address(acceptedToken) != address(0));
        assert(receiver != address(0));

        _acceptedToken = acceptedToken;
        lock = _lockAddress;

        cfaV1Lib = CFAv1Library.InitData({
            host: host,
            cfa: IConstantFlowAgreementV1(
                address(host.getAgreementClass(CFA_ID))
            )
        });
        idaV1 = IDAv1Library.InitData({
            host: host,
            ida: IInstantDistributionAgreementV1(
                address(
                    host.getAgreementClass(
                        keccak256(
                            "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
                        )
                    )
                )
            )
        });

        // Registers Super App, indicating it is the final level (it cannot stream to other super
        // apps), and that the `before*` callbacks should not be called on this contract, only the
        // `after*` callbacks.
        host.registerApp(
            SuperAppDefinitions.APP_LEVEL_FINAL |
                SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
        );
    }

    modifier onlyNFTMembership() {
        require(
            lock.balanceOf(msg.sender) > 0,
            "Address does not hold NFT membership"
        );
        _;
    }
    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        if (superToken != _acceptedToken) revert InvalidToken();
        if (agreementClass != address(cfaV1Lib.cfa)) revert InvalidAgreement();
        _;
    }

    modifier onlyHost() {
        if (msg.sender != address(cfaV1Lib.host)) revert Unauthorized();
        _;
    }
    enum VoteType {
        YES,
        NO
    }
    struct Proposal {
        uint256 proposalId;
        uint256 yesVotes;
        uint256 noVotes;
        address proposer;
        string description;
        bool active;
        bool voted;
        VoteType vote;
    }

    struct Volunteer {
        string name;
        address volunteer;
        bool completed;
        uint256 proposalId;
    }
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

    mapping(address => mapping(bool => bool)) votedI;
    mapping(uint256 => Proposal) public proposals;
    address[] public proposerAddress;
    address[] public activeProposerAddress;
    uint256 totalProposals;
    address[] public volunteers;
    mapping(address => Volunteer) Volunteers;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);

    function createProposal(string memory _description) external {
        Proposal storage newProposals = proposals[totalProposals];
        newProposals.proposalId = totalProposals;
        newProposals.proposer = msg.sender;
        newProposals.description = _description;
        newProposals.active = false;
        proposerAddress.push(msg.sender);
        totalProposals++;
    }

    function castVote(uint256 proposalId, VoteType _voteType) external {
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.active == false,
            "You cannot vote for completed proposals!"
        );
        require(
            votedI[msg.sender][newProposals.voted] == false,
            "You have already voted"
        );
        if (_voteType == VoteType.YES) {
            votedI[msg.sender][newProposals.voted] = true;
            newProposals.yesVotes += 1;
        } else if (_voteType == VoteType.NO) {
            votedI[msg.sender][newProposals.voted] = true;
            newProposals.noVotes += 1;
        }
    }

    function executeProposal(uint256 proposalId, bytes memory ctx) public {
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.active == false,
            "You cannot vote for completed proposals!"
        );

        activeProposerAddress.push(newProposals.proposer);
        currentProposar = newProposals.proposer;
        require(newProposals.yesVotes > newProposals.noVotes);
        newProposals.active = true;
        int96 netFlowRate = cfaV1Lib.cfa.getNetFlow(
            _acceptedToken,
            address(this)
        );

        (, int96 outFlowRate, , ) = cfaV1Lib.cfa.getFlow(
            _acceptedToken,
            address(this),
            newProposals.proposer
        );
        int96 inFlowRate = netFlowRate + outFlowRate;
        if (outFlowRate > 0) {}
        cfaV1Lib.createFlowWithCtx(
            ctx,
            currentProposar,
            _acceptedToken,
            inFlowRate
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
        newPlanner.ProposersRequested.push(msg.sender);
    }

    function acceptedProposal(address _proposer) external {
        Planner storage newPlanner = planners[msg.sender];
        newPlanner.ProposersAccepted.push(_proposer);
    }

    function executePlannerProposal(
        int96 ProposerflowRate,
        int96 PlannerflowRate,
        address planner
    ) external {
        (, int96 outFlowRate, , ) = cfaV1Lib.cfa.getFlow(
            _acceptedToken,
            address(this),
            currentProposar
        );

        if (outFlowRate > 0) {
            cfaV1Lib.updateFlow(
                currentProposar,
                _acceptedToken,
                ProposerflowRate
            );
            cfaV1Lib.createFlow(planner, _acceptedToken, PlannerflowRate);
        }
    }

    function _isVolunteerCompleted(uint256 proposalId, address _volunteerAddr)
        external
    {
        Proposal storage newProposals = proposals[proposalId];
        require(newProposals.proposer == msg.sender);
        Volunteers[_volunteerAddr].completed = true;
    }

    function createIndex() external {
        idaV1.createIndex(_acceptedToken, _INDEX_ID);
    }

    function distribute() external {
        (int256 cashAmount, , ) = _acceptedToken.realtimeBalanceOf(
            address(this),
            block.timestamp
        );

        require(cashAmount > 0, "SQF: You need Money to distribute");
        (uint256 actualCashAmount, ) = idaV1.ida.calculateDistribution(
            _acceptedToken,
            address(this),
            _INDEX_ID,
            uint256(cashAmount)
        );
        idaV1.distribute(_acceptedToken, _INDEX_ID, actualCashAmount);
    }

    function gainShare(address subscriber) public {
        // Get current units subscriber holds
        (, , uint256 currentUnitsHeld, ) = idaV1.getSubscription(
            _acceptedToken,
            address(this),
            _INDEX_ID,
            subscriber
        );

        // Update to current amount + 1
        idaV1.updateSubscriptionUnits(
            _acceptedToken,
            _INDEX_ID,
            subscriber,
            uint128(currentUnitsHeld + 1)
        );
    }

    function deleteShares(address subscriber) public {
        idaV1.deleteSubscription(
            _acceptedToken,
            address(this),
            _INDEX_ID,
            subscriber
        );
    }

    // ---------------------------------------------------------------------------------------------
    // SUPER APP CALLBACKS

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId
        bytes calldata, //_agreementData
        bytes calldata, //_cbdata
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        //        newCtx=executeProposal();

        return _updateOutflow(_ctx);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData,
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateOutflow(_ctx);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (
            _superToken != _acceptedToken ||
            _agreementClass != address(cfaV1Lib.cfa)
        ) {
            return _ctx;
        }

        return _updateOutflow(_ctx);
    }

    // function increaseFlow(   address to,
    //         int96 flowRate,bytes calldata ctx) private returns (bytes memory newCtx) {
    //         newCtx = ctx;

    //         }

    /// @dev Updates the outflow. The flow is either created, updated, or deleted, depending on the
    /// net flow rate.
    /// @param ctx The context byte array from the Host's calldata.
    /// @return newCtx The new context byte array to be returned to the Host.
    function _updateOutflow(bytes calldata ctx)
        private
        returns (bytes memory newCtx)
    {
        newCtx = ctx;

        int96 netFlowRate = cfaV1Lib.cfa.getNetFlow(
            _acceptedToken,
            address(this)
        );

        (, int96 outFlowRate, , ) = cfaV1Lib.cfa.getFlow(
            _acceptedToken,
            address(this),
            currentProposar
        );

        int96 inFlowRate = netFlowRate + outFlowRate;

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = cfaV1Lib.deleteFlowWithCtx(
                ctx,
                address(this),
                currentProposar,
                _acceptedToken
            );
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = cfaV1Lib.updateFlowWithCtx(
                ctx,
                currentProposar,
                _acceptedToken,
                inFlowRate
            );
        } else {
            // The flow does not exist but should be created.
            newCtx = cfaV1Lib.createFlowWithCtx(
                ctx,
                currentProposar,
                _acceptedToken,
                inFlowRate
            );
        }
    }
}
