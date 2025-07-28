# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SimLifeGame is a single-player life simulation game called "Vegas-Life" designed for ages 8-16. The game simulates 25 years of life (2000-2025) in approximately 30 minutes of real-time play, where 1 minute = 1 game month.

## Game Architecture

### Core Game Loop
The monthly cycle follows this sequence:
1. **Salary Processing** (0-5s): Calculate net income after taxes and deductions
2. **Fixed Costs** (5-20s): Deduct housing, food, utilities, loan payments
3. **Player Actions** (20-55s): Investment decisions, purchases, loan payments
4. **Event Cards** (55-58s): Random events that affect finances/happiness
5. **Month End** (58-60s): Update state, check failure conditions, autosave

### Data Models

Key TypeScript interfaces defined in the spec:
- `PlayerProfile`: Core player state including age, profession, finances
- `Portfolio`: Cash, bank, stocks, bonds, crypto holdings
- `Loan`: Student loans, car loans, mortgages with payment calculations
- `CarHolding` & `PropertyHolding`: Asset management with depreciation/appreciation

### Financial Systems

- **Taxation**: `net = gross/12 − 24.5% federal − 7.65% FICA − $200 health`
- **Loan Calculations**: Uses standard amortization formula `monthly = P·r/12 / (1−(1+r/12)^-n)`
- **Investment Pricing**: 
  - Stocks/Bonds: Alpha Vantage monthly close prices
  - Crypto: CoinGecko monthly data with 0.5% fees
  - Real Estate: Case-Shiller LVXRNSA index with property type multipliers

### Command System

The game uses CLI-style commands for player actions:
- `buy AAPL 20` - Purchase stocks
- `buy BTC 0.05` - Purchase crypto (with fees)
- `finance car honda_civic_2000 25` - Finance vehicle purchase
- `finance house condo 30` - Mortgage financing
- `sell NVDA 500` - Sell investments
- `deposit 1000` / `withdraw 300` - Bank transactions
- `pay loan 5000` - Extra principal payments
- `portfolio` - View current holdings
- `pass` - Skip month actions

## Game Failure Conditions

Primary failure: Cash below $0 for 6 consecutive months triggers game over.

## Testing Strategy

The spec defines comprehensive test cases:
- **Unit Tests**: Finance calculations, salary generation, event system
- **Integration Tests**: Mortgage workflows, negative cash scenarios
- **Scenario Tests**: Profession-specific survival tests, investment strategies
- **UI Tests**: PWA functionality via Cypress

## Implementation Notes

- Target platform: PWA for Chrome/Safari
- No server-side PII storage
- Educational focus with realistic financial modeling
- Uses real historical market data for authenticity
- 53 different event cards with weights and cooldowns