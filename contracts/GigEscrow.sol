// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title GigEscrow - basic escrow for Web3 gig marketplace
/// @notice Supports ETH and ERC20 payments. Platform takes a 10% fee on release.
/// @dev This contract is a simplified prototype and has not been audited.
contract GigEscrow is Ownable, ReentrancyGuard {
    enum GigStatus { None, Created, Accepted, Submitted, Disputed, Completed, Cancelled }

    struct Gig {
        address client;
        address freelancer;
        address token; // address(0) for ETH
        uint256 amount;
        GigStatus status;
        bool disputed;
    }

    uint256 public constant FEE_BPS = 1000; // 10% fee
    uint256 private nextGigId = 1;
    mapping(uint256 => Gig) public gigs;
    uint256 public feesAccrued;

    event GigCreated(uint256 indexed gigId, address indexed client, address indexed freelancer, address token, uint256 amount);
    event GigAccepted(uint256 indexed gigId);
    event WorkSubmitted(uint256 indexed gigId);
    event WorkApproved(uint256 indexed gigId, uint256 payout, uint256 fee);
    event DisputeOpened(uint256 indexed gigId);
    event GigCancelled(uint256 indexed gigId);

    /// @notice Create a gig and lock payment in escrow
    /// @param _freelancer Address of the freelancer
    /// @param _token Token to pay with (address(0) for ETH)
    /// @param _amount Amount of token (or msg.value for ETH)
    function createGig(address _freelancer, address _token, uint256 _amount) external payable nonReentrant returns (uint256 gigId) {
        require(_freelancer != address(0), "freelancer required");
        gigId = nextGigId++;

        Gig storage g = gigs[gigId];
        g.client = msg.sender;
        g.freelancer = _freelancer;
        g.token = _token;
        g.amount = _amount;
        g.status = GigStatus.Created;

        if (_token == address(0)) {
            require(msg.value == _amount, "value mismatch");
        } else {
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        emit GigCreated(gigId, msg.sender, _freelancer, _token, _amount);
    }

    /// @notice Freelancer accepts the gig
    function acceptGig(uint256 gigId) external {
        Gig storage g = gigs[gigId];
        require(msg.sender == g.freelancer, "only freelancer");
        require(g.status == GigStatus.Created, "invalid status");
        g.status = GigStatus.Accepted;
        emit GigAccepted(gigId);
    }

    /// @notice Mark work submitted
    function submitWork(uint256 gigId) external {
        Gig storage g = gigs[gigId];
        require(msg.sender == g.freelancer, "only freelancer");
        require(g.status == GigStatus.Accepted, "invalid status");
        g.status = GigStatus.Submitted;
        emit WorkSubmitted(gigId);
    }

    /// @notice Approve completed work and release payment minus fee
    function approveWork(uint256 gigId) external nonReentrant {
        Gig storage g = gigs[gigId];
        require(msg.sender == g.client, "only client");
        require(g.status == GigStatus.Submitted, "invalid status");
        g.status = GigStatus.Completed;

        uint256 fee = (g.amount * FEE_BPS) / 10000;
        uint256 payout = g.amount - fee;
        feesAccrued += fee;

        if (g.token == address(0)) {
            payable(g.freelancer).transfer(payout);
        } else {
            IERC20(g.token).transfer(g.freelancer, payout);
        }

        emit WorkApproved(gigId, payout, fee);
    }

    /// @notice Open a dispute (for future off-chain resolution)
    function openDispute(uint256 gigId) external {
        Gig storage g = gigs[gigId];
        require(msg.sender == g.client || msg.sender == g.freelancer, "not participant");
        require(g.status == GigStatus.Submitted || g.status == GigStatus.Accepted, "invalid status");
        g.disputed = true;
        g.status = GigStatus.Disputed;
        emit DisputeOpened(gigId);
    }

    /// @notice Cancel a gig before freelancer accepts
    function cancelGig(uint256 gigId) external nonReentrant {
        Gig storage g = gigs[gigId];
        require(msg.sender == g.client, "only client");
        require(g.status == GigStatus.Created, "cannot cancel");
        g.status = GigStatus.Cancelled;

        if (g.token == address(0)) {
            payable(g.client).transfer(g.amount);
        } else {
            IERC20(g.token).transfer(g.client, g.amount);
        }
        emit GigCancelled(gigId);
    }

    /// @notice Withdraw accumulated platform fees
    function withdrawFees(address _to) external onlyOwner {
        require(_to != address(0), "to address required");
        uint256 amount = feesAccrued;
        feesAccrued = 0;
        if (amount > 0) {
            payable(_to).transfer(amount);
        }
    }

    // -------------------------------------------------------------------------
    // Future Extensions (commented placeholders)
    // -------------------------------------------------------------------------
    // function createVestingGig(...) external { /* integrate OpenZeppelin VestingWallet */ }
    // function createRevenueShareGig(...) external { /* integrate Superfluid streams */ }
    // function mintEquityNFT(...) external { /* mint ERC-1155 for equity/bonuses */ }
}
