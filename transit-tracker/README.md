# Real-Time Transit Tracker

A blockchain-based real-time transit tracking system built on Stacks blockchain using Clarity smart contracts.

## Project Overview

This project integrates public transport APIs (or mock data) with blockchain technology to provide:
- Live vehicle position tracking
- Arrival time estimates
- Optimal route suggestions between two points

The system leverages blockchain technology to ensure transparency, immutability of transit data, and decentralized access to transit information.

## Architecture

This project consists of:

1. **Clarity Smart Contracts** - Core data storage and business logic
2. **Backend Service** - Fetches real-time transit data from APIs and updates the blockchain
3. **Frontend Interface** - Visualizes transit data for end users

## Smart Contract Structure

- `transit-data.clar` - Main contract that stores and provides access to transit data
  - Stores information about stops, vehicles, and routes
  - Provides functions to update vehicle positions and status
  - Allows querying of transit information
  - Implements secure access control for data providers
  - Contains event logging for security audit trails

- `route-planner.clar` - Contract for route planning and optimization
  - Stores cached routes between stops
  - Calculates estimated travel times
  - Implements a token-based payment model for route queries
  - Provides route verification through cryptographic hashing

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (v14 or above)
- [Git](https://git-scm.com/)

## Project Setup

1. Clone the repository
```bash
git clone https://github.com/midorichie/transit-tracker.git
cd transit-tracker
```

2. Install Clarinet (if not already installed)
```bash
# On macOS
brew install clarinet

# On Linux
curl -sSL https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar -xz -C /usr/local/bin

# On Windows (using PowerShell)
iwr https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-windows-x64.zip -OutFile clarinet.zip
Expand-Archive -Path clarinet.zip -DestinationPath $Env:USERPROFILE\AppData\Local\Microsoft\WindowsApps
Remove-Item clarinet.zip
```

3. Initialize the Clarinet project (if starting from scratch)
```bash
clarinet new
```

4. Test the smart contracts
```bash
clarinet test
```

## Smart Contract Deployment

1. Configure your deployment settings in `Clarinet.toml`

2. Deploy to testnet
```bash
clarinet deploy --testnet
```

3. Deploy to mainnet (when ready)
```bash
clarinet deploy --mainnet
```

## Development Workflow

1. Edit Clarity contracts in the `contracts` directory
2. Write tests in the `tests` directory
3. Run tests with `clarinet test`
4. Check for security issues with `clarinet check`
5. Deploy changes with `clarinet deploy`

### Contract Interaction Flow

```
User/Application → Frontend → Backend Service → Smart Contracts
                      ↑                ↑              ↑
                      └────────────────┴──────────────┘
                          Query Results & Updates
```

The system uses a hybrid on-chain/off-chain architecture:
- Core transit data and route information stored on-chain
- Real-time updates and calculations performed off-chain
- Verification and data integrity ensured by smart contracts

## Integrating with Transit APIs

The project is designed to work with various public transport APIs. To integrate with specific APIs:

1. Implement API client functions in the backend service
2. Configure API credentials in environment variables
3. Set up automated data polling to keep blockchain data fresh

## Security Considerations

- Multi-level access control system:
  - Contract owner has full administrative rights
  - Authorized data providers can update transit information
  - Public users can only query data

- Enhanced data validation:
  - Coordinate validation to ensure geographical accuracy
  - Route integrity verification through cryptographic hashing
  - Input sanitization for all user-provided data

- Anti-abuse measures:
  - Rate limiting to prevent excessive update transactions
  - Query limits to prevent API abuse
  - Token-based payment model for premium route calculations

- Audit and monitoring:
  - Comprehensive event logging for all state-changing operations
  - Ability to track all data modifications with timestamps and sender information
  - Toggleable logging for performance optimization

## Testing

Run the test suite:

```bash
clarinet test
```
