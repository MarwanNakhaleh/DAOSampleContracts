// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DAO
/// @author Marwan Nakhaleh
contract DAO is Ownable {
    IERC20 public governanceToken;
    string public contractName;

    struct Member {
        uint256 tokens;
        mapping(bytes => bool) approvalsByProposal;
    }

    struct Proposal {
        uint40 proposalId;
        bytes proposalText;
        address proposalOwner;
        mapping(address => uint256) votesByProposalId;
        uint256 startTime;
        uint256 expiryTime;
        uint256 passTime;
        ProposalState proposalState;
    }

    enum ProposalState {
        PROPOSED,
        PASSED,
        EXECUTED,
        REJECTED
    }

    mapping(address => Member) public members;
    mapping(uint40 => Proposal) public proposals;

    uint40 public proposalCount;

    event SetMultisig(address indexed multisigWallet);
    event MultisigVote(uint256 indexed proposalId);
    event ProposalCreated(uint40 indexed proposalId);
    event ProposalPassed(uint40 indexed proposalId);
    event ProposalRejected(uint40 indexed proposalId);
    event ProposalExecuted(uint40 indexed proposalId);
    event UserVote(address indexed voter, bool side, uint256 indexed proposalId, uint96 amount);

    address public multisigWallet;

    //this function is for returning value
    function getProposalText(uint40 proposalId) external view returns(bytes memory){
        return proposals[proposalId].proposalText;
    }

    modifier hasMultisig() {
        require(multisigWallet != address(0), "Multisig wallet not set");
        _;
    }

    modifier isMember() {
        require(governanceToken.balanceOf(msg.sender) > 0, "Caller is not a member");
        _;
    }

    constructor(string memory _contractName, IERC20 _governanceToken) Ownable(msg.sender) {
        governanceToken = _governanceToken;
        contractName = _contractName;
    }

    function setMultisigWallet(address _multisigWallet) external onlyOwner {
        require(_multisigWallet != address(0));
        multisigWallet = _multisigWallet;
        emit SetMultisig(_multisigWallet);
    }

    function createProposal(uint256 _expiryTime, bytes memory proposalText) external hasMultisig isMember {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.proposalId = proposalCount;
        p.proposalText = proposalText;
        p.proposalOwner = msg.sender;
        p.startTime = block.timestamp; // TODO: Use Chainlink for timestamps for increased security
        p.expiryTime = _expiryTime;
        p.proposalState = ProposalState.PROPOSED;

        emit ProposalCreated(proposalCount);
    }

    function vote(uint40 _proposalId, bool _side) external hasMultisig isMember {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.expiryTime, "Proposal has expired");
        require(!members[msg.sender].approvalsByProposal[abi.encode(_proposalId)], "Already voted");

        uint256 voteWeight = governanceToken.balanceOf(msg.sender);

        if (_side) {
            p.votesByProposalId[msg.sender] = voteWeight;
        } else {
            p.votesByProposalId[msg.sender] = 0;
        }
        members[msg.sender].approvalsByProposal[abi.encode(_proposalId)] = true;

        emit UserVote(msg.sender, _side, _proposalId, uint96(voteWeight));
    }

    // TODO: Decide on how to accept or reject a proposal based on votes or something
}