// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ContractDevDao {
    address public owner;
    uint256 public totalProposals;
    uint256 public totalMembers;
    uint256 public votingPower;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool passed;
    }
    
    struct Member {
        address memberAddress;
        uint256 votingPower;
        bool isActive;
        uint256 joinDate;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event MemberAdded(address indexed member, uint256 votingPower);
    event MemberRemoved(address indexed member);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        votingPower = 1000; // Default voting power
        _addMember(msg.sender, votingPower);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can call this function");
        _;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _duration
    ) public onlyMember returns (uint256) {
        require(_duration > 0, "Duration must be greater than 0");
        
        uint256 proposalId = totalProposals;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            executed: false,
            passed: false
        });
        
        totalProposals++;
        
        emit ProposalCreated(proposalId, msg.sender, _title);
        return proposalId;
    }

    function vote(uint256 _proposalId, bool _support) public onlyMember {
        require(_proposalId < totalProposals, "Proposal does not exist");
        require(!hasVoted[msg.sender][_proposalId], "Already voted on this proposal");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        
        hasVoted[msg.sender][_proposalId] = true;
        uint256 power = members[msg.sender].votingPower;
        
        if (_support) {
            proposals[_proposalId].votesFor += power;
        } else {
            proposals[_proposalId].votesAgainst += power;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, power);
    }

    function executeProposal(uint256 _proposalId) public onlyMember {
        require(_proposalId < totalProposals, "Proposal does not exist");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period has not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        
        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;
        proposal.passed = proposal.votesFor > proposal.votesAgainst;
        
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    function addMember(address _member, uint256 _votingPower) public onlyOwner {
        require(_member != address(0), "Cannot add zero address");
        require(!members[_member].isActive, "Member already exists");
        
        _addMember(_member, _votingPower);
    }

    function _addMember(address _member, uint256 _votingPower) internal {
        members[_member] = Member({
            memberAddress: _member,
            votingPower: _votingPower,
            isActive: true,
            joinDate: block.timestamp
        });
        
        totalMembers++;
        emit MemberAdded(_member, _votingPower);
    }

    function removeMember(address _member) public onlyOwner {
        require(members[_member].isActive, "Member does not exist");
        
        members[_member].isActive = false;
        totalMembers--;
        
        emit MemberRemoved(_member);
    }

    function getProposal(uint256 _proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        bool passed
    ) {
        require(_proposalId < totalProposals, "Proposal does not exist");
        
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.passed
        );
    }

    function getDaoStats() public view returns (
        uint256 _totalProposals,
        uint256 _totalMembers,
        uint256 _votingPower
    ) {
        return (totalProposals, totalMembers, votingPower);
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }
}
