# Decentralized Web3 Gig Marketplace

This repository contains a work-in-progress prototype for a decentralized gig marketplace targeting Web3 builders and creatives. The project is informed by the "Technical and Strategic Blueprint" provided by the user.

## Overview
- **Smart Contract Escrow** on Layer 2 (Arbitrum/Base) ensures secure payment locking and release.
- **Flexible Payments** supporting flat tokens, future project tokens (vesting or airdropped), NFT equity shares (ERC-1155), and on-chain revenue streaming via Superfluid.
- **Reputation Engine** with optional zero-knowledge proofs for privacy-preserving credential verification.
- **Frontend** built with Next.js and Tailwind CSS.
- **Backend** using Node.js with Supabase or Firebase for rapid MVP development.
- **Decentralized Profile Storage** using Ceramic.

This repository will evolve to include a minimal example of the core components. The goal is to provide a starting point for further development and experimentation.
The `GigEscrow` contract in `contracts/` supports ETH and ERC-20 payments with a built-in 10% platform fee and basic dispute tracking.


## Repository Structure
- `frontend/` – minimal Next.js application.
- `contracts/` – Solidity smart contracts and Hardhat setup.
- `docs/` – design documents and future specifications.

## Status
This is an early-stage skeleton. Additional functionality will be added iteratively.
