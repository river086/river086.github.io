# 💼 SimLifeGame Side Job System - User Guide

## Overview
The side job system allows you to earn extra money by doing one-time gig work! Each side job costs energy and provides additional income to supplement your main career.

## How to Use Side Jobs

### 🎮 Getting Started
1. Start the game and choose your profession
2. Look for the **💼 Side Job** button in the Action Controls
3. Click it to do a random available side job
4. Your energy will be consumed and you'll earn money!

### ⚡ Energy System
- **Starting Energy**: 75 energy points
- **Energy Recovery**: +50 energy every month (automatic)
- **Energy Cost**: Each job costs 10-40 energy depending on difficulty
- **Low Energy**: If you don't have enough energy, the job won't execute

### 🪟 Side Job Completion Popup
- **Detailed Results**: Shows job name, description, and payment details
- **Energy Tracking**: Displays energy cost and remaining energy
- **Visual Feedback**: Different icons for job types (🌟 Premium, 💪 Physical, 🍂 Seasonal)
- **Seasonal Info**: Special notification for seasonal jobs

### 💰 Available Side Jobs (24 Total)

#### 🚀 Quick & Easy Jobs (Low Energy, Low Pay)
- **Dog Walking** - $20-40, 10 energy, 1-2 hours
- **Food Delivery** - $25-60, 15 energy, 2-4 hours  
- **Car Washing** - $25-60, 20 energy, 1-2 hours
- **Grocery Shopping** - $20-50, 15 energy, 1-3 hours

#### 🏠 Physical Jobs (Medium Energy, Medium Pay)
- **Lawn Mowing** - $30-80, 25 energy, 2-3 hours
- **House Cleaning** - $40-100, 30 energy, 3-4 hours
- **Moving Helper** - $60-120, 35 energy, 4-6 hours
- **Handyman Work** - $70-160, 30 energy, 3-5 hours

#### 🧠 Skilled Jobs (Medium Energy, High Pay)
- **Tutoring** - $50-120, 25 energy (requires 70+ Wisdom)
- **Freelance Writing** - $60-150, 20 energy (requires 65+ Wisdom, 60+ Focus)
- **Graphic Design** - $80-200, 30 energy (requires 70+ Wisdom, 70+ Focus)
- **Web Development** - $150-400, 40 energy (requires 80+ Wisdom, 75+ Focus)

#### 🎨 Creative Jobs (Variable Requirements)
- **Photography** - $100-300, 25 energy (requires 65+ Charm, 60+ Focus)
- **Music Lessons** - $40-100, 20 energy (requires 60+ Charm, 55+ Wisdom)
- **Art Commissions** - $50-200, 30 energy (requires 65+ Focus, 50+ Charm)

#### 👶 Service Jobs (Age/Skill Requirements)
- **Babysitting** - $35-75, 20 energy (requires 60+ Charm, ages 16-50)
- **Pet Sitting** - $30-80, 15 energy (requires 55+ Charm)
- **Event Staff** - $60-120, 30 energy (requires 35+ Energy)
- **Catering Helper** - $50-100, 25 energy (requires 55+ Charm)

#### 🌟 Premium Jobs (High Requirements, High Pay)
- **Business Consulting** - $200-500, 35 energy (requires 85+ Wisdom, 75+ Charm, 70+ PSP, ages 25+)
- **Construction Helper** - $80-180, 40 energy (requires 50+ Energy, ages 18-55)

#### 🍂 Seasonal Jobs (Season-Specific)
- **Snow Shoveling** - $30-80, 25 energy (Winter only)
- **Leaf Raking** - $25-70, 20 energy (Fall only)  
- **Tax Preparation** - $75-200, 30 energy (Spring only, requires 75+ Wisdom, 70+ Focus)

## 📊 Job Requirements

### Age Limits
- Most jobs: Ages 16-70
- Young jobs (Dog Walking): Ages 14-75
- Physical jobs: Ages 18-55
- Professional jobs: Ages 25-70

### Stat Requirements
- **Wisdom**: Required for tutoring, writing, design, consulting
- **Charm**: Required for babysitting, pet sitting, photography
- **Focus**: Required for writing, design, web development
- **Energy**: Required for physical/construction work
- **PSP**: Required for high-level consulting

### Seasonal Availability
- **Spring**: All jobs + Tax Preparation
- **Summer**: All regular jobs  
- **Fall**: All jobs + Leaf Raking
- **Winter**: All jobs + Snow Shoveling

## 🎯 Strategy Tips

### Early Game (Ages 24-30)
- Focus on **Dog Walking**, **Food Delivery**, **Car Washing**
- Low energy cost, accessible to everyone
- Build up energy for bigger jobs later

### Mid Game (Ages 30-40)
- Upgrade to **House Cleaning**, **Lawn Mowing**, **Tutoring**
- Better pay for moderate energy investment
- Use accumulated stats for skilled work

### Late Game (Ages 40+)
- **Business Consulting**, **Photography**, **Web Development**
- Highest paying jobs if you have the stats
- Maximize income per energy spent

### Energy Management
- **Track your energy**: Starts at 75, recovers +50/month
- **Multiple jobs per month**: Higher recovery allows 2-3 jobs monthly
- **Balance with events**: Save some energy for emergency side income

## 🔧 Console Commands (For Testing)

Open browser console (F12) and try:

```javascript
// Check side job system status
testSideJobLoading()

// Check your current energy
console.log('Current energy:', game.gameState.playerStatus.energy)

// See available jobs for your current stats
game.getAvailableSideJobs()

// Manual side job (same as button)
game.doOneTimeSideJob()
```

## 📈 Example Gameplay

```
Starting Energy: 75
Age: 24, Wisdom: 65, Charm: 60

Month 1: 
- Side Job → Dog Walking → Earn $35, Energy: 75→65
- Side Job → Food Delivery → Earn $45, Energy: 65→50
- Side Job → Car Washing → Earn $40, Energy: 50→30

Month 2: Energy recovered to 80 (30+50)
- Side Job → House Cleaning → Earn $80, Energy: 80→50
- Side Job → Tutoring → Earn $95, Energy: 50→25

Month 3: Energy recovered to 75 (25+50)
- Continue with multiple jobs per month!
```

## 🎮 Integration with Main Game

### Financial Impact
- **Income Tracking**: Side job earnings show in cash flow history
- **Category**: Labeled as "sidejob" in transaction records
- **Tax-Free**: Side job income is not subject to game's tax system

### Monthly Cycle Integration
- **Energy Recovery**: Happens during month advancement (+10 energy)
- **No Conflicts**: Can do side jobs anytime during action phase
- **Stat Growth**: Higher stats unlock better-paying jobs over time

### Game Balance
- **Supplement, Not Replace**: Side jobs provide extra income, not career replacement
- **Energy Limitation**: Prevents abuse by limiting frequency
- **Skill Gates**: Better jobs require character development

---

The side job system adds a new dimension to income generation while requiring strategic energy management! 💪💰