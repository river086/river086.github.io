# 🐾 SimLifeGame Pet System - User Guide

## Overview
The pet system has been successfully integrated into SimLifeGame! You can now own pets that provide happiness bonuses, incur monthly costs, and add a new dimension to your life simulation.

## How to Use the Pet System

### 🎮 Getting Started
1. Start the game and choose your profession
2. Wait for the game to load (pets.xml will be loaded automatically)
3. Use the console commands or global functions to interact with pets

### 💻 Console Commands (Browser Dev Tools)

Open your browser's developer tools (F12) and use these commands:

#### View Available Pets
```javascript
listPets()
```
This shows all 23 available pets with:
- ✅/❌ Affordability indicator
- ✅/❌ Age requirement indicator  
- Purchase cost and description
- Monthly cost and happiness bonus

#### Buy a Pet
```javascript
buyPet('goldfish')        // Buy a goldfish
buyPet('cat')            // Buy a cat
buyPet('horse')          // Buy a horse (if you meet requirements)
```

#### View Your Pets
```javascript
showPets()
```
This displays:
- All owned pets with age and stats
- Total monthly pet costs
- Total happiness bonus from pets

#### Sell a Pet
```javascript
sellPet('goldfish_1234567890')  // Use the pet's ID from showPets()
```

### 🐾 Available Pets

#### Small & Affordable
- **Goldfish** ($25, +5 happiness, $15/month)
- **Betta Fish** ($15, +6 happiness, $10/month)
- **Hamster** ($40, +8 happiness, $25/month)
- **Guinea Pig** ($35, +12 happiness, $30/month)

#### Medium Pets
- **Cat** ($150, +20 happiness, $65/month)
- **Small Dog** ($300, +25 happiness, $85/month)
- **Rabbit** ($80, +15 happiness, $45/month)
- **Ferret** ($120, +18 happiness, $55/month)

#### Exotic Pets
- **Sugar Glider** ($250, +22 happiness, $60/month)
- **Hedgehog** ($180, +14 happiness, $50/month)
- **Axolotl** ($80, +12 happiness, $25/month)

#### Premium Pets
- **Horse** ($5,000, +50 happiness, $800/month)
- **Miniature Pig** ($800, +35 happiness, $100/month)
- **Service Dog** ($2,000, +45 happiness, $120/month)

### 📊 Pet Mechanics

#### Requirements
Each pet has requirements you must meet:
- **Age limits**: Must be within age range
- **Cash minimum**: Need sufficient starting cash
- **Stats**: Some pets require wisdom/charm
- **Net worth**: Expensive pets need high net worth
- **Housing**: Some pets need specific housing

#### Monthly Costs
- Pet food and care costs are deducted monthly
- Costs are included in your monthly expense calculation
- Shown in expense breakdown

#### Happiness Bonuses
- Each pet provides a constant happiness bonus
- Bonuses stack if you own multiple pets
- Displayed in your happiness total: `150/1000 (+25 from pets)`

#### Pet Aging & Death
- Pets age each month
- Each pet has a realistic lifespan (goldfish: 3 years, parrot: 50 years)
- When pets reach their lifespan, they pass away naturally
- You lose 20 happiness when a pet dies

#### Pet Selling
- You can sell pets for a fraction of purchase price
- Sale price depends on pet's age/condition:
  - Young pets (0-50% lifespan): 60% of purchase price
  - Middle-aged (50-80% lifespan): 40% of purchase price
  - Old pets (80%+ lifespan): 20% of purchase price
- Selling reduces your happiness by the pet's bonus amount

### 🎯 Strategy Tips

#### Early Game (Age 24-30)
- Start with cheap pets: Goldfish ($25), Betta Fish ($15)
- Build up cash before getting expensive pets
- Guinea Pig ($35) gives good happiness for low cost

#### Mid Game (Age 30-40)  
- Consider medium pets: Cat ($150), Rabbit ($80)
- Ferrets ($120) are playful and boost luck
- Exotic pets like Hedgehog ($180) boost wisdom

#### Late Game (Age 40+)
- Premium pets: Horse ($5,000) if you have ranch
- Service Dog ($2,000) provides excellent benefits
- Multiple pets stack happiness bonuses

#### Financial Considerations
- Budget for monthly costs before buying
- Emergency fund for pet expenses
- Consider pet insurance (future feature)

### 🔧 Technical Details

#### Game Integration
- Pets data loaded from `pets.xml`
- Pet costs included in monthly expenses
- Happiness bonuses calculated in real-time
- Pet aging processed each month

#### Save/Load
- Pet ownership saved with game state
- Pet age and purchase date preserved
- Happiness bonuses restored on load

### 🐛 Troubleshooting

#### Common Issues
- **"Pet not found"**: Check spelling, use exact pet ID from pets.xml
- **"Insufficient cash"**: Pet has minimum cash requirements beyond purchase price
- **"Too young/old"**: Check pet age requirements
- **"Game not started"**: Start game first, then buy pets

#### Debug Commands
```javascript
// Check loaded pets
console.log(Object.keys(game.pets))

// Check your pet ownership
console.log(game.gameState.pets)

// View pet data
console.log(game.pets.goldfish)
```

### 📈 Example Gameplay

```javascript
// 1. Start game, choose profession, wait for loading

// 2. Check what you can afford
listPets()

// 3. Buy your first pet
buyPet('goldfish')
// Output: 🐾 Bought Goldfish for $25! Monthly cost: $15

// 4. Check your pets
showPets()
// Output: 🐾 Your Pets:
//         • Goldfish (goldfish) - 0 months old, Happiness bonus: +5, Monthly cost: $15

// 5. Watch happiness increase
// Happiness display: 105/1000 (+5 from pets)

// 6. Later, sell pet if needed
sellPet('goldfish_1640995200000')
// Output: 💔 Sold Goldfish for $15 (12 months old)
```

### 🎮 Integration with Main Game

#### Monthly Cycle
- Pet costs deducted during expense phase
- Pet aging happens during month advance
- Pet happiness added to total happiness

#### Financial Impact
- Monthly expenses increase with pets
- Net worth calculation includes pet value
- Cash flow tracking includes pet transactions

#### Game Events
- Pet death events reduce happiness
- Future: Pet-related random events planned

### 🚀 Future Enhancements

Planned features:
- Pet insurance system
- Pet breeding mechanics
- Pet-related random events
- Pet training/skill systems
- Pet achievement system
- Veterinarian profession synergy

---

## Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `listPets()` | View available pets | Shows all 23 pets |
| `buyPet('type')` | Purchase a pet | `buyPet('cat')` |
| `showPets()` | View owned pets | Shows your pets |
| `sellPet('id')` | Sell a pet | `sellPet('cat_123')` |

**The pet system is now fully integrated and ready to use! 🐾**