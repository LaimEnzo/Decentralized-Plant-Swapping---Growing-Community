A blockchain-powered peer-to-peer network for exchanging plants and sharing gardening knowledge 🌿

## 🌟 Overview

This smart contract creates a decentralized community where plant enthusiasts can mint plant NFTs, swap plants with others, build reputation, and participate in growing contests. Each plant is tracked with care metadata, growth history, and geographical information.

## ✨ Key Features

- 🏷️ **Plant NFTs**: Mint unique plant tokens with care instructions and metadata
- 🔄 **Plant Swapping**: Create listings and execute peer-to-peer plant exchanges  
- 📍 **Geo-tagging**: Location-based swap matching
- ⭐ **Reputation System**: Build credibility through successful swaps and plant care
- 🏆 **Growth Contests**: Community competitions with DAO-based voting
- 📈 **Growth Tracking**: Monitor plant development stages over time
- 🌟 **Plant Evolution**: Transform plants into higher rarity variants through dedicated care and reputation

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Decentralized-Plant-Swapping---Growing-Community
clarinet check
```

## 📋 Contract Functions

### 🌱 Plant Management

#### Mint Plant
```clarity
(mint-plant "Rose" "Rosa rubiginosa" u3 40000000 -75000000 "Water daily, full sun")
```
- Creates a new plant NFT with metadata
- Parameters: name, species, rarity (1-5), latitude, longitude, care instructions
- Returns: plant ID

#### Update Growth Stage
```clarity
(update-growth-stage u1 u3)
```
- Updates plant's growth stage
- Rewards reputation points to owner
- Parameters: plant-id, new-stage

#### Evolve Plant
```clarity
(evolve-plant u1)
```
- Evolves plant to next rarity level if conditions met
- Requires reputation >= 500 and care streak >= 5
- Parameters: plant-id

### 🔄 Plant Swapping

#### Create Swap Listing
```clarity
(create-swap-listing u1 "Succulent" 40000000 -75000000)
```
- Lists plant for swapping
- Parameters: plant-id, desired-species, latitude, longitude
- Returns: swap listing ID

#### Execute Swap
```clarity
(execute-swap u1 u2)
```
- Completes plant exchange between users
- Transfers ownership and awards reputation
- Parameters: swap-id, offered-plant-id

### ⭐ Reputation System

#### Rate Plant
```clarity
(rate-plant u1 u5)
```
- Rate another user's plant (1-5 stars)
- Increases plant and owner reputation
- Parameters: plant-id, rating

### 🏆 Contest System

#### Create Contest (Admin Only)
```clarity
(create-contest "Best Roses 2024" "Show your finest roses" u1000 u500)
```
- Creates new growing contest
- Parameters: name, description, duration-blocks, reward-amount

#### Enter Contest
```clarity
(enter-contest u1 u2)
```
- Submit plant to contest
- Parameters: contest-id, plant-id

#### Vote in Contest
```clarity
(vote-contest u1 u2 'SP123...)
```
- Vote for contest entry
- Parameters: contest-id, plant-id, participant-address

## 🔍 Read-Only Functions

- `(get-plant u1)` - Get plant details by ID
- `(get-user-plants 'SP123...)` - Get user's plant collection
- `(get-swap-listing u1)` - Get swap listing details
- `(get-user-reputation 'SP123...)` - Get user's reputation score
- `(get-contest u1)` - Get contest information

## 🏗️ Data Structure

### Plant NFT
```clarity
{
  owner: principal,
  name: string,
  species: string,
  rarity: uint (1-5, increases via evolution),
  lat: int,
  lng: int,
  care-instructions: string,
  growth-stage: uint,
  birth-block: uint,
  reputation: uint
}
```

### Swap Listing
```clarity
{
  plant-id: uint,
  owner: principal,
  desired-species: string,
  lat: int,
  lng: int,
  active: bool,
  created-block: uint
}
```

## 🎯 Usage Examples

### Basic Plant Trading Flow
1. **Mint your plant**: `(mint-plant "Fiddle Leaf Fig" "Ficus lyrata" u4 ...)`
2. **Create swap listing**: `(create-swap-listing u1 "Monstera" ...)`
3. **Someone executes swap**: `(execute-swap u1 u2)`
4. **Rate the exchange**: `(rate-plant u2 u5)`

### Contest Participation
1. **Enter contest**: `(enter-contest u1 u1)`
2. **Community votes**: `(vote-contest u1 u1 'SP123...)`
3. **Admin finalizes**: `(finalize-contest u1 'SP123...)`

## 🧪 Testing

```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request

## 📜 License

MIT License - feel free to grow this project! 🌱

---

*Happy plant swapping! 🌿💚*
