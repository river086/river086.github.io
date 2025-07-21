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
            happiness: 50,
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
        this.setupEventListeners();
        await this.loadProfessions();
        await this.loadEvents();
        this.showProfessionSelection();
    }
    
    showProfessionSelection() {
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
    
    startGame() {
        this.gameState.gameStarted = true;
        this.updateUI();
        const profession = this.professions[this.gameState.professionId];
        this.log(`Welcome to Vegas-Life! You are a 24-year-old ${profession.title} with $500 and a dream.`, 'info');
        this.log(`Your starting salary: $${this.gameState.grossAnnual.toFixed(0)}/year`, 'info');
        this.log('Use the "End Turn" button to advance to the next month.', 'info');
    }
    
    initializeProfession(professionId) {
        const profession = this.professions[professionId];
        
        this.gameState.grossAnnual = this.randomBetween(profession.salaryRange[0], profession.salaryRange[1]);
        this.gameState.fixedCosts = profession.fixedCosts.food + profession.fixedCosts.housing + 390; // utilities etc.
        
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
            
            if (selectedEvent.effects.happiness) {
                this.gameState.happiness = Math.max(0, Math.min(100, 
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
    
    executeCommand(commandText = null) {
        const command = commandText || document.getElementById('command-input').value.trim();
        if (!command) return;
        
        document.getElementById('command-input').value = '';
        this.log(`> ${command}`, 'info');
        
        const parts = command.toLowerCase().split(' ');
        const action = parts[0];
        
        try {
            switch (action) {
                case 'buy':
                    this.handleBuy(parts);
                    break;
                case 'sell':
                    this.handleSell(parts);
                    break;
                case 'deposit':
                    this.handleDeposit(parts);
                    break;
                case 'withdraw':
                    this.handleWithdraw(parts);
                    break;
                case 'portfolio':
                    this.showPortfolio();
                    break;
                case 'pass':
                    this.log('Skipping month actions...', 'info');
                    break;
                default:
                    this.log(`Unknown command: ${action}`, 'error');
            }
        } catch (error) {
            this.log(`Error: ${error.message}`, 'error');
        }
        
        this.updateUI();
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
            this.log(`Bought ${amount} ${symbol} for $${cost.toFixed(2)}`, 'success');
        } else {
            const price = this.getStockPrice(symbol);
            const cost = amount * price;
            
            if (this.gameState.portfolio.cash < cost) {
                throw new Error('Insufficient cash');
            }
            
            this.gameState.portfolio.cash -= cost;
            this.gameState.portfolio.stocks[symbol] = (this.gameState.portfolio.stocks[symbol] || 0) + amount;
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
            this.log(`Sold ${amount} ${symbol} for $${proceeds.toFixed(2)}`, 'success');
        } else {
            if (!this.gameState.portfolio.stocks[symbol] || this.gameState.portfolio.stocks[symbol] < amount) {
                throw new Error('Insufficient stock holdings');
            }
            
            const price = this.getStockPrice(symbol);
            const proceeds = amount * price;
            
            this.gameState.portfolio.cash += proceeds;
            this.gameState.portfolio.stocks[symbol] -= amount;
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
    
    isCrypto(symbol) {
        return ['BTC', 'ETH', 'LTC', 'USDC'].includes(symbol);
    }
    
    getStockPrice(symbol) {
        const key = `${this.gameState.currentYear}-${this.gameState.currentMonth.toString().padStart(2, '0')}`;
        return this.stockPrices[symbol]?.[key] || 100;
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
        
        document.getElementById('happiness').textContent = this.gameState.happiness;
        
        // Update progress bar to show current month
        const progressBar = document.getElementById('month-progress');
        if (this.gameState.gameStarted && !this.gameState.gameOver) {
            progressBar.textContent = `${this.getMonthName(this.gameState.currentMonth)} ${this.gameState.currentYear} - Take Actions`;
            progressBar.style.width = '100%';
        }
        
        // Update assets panel
        this.updateAssetsPanel();
    }
    
    async loadProfessions() {
        try {
            const response = await fetch('professions.xml');
            const xmlText = await response.text();
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlText, 'text/xml');
            
            const professionNodes = xmlDoc.querySelectorAll('profession');
            professionNodes.forEach(node => {
                const id = node.getAttribute('id');
                const profession = {
                    id: id,
                    title: node.querySelector('title').textContent,
                    salaryRange: [
                        parseInt(node.querySelector('salaryRange min').textContent),
                        parseInt(node.querySelector('salaryRange max').textContent)
                    ],
                    raise: parseFloat(node.querySelector('raise').textContent),
                    studentLoan: {
                        principal: parseInt(node.querySelector('studentLoan principal').textContent),
                        annualRate: parseFloat(node.querySelector('studentLoan annualRate').textContent),
                        termMonths: parseInt(node.querySelector('studentLoan termMonths').textContent)
                    },
                    fixedCosts: {
                        food: parseInt(node.querySelector('fixedCosts food').textContent),
                        housing: parseInt(node.querySelector('fixedCosts housing').textContent)
                    }
                };
                this.professions[id] = profession;
            });
            console.log('Loaded professions:', Object.keys(this.professions));
        } catch (error) {
            console.error('Error loading professions:', error);
            // Fallback to hardcoded professions if XML loading fails
            this.professions = {
                'teacher_elementary': {
                    id: 'teacher_elementary',
                    title: 'Elementary Teacher',
                    salaryRange: [45000, 85000],
                    raise: 0.05,
                    studentLoan: { principal: 22000, annualRate: 0.05, termMonths: 120 },
                    fixedCosts: { food: 600, housing: 1800 }
                },
                'software_dev': {
                    id: 'software_dev',
                    title: 'Software Developer',
                    salaryRange: [85000, 150000],
                    raise: 0.08,
                    studentLoan: { principal: 35000, annualRate: 0.05, termMonths: 120 },
                    fixedCosts: { food: 700, housing: 2200 }
                },
                'nurse': {
                    id: 'nurse',
                    title: 'Registered Nurse',
                    salaryRange: [55000, 95000],
                    raise: 0.06,
                    studentLoan: { principal: 28000, annualRate: 0.05, termMonths: 120 },
                    fixedCosts: { food: 650, housing: 1900 }
                }
            };
            console.log('Using fallback professions');
        }
    }
    
    async loadEvents() {
        try {
            const response = await fetch('events.xml');
            const xmlText = await response.text();
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlText, 'text/xml');
            
            const eventNodes = xmlDoc.querySelectorAll('event');
            eventNodes.forEach(node => {
                const effects = {};
                const effectsNode = node.querySelector('effects');
                if (effectsNode && effectsNode.children.length > 0) {
                    Array.from(effectsNode.children).forEach(child => {
                        effects[child.tagName] = parseInt(child.textContent);
                    });
                }
                
                const event = {
                    id: node.getAttribute('id'),
                    category: node.querySelector('category').textContent,
                    weight: parseFloat(node.querySelector('weight').textContent),
                    cooldown: parseInt(node.querySelector('cooldown').textContent),
                    costRange: [
                        parseInt(node.querySelector('costRange min').textContent),
                        parseInt(node.querySelector('costRange max').textContent)
                    ],
                    effects: effects,
                    description: node.querySelector('description').textContent,
                    detailedDescription: node.querySelector('detailedDescription').textContent
                };
                this.events.push(event);
            });
        } catch (error) {
            console.error('Error loading events:', error);
            // Fallback to hardcoded events if XML loading fails
            this.events = [
                {
                    id: 'travel_trip',
                    category: 'lifestyle',
                    weight: 0.5,
                    cooldown: 12,
                    costRange: [300, 1000],
                    effects: { happiness: 8 },
                    description: 'Weekend getaway',
                    detailedDescription: 'You decide to take a spontaneous weekend trip to recharge and explore new places.'
                },
                {
                    id: 'car_repair',
                    category: 'maintenance',
                    weight: 0.8,
                    cooldown: 6,
                    costRange: [200, 800],
                    effects: { happiness: -3 },
                    description: 'Car needs repairs',
                    detailedDescription: 'Your car has developed mechanical issues that require immediate attention.'
                },
                {
                    id: 'bonus',
                    category: 'income',
                    weight: 0.3,
                    cooldown: 24,
                    costRange: [-2000, -500],
                    effects: { happiness: 5 },
                    description: 'Work bonus!',
                    detailedDescription: 'Your hard work and dedication have been recognized with a performance bonus!'
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
            console.log('Using fallback events');
        }
    }
    
    setupEventListeners() {
        document.getElementById('command-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.executeCommand();
            }
        });
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
        this.gameState.properties.forEach(property => {
            const div = document.createElement('div');
            div.className = 'asset-item';
            div.innerHTML = `
                <span class="asset-name">${property.id.replace(/_/g, ' ')}</span>
                <span class="asset-value">$${property.value.toFixed(2)}</span>
            `;
            propertiesList.appendChild(div);
        });
        
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
    
    randomBetween(min, max) {
        return Math.random() * (max - min) + min;
    }
}

// Initialize game when page loads
let game;
window.addEventListener('DOMContentLoaded', () => {
    game = new SimLifeGame();
});