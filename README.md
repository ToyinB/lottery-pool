# Lottery Pool Smart Contract

A decentralized lottery system built on the Stacks blockchain using Clarity smart contract language. This contract allows multiple participants to buy tickets and automatically selects a winner at the end of each lottery round.

## Features

- **Multi-ticket support**: Players can purchase multiple tickets to increase their winning chances
- **Automated winner selection**: Uses pseudo-random number generation to fairly select winners
- **Owner-controlled rounds**: Only the contract owner can start and end lottery rounds
- **Overflow protection**: Built-in safeguards prevent arithmetic overflow attacks
- **Transparent history**: All lottery results are stored on-chain for verification

## Contract Overview

### Key Parameters
- **Ticket Price**: 100 STX per ticket
- **Minimum Players**: 3 participants required
- **Maximum Participants**: 50 players per lottery round

### Data Storage
- `lottery-id`: Current lottery round number
- `lottery-balance`: Total STX collected for current round
- `lottery-status`: Whether lottery is active
- `participants`: List of players in each lottery round
- `player-tickets`: Number of tickets owned by each player
- `lottery-winners`: Historical record of winners and prize amounts

## Public Functions

### `start-lottery()`
- **Access**: Contract owner only
- **Purpose**: Activates a new lottery round
- **Returns**: `(ok true)` on success

### `buy-ticket(number-of-tickets)`
- **Access**: Any user
- **Purpose**: Purchase lottery tickets for the current round
- **Parameters**: 
  - `number-of-tickets` (uint): Number of tickets to purchase
- **Cost**: `number-of-tickets × 100 STX`
- **Returns**: `(ok true)` on successful purchase

### `end-lottery()`
- **Access**: Contract owner only
- **Purpose**: Ends current lottery, selects winner, and distributes prize
- **Process**:
  1. Randomly selects winner from participants
  2. Transfers entire lottery balance to winner
  3. Records winner in contract history
  4. Resets for next round
- **Returns**: `(ok true)` on success

## Read-Only Functions

### `get-lottery-info()`
Returns current lottery status including:
- Current lottery ID
- Total balance
- Active status
- Ticket price
- Minimum players required

### `get-winner(lottery-round)`
- **Parameters**: `lottery-round` (uint)
- **Returns**: Winner information for specified lottery round

### `get-player-tickets(player, lottery-round)`
- **Parameters**: 
  - `player` (principal): Player's address
  - `lottery-round` (uint): Lottery round number
- **Returns**: Number of tickets owned by player in specified round

## Security Features

### Overflow Protection
The contract includes `safe-add` function and overflow checks to prevent:
- Arithmetic overflow in ticket calculations
- Balance manipulation attacks
- Invalid ticket purchase amounts

### Access Control
- Only contract owner can start/end lottery rounds
- Prevents unauthorized lottery manipulation

### Fair Random Selection
Uses combination of block time and internal nonce for pseudo-random winner selection.

## Usage Example

1. **Owner starts lottery**: Call `start-lottery()`
2. **Players buy tickets**: Call `buy-ticket(5)` to purchase 5 tickets for 500 STX
3. **Owner ends lottery**: Call `end-lottery()` to select winner and distribute prize
4. **Check results**: Use `get-winner(0)` to see first lottery results

## Error Codes

- `u1`: Unauthorized access (not contract owner)
- `u2`: Winner selection failed
- `u3`: Participant list full or invalid
- `u4`: Arithmetic overflow detected

## Deployment Notes

- Contract owner is set to the deploying address (`tx-sender`)
- Initial lottery ID starts at 0
- Lottery must be manually started by owner after deployment

## Limitations

- Pseudo-random number generation (not cryptographically secure)
- Maximum 50 participants per round
- No automatic lottery scheduling
- Winner takes entire pool (no percentage splits)
