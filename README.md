VeriTrust Smart Contract

**VeriTrust** is a Solidity-based smart contract designed to manage decentralized verification and trust registration on-chain. It enables issuers to register, issue, and revoke verifications for addresses, ensuring a secure and transparent trust system.

---

Features

- **Trust Registry:** Stores verified addresses with their current status.  
- **Issuer Management:** Allows only authorized issuers to issue or revoke verifications.  
- **Verification Workflow:** Issue, revoke, and query verification status for any address.  
- **Event Logging:** Emits events for key actions:
  - `IssuerRegistered`
  - `VerificationIssued`
  - `VerificationRevoked`
- **Access Control:** Prevents unauthorized modifications and ensures data integrity.  
- **Audit-Friendly:** Structured for compatibility with Solidity linters and auditing tools.

---

Functions

Issuer Management
- `registerIssuer(address issuer)`: Register a new issuer.  
- `removeIssuer(address issuer)`: Remove an existing issuer.  

Verification Management
- `issueVerification(address user)`: Issue verification to a user.  
- `revokeVerification(address user)`: Revoke verification from a user.  

Queries
- `isVerified(address user) -> bool`: Returns the verification status of a user.  
- `getIssuers() -> address[]`: Returns the list of all authorized issuers.

---

Events

- `IssuerRegistered(address issuer)` – Emitted when a new issuer is registered.  
- `VerificationIssued(address user, address issuer)` – Emitted when a verification is issued.  
- `VerificationRevoked(address user, address issuer)` – Emitted when a verification is revoked.

---

Installation & Usage

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/veritrust.git
   cd veritrust
