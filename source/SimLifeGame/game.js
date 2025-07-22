class SimLifeGame {
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
            gameOver: false,
            gameStarted: false
        };
        
        this.professions = {};
        this.events = [];
        this.eventCooldowns = {};
        this.stockPrices = this.generateMockStockPrices();
        this.cryptoPrices = this.generateMockCryptoPrices();
        
        this.init();
    }
    
    async init() {
        await this.loadProfessions();
        await this.loadEvents();
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
            
            const fixedCostsTotal = profession.fixedCosts.food + 390; // utilities etc. (no housing - living with parents)
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
        this.gameState.fixedCosts = profession.fixedCosts.food + 390; // utilities etc. (no housing - living with parents)
        
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
        
        // Add car maintenance
        this.gameState.cars.forEach(car => {
            totalExpenses += car.maintenance;
        });
        
        // Add property maintenance costs
        this.gameState.properties.forEach(property => {
            totalExpenses += property.maintenance;
        });
        
        return totalExpenses;
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
            netWorth += shares * price;
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
        if (parts.length < 3) throw new Error('Usage: buy SYMBOL AMOUNT');
        
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
    
    handleSell(parts) {
        if (parts.length < 3) throw new Error('Usage: sell SYMBOL AMOUNT');
        
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
                    portfolioText += `  ${symbol}: ${shares} shares @ $${price.toFixed(2)} = $${(shares * price).toFixed(2)}\n`;
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
        
        let historyText = '💰 CASH FLOW HISTORY (現金流水帳歷史):\n';
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
        
        const stockSymbols = ['AAPL', 'MSFT', 'NVDA', 'AMZN', 'GOOGL'];
        
        stockSymbols.forEach(symbol => {
            const price = this.getStockPrice(symbol);
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
            
            stockDiv.innerHTML = `
                <div style="display: flex; justify-content: between; align-items: center; margin-bottom: 10px;">
                    <div>
                        <h4 style="margin: 0; color: #007bff;">${symbol}</h4>
                        <div style="font-size: 0.9em; color: #666;">Price: $${price.toFixed(2)} | Holdings: ${holdings} shares</div>
                        <div style="font-size: 0.9em; color: #666;">Value: $${(holdings * price).toFixed(2)}</div>
                        <div style="font-size: 0.85em; color: ${changeColor}; font-weight: bold;">${changeSymbol}${priceChange.toFixed(1)}% this month</div>
                    </div>
                </div>
                
                <div style="background: #f8f9fa; padding: 10px; border-radius: 3px; margin-bottom: 10px;">
                    <div style="font-size: 0.9em; font-weight: bold; margin-bottom: 5px;">📈 12-Month Price History</div>
                    <div style="display: flex; justify-content: space-between; font-size: 0.8em; color: #666;">
                        ${priceHistory.slice(-6).map(data => `
                            <div style="text-align: center;">
                                <div>${data.date}</div>
                                <div style="font-weight: bold;">$${data.price.toFixed(0)}</div>
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
                
                div.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>${vehicleInfo.emoji} ${vehicleInfo.name}</strong>
                            <div style="font-size: 0.9em; color: #666;">
                                Value: $${car.value.toFixed(0)} | Maintenance: $${car.maintenance}/month
                            </div>
                        </div>
                        <button class="btn" onclick="handleVehicleSell('${car.id}')" 
                                style="background: #dc3545; padding: 5px 10px;">Sell</button>
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
                        Price: $${vehicle.price.toLocaleString()} | Maintenance: $${vehicle.maintenance}/month
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div style="font-size: 0.85em; color: #666;">
                            ${vehicle.description}
                        </div>
                        <button class="btn" onclick="handleVehicleBuy('${vehicle.id}')" 
                                style="background: #28a745; padding: 5px 10px;">Buy</button>
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
                description: 'Reliable compact car, great for daily commuting'
            },
            {
                id: 'toyota_camry_2021',
                name: '2021 Toyota Camry',
                emoji: '🚙',
                price: 28000,
                maintenance: 200,
                description: 'Mid-size sedan with excellent fuel economy'
            },
            {
                id: 'bmw_3_series_2022',
                name: '2022 BMW 3 Series',
                emoji: '🏎️',
                price: 45000,
                maintenance: 350,
                description: 'Luxury sports sedan with premium features'
            },
            {
                id: 'ford_f150_2021',
                name: '2021 Ford F-150',
                emoji: '🚚',
                price: 35000,
                maintenance: 280,
                description: 'Full-size pickup truck, perfect for work'
            },
            {
                id: 'tesla_model_3_2023',
                name: '2023 Tesla Model 3',
                emoji: '⚡',
                price: 42000,
                maintenance: 120,
                description: 'Electric sedan with autopilot features'
            },
            {
                id: 'jeep_wrangler_2021',
                name: '2021 Jeep Wrangler',
                emoji: '🚐',
                price: 38000,
                maintenance: 320,
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
        
        // Don't allow selling the starter car if it's the only vehicle
        if (this.gameState.cars.length === 1 && vehicleId === 'starter_compact_1995') {
            throw new Error('Cannot sell your only vehicle. You need transportation!');
        }
        
        const car = this.gameState.cars[carIndex];
        const vehicleInfo = this.getAvailableVehicles().find(v => v.id === vehicleId);
        const sellPrice = Math.floor(car.value * 0.7); // Sell for 70% of current value
        
        this.gameState.portfolio.cash += sellPrice;
        this.gameState.cars.splice(carIndex, 1);
        
        this.recordCashFlow('income', sellPrice, `Sell ${vehicleInfo?.name || vehicleId}`, 'vehicle');
        this.log(`Sold ${vehicleInfo?.name || vehicleId} for $${sellPrice.toLocaleString()}`, 'success');
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
                
                div.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>${propertyInfo.emoji} ${propertyInfo.name}</strong>
                            <div style="font-size: 0.9em; color: #666;">
                                Value: $${property.value.toLocaleString()} | Maintenance: $${property.maintenance}/month
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
                        Price: $${property.price.toLocaleString()} | Maintenance: $${property.maintenance}/month
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div style="font-size: 0.85em; color: #666;">
                            ${property.description}
                        </div>
                        <button class="btn" onclick="handlePropertyBuy('${property.id}')" 
                                style="background: #28a745; padding: 5px 10px;">Buy</button>
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
                description: 'Compact downtown studio, perfect for young professionals'
            },
            {
                id: 'one_bedroom_condo',
                name: '1BR Condo',
                emoji: '🏢',
                price: 220000,
                maintenance: 950,
                description: 'Modern condo with amenities and city views'
            },
            {
                id: 'two_bedroom_house',
                name: '2BR House',
                emoji: '🏡',
                price: 320000,
                maintenance: 1200,
                description: 'Suburban house with yard and garage'
            },
            {
                id: 'three_bedroom_house',
                name: '3BR Family House',
                emoji: '🏘️',
                price: 450000,
                maintenance: 1500,
                description: 'Spacious family home in good neighborhood'
            },
            {
                id: 'luxury_penthouse',
                name: 'Luxury Penthouse',
                emoji: '🏰',
                price: 800000,
                maintenance: 2500,
                description: 'Premium penthouse with panoramic city views'
            },
            {
                id: 'vacation_cabin',
                name: 'Mountain Cabin',
                emoji: '🏔️',
                price: 280000,
                maintenance: 600,
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
    
    isCrypto(symbol) {
        return ['BTC', 'ETH', 'LTC', 'USDC'].includes(symbol);
    }
    
    getStockPrice(symbol) {
        const key = `${this.gameState.currentYear}-${this.gameState.currentMonth.toString().padStart(2, '0')}`;
        return this.stockPrices[symbol]?.[key] || 100;
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
            const price = this.stockPrices[symbol]?.[key] || 100;
            
            history.push({
                date: `${this.getMonthName(month)} ${year}`.substring(0, 6),
                price: price
            });
        }
        
        return history;
    }
    
    getCryptoPrice(symbol) {
        const key = `${this.gameState.currentYear}-${this.gameState.currentMonth.toString().padStart(2, '0')}`;
        return this.cryptoPrices[symbol]?.[key] || 1;
    }
    
    generateMockStockPrices() {
        const stocks = {
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
                    const volatility = (Math.random() - 0.5) * 0.1;
                    currentPrice *= (1 + config.trend + volatility);
                    const key = `${year}-${month.toString().padStart(2, '0')}`;
                    prices[symbol][key] = Math.max(1, currentPrice);
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
    
    updateUI() {
        document.getElementById('age').textContent = this.gameState.ageYears;
        document.getElementById('cash').textContent = `$${this.gameState.portfolio.cash.toFixed(0)}`;
        document.getElementById('net-worth').textContent = `$${this.calculateNetWorth().toFixed(0)}`;
        document.getElementById('date').textContent = `${this.getMonthName(this.gameState.currentMonth)} ${this.gameState.currentYear}`;
        
        if (this.gameState.professionId) {
            const profession = this.professions[this.gameState.professionId];
            document.getElementById('profession').textContent = `${profession.title} ($${Math.round(this.gameState.grossAnnual / 1000)}k/yr)`;
        } else {
            document.getElementById('profession').textContent = 'Choose Profession';
        }
        
        document.getElementById('happiness').textContent = `${this.gameState.happiness} / 1000`;
        
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
                const value = shares * price;
                const div = document.createElement('div');
                div.className = 'asset-item';
                div.innerHTML = `
                    <span class="asset-name">${symbol} (${shares} shares)</span>
                    <span class="asset-value">$${value.toFixed(2)}</span>
                `;
                stocksList.appendChild(div);
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
                div.innerHTML = `
                    <span class="asset-name">${property.id.replace(/_/g, ' ')}</span>
                    <span class="asset-value">$${property.value.toFixed(2)}</span>
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
        
        const stockSymbols = ['AAPL', 'MSFT', 'NVDA', 'AMZN', 'GOOGL'];
        stockSymbols.forEach(symbol => {
            const price = this.getStockPrice(symbol);
            const div = document.createElement('div');
            div.className = 'stock-item';
            div.innerHTML = `
                <span class="stock-symbol">${symbol}</span>
                <span class="stock-price">$${price.toFixed(2)}</span>
            `;
            stocksContainer.appendChild(div);
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