// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import { IWorldID } from 'https://github.com/worldcoin/world-id-starter-hardhat/blob/main/contracts/interfaces/IWorldID.sol';
// import { ByteHasher } from 'https://github.com/worldcoin/world-id-starter-hardhat/blob/main/contracts/helpers/ByteHasher.sol';

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

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

    /// @dev Super token that may be streamed to this contract
    // ISuperToken internal immutable _acceptedToken;
    // IWorldID internal  worldId;
    /// @dev Super token that may be streamed to this contract

    IPublicLock public lock;

    /// @dev The WorldID group ID (1)
    // uint256 internal immutable groupId = 1;

    // constructor(
    //     ISuperfluid host,
    //     ISuperToken acceptedToken,
    //     address receiver,
    //     IPublicLock _lockAddress // ,IWorldID _worldId
    // ) {
    //     // worldId = _worldId;

    //     assert(address(host) != address(0));
    //     assert(address(acceptedToken) != address(0));
    //     assert(receiver != address(0));

    //     _acceptedToken = acceptedToken;
    //     lock = _lockAddress;

    //     cfaV1Lib = CFAv1Library.InitData({
    //         host: host,
    //         cfa: IConstantFlowAgreementV1(
    //             address(host.getAgreementClass(CFA_ID))
    //         )
    //    });

    //     // Registers Super App, indicating it is the final level (it cannot stream to other super
    //     // apps), and that the `before*` callbacks should not be called on this contract, only the
    //     // `after*` callbacks.
    //     host.registerApp(
    //         SuperAppDefinitions.APP_LEVEL_FINAL |
    //             SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
    //             SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
    //             SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
    //     );
    // }

    modifier onlyNFTMembership() {
        require(
            lock.balanceOf(msg.sender) > 0,
            "Address does not hold NFT membership"
        );
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

    mapping(address => mapping(bool => bool)) votedI;
    mapping(uint256 => Proposal) public proposals;
    address[] public proposerAddress;
    uint256 totalProposals;

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

    function executeProposal(uint256 proposalId) public {
        Proposal storage newProposals = proposals[proposalId];

        require(
            newProposals.active == false,
            "You cannot vote for completed proposals!"
        );

        require(newProposals.yesVotes > newProposals.noVotes);
        newProposals.active = true;
    }
}
