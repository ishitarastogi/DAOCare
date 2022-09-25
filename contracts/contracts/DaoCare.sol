// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {IWorldID} from "./IWorldID.sol";
import {ByteHasher} from "./ByteHasher.sol";
import "./IPublicLock.sol";
import "./IPUSHCommInterface.sol";

/// @dev Constant Flow  and Instant distribution Agreement registration key, used to get the address from the host.
bytes32 constant CFA_ID = keccak256(
    "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
);
bytes32 constant IDA_ID = keccak256(
    "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
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
error InvalidNullifier();

/*/////////////////////////////////////////////////////////////////////////
  ******************************* DAO CARE **********************************
  /////////////////////////////////////////////////////////////////////////*/

/**
 * @title DAOCare
 * @author Ishita Rastogi
 *
 * @notice This is the DAO based contract to create proposals for NGOs. It enables sybil resistant voting mechanism
 * with constant flow of funds to parties which received grants. Only Unlock NFT Holders can participate.
 */
contract DAOCare is SuperAppBase {
    using ByteHasher for bytes;

    /// @notice Staging Polygon contract address
    address public EPNS_COMM_ADDRESS =
        0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;

    ISuperfluid public _host;
    /// @notice CFA library setup
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1Lib;

    /// @notice IDA library setup
    using IDAv1Library for IDAv1Library.InitData;
    IDAv1Library.InitData public idaV1;

    /// @notice Index ID.
    uint32 internal constant _INDEX_ID = 0;

    /// @dev Super token streamed to this contract
    ISuperToken internal immutable _acceptedToken;

    /// @dev deployed lock address on goreli
    IPublicLock public lock;

    /// @dev The WorldID instance that will be used for managing groups and verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group whose participants can claim this airdrop
    uint256 internal immutable groupId;

    /// @dev The World ID Action ID
    uint256 internal immutable actionId;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;

    address EPNS_CHANNEL_ADDRESS = 0xCFfCb4c9d94524E4609FFEF60c47DAf8FC38AE1b;

    uint256 public votePercentage;
    uint128 ProposerUnitShare;

    address public owner;

    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        string memory _actionId,
        ISuperfluid host,
        ISuperToken acceptedToken,
        IPublicLock _lockAddress
    ) {
        assert(address(host) != address(0));
        assert(address(acceptedToken) != address(0));
        worldId = _worldId;
        groupId = _groupId;
        actionId = abi.encodePacked(_actionId).hashToField();
        _acceptedToken = acceptedToken;
        lock = _lockAddress;
        _host = host;
        owner = msg.sender;

        cfaV1Lib = CFAv1Library.InitData({
            host: host,
            cfa: IConstantFlowAgreementV1(
                address(host.getAgreementClass(CFA_ID))
            )
        });
        idaV1 = IDAv1Library.InitData({
            host: host,
            ida: IInstantDistributionAgreementV1(
                address(host.getAgreementClass(IDA_ID))
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

    ///@dev only addresses holding unlock NFT can particpate.
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
        if (msg.sender != address(_host)) revert Unauthorized();
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /******************************** Proposal*********************** */

    enum VoteType {
        YES,
        NO
    }
    /// @dev struct to store the proposal details
    struct Proposal {
        //unique proposal id
        uint256 proposalId;
        uint256 yesVotes;
        uint256 noVotes;
        // address of proposal creator
        address proposer;
        // proposal descripition; store on web3storage
        string description;
        //whether proposal has been completed or not
        bool completed;
        //whether person has voted already
        bool voted;
        VoteType vote;
        bool exists;
    }

    /// mapping from proposalID to Proposal struct
    mapping(uint256 => Proposal) public proposals;
    ///@dev mapping to check whether user has already voted
    mapping(address => mapping(bool => bool)) votedI;
    /// @dev array to store all the proposer addresses
    address[] public proposerAddress;
    ///@dev total number of proposals
    uint256 totalProposals;

    /**************************** Volunteer ****************************/

    /// @dev struct to store volunteer details
    struct Volunteer {
        address volunteer;
        // whether volunteer completed the task
        bool completed;
        uint256 proposalId;
    }
    /// @dev mapping from volunteer address to Volunteer struct
    mapping(address => Volunteer) Volunteers;

    /**************************** Stratagic Planner ****************************/

    struct Planner {
        address Planner;
        bool accepted;
        uint256 proposalId;
    }
    mapping(address => Planner) planners;

    /**************************** Contract Events ****************************/

    /// @notice Emitted when pool is created
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string cid
    );
    event voteCast(uint256 proposalid, address voteAddr);
    event proposalExecuted(uint256 proposalId, uint256 unitShare);
    event plannerRegistered(address planner, uint256 proposalId);
    event volunteerRegistered(address volunteer, uint256 proposalId);

    /**************************** Contract Functions ****************************/

    /**
     * @dev This function create proposal and integrates EPNS boradcast notification.
     * Channel is deployed on the polygon testnet.
     * @param _description stores the proposal description on web3storage
     */
    function createProposal(string memory _description)
        external
        onlyNFTMembership
    {
        Proposal storage newProposals = proposals[totalProposals];
        newProposals.proposalId = totalProposals;
        newProposals.proposer = msg.sender;
        newProposals.description = _description;
        newProposals.completed = false;
        newProposals.exists = true;
        proposerAddress.push(msg.sender);
        totalProposals++;
        /// @dev EPNS integration for broadcast notifications
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            EPNS_CHANNEL_ADDRESS,
            EPNS_CHANNEL_ADDRESS,
            bytes(
                string(
                    // We are passing identity here
                    abi.encodePacked(
                        "0", // this is notification identity
                        "1", // this is payload type
                        "+", // segregator
                        "New Proposal Created", // this is notificaiton title
                        "+", // segregator
                        "Check it out" // notification body
                    )
                )
            )
        );
        emit ProposalCreated(newProposals.proposalId, msg.sender, _description);
    }

    /**
     * @dev This function allows nft holder to vote on proposal. Unlock protocols is used for NFT membership
     * It also integrate worldcoin so that one person can only vote one time
     * @param proposalId unique proposalid
     * @param _voteType enum to declare yes or no votes
     * @param root The root of the Merkle tree
     * @param nullifierHash The nullifier for this proof, preventing double signaling
     * @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
     */
    function castVote(
        uint256 proposalId,
        VoteType _voteType,
        address input,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external onlyNFTMembership {
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(input).hashToField(), // The signal of the proof
            nullifierHash,
            actionId,
            proof
        );

        nullifierHashes[nullifierHash] = true;
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.completed == false,
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
        emit voteCast(proposalId, msg.sender);
    }

    /**
     * @dev This function execute the proposal and initiate the superfluid stream
     */
    function executeProposal(uint256 proposalId, bytes memory ctx)
        internal
        onlyOwner
        returns (bytes memory newCtx)
    {
        Proposal storage newProposals = proposals[proposalId];

        require(proposals[proposalId].exists, "This proposal does not exist.");

        require(
            newProposals.completed == false,
            "You cannot vote for completed proposals!"
        );

        uint256 votingTotal = newProposals.yesVotes + newProposals.noVotes;
        uint256 votingPer = (newProposals.yesVotes * 100) / votingTotal;
        require(votingPer > votePercentage);

        newProposals.completed = true;
        emit proposalExecuted(proposalId, ProposerUnitShare);

        return _updateVotes(newProposals.proposer, ProposerUnitShare, ctx);
    }

    /**************************** Instant distrubution Agreement function ****************************/

    function createIndex() external {
        idaV1.createIndex(_acceptedToken, _INDEX_ID);
    }

    function distribute() external onlyOwner {
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

    function _updateVotes(
        address proposer,
        uint128 units,
        bytes memory ctx
    ) internal returns (bytes memory newCtx) {
        return
            idaV1.updateSubscriptionUnitsWithCtx(
                ctx,
                _acceptedToken,
                _INDEX_ID,
                proposer,
                units
            );
    }

    // function deleteShares(address subscriber) public {
    //     idaV1.deleteSubscription(_acceptedToken, address(this), _INDEX_ID, subscriber);
    // }

    /**************************** Setter Functions ****************************/

    /// @dev This function sets the minimum percentage of vote required for the proposal to be executed
    function setVotePercentage(uint256 _votePercentage) public {
        votePercentage = _votePercentage;
    }

    /// @dev set unit of shares
    function setUnit(uint128 _ProposerUnitShare) public {
        ProposerUnitShare = _ProposerUnitShare;
    }

    /**************************** Volunteer Registration ****************************/

    function VolunteerRegister(uint256 _proposalId) external {
        Volunteer storage newVolunteer = Volunteers[msg.sender];
        newVolunteer.volunteer = msg.sender;
        newVolunteer.completed = false;
        newVolunteer.proposalId = _proposalId;
    }

    function _isVolunteerCompleted(uint256 proposalId, address _volunteerAddr)
        external
    {
        uint256 id = Volunteers[_volunteerAddr].proposalId;
        require(proposals[id].proposer == msg.sender);
        Volunteers[_volunteerAddr].completed = true;
        emit volunteerRegistered(_volunteerAddr, proposalId);
    }

    /**************************** Planner Registration ****************************/

    function plannerSubmitProposal(uint256 proposalId) external {
        Planner storage newPlanner = planners[msg.sender];
        newPlanner.Planner = msg.sender;
        newPlanner.proposalId = proposalId;
        newPlanner.accepted = false;
    }

    function _isProposalAccepted(address planner) external {
        uint256 id = planners[planner].proposalId;
        require(proposals[id].proposer == msg.sender);
        planners[planner].accepted = true;
        emit plannerRegistered(planner, id);
    }

    function executePlannerProposal(
        int96 ProposerflowRate,
        int96 PlannerflowRate,
        address planner
    ) external {
        uint256 id = planners[planner].proposalId;
        require(planners[planner].accepted == true, "message");
        (, int96 outFlowRate, , ) = cfaV1Lib.cfa.getFlow(
            _acceptedToken,
            address(this),
            proposals[id].proposer
        );

        if (outFlowRate > 0) {
            cfaV1Lib.updateFlow(
                proposals[id].proposer,
                _acceptedToken,
                ProposerflowRate
            );
            cfaV1Lib.createFlow(planner, _acceptedToken, PlannerflowRate);
        }
    }

    // ---------------------------------------------------------------------------------------------
    // SUPER APP CALLBACKS

    function beforeAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32,
        bytes calldata, //_agreementData,
        bytes calldata _ctx
    )
        external
        view
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory cbdata)
    {
        ISuperfluid.Context memory decompiledContext = _host.decodeCtx(_ctx);
        uint256 proposalId = abi.decode(decompiledContext.userData, (uint256));

        return abi.encode(proposalId);
    }

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        uint256 proposalId = abi.decode(_cbdata, (uint256));

        newCtx = _updateOutflow(proposalId, _ctx);
        newCtx = executeProposal(proposalId, newCtx);

        return newCtx;
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData,
        bytes calldata _cbdata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        uint256 proposalId = abi.decode(_cbdata, (uint256));
        return _updateOutflow(proposalId, _ctx);
    }

    // Todo : delete subscription
    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData
        bytes calldata _cbdata, // _cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (
            _superToken != _acceptedToken ||
            _agreementClass != address(cfaV1Lib.cfa)
        ) {
            return _ctx;
        }

        uint256 proposalId = abi.decode(_cbdata, (uint256));
        return _updateOutflow(proposalId, _ctx);
    }

    function _updateOutflow(uint256 proposalId, bytes calldata ctx)
        private
        returns (bytes memory newCtx)
    {
        newCtx = ctx;
        Proposal storage newProposals = proposals[proposalId];

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

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = cfaV1Lib.deleteFlowWithCtx(
                ctx,
                address(this),
                newProposals.proposer,
                _acceptedToken
            );
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = cfaV1Lib.updateFlowWithCtx(
                ctx,
                newProposals.proposer,
                _acceptedToken,
                inFlowRate
            );
        } else {
            // The flow does not exist but should be created.
            newCtx = cfaV1Lib.createFlowWithCtx(
                ctx,
                newProposals.proposer,
                _acceptedToken,
                inFlowRate
            );
        }
    }
}
