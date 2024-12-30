# Journa - Advanced Blockchain Voting System

## Overview
Journa is a sophisticated voting system built on the Stacks blockchain using Clarity smart contracts. It allows for secure, transparent, and flexible voting on various topics, with advanced features like vote delegation and time-limited voting periods.

## Features
- Multi-topic voting system
- Vote delegation
- Time-limited voting periods
- Weighted voting based on token balance
- Comprehensive security measures
- Extensive test suite

## Smart Contract Functions

### Public Functions
- `create-topic`: Create a new voting topic
- `cast-vote`: Cast a vote on a topic
- `delegate-vote`: Delegate voting power to another user
- `end-voting`: End the voting period for a topic (admin only)

### Read-Only Functions
- `get-topic-votes`: Get the current votes for a topic
- `get-user-voting-power`: Get a user's current voting power
- `get-topic-status`: Check if a topic's voting period is active
- `get-leading-option`: Get the current leading option for a topic

## Security Features
- Access control for admin functions
- Vote verification to prevent double voting
- Time-locked voting periods
- Checks for delegate cycles

## Testing
This project includes a comprehensive test suite using Clarinet. To run the tests:

1. Install Clarinet
2. Navigate to the project directory
3. Run `clarinet test`

## Usage
1. Deploy the contract to the Stacks blockchain
2. Use a Stacks wallet to interact with the contract functions
3. Create voting topics using `create-topic`
4. Users can cast votes using `cast-vote` or delegate their voting power
5. View results using the read-only functions