# RealEstateDex

**Synthetic Real Estate Investment Trust (REIT) Platform on Stacks**

RealEstateDex is a decentralized finance (DeFi) protocol that enables users to gain synthetic exposure to Real Estate Investment Trusts (REITs) through collateralized debt positions (CDPs) on the Stacks blockchain. Users can deposit STX as collateral to mint synthetic REIT tokens (sREIT), providing diversified real estate exposure without directly owning physical properties or traditional REIT shares.

## 🏗️ Features

### Core Functionality
- **Collateralized Minting**: Deposit STX as collateral to mint synthetic REIT tokens
- **Over-Collateralization**: 150% minimum collateralization ratio ensures system stability
- **Liquidation Protection**: Automatic liquidation threshold at 120% collateralization ratio
- **Flexible Collateral Management**: Deposit and withdraw collateral while maintaining safe ratios
- **Token Burning**: Burn sREIT tokens to reduce debt and reclaim collateral

### Token Standard Compliance
- **SIP-010 Compatible**: Full compliance with Stacks fungible token standard
- **Transferable**: Standard transfer functionality with memo support
- **Readable Metadata**: Token name, symbol, decimals, and URI support

### Oracle Integration
- **Price Feeds**: Real-time REIT price updates through authorized oracles
- **Price History**: Historical price data storage for analytics
- **Oracle Management**: Admin controls for adding/removing authorized price feeds

### Administrative Controls
- **Minting Toggle**: Enable/disable new token minting during maintenance
- **Oracle Toggle**: Control oracle functionality
- **Multi-Oracle Support**: Multiple authorized oracles for price redundancy

## 🔧 Technical Specifications

### Blockchain & Language
- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Token Standard**: SIP-010 Fungible Token

### Key Parameters
- **Token Symbol**: sREIT
- **Token Name**: Synthetic REIT Token
- **Decimals**: 6
- **Minimum Collateral Ratio**: 150%
- **Liquidation Threshold**: 120%
- **Initial REIT Price**: 100 STX per sREIT
- **Price Precision**: 1,000,000 (6 decimals)

### Contract Architecture
```
RealEstateDex.clar
├── Token Implementation (SIP-010)
├── Collateral Management
├── Minting/Burning Logic
├── Oracle Price Feeds
├── Liquidation Mechanics
└── Administrative Functions
```

## 🚀 Installation & Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) (latest version)
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Stacks Wallet](https://www.hiro.so/wallet) for testnet interaction

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd RealEstateDex
   ```

2. **Install dependencies**
   ```bash
   cd RealEstateDex_contract
   npm install
   ```

3. **Run tests**
   ```bash
   npm test
   ```

4. **Start Clarinet console**
   ```bash
   clarinet console
   ```

### Network Configuration

The project includes configuration for three networks:

- **Devnet**: Local development (`settings/Devnet.toml`)
- **Testnet**: Stacks testnet (`settings/Testnet.toml`)  
- **Mainnet**: Stacks mainnet (`settings/Mainnet.toml`)

## 📖 Usage Examples

### Basic Token Operations

#### Check Token Information
```clarity
;; Get token name
(contract-call? .RealEstateDex get-name)

;; Get token symbol  
(contract-call? .RealEstateDex get-symbol)

;; Get user balance
(contract-call? .RealEstateDex get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Transfer Tokens
```clarity
;; Transfer 1000000 sREIT (1 sREIT with 6 decimals) to another address
(contract-call? .RealEstateDex transfer 
  u1000000 
  tx-sender 
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG 
  none)
```

### Collateral and Minting Operations

#### Deposit Collateral
```clarity
;; Deposit 150 STX as collateral (150000000 micro-STX)
(contract-call? .RealEstateDex deposit-collateral u150000000)
```

#### Mint Synthetic REIT Tokens
```clarity
;; Mint 1 sREIT token (requires sufficient collateral)
(contract-call? .RealEstateDex mint-sreit u1000000)
```

#### Burn Tokens to Reduce Debt
```clarity
;; Burn 0.5 sREIT to reduce debt
(contract-call? .RealEstateDex burn-sreit u500000)
```

#### Withdraw Collateral
```clarity
;; Withdraw 50 STX (if collateralization allows)
(contract-call? .RealEstateDex withdraw-collateral u50000000)
```

### Read-Only Functions

#### Check User Position
```clarity
;; Get detailed user position
(contract-call? .RealEstateDex get-user-position 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get collateral balance
(contract-call? .RealEstateDex get-collateral-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get collateralization ratio
(contract-call? .RealEstateDex get-collateral-ratio 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Market Information
```clarity
;; Get current REIT price
(contract-call? .RealEstateDex get-reit-price)

;; Get contract status
(contract-call? .RealEstateDex get-contract-status)

;; Check liquidation status
(contract-call? .RealEstateDex can-liquidate 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 📋 Contract Functions Documentation

### Public Functions

#### Core User Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `deposit-collateral` | `amount: uint` | Deposit STX as collateral for minting |
| `mint-sreit` | `amount: uint` | Mint sREIT tokens against collateral |
| `burn-sreit` | `amount: uint` | Burn sREIT tokens to reduce debt |
| `withdraw-collateral` | `amount: uint` | Withdraw excess collateral |
| `transfer` | `amount: uint, from: principal, to: principal, memo: (optional buff 34)` | Transfer sREIT tokens |

#### Administrative Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `update-reit-price` | `new-price: uint` | Update REIT price (oracle only) |
| `add-oracle` | `oracle: principal` | Add authorized oracle (owner only) |
| `remove-oracle` | `oracle: principal` | Remove oracle authorization (owner only) |
| `toggle-minting` | None | Enable/disable minting (owner only) |
| `toggle-oracle` | None | Enable/disable oracle updates (owner only) |

### Read-Only Functions

| Function | Parameters | Return Type | Description |
|----------|------------|-------------|-------------|
| `get-balance` | `who: principal` | `(response uint uint)` | Get sREIT balance |
| `get-total-supply` | None | `(response uint uint)` | Get total sREIT supply |
| `get-collateral-balance` | `user: principal` | `uint` | Get user's STX collateral |
| `get-user-position` | `user: principal` | `(optional {...})` | Get complete user position |
| `get-reit-price` | None | `uint` | Get current REIT price |
| `get-collateral-ratio` | `user: principal` | `(optional uint)` | Get collateralization ratio |
| `can-liquidate` | `user: principal` | `bool` | Check if position can be liquidated |
| `get-contract-status` | None | `{...}` | Get overall contract status |

## 🚀 Deployment Guide

### Testnet Deployment

1. **Configure your deployment account**
   ```bash
   clarinet accounts new my-account
   ```

2. **Deploy to testnet**
   ```bash
   clarinet publish --testnet
   ```

3. **Verify deployment**
   ```bash
   clarinet check
   ```

### Mainnet Deployment

1. **Review security checklist**
   - [ ] Complete security audit
   - [ ] Oracle partners confirmed
   - [ ] Initial parameters verified
   - [ ] Emergency procedures documented

2. **Deploy to mainnet**
   ```bash
   clarinet publish --mainnet
   ```

3. **Post-deployment setup**
   - Add authorized oracles
   - Set initial REIT price
   - Configure monitoring alerts

### Environment Variables

Create a `.env` file for sensitive configuration:

```bash
STACKS_PRIVATE_KEY=your_private_key
ORACLE_PRIVATE_KEY=oracle_private_key
INITIAL_REIT_PRICE=100000000
```

## 🔒 Security Considerations

### Smart Contract Security

1. **Collateralization Safeguards**
   - Minimum 150% collateral ratio enforced
   - Liquidation threshold at 120% prevents insolvency
   - Over-collateralization protects against price volatility

2. **Oracle Security**
   - Multi-oracle support prevents single point of failure
   - Price update authorization system
   - Historical price validation

3. **Access Controls**
   - Owner-only administrative functions
   - Oracle authorization management
   - Emergency pause mechanisms

### Risk Factors

⚠️ **Important Risks to Consider:**

- **Smart Contract Risk**: Bugs or vulnerabilities in contract code
- **Oracle Risk**: Price feed manipulation or failure
- **Liquidation Risk**: Collateral can be liquidated if ratio falls below 120%
- **Market Risk**: REIT price volatility affects collateral requirements
- **Regulatory Risk**: Changes in DeFi or real estate regulations

### Best Practices

1. **For Users:**
   - Maintain collateral ratio well above 150%
   - Monitor price movements and oracle updates
   - Only invest funds you can afford to lose

2. **For Developers:**
   - Regular security audits
   - Comprehensive testing including edge cases
   - Gradual parameter adjustments

3. **For Operators:**
   - Multiple oracle sources
   - Real-time monitoring systems
   - Clear liquidation procedures

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: Multi-function workflows
- **Edge Case Tests**: Boundary conditions and error scenarios
- **Gas Cost Analysis**: Transaction cost optimization

### Writing Custom Tests

Example test structure:

```typescript
import { describe, expect, it } from "vitest";

describe("RealEstateDex Tests", () => {
  it("should allow collateral deposit", () => {
    const { result } = simnet.callPublicFn(
      "RealEstateDex",
      "deposit-collateral",
      [Cl.uint(1000000)],
      address1
    );
    expect(result).toBeOk(Cl.uint(1000000));
  });
});
```

## 🤝 Contributing

We welcome contributions to the RealEstateDex project! Please follow these guidelines:

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass (`npm test`)
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Add comprehensive test coverage
- Include documentation for new features
- Use clear, descriptive variable names

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links & Resources

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [SIP-010 Token Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)

## 📞 Support

For questions, issues, or contributions:

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: [Project Wiki](../../wiki)

---

**Disclaimer**: This software is experimental and provided "as is". Users should understand the risks involved in DeFi protocols and only use funds they can afford to lose. The developers are not responsible for any losses incurred through the use of this smart contract.