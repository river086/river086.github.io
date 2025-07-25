class SimLifeGame {
    static VERSION = '1.3.0'; // Update this when making changes to the game
    
    constructor() {
        this.gameState = {
            ageYears: 24,
            currentYear: 2000,
            currentMonth: 1,
            professionId: '',
            grossAnnual: 0,
            salaryFactor: 1.0,
            fixedCosts: 0,
            happiness: 100,
            negativeCashStreak: 0,
            playerStatus: {
                energy: 75,      // 體力 (1-100)
                focus: 70,       // 專注 (1-100)
                wisdom: 65,      // 智慧 (1-100)
                charm: 60,       // 魅力 (1-100)
                luck: 55,        // 幸運 (1-100)
                psp: 50          // 專業技能點 (1-100)
            },
            loans: [],
            cars: [],
            properties: [],
            portfolio: {
                cash: 500,
                bank: 0,
                stocks: {},
                bonds: {},
                crypto: {}
            },
            cashFlowHistory: [],
            pets: [],
            gameOver: false,
            gameStarted: false
        };
        
        this.professions = {};
        this.events = [];
        this.pets = {};
        this.eventCooldowns = {};
        // Stock and crypto prices will be generated after loading stock data
        
        this.init();
    }
    
    async init() {
        // Update version display
        document.getElementById('game-version').textContent = `v${SimLifeGame.VERSION}`;
        
        await this.loadProfessions();
        await this.loadEvents();
        await this.loadPets();
        await this.loadStocks();
        this.showProfessionSelection();
    }
    
    showProfessionSelection() {
        // Ensure we have professions loaded before generating cards
        if (Object.keys(this.professions).length === 0) {
            console.error('No professions loaded! Cannot show profession selection.');
            return;
        }
        
        this.generateProfessionCards();
        document.getElementById('profession-selection').style.display = 'flex';
    }
    
    selectProfession(professionId) {
        if (!this.professions[professionId]) {
            console.error(`Profession ${professionId} not found. Available professions:`, Object.keys(this.professions));
            this.log('Error: Profession data not loaded. Please refresh the page.', 'error');
            return;
        }
        
        this.gameState.professionId = professionId;
        this.initializeProfession(professionId);
        this.addStarterCar();
        this.hideProfessionSelection();
        this.startGame();
    }
    
    hideProfessionSelection() {
        document.getElementById('profession-selection').style.display = 'none';
    }
    
    generateProfessionCards() {
        const grid = document.getElementById('profession-grid');
        grid.innerHTML = '';
        
        console.log('Generating cards for professions:', Object.keys(this.professions));
        console.log('Number of professions to display:', Object.keys(this.professions).length);
        
        let cardCount = 0;
        Object.entries(this.professions).forEach(([id, profession]) => {
            cardCount++;
            const card = document.createElement('div');
            card.className = 'profession-card';
            card.onclick = () => this.selectProfession(id);
            
            const fixedCostsTotal = profession.fixedCosts.food + 390 + 20; // utilities, entertainment etc. (no housing - living with parents)
            const raisePercent = Math.round(profession.raise * 100);
            const loanYears = profession.studentLoan.termMonths / 12;
            
            let loanDisplay = '';
            if (profession.studentLoan.principal > 0) {
                loanDisplay = `<div class="profession-loan">Student Loan: $${profession.studentLoan.principal.toLocaleString()} at ${Math.round(profession.studentLoan.annualRate * 100)}% (${loanYears} years)</div>`;
            } else {
                loanDisplay = `<div class="profession-loan" style="background: #d4edda; color: #155724;">No Student Loan Required!</div>`;
            }
            
            card.innerHTML = `
                <div class="profession-title">${profession.title}</div>
                <div class="profession-salary">$${profession.salaryRange[0].toLocaleString()} - $${profession.salaryRange[1].toLocaleString()}</div>
                <div class="profession-details">
                    • Annual raises: ${raisePercent}%<br>
                    • Fixed costs: $${Math.round(fixedCostsTotal).toLocaleString()}/month<br>
                    • Starting career path
                </div>
                ${loanDisplay}
            `;
            
            grid.appendChild(card);
        });
        
        console.log('Generated', cardCount, 'profession cards');
        console.log('Grid children count:', grid.children.length);
        
        // Add scroll event listener to hide hint when user scrolls
        const scrollHint = document.getElementById('scroll-hint');
        grid.addEventListener('scroll', () => {
            if (scrollHint) {
                scrollHint.style.opacity = '0.3';
            }
        });
        
        // Hide scroll hint if all professions fit without scrolling
        setTimeout(() => {
            if (grid.scrollHeight <= grid.clientHeight && scrollHint) {
                scrollHint.style.display = 'none';
            }
        }, 100);
    }
    
    startGame() {
        this.gameState.gameStarted = true;
        this.updateUI();
        const profession = this.professions[this.gameState.professionId];
        this.log(`Welcome to Life Simulator! You are a 24-year-old ${profession.title} with $500 and a dream.`, 'info');
        this.log(`Your starting salary: $${this.gameState.grossAnnual.toFixed(0)}/year`, 'info');
        this.log('Use the "End Turn" button to advance to the next month.', 'info');
    }
    
    initializeProfession(professionId) {
        const profession = this.professions[professionId];
        
        this.gameState.grossAnnual = this.randomBetween(profession.salaryRange[0], profession.salaryRange[1]);
        this.gameState.fixedCosts = profession.fixedCosts.food + 390 + 20; // utilities, phone, internet, entertainment (Netflix, Crunchyroll) etc. (no housing - living with parents)
        
        if (profession.studentLoan) {
            const loan = {
                kind: 'student',
                balance: profession.studentLoan.principal,
                annualRate: profession.studentLoan.annualRate,
                termMonths: profession.studentLoan.termMonths,
                monthlyPayment: this.calculateMonthlyPayment(
                    profession.studentLoan.principal,
                    profession.studentLoan.annualRate,
                    profession.studentLoan.termMonths
                )
            };
            this.gameState.loans.push(loan);
        }
    }
    
    addStarterCar() {
        const starterCar = {
            id: 'starter_compact_1995',
            value: 3000,
            maintenance: 150,
            insurance: 75,
            licensePlate: 10,
            loan: null
        };
        this.gameState.cars.push(starterCar);
    }
    
    calculateMonthlyPayment(principal, annualRate, months) {
        if (principal <= 0 || months <= 0) return 0;
        const monthlyRate = annualRate / 12;
        return (principal * monthlyRate) / (1 - Math.pow(1 + monthlyRate, -months));
    }
    
    calculateNetIncome() {
        const grossMonthly = this.gameState.grossAnnual / 12;
        const federal = grossMonthly * 0.245;
        const fica = grossMonthly * 0.0765;
        const health = 200;
        return grossMonthly - federal - fica - health;
    }
    
    calculateMonthlyExpenses() {
        let totalExpenses = this.gameState.fixedCosts;
        
        // Add loan payments
        this.gameState.loans.forEach(loan => {
            totalExpenses += loan.monthlyPayment;
        });
        
        // Add car maintenance, insurance, and license fees
        this.gameState.cars.forEach(car => {
            totalExpenses += car.maintenance;
            totalExpenses += car.insurance || 0;
            totalExpenses += car.licensePlate || 0;
        });
        
        // Add property maintenance costs and property tax
        this.gameState.properties.forEach(property => {
            totalExpenses += property.maintenance;
            totalExpenses += property.propertyTax;
        });
        
        // Add pet maintenance costs
        this.gameState.pets.forEach(pet => {
            totalExpenses += pet.data.monthlyCost;
        });
        
        return totalExpenses;
    }
    
    calculateTotalHappiness() {
        let totalHappiness = this.gameState.happiness;
        
        // Add pet happiness bonuses
        this.gameState.pets.forEach(pet => {
            totalHappiness += pet.data.happinessBonus;
        });
        
        return Math.min(1000, totalHappiness);
    }

    calculateNetWorth() {
        let netWorth = this.gameState.portfolio.cash + this.gameState.portfolio.bank;
        
        // Add car values
        this.gameState.cars.forEach(car => {
            netWorth += car.value;
            if (car.loan) netWorth -= car.loan.balance;
        });
        
        // Add property values
        this.gameState.properties.forEach(property => {
            netWorth += property.value;
            if (property.loan) netWorth -= property.loan.balance;
        });
        
        // Add investments (simplified)
        Object.entries(this.gameState.portfolio.stocks).forEach(([symbol, shares]) => {
            const price = this.getStockPrice(symbol);
            if (price !== undefined) {
                netWorth += shares * price;
            }
        });
        
        Object.entries(this.gameState.portfolio.crypto).forEach(([symbol, amount]) => {
            const price = this.getCryptoPrice(symbol);
            netWorth += amount * price;
        });
        
        // Subtract other loan balances
        this.gameState.loans.forEach(loan => {
            netWorth -= loan.balance;
        });
        
        return netWorth;
    }
    
    processMonthlyFinances() {
        const netIncome = this.calculateNetIncome();
        let totalExpenses = this.gameState.fixedCosts;
        
        // Add loan payments
        this.gameState.loans.forEach(loan => {
            totalExpenses += loan.monthlyPayment;
        });
        
        // Add car maintenance
        this.gameState.cars.forEach(car => {
            totalExpenses += car.maintenance;
        });
        
        // Add property costs
        this.gameState.properties.forEach(property => {
            totalExpenses += property.maintenance;
        });
        
        const netCashFlow = netIncome - totalExpenses;
        this.gameState.portfolio.cash += netCashFlow;
        
        // Record monthly income and expenses
        this.recordCashFlow('income', netIncome, 'Monthly Salary', 'salary');
        this.recordCashFlow('expense', totalExpenses, 'Monthly Expenses', 'living');
        
        this.log(`Monthly income: $${netIncome.toFixed(0)}, Expenses: $${totalExpenses.toFixed(0)}, Net: $${netCashFlow.toFixed(0)}`, 'info');
        
        // Update loan balances
        this.gameState.loans = this.gameState.loans.filter(loan => {
            loan.balance -= (loan.monthlyPayment - (loan.balance * loan.annualRate / 12));
            return loan.balance > 0;
        });
        
        // Check for negative cash streak
        if (this.gameState.portfolio.cash < 0) {
            this.gameState.negativeCashStreak++;
            this.log(`Warning: Negative cash for ${this.gameState.negativeCashStreak} months`, 'warning');
            
            if (this.gameState.negativeCashStreak >= 6) {
                this.endGame('Bankruptcy: Cash below $0 for 6 consecutive months');
                return;
            }
        } else {
            this.gameState.negativeCashStreak = 0;
        }
    }
    
    checkPsychiatristVisit() {
        if (this.gameState.happiness < 10) {
            const cost = 75;
            this.gameState.portfolio.cash -= cost;
            this.gameState.happiness += 10;
            
            // Ensure happiness doesn't exceed 1000
            this.gameState.happiness = Math.min(1000, this.gameState.happiness);
            
            this.recordCashFlow('expense', cost, 'See a psychiatrist', 'health');
            this.log(`Mental health visit: Happiness too low. Visited psychiatrist ($${cost}), happiness increased by 10.`, 'warning');
        }
    }
    
    processEvent() {
        const eligibleEvents = this.events.filter(event => {
            return !this.eventCooldowns[event.id] || this.eventCooldowns[event.id] <= 0;
        });
        
        const totalWeight = eligibleEvents.reduce((sum, event) => sum + event.weight, 0);
        let random = Math.random() * totalWeight;
        
        let selectedEvent = null;
        for (const event of eligibleEvents) {
            random -= event.weight;
            if (random <= 0) {
                selectedEvent = event;
                break;
            }
        }
        
        if (selectedEvent && selectedEvent.id !== 'no_event') {
            const cost = this.randomBetween(selectedEvent.costRange[0], selectedEvent.costRange[1]);
            this.gameState.portfolio.cash -= cost;
            
            // Record event cash flow
            if (cost > 0) {
                this.recordCashFlow('expense', cost, selectedEvent.description, 'event');
            } else if (cost < 0) {
                this.recordCashFlow('income', Math.abs(cost), selectedEvent.description, 'event');
            }
            
            if (selectedEvent.effects.happiness) {
                this.gameState.happiness = Math.max(0, Math.min(1000, 
                    this.gameState.happiness + selectedEvent.effects.happiness));
            }
            
            this.eventCooldowns[selectedEvent.id] = selectedEvent.cooldown;
            this.log(`Event: ${selectedEvent.description} (Cost: $${cost})`, cost > 0 ? 'warning' : 'success');
            
            // Show event popup
            this.showEventPopup(selectedEvent, cost);
        }
        
        // Decrease all cooldowns
        Object.keys(this.eventCooldowns).forEach(eventId => {
            if (this.eventCooldowns[eventId] > 0) {
                this.eventCooldowns[eventId]--;
            }
        });
    }
    
    advanceMonth() {
        this.gameState.currentMonth++;
        
        // Age pets and check for natural death
        this.gameState.pets = this.gameState.pets.filter(pet => {
            pet.ageMonths++;
            
            if (pet.ageMonths >= pet.data.lifespan) {
                this.log(`💔 Your ${pet.data.name} has passed away peacefully after ${pet.ageMonths} months of companionship.`, 'warning');
                this.gameState.happiness = Math.max(0, this.gameState.happiness - 20);
                return false; // Remove pet
            }
            
            // Pet happiness may decline with age
            if (pet.ageMonths > pet.data.lifespan * 0.8) {
                pet.happiness = Math.max(50, pet.happiness - 1);
            }
            
            return true; // Keep pet
        });
        
        if (this.gameState.currentMonth > 12) {
            this.gameState.currentMonth = 1;
            this.gameState.currentYear++;
            this.gameState.ageYears++;
            
            // Annual salary increase
            const profession = this.professions[this.gameState.professionId];
            this.gameState.grossAnnual *= (1 + profession.raise);
            this.log(`Annual raise! New salary: $${this.gameState.grossAnnual.toFixed(0)}`, 'success');
        }
        
        // Check end of game
        if (this.gameState.currentYear > 2025 || this.gameState.ageYears >= 49) {
            this.endGame('Congratulations! You survived 25 years in Vegas!');
            return;
        }
    }
    
    
    handleBuy(parts) {
        if (parts.length < 3) throw new Error('Usage: buy SYMBOL AMOUNT or buy pet PET_TYPE');
        
        // Check if buying a pet
        if (parts[1].toLowerCase() === 'pet') {
            return this.handlePetPurchase(parts[2].toLowerCase());
        }
        
        const symbol = parts[1].toUpperCase();
        const amount = parseFloat(parts[2]);
        
        if (this.isCrypto(symbol)) {
            const price = this.getCryptoPrice(symbol);
            const cost = amount * price * 1.005; // 0.5% fee
            
            if (this.gameState.portfolio.cash < cost) {
                throw new Error('Insufficient cash');
            }
            
            this.gameState.portfolio.cash -= cost;
            this.gameState.portfolio.crypto[symbol] = (this.gameState.portfolio.crypto[symbol] || 0) + amount;
            this.recordCashFlow('expense', cost, `Buy ${amount} ${symbol}`, 'investment');
            this.log(`Bought ${amount} ${symbol} for $${cost.toFixed(2)}`, 'success');
        } else {
            const price = this.getStockPrice(symbol);
            const cost = amount * price;
            
            if (this.gameState.portfolio.cash < cost) {
                throw new Error('Insufficient cash');
            }
            
            this.gameState.portfolio.cash -= cost;
            this.gameState.portfolio.stocks[symbol] = (this.gameState.portfolio.stocks[symbol] || 0) + amount;
            this.recordCashFlow('expense', cost, `Buy ${amount} shares ${symbol}`, 'investment');
            this.log(`Bought ${amount} shares of ${symbol} for $${cost.toFixed(2)}`, 'success');
        }
    }
    
    handlePetPurchase(petType) {
        const pet = this.pets[petType];
        if (!pet) {
            throw new Error(`Pet type "${petType}" not found. Available pets: ${Object.keys(this.pets).join(', ')}`);
        }
        
        // Check requirements
        const req = pet.requirements;
        if (this.gameState.ageYears < req.minAge) {
            throw new Error(`You must be at least ${req.minAge} years old to buy a ${pet.name}`);
        }
        if (this.gameState.ageYears > req.maxAge) {
            throw new Error(`You are too old to buy a ${pet.name} (max age: ${req.maxAge})`);
        }
        if (this.gameState.portfolio.cash < req.minCash) {
            throw new Error(`You need at least $${req.minCash} cash to buy a ${pet.name}`);
        }
        if (this.gameState.portfolio.cash < pet.purchaseCost) {
            throw new Error(`Insufficient cash. ${pet.name} costs $${pet.purchaseCost}, you have $${this.gameState.portfolio.cash.toFixed(2)}`);
        }
        
        // Check player status requirements
        if (req.minWisdom && this.gameState.playerStatus.wisdom < req.minWisdom) {
            throw new Error(`You need at least ${req.minWisdom} wisdom to care for a ${pet.name}`);
        }
        if (req.minCharm && this.gameState.playerStatus.charm < req.minCharm) {
            throw new Error(`You need at least ${req.minCharm} charm to bond with a ${pet.name}`);
        }
        
        // Calculate net worth if required
        if (req.minNetWorth) {
            const netWorth = this.calculateNetWorth();
            if (netWorth < req.minNetWorth) {
                throw new Error(`You need at least $${req.minNetWorth} net worth to afford a ${pet.name}`);
            }
        }
        
        // Create new pet instance
        const newPet = {
            id: `${petType}_${Date.now()}`,
            type: petType,
            name: pet.name,
            ageMonths: 0,
            purchaseMonth: this.gameState.currentMonth,
            purchaseYear: this.gameState.currentYear,
            happiness: 100,
            data: pet
        };
        
        // Purchase the pet
        this.gameState.portfolio.cash -= pet.purchaseCost;
        this.gameState.pets.push(newPet);
        
        // Apply initial status bonuses
        if (pet.effects.playerStatus) {
            Object.entries(pet.effects.playerStatus).forEach(([stat, bonus]) => {
                if (bonus > 0) {
                    this.gameState.playerStatus[stat] = Math.min(100, this.gameState.playerStatus[stat] + bonus);
                }
            });
        }
        
        // Add to cash flow
        this.recordCashFlow('expense', pet.purchaseCost, `Bought ${pet.name}`, 'pet');
        
        this.log(`🐾 Bought ${pet.name} for $${pet.purchaseCost}! Monthly cost: $${pet.monthlyCost}`, 'success');
        this.log(`Pet happiness bonus: +${pet.happinessBonus}`, 'info');
        
        this.updateUI();
    }
    
    handlePetSale(petId) {
        const petIndex = this.gameState.pets.findIndex(pet => pet.id === petId);
        if (petIndex === -1) {
            const availablePets = this.gameState.pets.map(p => p.id).join(', ');
            throw new Error(`Pet with ID "${petId}" not found. Available pets: ${availablePets}`);
        }
        
        const pet = this.gameState.pets[petIndex];
        
        // Calculate sale price (pets lose value over time)
        const ageRatio = pet.ageMonths / pet.data.lifespan;
        const condition = ageRatio < 0.5 ? 0.6 : (ageRatio < 0.8 ? 0.4 : 0.2);
        const salePrice = Math.floor(pet.data.purchaseCost * condition);
        
        // Remove pet
        this.gameState.pets.splice(petIndex, 1);
        
        // Add money back
        this.gameState.portfolio.cash += salePrice;
        
        // Reduce happiness for selling pet
        this.gameState.happiness = Math.max(0, this.gameState.happiness - pet.data.happinessBonus);
        
        // Record transaction
        this.recordCashFlow('income', salePrice, `Sold ${pet.data.name}`, 'pet');
        
        this.log(`💔 Sold ${pet.data.name} for $${salePrice} (${pet.ageMonths} months old)`, 'warning');
        this.log(`Lost happiness bonus: -${pet.data.happinessBonus}`, 'info');
        
        this.updateUI();
    }

    handleSell(parts) {
        if (parts.length < 3) throw new Error('Usage: sell SYMBOL AMOUNT or sell pet PET_ID');
        
        // Check if selling a pet
        if (parts[1].toLowerCase() === 'pet') {
            return this.handlePetSale(parts[2]);
        }
        
        const symbol = parts[1].toUpperCase();
        const amount = parseFloat(parts[2]);
        
        if (this.isCrypto(symbol)) {
            if (!this.gameState.portfolio.crypto[symbol] || this.gameState.portfolio.crypto[symbol] < amount) {
                throw new Error('Insufficient crypto holdings');
            }
            
            const price = this.getCryptoPrice(symbol);
            const proceeds = amount * price * 0.995; // 0.5% fee
            
            this.gameState.portfolio.cash += proceeds;
            this.gameState.portfolio.crypto[symbol] -= amount;
            this.recordCashFlow('income', proceeds, `Sell ${amount} ${symbol}`, 'investment');
            this.log(`Sold ${amount} ${symbol} for $${proceeds.toFixed(2)}`, 'success');
        } else {
            if (!this.gameState.portfolio.stocks[symbol] || this.gameState.portfolio.stocks[symbol] < amount) {
                throw new Error('Insufficient stock holdings');
            }
            
            const price = this.getStockPrice(symbol);
            const proceeds = amount * price;
            
            this.gameState.portfolio.cash += proceeds;
            this.gameState.portfolio.stocks[symbol] -= amount;
            this.recordCashFlow('income', proceeds, `Sell ${amount} shares ${symbol}`, 'investment');
            this.log(`Sold ${amount} shares of ${symbol} for $${proceeds.toFixed(2)}`, 'success');
        }
    }
    
    handleDeposit(parts) {
        if (parts.length < 2) throw new Error('Usage: deposit AMOUNT');
        
        const amount = parseFloat(parts[1]);
        if (this.gameState.portfolio.cash < amount) {
            throw new Error('Insufficient cash');
        }
        
        this.gameState.portfolio.cash -= amount;
        this.gameState.portfolio.bank += amount;
        this.recordCashFlow('expense', amount, `Bank Deposit`, 'banking');
        this.log(`Deposited $${amount} to bank`, 'success');
    }
    
    handleWithdraw(parts) {
        if (parts.length < 2) throw new Error('Usage: withdraw AMOUNT');
        
        const amount = parseFloat(parts[1]);
        if (this.gameState.portfolio.bank < amount) {
            throw new Error('Insufficient bank balance');
        }
        
        this.gameState.portfolio.bank -= amount;
        this.gameState.portfolio.cash += amount;
        this.recordCashFlow('income', amount, `Bank Withdrawal`, 'banking');
        this.log(`Withdrew $${amount} from bank`, 'success');
    }
    
    showPortfolio() {
        let portfolioText = 'PORTFOLIO:\n';
        portfolioText += `Cash: $${this.gameState.portfolio.cash.toFixed(2)}\n`;
        portfolioText += `Bank: $${this.gameState.portfolio.bank.toFixed(2)}\n`;
        
        if (Object.keys(this.gameState.portfolio.stocks).length > 0) {
            portfolioText += 'STOCKS:\n';
            Object.entries(this.gameState.portfolio.stocks).forEach(([symbol, shares]) => {
                if (shares > 0) {
                    const price = this.getStockPrice(symbol);
                    if (price !== undefined) {
                        portfolioText += `  ${symbol}: ${shares} shares @ $${price.toFixed(2)} = $${(shares * price).toFixed(2)}\n`;
                    }
                }
            });
        }
        
        if (Object.keys(this.gameState.portfolio.crypto).length > 0) {
            portfolioText += 'CRYPTO:\n';
            Object.entries(this.gameState.portfolio.crypto).forEach(([symbol, amount]) => {
                if (amount > 0) {
                    const price = this.getCryptoPrice(symbol);
                    portfolioText += `  ${symbol}: ${amount} @ $${price.toFixed(2)} = $${(amount * price).toFixed(2)}\n`;
                }
            });
        }
        
        portfolioText += `\nNet Worth: $${this.calculateNetWorth().toFixed(2)}`;
        this.log(portfolioText, 'info');
    }
    
    showCashFlowHistory() {
        if (this.gameState.cashFlowHistory.length === 0) {
            this.log('No cash flow history available yet.', 'info');
            return;
        }
        
        let historyText = '💰 CASH FLOW HISTORY:\n';
        historyText += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
        
        this.gameState.cashFlowHistory.forEach((record, index) => {
            const typeIcon = record.type === 'income' ? '📈' : '📉';
            const amountSign = record.type === 'income' ? '+' : '-';
            const amountColor = record.type === 'income' ? 'success' : 'warning';
            
            historyText += `${typeIcon} ${record.date} | ${amountSign}$${record.amount.toFixed(0)} | ${record.description}\n`;
            historyText += `   Category: ${record.category} | Balance: $${record.balance.toFixed(0)}\n`;
            
            if (index < this.gameState.cashFlowHistory.length - 1) {
                historyText += '────────────────────────────────────────────────────────────────\n';
            }
        });
        
        historyText += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
        this.log(historyText, 'info');
    }
    
    updatePlayerStatusModal() {
        const statusContainer = document.getElementById('player-status-content');
        statusContainer.innerHTML = '';
        
        const statusData = [
            { key: 'energy', label: 'Energy', icon: '⚡', color: '#ff6b35' },
            { key: 'focus', label: 'Focus', icon: '🎯', color: '#4ecdc4' },
            { key: 'wisdom', label: 'Wisdom', icon: '🧠', color: '#6c5ce7' },
            { key: 'charm', label: 'Charm', icon: '✨', color: '#fd79a8' },
            { key: 'luck', label: 'Luck', icon: '🍀', color: '#00b894' },
            { key: 'psp', label: 'Professional Skills', icon: '💼', color: '#fdcb6e' }
        ];
        
        statusData.forEach(stat => {
            const value = this.gameState.playerStatus[stat.key];
            const statusCard = document.createElement('div');
            statusCard.style.background = 'white';
            statusCard.style.border = '2px solid #e9ecef';
            statusCard.style.borderRadius = '15px';
            statusCard.style.padding = '25px';
            statusCard.style.textAlign = 'center';
            statusCard.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
            statusCard.style.minHeight = '200px';
            
            // Create progress bar
            const progressPercent = Math.max(0, Math.min(100, value));
            
            statusCard.innerHTML = `
                <div style="font-size: 2.5em; margin-bottom: 12px;">${stat.icon}</div>
                <h3 style="margin: 0 0 18px 0; color: #333; font-size: 1.2em; font-weight: bold;">${stat.label}</h3>
                <div style="background: #f1f3f4; border-radius: 25px; height: 25px; margin-bottom: 15px; overflow: hidden; border: 1px solid #e0e0e0;">
                    <div style="background: ${stat.color}; height: 100%; width: ${progressPercent}%; border-radius: 25px; transition: width 0.3s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 0.8em;">
                        ${progressPercent >= 20 ? `${value}%` : ''}
                    </div>
                </div>
                <div style="font-size: 1.6em; font-weight: bold; color: ${stat.color}; margin-bottom: 8px;">${value}/100</div>
                <div style="font-size: 0.85em; color: #666; line-height: 1.4; padding: 8px; background: #f8f9fa; border-radius: 8px;">
                    ${this.getStatusDescription(stat.key, value)}
                </div>
            `;
            
            statusContainer.appendChild(statusCard);
        });
    }
    
    getStatusDescription(statKey, value) {
        const descriptions = {
            energy: {
                high: 'Full of energy and ready for anything!',
                medium: 'Feeling decent, could use some rest.',
                low: 'Exhausted and need to recharge.'
            },
            focus: {
                high: 'Crystal clear concentration.',
                medium: 'Reasonably focused on tasks.',
                low: 'Struggling to concentrate.'
            },
            wisdom: {
                high: 'Making wise decisions consistently.',
                medium: 'Learning from experiences.',
                low: 'Need to gain more knowledge.'
            },
            charm: {
                high: 'Naturally charismatic and likeable.',
                medium: 'Getting along well with others.',
                low: 'Working on social skills.'
            },
            luck: {
                high: 'Fortune favors you lately.',
                medium: 'Things are going reasonably well.',
                low: 'Could use a lucky break.'
            },
            psp: {
                high: 'Expert-level professional skills.',
                medium: 'Solid professional competence.',
                low: 'Building professional expertise.'
            }
        };
        
        const stat = descriptions[statKey];
        if (value >= 75) return stat.high;
        if (value >= 40) return stat.medium;
        return stat.low;
    }
    
    updateCashFlowModal() {
        const container = document.getElementById('cashflow-history-list');
        container.innerHTML = '';
        
        if (this.gameState.cashFlowHistory.length === 0) {
            container.innerHTML = '<div style="text-align: center; color: #666; padding: 20px;">No cash flow history available yet.</div>';
            return;
        }
        
        this.gameState.cashFlowHistory.forEach((record, index) => {
            const typeIcon = record.type === 'income' ? '📈' : '📉';
            const amountSign = record.type === 'income' ? '+' : '-';
            const amountColor = record.type === 'income' ? '#28a745' : '#dc3545';
            
            const recordDiv = document.createElement('div');
            recordDiv.className = 'expense-item';
            recordDiv.style.marginBottom = '10px';
            recordDiv.style.padding = '10px';
            recordDiv.style.border = '1px solid #ddd';
            recordDiv.style.borderRadius = '5px';
            recordDiv.style.backgroundColor = record.type === 'income' ? '#f8fff8' : '#fff8f8';
            
            recordDiv.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div style="font-weight: bold;">${typeIcon} ${record.description}</div>
                    <div style="color: ${amountColor}; font-weight: bold;">${amountSign}$${record.amount.toFixed(0)}</div>
                </div>
                <div style="font-size: 0.9em; color: #666; margin-top: 5px;">
                    📅 ${record.date} | 📂 ${record.category} | 💰 Balance: $${record.balance.toFixed(0)}
                </div>
            `;
            
            container.appendChild(recordDiv);
        });
    }
    
    updateBankModal() {
        document.getElementById('bank-cash-display').textContent = `$${this.gameState.portfolio.cash.toFixed(2)}`;
        document.getElementById('bank-balance-display').textContent = `$${this.gameState.portfolio.bank.toFixed(2)}`;
    }
    
    updateStockTradingModal() {
        document.getElementById('stock-cash-display').textContent = this.gameState.portfolio.cash.toFixed(0);
        
        const container = document.getElementById('stock-trading-list');
        container.innerHTML = '';
        
        const stockSymbols = this.getStockSymbols();
        
        stockSymbols.forEach(symbol => {
            const price = this.getStockPrice(symbol);
            if (price === undefined) return; // Skip stocks without prices
            const holdings = this.gameState.portfolio.stocks[symbol] || 0;
            
            const stockDiv = document.createElement('div');
            stockDiv.style.marginBottom = '15px';
            stockDiv.style.padding = '15px';
            stockDiv.style.border = '1px solid #ddd';
            stockDiv.style.borderRadius = '5px';
            stockDiv.style.backgroundColor = '#f8f9fa';
            
            // Get price history for the last 12 months
            const priceHistory = this.getStockPriceHistory(symbol, 12);
            const priceChange = priceHistory.length >= 2 ? ((price - priceHistory[priceHistory.length - 2].price) / priceHistory[priceHistory.length - 2].price * 100) : 0;
            const changeColor = priceChange >= 0 ? '#28a745' : '#dc3545';
            const changeSymbol = priceChange >= 0 ? '+' : '';
            
            const stockInfo = this.stocksData[symbol] || { name: symbol };
            stockDiv.innerHTML = `
                <div style="display: flex; justify-content: between; align-items: center; margin-bottom: 10px;">
                    <div>
                        <h4 style="margin: 0; color: #007bff;">${symbol} - ${stockInfo.name}</h4>
                        <div style="font-size: 0.9em; color: #666;">Price: $${price.toFixed(2)} | Holdings: ${holdings} shares</div>
                        <div style="font-size: 0.9em; color: #666;">Value: $${(holdings * price).toFixed(2)} | Sector: ${stockInfo.sector || 'N/A'}</div>
                        <div style="font-size: 0.85em; color: ${changeColor}; font-weight: bold;">${changeSymbol}${priceChange.toFixed(1)}% this month</div>
                    </div>
                </div>
                
                <div style="background: #f8f9fa; padding: 10px; border-radius: 3px; margin-bottom: 10px;">
                    <div style="font-size: 0.9em; font-weight: bold; margin-bottom: 5px;">📈 12-Month Price History</div>
                    <div style="display: flex; justify-content: space-between; font-size: 0.8em; color: #666;">
                        ${priceHistory.slice(-6).map(data => `
                            <div style="text-align: center;">
                                <div>${data.date}</div>
                                <div style="font-weight: bold;">$${data.price.toFixed(2)}</div>
                            </div>
                        `).join('')}
                    </div>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                    <div>
                        <label style="display: block; margin-bottom: 5px; font-weight: bold; color: #28a745;">📈 Buy Shares</label>
                        <div style="display: flex; gap: 5px;">
                            <input type="number" id="buy-${symbol}-amount" placeholder="Shares" 
                                   style="flex: 1; padding: 5px; border: 1px solid #ddd; border-radius: 3px;">
                            <button class="btn" onclick="handleStockBuy('${symbol}')" 
                                    style="background: #28a745; padding: 5px 10px;">Buy</button>
                        </div>
                    </div>
                    
                    <div>
                        <label style="display: block; margin-bottom: 5px; font-weight: bold; color: #dc3545;">📉 Sell Shares</label>
                        <div style="display: flex; gap: 5px;">
                            <input type="number" id="sell-${symbol}-amount" placeholder="Shares" 
                                   style="flex: 1; padding: 5px; border: 1px solid #ddd; border-radius: 3px;">
                            <button class="btn" onclick="handleStockSell('${symbol}')" 
                                    style="background: #dc3545; padding: 5px 10px;">Sell</button>
                        </div>
                    </div>
                </div>
            `;
            
            container.appendChild(stockDiv);
        });
    }
    
    updateCryptoTradingModal() {
        document.getElementById('crypto-cash-display').textContent = this.gameState.portfolio.cash.toFixed(0);
        
        const container = document.getElementById('crypto-trading-list');
        container.innerHTML = '';
        
        const cryptoSymbols = ['BTC', 'ETH', 'LTC', 'USDC'];
        const cryptoNames = {
            'BTC': 'Bitcoin',
            'ETH': 'Ethereum', 
            'LTC': 'Litecoin',
            'USDC': 'USD Coin'
        };
        
        cryptoSymbols.forEach(symbol => {
            const price = this.getCryptoPrice(symbol);
            const holdings = this.gameState.portfolio.crypto[symbol] || 0;
            
            const cryptoDiv = document.createElement('div');
            cryptoDiv.style.marginBottom = '15px';
            cryptoDiv.style.padding = '15px';
            cryptoDiv.style.border = '1px solid #ddd';
            cryptoDiv.style.borderRadius = '5px';
            cryptoDiv.style.backgroundColor = '#fff8f0';
            
            cryptoDiv.innerHTML = `
                <div style="display: flex; justify-content: between; align-items: center; margin-bottom: 10px;">
                    <div>
                        <h4 style="margin: 0; color: #ff6b35;">${symbol} - ${cryptoNames[symbol]}</h4>
                        <div style="font-size: 0.9em; color: #666;">Price: $${price.toFixed(4)} | Holdings: ${holdings.toFixed(4)} ${symbol}</div>
                        <div style="font-size: 0.9em; color: #666;">Value: $${(holdings * price).toFixed(2)}</div>
                    </div>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                    <div>
                        <label style="display: block; margin-bottom: 5px; font-weight: bold; color: #28a745;">📈 Buy ${symbol}</label>
                        <div style="display: flex; gap: 5px;">
                            <input type="number" id="buy-${symbol}-crypto-amount" placeholder="${symbol} Amount" step="0.0001"
                                   style="flex: 1; padding: 5px; border: 1px solid #ddd; border-radius: 3px;">
                            <button class="btn" onclick="handleCryptoBuy('${symbol}')" 
                                    style="background: #28a745; padding: 5px 10px;">Buy</button>
                        </div>
                        <div style="font-size: 0.8em; color: #666; margin-top: 2px;">Fee: 0.5%</div>
                    </div>
                    
                    <div>
                        <label style="display: block; margin-bottom: 5px; font-weight: bold; color: #dc3545;">📉 Sell ${symbol}</label>
                        <div style="display: flex; gap: 5px;">
                            <input type="number" id="sell-${symbol}-crypto-amount" placeholder="${symbol} Amount" step="0.0001"
                                   style="flex: 1; padding: 5px; border: 1px solid #ddd; border-radius: 3px;">
                            <button class="btn" onclick="handleCryptoSell('${symbol}')" 
                                    style="background: #dc3545; padding: 5px 10px;">Sell</button>
                        </div>
                        <div style="font-size: 0.8em; color: #666; margin-top: 2px;">Fee: 0.5%</div>
                    </div>
                </div>
            `;
            
            container.appendChild(cryptoDiv);
        });
    }
    
    updateVehicleModal() {
        document.getElementById('vehicle-cash-display').textContent = this.gameState.portfolio.cash.toFixed(0);
        
        // Update owned vehicles
        const ownedContainer = document.getElementById('owned-vehicles-list');
        ownedContainer.innerHTML = '';
        
        if (this.gameState.cars.length === 0) {
            ownedContainer.innerHTML = '<div style="color: #666; text-align: center; padding: 20px;">No vehicles owned</div>';
        } else {
            this.gameState.cars.forEach(car => {
                const vehicleInfo = this.getAvailableVehicles().find(v => v.id === car.id) || {name: car.id, emoji: '🚗'};
                const div = document.createElement('div');
                div.style.marginBottom = '10px';
                div.style.padding = '10px';
                div.style.border = '1px solid #ddd';
                div.style.borderRadius = '5px';
                div.style.backgroundColor = '#fff';
                
                const loanInfo = car.loan ? ` | Loan: $${car.loan.monthlyPayment.toFixed(0)}/mo` : '';
                const insuranceInfo = car.insurance ? ` | Insurance: $${car.insurance}/mo` : '';
                const licensePlateInfo = car.licensePlate ? ` | License: $${car.licensePlate}/mo` : '';
                div.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>${vehicleInfo.emoji} ${vehicleInfo.name}</strong>
                            <div style="font-size: 0.9em; color: #666;">
                                Value: $${car.value.toFixed(0)} | Maintenance: $${car.maintenance}/mo${insuranceInfo}${licensePlateInfo}${loanInfo}
                            </div>
                        </div>
                        <button class="btn" onclick="handleVehicleSell('${car.id}')" 
                                style="background: ${this.gameState.cars.length === 1 ? '#999' : '#dc3545'}; padding: 5px 10px;" 
                                ${this.gameState.cars.length === 1 ? 'disabled title="Cannot sell your only vehicle"' : ''}>Sell</button>
                    </div>
                `;
                
                ownedContainer.appendChild(div);
            });
        }
        
        // Update available vehicles
        const availableContainer = document.getElementById('available-vehicles-list');
        availableContainer.innerHTML = '';
        
        this.getAvailableVehicles().forEach(vehicle => {
            const div = document.createElement('div');
            div.style.marginBottom = '10px';
            div.style.padding = '10px';
            div.style.border = '1px solid #ddd';
            div.style.borderRadius = '5px';
            div.style.backgroundColor = '#f8f9fa';
            
            div.innerHTML = `
                <div>
                    <strong>${vehicle.emoji} ${vehicle.name}</strong>
                    <div style="font-size: 0.9em; color: #666; margin: 5px 0;">
                        Price: $${vehicle.price.toLocaleString()} | Maintenance: $${vehicle.maintenance}/mo | Insurance: $${vehicle.insurance}/mo | License: $${vehicle.licensePlate}/mo
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div style="font-size: 0.85em; color: #666;">
                            ${vehicle.description}
                        </div>
                        <div style="display: flex; gap: 5px;">
                            <button class="btn" onclick="handleVehicleBuy('${vehicle.id}')" 
                                    style="background: #28a745; padding: 5px 8px; font-size: 0.85em;">Cash</button>
                            <button class="btn" onclick="handleVehicleFinance('${vehicle.id}')" 
                                    style="background: #007bff; padding: 5px 8px; font-size: 0.85em;">Finance</button>
                        </div>
                    </div>
                </div>
            `;
            
            availableContainer.appendChild(div);
        });
    }
    
    getAvailableVehicles() {
        return [
            {
                id: 'honda_civic_2020',
                name: '2020 Honda Civic',
                emoji: '🚗',
                price: 22000,
                maintenance: 180,
                insurance: 85,
                licensePlate: 12,
                description: 'Reliable compact car, great for daily commuting'
            },
            {
                id: 'toyota_camry_2021',
                name: '2021 Toyota Camry',
                emoji: '🚙',
                price: 28000,
                maintenance: 200,
                insurance: 95,
                licensePlate: 15,
                description: 'Mid-size sedan with excellent fuel economy'
            },
            {
                id: 'bmw_3_series_2022',
                name: '2022 BMW 3 Series',
                emoji: '🏎️',
                price: 45000,
                maintenance: 350,
                insurance: 180,
                licensePlate: 25,
                description: 'Luxury sports sedan with premium features'
            },
            {
                id: 'ford_f150_2021',
                name: '2021 Ford F-150',
                emoji: '🚚',
                price: 35000,
                maintenance: 280,
                insurance: 140,
                licensePlate: 20,
                description: 'Full-size pickup truck, perfect for work'
            },
            {
                id: 'tesla_model_3_2023',
                name: '2023 Tesla Model 3',
                emoji: '⚡',
                price: 42000,
                maintenance: 120,
                insurance: 160,
                licensePlate: 22,
                description: 'Electric sedan with autopilot features'
            },
            {
                id: 'jeep_wrangler_2021',
                name: '2021 Jeep Wrangler',
                emoji: '🚐',
                price: 38000,
                maintenance: 320,
                insurance: 155,
                licensePlate: 18,
                description: 'Off-road capable SUV for adventures'
            }
        ];
    }
    
    buyVehicle(vehicleId) {
        const vehicle = this.getAvailableVehicles().find(v => v.id === vehicleId);
        if (!vehicle) {
            throw new Error('Vehicle not found');
        }
        
        if (this.gameState.portfolio.cash < vehicle.price) {
            throw new Error('Insufficient cash to buy this vehicle');
        }
        
        // Check if player already owns this vehicle
        if (this.gameState.cars.find(car => car.id === vehicleId)) {
            throw new Error('You already own this vehicle');
        }
        
        this.gameState.portfolio.cash -= vehicle.price;
        this.gameState.cars.push({
            id: vehicle.id,
            value: vehicle.price,
            maintenance: vehicle.maintenance,
            insurance: vehicle.insurance,
            licensePlate: vehicle.licensePlate,
            loan: null
        });
        
        this.recordCashFlow('expense', vehicle.price, `Buy ${vehicle.name}`, 'vehicle');
        this.log(`Purchased ${vehicle.name} for $${vehicle.price.toLocaleString()}`, 'success');
    }
    
    sellVehicle(vehicleId) {
        const carIndex = this.gameState.cars.findIndex(car => car.id === vehicleId);
        if (carIndex === -1) {
            throw new Error('Vehicle not found in your garage');
        }
        
        // Don't allow selling any vehicle if it's the only one
        if (this.gameState.cars.length === 1) {
            throw new Error('Cannot sell your only vehicle. You need transportation to work!');
        }
        
        const car = this.gameState.cars[carIndex];
        const vehicleInfo = this.getAvailableVehicles().find(v => v.id === vehicleId);
        const sellPrice = Math.floor(car.value * 0.7); // Sell for 70% of current value
        
        this.gameState.portfolio.cash += sellPrice;
        this.gameState.cars.splice(carIndex, 1);
        
        this.recordCashFlow('income', sellPrice, `Sell ${vehicleInfo?.name || vehicleId}`, 'vehicle');
        this.log(`Sold ${vehicleInfo?.name || vehicleId} for $${sellPrice.toLocaleString()}`, 'success');
    }
    
    financeVehicle(vehicleId) {
        const vehicle = this.getAvailableVehicles().find(v => v.id === vehicleId);
        if (!vehicle) {
            throw new Error('Vehicle not found');
        }
        
        // Check if player already owns this vehicle
        if (this.gameState.cars.find(car => car.id === vehicleId)) {
            throw new Error('You already own this vehicle');
        }
        
        // Calculate financing terms
        const downPayment = Math.floor(vehicle.price * 0.2); // 20% down payment
        const loanAmount = vehicle.price - downPayment;
        const annualRate = 0.065; // 6.5% APR for auto loans
        const termMonths = 60; // 5 years
        const monthlyPayment = this.calculateMonthlyPayment(loanAmount, annualRate, termMonths);
        
        if (this.gameState.portfolio.cash < downPayment) {
            throw new Error(`Insufficient cash for down payment. Need $${downPayment.toLocaleString()} (20%)`);
        }
        
        // Process the financing
        this.gameState.portfolio.cash -= downPayment;
        
        // Add the vehicle with loan
        this.gameState.cars.push({
            id: vehicle.id,
            value: vehicle.price,
            maintenance: vehicle.maintenance,
            insurance: vehicle.insurance,
            licensePlate: vehicle.licensePlate,
            loan: {
                balance: loanAmount,
                monthlyPayment: monthlyPayment,
                annualRate: annualRate,
                termMonths: termMonths
            }
        });
        
        // Add loan to the loans array
        this.gameState.loans.push({
            kind: 'vehicle',
            balance: loanAmount,
            annualRate: annualRate,
            termMonths: termMonths,
            monthlyPayment: monthlyPayment,
            assetId: vehicle.id
        });
        
        this.recordCashFlow('expense', downPayment, `${vehicle.name} Down Payment`, 'vehicle');
        this.log(`Financed ${vehicle.name} - Down payment: $${downPayment.toLocaleString()}, Monthly payment: $${monthlyPayment.toFixed(0)}`, 'success');
    }
    
    updateRealEstateModal() {
        document.getElementById('realestate-cash-display').textContent = this.gameState.portfolio.cash.toFixed(0);
        
        // Update owned properties
        const ownedContainer = document.getElementById('owned-properties-list');
        ownedContainer.innerHTML = '';
        
        if (this.gameState.properties.length === 0) {
            ownedContainer.innerHTML = '<div style="color: #666; text-align: center; padding: 20px;">No properties owned<br><small>Living with parents</small></div>';
        } else {
            this.gameState.properties.forEach(property => {
                const propertyInfo = this.getAvailableProperties().find(p => p.id === property.id) || {name: property.id, emoji: '🏠'};
                const div = document.createElement('div');
                div.style.marginBottom = '10px';
                div.style.padding = '10px';
                div.style.border = '1px solid #ddd';
                div.style.borderRadius = '5px';
                div.style.backgroundColor = '#fff';
                
                const loanInfo = property.loan ? ` | Mortgage: $${property.loan.monthlyPayment.toFixed(0)}/mo` : '';
                div.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>${propertyInfo.emoji} ${propertyInfo.name}</strong>
                            <div style="font-size: 0.9em; color: #666;">
                                Value: $${property.value.toLocaleString()} | Maintenance: $${property.maintenance}/month | Property Tax: $${property.propertyTax}/month${loanInfo}
                            </div>
                        </div>
                        <button class="btn" onclick="handlePropertySell('${property.id}')" 
                                style="background: #dc3545; padding: 5px 10px;">Sell</button>
                    </div>
                `;
                
                ownedContainer.appendChild(div);
            });
        }
        
        // Update available properties
        const availableContainer = document.getElementById('available-properties-list');
        availableContainer.innerHTML = '';
        
        this.getAvailableProperties().forEach(property => {
            const div = document.createElement('div');
            div.style.marginBottom = '10px';
            div.style.padding = '10px';
            div.style.border = '1px solid #ddd';
            div.style.borderRadius = '5px';
            div.style.backgroundColor = '#f8f9fa';
            
            div.innerHTML = `
                <div>
                    <strong>${property.emoji} ${property.name}</strong>
                    <div style="font-size: 0.9em; color: #666; margin: 5px 0;">
                        Price: $${property.price.toLocaleString()} | Maintenance: $${property.maintenance}/month | Property Tax: $${property.propertyTax}/month
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div style="font-size: 0.85em; color: #666;">
                            ${property.description}
                        </div>
                        <div style="display: flex; gap: 5px;">
                            <button class="btn" onclick="handlePropertyBuy('${property.id}')" 
                                    style="background: #28a745; padding: 5px 8px; font-size: 0.85em;">Cash</button>
                            <button class="btn" onclick="handlePropertyFinance('${property.id}')" 
                                    style="background: #007bff; padding: 5px 8px; font-size: 0.85em;">Mortgage</button>
                        </div>
                    </div>
                </div>
            `;
            
            availableContainer.appendChild(div);
        });
    }
    
    getAvailableProperties() {
        return [
            {
                id: 'studio_apartment',
                name: 'Studio Apartment',
                emoji: '🏠',
                price: 150000,
                maintenance: 800,
                propertyTax: 188, // ~1.5% annually / 12 months
                description: 'Compact downtown studio, perfect for young professionals'
            },
            {
                id: 'one_bedroom_condo',
                name: '1BR Condo',
                emoji: '🏢',
                price: 220000,
                maintenance: 950,
                propertyTax: 275, // ~1.5% annually / 12 months
                description: 'Modern condo with amenities and city views'
            },
            {
                id: 'two_bedroom_house',
                name: '2BR House',
                emoji: '🏡',
                price: 320000,
                maintenance: 1200,
                propertyTax: 400, // ~1.5% annually / 12 months
                description: 'Suburban house with yard and garage'
            },
            {
                id: 'three_bedroom_house',
                name: '3BR Family House',
                emoji: '🏘️',
                price: 450000,
                maintenance: 1500,
                propertyTax: 563, // ~1.5% annually / 12 months
                description: 'Spacious family home in good neighborhood'
            },
            {
                id: 'luxury_penthouse',
                name: 'Luxury Penthouse',
                emoji: '🏰',
                price: 800000,
                maintenance: 2500,
                propertyTax: 1000, // ~1.5% annually / 12 months
                description: 'Premium penthouse with panoramic city views'
            },
            {
                id: 'vacation_cabin',
                name: 'Mountain Cabin',
                emoji: '🏔️',
                price: 280000,
                maintenance: 600,
                propertyTax: 350, // ~1.5% annually / 12 months
                description: 'Peaceful retreat in the mountains, rental income potential'
            }
        ];
    }
    
    buyProperty(propertyId) {
        const property = this.getAvailableProperties().find(p => p.id === propertyId);
        if (!property) {
            throw new Error('Property not found');
        }
        
        if (this.gameState.portfolio.cash < property.price) {
            throw new Error('Insufficient cash to buy this property');
        }
        
        // Check if player already owns this property
        if (this.gameState.properties.find(prop => prop.id === propertyId)) {
            throw new Error('You already own this property');
        }
        
        this.gameState.portfolio.cash -= property.price;
        this.gameState.properties.push({
            id: property.id,
            value: property.price,
            maintenance: property.maintenance,
            propertyTax: property.propertyTax,
            loan: null
        });
        
        this.recordCashFlow('expense', property.price, `Buy ${property.name}`, 'real_estate');
        this.log(`Purchased ${property.name} for $${property.price.toLocaleString()}`, 'success');
        
        // If this is the first property, update housing costs
        if (this.gameState.properties.length === 1) {
            this.log('You moved out of your parents\' house! Housing costs now apply.', 'info');
        }
    }
    
    sellProperty(propertyId) {
        const propertyIndex = this.gameState.properties.findIndex(prop => prop.id === propertyId);
        if (propertyIndex === -1) {
            throw new Error('Property not found in your portfolio');
        }
        
        const property = this.gameState.properties[propertyIndex];
        const propertyInfo = this.getAvailableProperties().find(p => p.id === propertyId);
        const sellPrice = Math.floor(property.value * 0.9); // Sell for 90% of current value
        
        this.gameState.portfolio.cash += sellPrice;
        this.gameState.properties.splice(propertyIndex, 1);
        
        this.recordCashFlow('income', sellPrice, `Sell ${propertyInfo?.name || propertyId}`, 'real_estate');
        this.log(`Sold ${propertyInfo?.name || propertyId} for $${sellPrice.toLocaleString()}`, 'success');
        
        // If this was the last property, player moves back with parents
        if (this.gameState.properties.length === 0) {
            this.log('You moved back in with your parents. No more housing costs!', 'info');
        }
    }
    
    financeProperty(propertyId) {
        const property = this.getAvailableProperties().find(p => p.id === propertyId);
        if (!property) {
            throw new Error('Property not found');
        }
        
        // Check if player already owns this property
        if (this.gameState.properties.find(prop => prop.id === propertyId)) {
            throw new Error('You already own this property');
        }
        
        // Calculate mortgage terms
        const downPayment = Math.floor(property.price * 0.2); // 20% down payment
        const loanAmount = property.price - downPayment;
        const annualRate = 0.045; // 4.5% APR for mortgages
        const termMonths = 360; // 30 years
        const monthlyPayment = this.calculateMonthlyPayment(loanAmount, annualRate, termMonths);
        
        if (this.gameState.portfolio.cash < downPayment) {
            throw new Error(`Insufficient cash for down payment. Need $${downPayment.toLocaleString()} (20%)`);
        }
        
        // Process the mortgage
        this.gameState.portfolio.cash -= downPayment;
        
        // Add the property with mortgage
        this.gameState.properties.push({
            id: property.id,
            value: property.price,
            maintenance: property.maintenance,
            propertyTax: property.propertyTax,
            loan: {
                balance: loanAmount,
                monthlyPayment: monthlyPayment,
                annualRate: annualRate,
                termMonths: termMonths
            }
        });
        
        // Add mortgage to the loans array
        this.gameState.loans.push({
            kind: 'mortgage',
            balance: loanAmount,
            annualRate: annualRate,
            termMonths: termMonths,
            monthlyPayment: monthlyPayment,
            assetId: property.id
        });
        
        this.recordCashFlow('expense', downPayment, `${property.name} Down Payment`, 'real_estate');
        this.log(`Mortgaged ${property.name} - Down payment: $${downPayment.toLocaleString()}, Monthly payment: $${monthlyPayment.toFixed(0)}`, 'success');
        
        // If this is the first property, update housing costs
        if (this.gameState.properties.length === 1) {
            this.log('You moved out of your parents\' house! Housing costs now apply.', 'info');
        }
    }
    
    isCrypto(symbol) {
        return ['BTC', 'ETH', 'LTC', 'USDC'].includes(symbol);
    }
    
    getStockPrice(symbol) {
        const key = `${this.gameState.currentYear}-${this.gameState.currentMonth.toString().padStart(2, '0')}`;
        return this.stockPrices[symbol]?.[key];
    }
    
    getStockPriceHistory(symbol, months = 12) {
        const history = [];
        const currentYear = this.gameState.currentYear;
        const currentMonth = this.gameState.currentMonth;
        
        for (let i = months - 1; i >= 0; i--) {
            let year = currentYear;
            let month = currentMonth - i;
            
            if (month <= 0) {
                year -= 1;
                month += 12;
            }
            
            const key = `${year}-${month.toString().padStart(2, '0')}`;
            const price = this.stockPrices[symbol]?.[key];
            
            if (price !== undefined) {
                history.push({
                    date: `${this.getMonthName(month)} ${year}`.substring(0, 6),
                    price: price
                });
            }
        }
        
        return history;
    }
    
    getCryptoPrice(symbol) {
        const key = `${this.gameState.currentYear}-${this.gameState.currentMonth.toString().padStart(2, '0')}`;
        return this.cryptoPrices[symbol]?.[key] || 1;
    }
    
    generateMockStockPrices() {
        const stocks = this.stocksData || {
            'AAPL': { base: 25, trend: 0.015 },
            'MSFT': { base: 50, trend: 0.012 },
            'NVDA': { base: 15, trend: 0.025 },
            'AMZN': { base: 40, trend: 0.018 },
            'GOOGL': { base: 250, trend: 0.014 }
        };
        
        const prices = {};
        
        Object.entries(stocks).forEach(([symbol, config]) => {
            prices[symbol] = {};
            let currentPrice = config.base;
            
            for (let year = 2000; year <= 2025; year++) {
                for (let month = 1; month <= 12; month++) {
                    // Reduced volatility to max ±5% per month
                    let volatility = (Math.random() - 0.5) * 0.05;
                    
                    // Add market crash scenarios with gradual decline
                    if (year === 2000 && month >= 3 && month <= 10) {
                        volatility = Math.min(volatility, -0.02); // Dot-com crash
                    } else if (year === 2008 && month >= 9 && month <= 12) {
                        volatility = Math.min(volatility, -0.03); // Financial crisis
                    } else if (year === 2020 && month >= 2 && month <= 4) {
                        volatility = Math.min(volatility, -0.025); // COVID crash
                    }
                    
                    currentPrice *= (1 + config.trend/12 + volatility);
                    const key = `${year}-${month.toString().padStart(2, '0')}`;
                    prices[symbol][key] = Math.round(currentPrice * 100) / 100;
                }
            }
        });
        
        return prices;
    }
    
    generateMockCryptoPrices() {
        const cryptos = {
            'BTC': { base: 0.1, trend: 0.035, startYear: 2009 },
            'ETH': { base: 1, trend: 0.030, startYear: 2015 },
            'LTC': { base: 0.1, trend: 0.025, startYear: 2013 },
            'USDC': { base: 1, trend: 0.001, startYear: 2018 }
        };
        
        const prices = {};
        
        Object.entries(cryptos).forEach(([symbol, config]) => {
            prices[symbol] = {};
            let currentPrice = config.base;
            
            for (let year = 2000; year <= 2025; year++) {
                for (let month = 1; month <= 12; month++) {
                    if (year >= config.startYear) {
                        const volatility = (Math.random() - 0.5) * 0.2;
                        currentPrice *= (1 + config.trend + volatility);
                        const key = `${year}-${month.toString().padStart(2, '0')}`;
                        prices[symbol][key] = Math.max(0.01, currentPrice);
                    }
                }
            }
        });
        
        return prices;
    }
    
    endTurn() {
        if (this.gameState.gameOver || !this.gameState.gameStarted) return;
        
        this.processMonthEnd();
    }
    
    processMonthEnd() {
        this.log('--- MONTH END ---', 'info');
        this.processMonthlyFinances();
        this.checkPsychiatristVisit();
        this.processEvent();
        this.advanceMonth();
        this.updateUI();
        this.log('--- NEW MONTH ---', 'info');
    }
    
    
    endGame(reason) {
        this.gameState.gameOver = true;
        
        const gameOverDiv = document.getElementById('game-over');
        const title = document.getElementById('game-over-title');
        const message = document.getElementById('game-over-message');
        const stats = document.getElementById('final-stats');
        
        title.textContent = reason.includes('Congratulations') ? 'Victory!' : 'Game Over';
        message.textContent = reason;
        
        const finalNetWorth = this.calculateNetWorth();
        const finalAge = this.gameState.ageYears;
        const yearsPlayed = finalAge - 24;
        
        stats.innerHTML = `
            <h3>Final Statistics</h3>
            <p><strong>Age:</strong> ${finalAge} years old</p>
            <p><strong>Years Played:</strong> ${yearsPlayed}</p>
            <p><strong>Final Net Worth:</strong> $${finalNetWorth.toFixed(2)}</p>
            <p><strong>Final Cash:</strong> $${this.gameState.portfolio.cash.toFixed(2)}</p>
            <p><strong>Profession:</strong> ${this.professions[this.gameState.professionId].title}</p>
        `;
        
        gameOverDiv.style.display = 'flex';
    }
    
    restart() {
        location.reload();
    }
    
    showPetStatus() {
        if (this.gameState.pets.length === 0) {
            this.log('You don\'t own any pets yet. Use "buy pet <type>" to get one!', 'info');
            this.log('Available pets: ' + Object.keys(this.pets).join(', '), 'info');
            return;
        }
        
        this.log('🐾 Your Pets:', 'info');
        let totalMonthlyCost = 0;
        
        this.gameState.pets.forEach(pet => {
            const age = `${pet.ageMonths} months old`;
            const happiness = `Happiness bonus: +${pet.data.happinessBonus}`;
            const cost = `Monthly cost: $${pet.data.monthlyCost}`;
            
            this.log(`• ${pet.data.name} (${pet.type}) - ${age}, ${happiness}, ${cost}`, 'success');
            totalMonthlyCost += pet.data.monthlyCost;
        });
        
        this.log(`Total monthly pet costs: $${totalMonthlyCost}`, 'info');
        this.log(`Total pet happiness bonus: +${this.gameState.pets.reduce((sum, pet) => sum + pet.data.happinessBonus, 0)}`, 'success');
    }
    
    listAvailablePets() {
        this.log('🐾 Available Pets:', 'info');
        
        Object.values(this.pets).forEach(pet => {
            const affordable = this.gameState.portfolio.cash >= pet.purchaseCost ? '✅' : '❌';
            const ageOk = this.gameState.ageYears >= pet.requirements.minAge && 
                         this.gameState.ageYears <= pet.requirements.maxAge ? '✅' : '❌';
            
            this.log(`${affordable}${ageOk} ${pet.name} - $${pet.purchaseCost} (${pet.description})`, 'info');
            this.log(`   Monthly cost: $${pet.monthlyCost}, Happiness: +${pet.happinessBonus}`, 'info');
        });
        
        this.log('Use command: buy pet <pet_type> (e.g., "buy pet goldfish")', 'info');
    }

    updateUI() {
        document.getElementById('age').textContent = this.gameState.ageYears;
        document.getElementById('cash').textContent = `$${this.gameState.portfolio.cash.toFixed(0)}`;
        document.getElementById('net-worth').textContent = `$${this.calculateNetWorth().toFixed(0)}`;
        
        if (this.gameState.professionId) {
            const profession = this.professions[this.gameState.professionId];
            document.getElementById('profession').textContent = `${profession.title} ($${Math.round(this.gameState.grossAnnual / 1000)}k/yr)`;
        } else {
            document.getElementById('profession').textContent = 'Choose Profession';
        }
        
        const totalHappiness = this.calculateTotalHappiness();
        const petBonus = totalHappiness - this.gameState.happiness;
        document.getElementById('happiness').textContent = petBonus > 0 
            ? `${totalHappiness} / 1000 (+${petBonus} from pets)`
            : `${totalHappiness} / 1000`;
        
        // Calculate and display monthly expenses
        const monthlyExpenses = this.calculateMonthlyExpenses();
        document.getElementById('monthly-expenses').textContent = `$${monthlyExpenses.toFixed(0)}`;
        
        // Update progress bar to show current month
        const progressBar = document.getElementById('month-progress');
        if (this.gameState.gameStarted && !this.gameState.gameOver) {
            progressBar.textContent = `${this.getMonthName(this.gameState.currentMonth)} ${this.gameState.currentYear} - Take Actions`;
            progressBar.style.width = '100%';
        }
        
        // Update seasonal background
        this.updateSeasonalBackground();
        
        // Update assets panel
        this.updateAssetsPanel();
        
        // Update pet display on main screen
        if (typeof updatePetDisplay === 'function') {
            updatePetDisplay();
        }
    }
    
    updateSeasonalBackground() {
        if (!this.gameState.gameStarted) return;
        
        const month = this.gameState.currentMonth;
        let season, backgroundColor;
        
        // Determine season based on month
        if (month >= 3 && month <= 5) {
            // Spring (March, April, May)
            season = 'spring';
            backgroundColor = 'linear-gradient(135deg, #e8f5e8 0%, #b8e6b8 100%)';
        } else if (month >= 6 && month <= 8) {
            // Summer (June, July, August)
            season = 'summer';
            backgroundColor = 'linear-gradient(135deg, #fff8dc 0%, #ffd700 100%)';
        } else if (month >= 9 && month <= 11) {
            // Autumn (September, October, November)
            season = 'autumn';
            backgroundColor = 'linear-gradient(135deg, #ffeaa7 0%, #fab1a0 100%)';
        } else {
            // Winter (December, January, February)
            season = 'winter';
            backgroundColor = 'linear-gradient(135deg, #dfe6e9 0%, #b2bec3 100%)';
        }
        
        // Apply background to body
        document.body.style.background = backgroundColor;
        document.body.style.transition = 'background 1s ease-in-out';
    }
    
    async loadProfessions() {
        console.log('Loading embedded professions...');
        // Use embedded data instead of fetching XML to avoid CORS issues
        this.professions = this.getEmbeddedProfessions();
        console.log('Loaded professions:', Object.keys(this.professions));
        console.log('Total profession count:', Object.keys(this.professions).length);
    }
    
    getEmbeddedProfessions() {
        return {
            'fast_food_worker': {
                id: 'fast_food_worker',
                title: 'Fast-Food Worker',
                salaryRange: [20000, 36000],
                raise: 0.04,
                studentLoan: { principal: 0, annualRate: 0.05, termMonths: 0 },
                fixedCosts: { food: 600, housing: 1800 }
            },
            'barista': {
                id: 'barista',
                title: 'Barista',
                salaryRange: [21000, 38000],
                raise: 0.05,
                studentLoan: { principal: 0, annualRate: 0.05, termMonths: 0 },
                fixedCosts: { food: 600, housing: 1800 }
            },
            'retail_sales': {
                id: 'retail_sales',
                title: 'Retail Sales Clerk',
                salaryRange: [24000, 42000],
                raise: 0.05,
                studentLoan: { principal: 0, annualRate: 0.05, termMonths: 0 },
                fixedCosts: { food: 600, housing: 1800 }
            },
            'waiter': {
                id: 'waiter',
                title: 'Restaurant Server',
                salaryRange: [24000, 42000],
                raise: 0.07,
                studentLoan: { principal: 15000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 600, housing: 1800 }
            },
            'customer_service_rep': {
                id: 'customer_service_rep',
                title: 'Customer Service Rep',
                salaryRange: [30000, 55000],
                raise: 0.06,
                studentLoan: { principal: 5000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 650, housing: 1900 }
            },
            'administrative_assistant': {
                id: 'administrative_assistant',
                title: 'Administrative Assistant',
                salaryRange: [33000, 60000],
                raise: 0.06,
                studentLoan: { principal: 5000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 650, housing: 1900 }
            },
            'construction_laborer': {
                id: 'construction_laborer',
                title: 'Construction Laborer',
                salaryRange: [30000, 50000],
                raise: 0.05,
                studentLoan: { principal: 0, annualRate: 0.05, termMonths: 0 },
                fixedCosts: { food: 650, housing: 1900 }
            },
            'truck_driver': {
                id: 'truck_driver',
                title: 'Truck Driver',
                salaryRange: [42000, 70000],
                raise: 0.06,
                studentLoan: { principal: 7000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 650, housing: 1900 }
            },
            'electrician': {
                id: 'electrician',
                title: 'Electrician',
                salaryRange: [45000, 80000],
                raise: 0.06,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'plumber': {
                id: 'plumber',
                title: 'Plumber',
                salaryRange: [43000, 77000],
                raise: 0.06,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'carpenter': {
                id: 'carpenter',
                title: 'Carpenter',
                salaryRange: [38000, 70000],
                raise: 0.06,
                studentLoan: { principal: 5000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'auto_mechanic': {
                id: 'auto_mechanic',
                title: 'Automotive Technician',
                salaryRange: [35000, 60000],
                raise: 0.06,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'chef': {
                id: 'chef',
                title: 'Chef',
                salaryRange: [40000, 72000],
                raise: 0.07,
                studentLoan: { principal: 15000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'fitness_trainer': {
                id: 'fitness_trainer',
                title: 'Fitness Trainer',
                salaryRange: [32000, 60000],
                raise: 0.08,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'graphic_designer': {
                id: 'graphic_designer',
                title: 'Graphic Designer',
                salaryRange: [38000, 80000],
                raise: 0.07,
                studentLoan: { principal: 20000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'ux_designer': {
                id: 'ux_designer',
                title: 'UX Designer',
                salaryRange: [75000, 140000],
                raise: 0.08,
                studentLoan: { principal: 22000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 900, housing: 2400 }
            },
            'journalist': {
                id: 'journalist',
                title: 'Journalist',
                salaryRange: [38000, 70000],
                raise: 0.06,
                studentLoan: { principal: 25000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'content_creator': {
                id: 'content_creator',
                title: 'Content Creator',
                salaryRange: [35000, 85000],
                raise: 0.20,
                studentLoan: { principal: 25000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'marketing_specialist': {
                id: 'marketing_specialist',
                title: 'Marketing Specialist',
                salaryRange: [45000, 95000],
                raise: 0.07,
                studentLoan: { principal: 20000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 800, housing: 2200 }
            },
            'sales_manager': {
                id: 'sales_manager',
                title: 'Sales Manager',
                salaryRange: [85000, 175000],
                raise: 0.10,
                studentLoan: { principal: 15000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 900, housing: 2400 }
            },
            'accountant': {
                id: 'accountant',
                title: 'Accountant',
                salaryRange: [50000, 105000],
                raise: 0.07,
                studentLoan: { principal: 22000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 800, housing: 2200 }
            },
            'financial_analyst': {
                id: 'financial_analyst',
                title: 'Financial Analyst',
                salaryRange: [70000, 125000],
                raise: 0.08,
                studentLoan: { principal: 25000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 850, housing: 2300 }
            },
            'software_dev': {
                id: 'software_dev',
                title: 'Software Developer',
                salaryRange: [85000, 150000],
                raise: 0.08,
                studentLoan: { principal: 35000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 900, housing: 2400 }
            },
            'data_scientist': {
                id: 'data_scientist',
                title: 'Data Scientist',
                salaryRange: [80000, 145000],
                raise: 0.10,
                studentLoan: { principal: 30000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 900, housing: 2400 }
            },
            'teacher_elementary': {
                id: 'teacher_elementary',
                title: 'Elementary Teacher',
                salaryRange: [45000, 85000],
                raise: 0.05,
                studentLoan: { principal: 22000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 600, housing: 1800 }
            },
            'registered_nurse': {
                id: 'registered_nurse',
                title: 'Registered Nurse',
                salaryRange: [65000, 115000],
                raise: 0.06,
                studentLoan: { principal: 25000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 800, housing: 2200 }
            },
            'paramedic': {
                id: 'paramedic',
                title: 'Paramedic',
                salaryRange: [35000, 62000],
                raise: 0.06,
                studentLoan: { principal: 12000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 700, housing: 2000 }
            },
            'police_officer': {
                id: 'police_officer',
                title: 'Police Officer',
                salaryRange: [50000, 95000],
                raise: 0.06,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'firefighter': {
                id: 'firefighter',
                title: 'Firefighter',
                salaryRange: [40000, 75000],
                raise: 0.06,
                studentLoan: { principal: 10000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 750, housing: 2100 }
            },
            'real_estate_agent': {
                id: 'real_estate_agent',
                title: 'Real Estate Agent',
                salaryRange: [35000, 80000],
                raise: 0.08,
                studentLoan: { principal: 8000, annualRate: 0.05, termMonths: 120 },
                fixedCosts: { food: 800, housing: 2200 }
            }
        };
    }
    
    async loadEvents() {
        console.log('Loading embedded events...');
        // Use embedded data instead of fetching XML to avoid CORS issues
        this.events = this.getEmbeddedEvents();
        console.log('Loaded events:', this.events.map(e => e.id));
    }

    async loadPets() {
        try {
            console.log('Starting to load pets.xml...');
            const response = await fetch('pets.xml');
            if (!response.ok) {
                throw new Error(`Failed to fetch pets.xml: ${response.status} ${response.statusText}`);
            }
            const text = await response.text();
            console.log('pets.xml loaded, parsing...');
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(text, 'text/xml');
            
            // Check for XML parsing errors
            const parserError = xmlDoc.querySelector('parsererror');
            if (parserError) {
                throw new Error('XML parsing error: ' + parserError.textContent);
            }
            
            // Load pets
            const petNodes = xmlDoc.querySelectorAll('pets > pet');
            petNodes.forEach(petNode => {
                const id = petNode.getAttribute('id');
                this.pets[id] = {
                    id: id,
                    name: petNode.querySelector('name')?.textContent || '',
                    type: petNode.querySelector('type')?.textContent || '',
                    purchaseCost: parseInt(petNode.querySelector('purchaseCost')?.textContent || '0'),
                    monthlyCost: parseInt(petNode.querySelector('monthlyCost')?.textContent || '0'),
                    lifespan: parseInt(petNode.querySelector('lifespan')?.textContent || '12'),
                    happinessBonus: parseInt(petNode.querySelector('happinessBonus')?.textContent || '0'),
                    description: petNode.querySelector('description')?.textContent || '',
                    requirements: this.parsePetRequirements(petNode.querySelector('requirements')),
                    effects: this.parsePetEffects(petNode.querySelector('effects'))
                };
            });
            
            console.log(`Loaded ${Object.keys(this.pets).length} pets from XML`);
            console.log('First few pets:', Object.keys(this.pets).slice(0, 5));
        } catch (error) {
            console.error('Error loading pets from XML:', error);
            console.log('Falling back to embedded pet data...');
            this.loadEmbeddedPets();
        }
    }
    
    loadEmbeddedPets() {
        // Fallback embedded pet data to avoid CORS issues
        this.pets = {
            goldfish: {
                id: 'goldfish',
                name: 'Goldfish',
                type: 'fish',
                purchaseCost: 25,
                monthlyCost: 15,
                lifespan: 36,
                happinessBonus: 5,
                description: 'A simple goldfish in a bowl. Low maintenance and calming to watch.',
                requirements: { minAge: 18, maxAge: 65, minCash: 50, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐠'
            },
            hamster: {
                id: 'hamster',
                name: 'Hamster',
                type: 'small_mammal',
                purchaseCost: 40,
                monthlyCost: 25,
                lifespan: 24,
                happinessBonus: 8,
                description: 'A cute hamster with a cage and exercise wheel. Fun to watch and interact with.',
                requirements: { minAge: 16, maxAge: 70, minCash: 100, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐹'
            },
            cat: {
                id: 'cat',
                name: 'Cat',
                type: 'cat',
                purchaseCost: 150,
                monthlyCost: 65,
                lifespan: 180,
                happinessBonus: 20,
                description: 'An independent cat that provides companionship and stress relief.',
                requirements: { minAge: 22, maxAge: 75, minCash: 400, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐱'
            },
            small_dog: {
                id: 'small_dog',
                name: 'Small Dog',
                type: 'dog',
                purchaseCost: 300,
                monthlyCost: 85,
                lifespan: 168,
                happinessBonus: 25,
                description: 'A small, friendly dog that loves walks and playing fetch.',
                requirements: { minAge: 25, maxAge: 70, minCash: 600, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐶'
            },
            rabbit: {
                id: 'rabbit',
                name: 'Rabbit',
                type: 'small_mammal',
                purchaseCost: 80,
                monthlyCost: 45,
                lifespan: 96,
                happinessBonus: 15,
                description: 'A fluffy rabbit that enjoys hopping around and eating vegetables.',
                requirements: { minAge: 20, maxAge: 70, minCash: 200, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐰'
            },
            budgie: {
                id: 'budgie',
                name: 'Budgerigar',
                type: 'bird',
                purchaseCost: 60,
                monthlyCost: 30,
                lifespan: 84,
                happinessBonus: 12,
                description: 'A colorful budgie that can learn to talk. Great companion for conversation.',
                requirements: { minAge: 18, maxAge: 75, minCash: 150, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🦜'
            },
            guinea_pig: {
                id: 'guinea_pig',
                name: 'Guinea Pig',
                type: 'small_mammal',
                purchaseCost: 35,
                monthlyCost: 30,
                lifespan: 72,
                happinessBonus: 12,
                description: 'A social guinea pig that enjoys companionship and makes cute squeaking sounds.',
                requirements: { minAge: 16, maxAge: 70, minCash: 120, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐹'
            },
            betta_fish: {
                id: 'betta_fish',
                name: 'Betta Fish',
                type: 'fish',
                purchaseCost: 15,
                monthlyCost: 10,
                lifespan: 30,
                happinessBonus: 6,
                description: 'A vibrant betta fish with beautiful flowing fins. Easy to care for.',
                requirements: { minAge: 16, maxAge: 80, minCash: 40, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐟'
            },
            parrot: {
                id: 'parrot',
                name: 'Parrot',
                type: 'bird',
                purchaseCost: 800,
                monthlyCost: 75,
                lifespan: 600,
                happinessBonus: 30,
                description: 'An intelligent parrot that can learn words and provide decades of companionship.',
                requirements: { minAge: 30, maxAge: 50, minCash: 1500, minWisdom: 70, minCharm: 0 },
                effects: {},
                emoji: '🦜'
            },
            horse: {
                id: 'horse',
                name: 'Horse',
                type: 'large_mammal',
                purchaseCost: 5000,
                monthlyCost: 800,
                lifespan: 300,
                happinessBonus: 50,
                description: 'A majestic horse for riding and companionship. Requires significant resources.',
                requirements: { minAge: 35, maxAge: 60, minCash: 15000, minWisdom: 0, minCharm: 0 },
                effects: {},
                emoji: '🐴'
            }
        };
        
        console.log(`Loaded ${Object.keys(this.pets).length} embedded pets as fallback`);
    }
    
    parsePetRequirements(reqNode) {
        if (!reqNode) return {};
        
        return {
            minAge: parseInt(reqNode.querySelector('minAge')?.textContent || '0'),
            maxAge: parseInt(reqNode.querySelector('maxAge')?.textContent || '999'),
            minCash: parseInt(reqNode.querySelector('minCash')?.textContent || '0'),
            minNetWorth: parseInt(reqNode.querySelector('minNetWorth')?.textContent || '0'),
            minHousing: reqNode.querySelector('minHousing')?.textContent || '',
            minWisdom: parseInt(reqNode.querySelector('minWisdom')?.textContent || '0'),
            minCharm: parseInt(reqNode.querySelector('minCharm')?.textContent || '0'),
            specialNeed: reqNode.querySelector('specialNeed')?.textContent === 'true'
        };
    }
    
    parsePetEffects(effectsNode) {
        if (!effectsNode) return {};
        
        const effects = {};
        const statusNode = effectsNode.querySelector('playerStatus');
        if (statusNode) {
            effects.playerStatus = {
                energy: parseInt(statusNode.querySelector('energy')?.textContent || '0'),
                focus: parseInt(statusNode.querySelector('focus')?.textContent || '0'),
                wisdom: parseInt(statusNode.querySelector('wisdom')?.textContent || '0'),
                charm: parseInt(statusNode.querySelector('charm')?.textContent || '0'),
                luck: parseInt(statusNode.querySelector('luck')?.textContent || '0'),
                psp: parseInt(statusNode.querySelector('psp')?.textContent || '0')
            };
        }
        return effects;
    }

    async loadStocks() {
        console.log('Loading embedded stocks...');
        // Use embedded data instead of fetching XML to avoid CORS issues
        this.stocksData = this.getEmbeddedStocks();
        console.log('Loaded stocks:', Object.keys(this.stocksData));
        
        // Generate prices after stock data is loaded
        this.stockPrices = this.generateMockStockPrices();
        this.cryptoPrices = this.generateMockCryptoPrices();
        console.log('Generated stock and crypto prices');
    }
    
    getEmbeddedEvents() {
        return [
            {
                id: 'travel_trip',
                category: 'lifestyle',
                weight: 0.5,
                cooldown: 12,
                costRange: [300, 1000],
                effects: { happiness: 8 },
                description: 'Weekend getaway',
                detailedDescription: 'You decide to take a spontaneous weekend trip to recharge and explore new places. The experience brings joy and creates lasting memories.'
            },
            {
                id: 'car_repair',
                category: 'maintenance',
                weight: 0.8,
                cooldown: 6,
                costRange: [200, 800],
                effects: { happiness: -3 },
                description: 'Car needs repairs',
                detailedDescription: 'Your car has developed mechanical issues that require immediate attention. The unexpected repair costs are frustrating but necessary for reliable transportation.'
            },
            {
                id: 'bonus',
                category: 'income',
                weight: 0.3,
                cooldown: 24,
                costRange: [-2000, -500],
                effects: { happiness: 5 },
                description: 'Work bonus!',
                detailedDescription: 'Your hard work and dedication have been recognized! Your employer rewards you with a performance bonus that boosts both your finances and morale.'
            },
            {
                id: 'medical_expense',
                category: 'health',
                weight: 0.4,
                cooldown: 18,
                costRange: [150, 600],
                effects: { happiness: -2 },
                description: 'Medical checkup',
                detailedDescription: 'You need to visit the doctor for a routine checkup or minor health issue. While it\'s important for your well-being, the medical costs add up.'
            },
            {
                id: 'friend_wedding',
                category: 'social',
                weight: 0.2,
                cooldown: 36,
                costRange: [250, 500],
                effects: { happiness: 6 },
                description: 'Friend\'s wedding',
                detailedDescription: 'A close friend is getting married and you\'re invited to celebrate! Between the gift, outfit, and travel expenses, it costs money but brings joy and strengthens friendships.'
            },
            {
                id: 'no_event',
                category: 'none',
                weight: 2.0,
                cooldown: 0,
                costRange: [0, 0],
                effects: {},
                description: 'Quiet month',
                detailedDescription: 'Nothing significant happens this month. Sometimes life is just routine and peaceful.'
            }
        ];
    }

    getEmbeddedStocks() {
        return {
            'AAPL': { name: 'Apple Inc.', sector: 'Technology', base: 1.00, trend: 0.20 },
            'MSFT': { name: 'Microsoft Corp.', sector: 'Technology', base: 58.28, trend: 0.012 },
            'INTC': { name: 'Intel Corp.', sector: 'Technology', base: 43.50, trend: 0.008 },
            'CSCO': { name: 'Cisco Systems Inc.', sector: 'Technology', base: 54.03, trend: 0.010 },
            'ORCL': { name: 'Oracle Corp.', sector: 'Technology', base: 29.53, trend: 0.011 },
            'IBM': { name: 'International Business Machines Corp.', sector: 'Technology', base: 110.90, trend: 0.005 },
            'TXN': { name: 'Texas Instruments', sector: 'Technology', base: 51.44, trend: 0.009 },
            'HPQ': { name: 'HP Inc.', sector: 'Technology', base: 26.67, trend: 0.006 },
            'QCOM': { name: 'Qualcomm Inc.', sector: 'Technology', base: 89.66, trend: 0.013 },
            'NVDA': { name: 'NVIDIA Corp.', sector: 'Technology', base: 0.10, trend: 0.28 },
            'AMZN': { name: 'Amazon.com Inc.', sector: 'Consumer Discretionary', base: 4.47, trend: 0.025 },
            'DIS': { name: 'Walt Disney Co.', sector: 'Consumer Discretionary', base: 29.47, trend: 0.008 },
            'MCD': { name: 'McDonald\'s Corp.', sector: 'Consumer Discretionary', base: 39.62, trend: 0.007 },
            'SBUX': { name: 'Starbucks Corp.', sector: 'Consumer Discretionary', base: 3.08, trend: 0.015 },
            'NKE': { name: 'Nike Inc.', sector: 'Consumer Discretionary', base: 6.02, trend: 0.012 },
            'YUM': { name: 'Yum! Brands Inc.', sector: 'Consumer Discretionary', base: 6.71, trend: 0.009 },
            'WMT': { name: 'Walmart Inc.', sector: 'Consumer Staples', base: 22.27, trend: 0.006 },
            'KO': { name: 'Coca-Cola Co.', sector: 'Consumer Staples', base: 28.19, trend: 0.005 },
            'PEP': { name: 'PepsiCo Inc.', sector: 'Consumer Staples', base: 36.88, trend: 0.006 },
            'COST': { name: 'Costco Wholesale Corp.', sector: 'Consumer Staples', base: 44.50, trend: 0.010 },
            'CVS': { name: 'CVS Health Corp.', sector: 'Consumer Staples', base: 18.91, trend: 0.008 },
            'LOW': { name: 'Lowe\'s Companies Inc.', sector: 'Consumer Discretionary', base: 13.94, trend: 0.011 },
            'PG': { name: 'Procter & Gamble Co.', sector: 'Consumer Staples', base: 53.59, trend: 0.006 },
            'CL': { name: 'Colgate-Palmolive Co.', sector: 'Consumer Staples', base: 31.12, trend: 0.005 },
            'WBA': { name: 'Walgreens Boots Alliance Inc.', sector: 'Consumer Staples', base: 28.56, trend: 0.004 },
            'XOM': { name: 'Exxon Mobil Corp.', sector: 'Energy', base: 39.16, trend: 0.007 },
            'DD': { name: 'DuPont de Nemours, Inc.', sector: 'Materials', base: 62.92, trend: 0.006 },
            'CAT': { name: 'Caterpillar Inc.', sector: 'Industrials', base: 24.31, trend: 0.008 },
            'BA': { name: 'Boeing Co.', sector: 'Industrials', base: 40.19, trend: 0.009 },
            'JNJ': { name: 'Johnson & Johnson', sector: 'Health Care', base: 46.09, trend: 0.007 },
            'PFE': { name: 'Pfizer Inc.', sector: 'Health Care', base: 30.24, trend: 0.006 },
            'MRK': { name: 'Merck & Co. Inc.', sector: 'Health Care', base: 64.53, trend: 0.006 },
            'ABT': { name: 'Abbott Laboratories', sector: 'Health Care', base: 15.71, trend: 0.008 },
            'MDT': { name: 'Medtronic plc', sector: 'Health Care', base: 34.25, trend: 0.007 },
            'UNH': { name: 'UnitedHealth Group Inc.', sector: 'Health Care', base: 6.72, trend: 0.015 },
            'BMY': { name: 'Bristol-Myers Squibb Co.', sector: 'Health Care', base: 61.33, trend: 0.005 },
            'BAC': { name: 'Bank of America Corp.', sector: 'Financials', base: 24.22, trend: 0.008 },
            'JPM': { name: 'JPMorgan Chase & Co.', sector: 'Financials', base: 48.58, trend: 0.009 },
            'C': { name: 'Citigroup Inc.', sector: 'Financials', base: 397.50, trend: 0.006 },
            'WFC': { name: 'Wells Fargo & Co.', sector: 'Financials', base: 19.56, trend: 0.007 },
            'AIG': { name: 'American International Group Inc.', sector: 'Financials', base: 1385.83, trend: 0.005 },
            'GE': { name: 'General Electric Co.', sector: 'Industrials', base: 239.62, trend: 0.004 },
            'UPS': { name: 'United Parcel Service Inc.', sector: 'Industrials', base: 67.06, trend: 0.007 },
            'MMM': { name: '3M Co.', sector: 'Industrials', base: 39.45, trend: 0.006 },
            'ADP': { name: 'Automatic Data Processing Inc.', sector: 'Industrials', base: 41.24, trend: 0.008 },
            'AEP': { name: 'American Electric Power Co.', sector: 'Utilities', base: 31.44, trend: 0.005 },
            'F': { name: 'Ford Motor Co.', sector: 'Consumer Discretionary', base: 28.78, trend: 0.006 },
            'HMC': { name: 'Honda Motor Co., Ltd', sector: 'Consumer Discretionary', base: 18.92, trend: 0.007 },
            'MO': { name: 'Altria Group Inc.', sector: 'Consumer Staples', base: 23.44, trend: 0.004 },
            'HD': { name: 'Home Depot Inc.', sector: 'Consumer Discretionary', base: 65.19, trend: 0.010 }
        };
    }

    getStockSymbols() {
        return Object.keys(this.stocksData || {});
    }
    
    
    log(message, type = 'info') {
        const logArea = document.getElementById('game-log');
        const entry = document.createElement('div');
        entry.className = `log-entry log-${type}`;
        entry.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
        logArea.appendChild(entry);
        logArea.scrollTop = logArea.scrollHeight;
    }
    
    updateAssetsPanel() {
        // Update cash and bank
        document.getElementById('asset-cash').textContent = `$${this.gameState.portfolio.cash.toFixed(2)}`;
        document.getElementById('asset-bank').textContent = `$${this.gameState.portfolio.bank.toFixed(2)}`;
        
        // Update stocks
        const stocksList = document.getElementById('stocks-list');
        stocksList.innerHTML = '';
        Object.entries(this.gameState.portfolio.stocks).forEach(([symbol, shares]) => {
            if (shares > 0) {
                const price = this.getStockPrice(symbol);
                if (price !== undefined) {
                    const value = shares * price;
                    const div = document.createElement('div');
                    div.className = 'asset-item';
                    div.innerHTML = `
                        <span class="asset-name">${symbol} (${shares} shares)</span>
                        <span class="asset-value">$${value.toFixed(2)}</span>
                    `;
                    stocksList.appendChild(div);
                }
            }
        });
        
        // Update crypto
        const cryptoList = document.getElementById('crypto-list');
        cryptoList.innerHTML = '';
        Object.entries(this.gameState.portfolio.crypto).forEach(([symbol, amount]) => {
            if (amount > 0) {
                const price = this.getCryptoPrice(symbol);
                const value = amount * price;
                const div = document.createElement('div');
                div.className = 'asset-item';
                div.innerHTML = `
                    <span class="asset-name">${symbol} (${amount} units)</span>
                    <span class="asset-value">$${value.toFixed(2)}</span>
                `;
                cryptoList.appendChild(div);
            }
        });
        
        // Update cars
        const carsList = document.getElementById('cars-list');
        carsList.innerHTML = '';
        this.gameState.cars.forEach(car => {
            const div = document.createElement('div');
            div.className = 'asset-item';
            div.innerHTML = `
                <span class="asset-name">${car.id.replace(/_/g, ' ')}</span>
                <span class="asset-value">$${car.value.toFixed(2)}</span>
            `;
            carsList.appendChild(div);
        });
        
        // Update properties
        const propertiesList = document.getElementById('properties-list');
        propertiesList.innerHTML = '';
        
        if (this.gameState.properties.length === 0) {
            // Show living with parents if no real estate
            const div = document.createElement('div');
            div.className = 'asset-item';
            div.innerHTML = `
                <span class="asset-name">🏠 Living with Parents</span>
                <span class="asset-value" style="color: #28a745;">Free</span>
            `;
            propertiesList.appendChild(div);
        } else {
            this.gameState.properties.forEach(property => {
                const div = document.createElement('div');
                div.className = 'asset-item';
                const monthlyCosts = property.maintenance + property.propertyTax;
                const loanPayment = property.loan ? ` + $${property.loan.monthlyPayment.toFixed(0)} loan` : '';
                div.innerHTML = `
                    <div>
                        <span class="asset-name">🏠 ${property.id.replace(/_/g, ' ')}</span>
                        <div style="font-size: 0.75em; color: #666; margin-top: 2px;">
                            Monthly: $${monthlyCosts}/mo (Tax: $${property.propertyTax} + Maint: $${property.maintenance})${loanPayment}
                        </div>
                    </div>
                    <span class="asset-value">$${property.value.toFixed(0)}</span>
                `;
                propertiesList.appendChild(div);
            });
        }
        
        // Update loans
        const loansList = document.getElementById('loans-list');
        loansList.innerHTML = '';
        this.gameState.loans.forEach(loan => {
            const div = document.createElement('div');
            div.className = 'asset-item';
            div.innerHTML = `
                <span class="asset-name">${loan.kind} Loan</span>
                <span class="asset-debt">-$${loan.balance.toFixed(2)}</span>
            `;
            loansList.appendChild(div);
        });
    }
    
    getMonthName(monthNum) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[monthNum - 1];
    }
    
    showEventPopup(event, cost) {
        const popup = document.getElementById('event-popup');
        const title = document.getElementById('event-popup-title');
        const description = document.getElementById('event-popup-description');
        const costElement = document.getElementById('event-popup-cost');
        const happinessElement = document.getElementById('event-popup-happiness');
        
        title.textContent = event.description;
        description.textContent = event.detailedDescription || event.description;
        
        // Format cost display
        if (cost > 0) {
            costElement.textContent = `Cost: -$${cost.toFixed(0)}`;
            costElement.className = 'event-cost negative';
        } else if (cost < 0) {
            costElement.textContent = `Income: +$${Math.abs(cost).toFixed(0)}`;
            costElement.className = 'event-cost positive';
        } else {
            costElement.textContent = 'No financial impact';
            costElement.className = 'event-cost';
        }
        
        // Format happiness display
        if (event.effects.happiness) {
            const happinessChange = event.effects.happiness;
            if (happinessChange > 0) {
                happinessElement.textContent = `Happiness: +${happinessChange}`;
                happinessElement.style.color = '#28a745';
            } else {
                happinessElement.textContent = `Happiness: ${happinessChange}`;
                happinessElement.style.color = '#dc3545';
            }
        } else {
            happinessElement.textContent = 'No happiness change';
            happinessElement.style.color = '#666';
        }
        
        popup.style.display = 'flex';
    }
    
    updateStockInfo() {
        // Update current date
        document.getElementById('stock-current-date').textContent = 
            `${this.getMonthName(this.gameState.currentMonth)} ${this.gameState.currentYear}`;
        
        // Update stock prices
        const stocksContainer = document.getElementById('stocks-info');
        stocksContainer.innerHTML = '';
        
        const stockSymbols = this.getStockSymbols();
        stockSymbols.forEach(symbol => {
            const price = this.getStockPrice(symbol);
            if (price !== undefined) {
                const stockInfo = this.stocksData[symbol] || { name: symbol, sector: 'N/A' };
                const div = document.createElement('div');
                div.className = 'stock-item';
                div.innerHTML = `
                    <div>
                        <span class="stock-symbol">${symbol} - ${stockInfo.name}</span>
                        <div style="font-size: 0.8em; color: #666;">${stockInfo.sector}</div>
                    </div>
                    <span class="stock-price">$${price.toFixed(2)}</span>
                `;
                stocksContainer.appendChild(div);
            }
        });
        
        // Update crypto prices
        const cryptoContainer = document.getElementById('crypto-info');
        cryptoContainer.innerHTML = '';
        
        const cryptoSymbols = ['BTC', 'ETH', 'LTC', 'USDC'];
        cryptoSymbols.forEach(symbol => {
            const price = this.getCryptoPrice(symbol);
            const div = document.createElement('div');
            div.className = 'stock-item';
            div.innerHTML = `
                <span class="stock-symbol">${symbol}</span>
                <span class="crypto-price">$${price.toFixed(2)}</span>
            `;
            cryptoContainer.appendChild(div);
        });
    }
    
    updateExpenseBreakdown() {
        const container = document.getElementById('expense-breakdown-list');
        container.innerHTML = '';
        
        const profession = this.professions[this.gameState.professionId];
        let totalExpenses = 0;
        
        // Food expenses
        if (profession) {
            const foodExpense = profession.fixedCosts.food;
            totalExpenses += foodExpense;
            this.addExpenseItem(container, '🍔 Food', foodExpense);
            
            // Housing expenses (only if not living with parents)
            // For now, player lives with parents so no housing expense
            // TODO: Add housing expense when player moves out
        }
        
        // Utilities & Other Fixed Costs
        const utilities = 390; // utilities, phone, internet, etc.
        totalExpenses += utilities;
        this.addExpenseItem(container, '🔌 Utilities & Other', utilities);
        
        // Entertainment subscriptions
        const entertainment = 20; // Netflix, Crunchyroll, etc.
        totalExpenses += entertainment;
        this.addExpenseItem(container, '🎬 Entertainment', entertainment);
        
        // Loan payments
        this.gameState.loans.forEach((loan, index) => {
            const loanType = loan.kind.charAt(0).toUpperCase() + loan.kind.slice(1);
            this.addExpenseItem(container, `📋 ${loanType} Loan Payment`, loan.monthlyPayment);
            totalExpenses += loan.monthlyPayment;
        });
        
        // Car maintenance
        this.gameState.cars.forEach((car, index) => {
            const carName = car.id.replace(/_/g, ' ');
            this.addExpenseItem(container, `🚗 ${carName} Maintenance`, car.maintenance);
            totalExpenses += car.maintenance;
        });
        
        // Property maintenance
        this.gameState.properties.forEach((property, index) => {
            const propertyName = property.id.replace(/_/g, ' ');
            this.addExpenseItem(container, `🏠 ${propertyName} Maintenance`, property.maintenance);
            totalExpenses += property.maintenance;
        });
        
        // Property taxes
        this.gameState.properties.forEach((property, index) => {
            const propertyName = property.id.replace(/_/g, ' ');
            this.addExpenseItem(container, `🏛️ ${propertyName} Property Tax`, property.propertyTax);
            totalExpenses += property.propertyTax;
        });
        
        // Total
        const totalDiv = document.createElement('div');
        totalDiv.className = 'expense-item';
        totalDiv.innerHTML = `
            <span class="expense-category">💰 Total Monthly Expenses</span>
            <span class="expense-amount expense-total">$${totalExpenses.toFixed(0)}</span>
        `;
        container.appendChild(totalDiv);
    }
    
    addExpenseItem(container, category, amount) {
        const div = document.createElement('div');
        div.className = 'expense-item';
        div.innerHTML = `
            <span class="expense-category">${category}</span>
            <span class="expense-amount">$${amount.toFixed(0)}</span>
        `;
        container.appendChild(div);
    }
    
    randomBetween(min, max) {
        return Math.random() * (max - min) + min;
    }
    
    recordCashFlow(type, amount, description, category = 'other') {
        const record = {
            date: `${this.getMonthName(this.gameState.currentMonth)} ${this.gameState.currentYear}`,
            type: type, // 'income' or 'expense'
            amount: Math.abs(amount),
            description: description,
            category: category,
            balance: this.gameState.portfolio.cash
        };
        this.gameState.cashFlowHistory.unshift(record); // Add to beginning
        
        // Keep only last 50 records to prevent memory issues
        if (this.gameState.cashFlowHistory.length > 50) {
            this.gameState.cashFlowHistory = this.gameState.cashFlowHistory.slice(0, 50);
        }
    }
}

// Initialize game when page loads
let game;
window.addEventListener('DOMContentLoaded', () => {
    game = new SimLifeGame();
});