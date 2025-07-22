````markdown
# Vegas-Life (Single-Player) — **Game Spec for “Vibe Coding” Implementation**  
*Revision 1.4 ─ 2025-07-19*

---

## 1 · High-Level Summary
| Item | Description |
|------|-------------|
| **Goal** | Play through 25 years (2000-01 → 2025-12) in ≈ 30 minutes. Accumulate highest net-worth while avoiding **“cash < 0 for 6 consecutive months”**. |
| **Target** | Ages 8-16 (educational). Runs as PWA in Chrome/Safari. No server-side PII. |
| **Core Loop** | *1 minute = 1 game-month*.<br>`Salary → Fixed costs & Loans → Player actions → Event card → Month end`. |
| **Starting State** | Age **24**, cash $500, starter-car (1995 compact, $3 000), chosen *junior* profession (random salary), student loan (if any). |
| **Victory / Failure** | End of 2025-12 = final score screen · **Fail** when cash < 0 six months in a row. |

---

## 2 · Time & Progression
| Real-time | In-game | Hook |
|-----------|---------|------|
| **1 min** | **1 month** | 0-5 s Salary, 5-20 s Fixed costs, 20-55 s Player actions, 55-58 s Event, 58-60 s Wrap & autosave |
| 12 months | +1 **age** year | `ageYears += 1` |
| 300 months | Full run | End screen |

---

## 3 · Data Models (Type Script notation ≈)
```ts
type LoanKind = 'student'|'car'|'mortgage';
interface Loan {
  kind: LoanKind;
  balance: number;
  annualRate: number;   // 0.05 | 0.06
  termMonths: number;   // 120 | 60 | 360
  monthlyPayment: number;
}

interface CarHolding {
  id: string;           // catalog id
  value: number;        // market
  maintenance: number;  // /month
  loan?: Loan;          // car loan
}

interface PropertyHolding {
  id: 'condo'|'sf'|'luxury';
  value: number;        // market
  maintenance: number;  // /month
  rent: number;         // /month
  loan?: Loan;          // mortgage
  monthsHeld: number;
}

interface Portfolio {
  cash: number;
  bank: number;
  stocks: Record<string,number>;   // units
  bonds:  Record<string,number>;
  crypto: Record<string,number>;   // units
}

interface PlayerProfile {
  ageYears: number;      // starts 24
  professionId: string;
  grossAnnual: number;
  salaryFactor: number;  // promotions etc.
  fixedCosts: number;    // life + housing etc. (auto)
  happiness: number;
  loans: Loan[];
  cars: CarHolding[];
  properties: PropertyHolding[];
  portfolio: Portfolio;
  negativeCashStreak: number;
  pspSystem?: PSPSystem;  // PSP tracking (software dev only)
}

interface PSPSystem {
  enabled: boolean;
  totalProjects: number;
  completedProjects: number;
  totalTasks: number;
  completedTasks: number;
  totalHoursTracked: number;
  productivityScore: number;   // 0-100
  qualityScore: number;        // 0-100
  defectRate: number;          // defects per 1000 LOC
  consultingIncome: number;    // monthly bonus
  lastConsultingMonth: number; // cooldown
}
````

---

## 4 · Professions (JSON)

```jsonc
{
  "id": "teacher_elementary",
  "title": "Elementary Teacher (Junior)",
  "salaryRange": [45000, 85000],
  "raise": 0.05,
  "studentLoan": { "principal": 22000, "annualRate": 0.05, "termMonths": 120 },
  "fixedCosts": { "food": 600, "housing": 1800 }
},
{
  "id": "software_developer_psp",
  "title": "Software Developer (PSP Certified)",
  "salaryRange": [95000, 180000],
  "raise": 0.08,
  "studentLoan": { "principal": 35000, "annualRate": 0.06, "termMonths": 120 },
  "fixedCosts": { "food": 800, "housing": 2200 },
  "pspSystem": {
    "enabled": true,
    "productivityBonus": 0.15,
    "qualityBonus": 0.20,
    "projectSuccessRate": 0.85
  }
}
```

*At start*: `grossAnnual = rnd(range)`.

### 4.1 PSP-Enhanced Software Developer Career

The **PSP Certified Software Developer** profession includes access to the Personal Software Process system:

**PSP System Features:**
- **Project Tracking**: Monitor development projects with budget and timeline tracking
- **Task Management**: Hierarchical task organization with time tracking
- **Quality Metrics**: Track defects, code reviews, and quality improvements
- **Productivity Analytics**: Measure and improve development efficiency
- **Process Improvement**: Data-driven development process optimization

**Career Benefits:**
- 15% productivity bonus on all projects
- 20% higher code quality ratings
- 85% project success rate (vs 70% industry average)
- Access to high-paying contract work opportunities
- Bonus income from PSP consulting and training

---

## 5 · Finance Systems

### 5.1 Salary & Tax

`net = gross/12 − 24.5 % federal − 7.65 % FICA − 200 $ health`

### 5.2 Investments

| Class                                             | Pricing                            | Notes                          |
| ------------------------------------------------- | ---------------------------------- | ------------------------------ |
| **Stocks/Bonds/ETF**                              | Alpha Vantage 月收盤                  | commission 0 %                 |
| **Crypto** (BTC ’09-, ETH ’15, LTC ’13, USDC ’18) | CoinGecko 月線                       | 0.5 % fee                      |
| **Real Estate (Vegas)**                           | Case-Shiller LVXRNSA × multipliers | condo ×0.6, sf ×1, luxury ×1.8 |

### 5.3 Loans

`monthly = P·r/12 / (1−(1+r/12)^-n)`
*Student*: 5 %, 120 m. *Car*: 6 %, 60 m. *Mortgage*: 6 %, 360 m.

### 5.4 Fixed Costs Table

* Life (600) + Rent (1 800) + Phone 50 + Net 40 + Utilities 150 + Trash 20 + Gas 120 + Streaming 10 + Car maint (variable).

---

## 6 · Events (53 cards + PSP Events)

```jsonc
{
  "id": "travel_trip",
  "category": "lifestyle",
  "weight": 0.5,
  "cooldown": 12,
  "costRange": [300,1000],
  "effects": { "happiness": 8 }
}
```

### 6.1 PSP-Specific Events (Software Developer only)

```jsonc
{
  "id": "psp_conference",
  "category": "professional",
  "weight": 0.3,
  "cooldown": 24,
  "costRange": [1200, 2500],
  "effects": { 
    "productivityScore": 10,
    "qualityScore": 8,
    "happiness": 5,
    "networking": true
  }
},
{
  "id": "psp_certification_renewal",
  "category": "professional",
  "weight": 0.2,
  "cooldown": 36,
  "costRange": [500, 800],
  "effects": {
    "salaryFactor": 0.03,
    "consultingRate": 50
  }
},
{
  "id": "psp_consulting_opportunity",
  "category": "income",
  "weight": 0.4,
  "cooldown": 6,
  "incomeRange": [2000, 8000],
  "requirements": { "productivityScore": 70, "qualityScore": 65 },
  "effects": { "consultingIncome": "range" }
},
{
  "id": "project_success_bonus",
  "category": "income",
  "weight": 0.6,
  "cooldown": 3,
  "requirements": { "completedProjects": 1, "qualityScore": 80 },
  "incomeRange": [1000, 3000],
  "effects": { "happiness": 3, "bonus": "range" }
}
```

*Monthly draw*: build `eligiblePool`, add `no_event`, weighted pick. PSP events only available to `software_developer_psp` profession.

---

## 7 · Commands

| CLI Style                         | Example         | Internals              |
| --------------------------------- | --------------- | ---------------------- |
| `buy AAPL 20`                     | stocks          | uses month close price |
| `buy BTC 0.05`                    | crypto          | 0.5 % fee              |
| `finance car honda_civic_2000 25` | car loan        |                        |
| `finance house condo 30`          | mortgage        |                        |
| `sell NVDA 500`                   | partial sell    |                        |
| `deposit 1000` / `withdraw 300`   | bank            |                        |
| `pay loan 5000`                   | extra principal |                        |
| `portfolio`                       | print summary   |                        |
| `pass`                            | skip actions    |                        |

### 7.1 PSP System Commands (Software Developer only)

| PSP Command                       | Example                    | Effect                     |
| --------------------------------- | -------------------------- | -------------------------- |
| `psp project create "E-commerce"` | create project             | +productivity tracking     |
| `psp task add "User Auth" 8h`     | add task with estimate    | +time tracking             |
| `psp metric record time 6.5h`     | record development time    | +analytics data            |
| `psp metric record defects 3`     | record bugs found          | +quality tracking          |
| `psp report productivity`         | view productivity report   | show efficiency trends     |
| `psp report quality`              | view quality metrics       | show defect rates          |
| `psp dashboard`                   | PSP overview               | projects, tasks, metrics   |
| `psp consult`                     | freelance PSP consulting   | +$500-2000 bonus income    |

### 7.2 PSP Dashboard UI Interface

**Button Location**: Top-right corner next to Portfolio button (PSP Developer profession only)
**Button Style**: Blue gradient with PSP icon, text "PSP Dashboard"

**Dashboard Layout**:
```html
<div class="psp-dashboard-modal">
  <div class="header">
    <h2>Personal Software Process Dashboard</h2>
    <span class="close-btn">×</span>
  </div>
  
  <div class="stats-grid">
    <div class="stat-card productivity">
      <h3>Productivity Score</h3>
      <div class="score">{productivityScore}/100</div>
      <div class="trend">↗ +5 this month</div>
    </div>
    
    <div class="stat-card quality">
      <h3>Quality Score</h3>
      <div class="score">{qualityScore}/100</div>
      <div class="defect-rate">{defectRate} defects/1000 LOC</div>
    </div>
    
    <div class="stat-card projects">
      <h3>Projects</h3>
      <div class="count">{completedProjects}/{totalProjects}</div>
      <div class="success-rate">85% success rate</div>
    </div>
    
    <div class="stat-card income">
      <h3>Consulting Income</h3>
      <div class="amount">${consultingIncome}/month</div>
      <div class="next-opportunity">Next: {daysUntilConsulting} days</div>
    </div>
  </div>
  
  <div class="actions-panel">
    <button class="psp-btn create-project">New Project</button>
    <button class="psp-btn add-task">Add Task</button>
    <button class="psp-btn record-time">Record Time</button>
    <button class="psp-btn view-reports">View Reports</button>
  </div>
  
  <div class="recent-activity">
    <h4>Recent Activity</h4>
    <ul class="activity-log">
      <li>✅ Completed task: User Authentication (8h)</li>
      <li>📊 Recorded 6.5h development time</li>
      <li>🐛 Fixed 2 defects in E-commerce project</li>
      <li>💰 Earned $1,200 from consulting</li>
    </ul>
  </div>
</div>
```

**Responsive Design**: Scales down to mobile, converts to full-screen overlay on smaller devices.

---

## 8 · Failure & Game-Over

```
if (cash < 0) streak++; else streak = 0;
if (streak >= 6) gameOver('negative cash');
```

---

## 9 · Test Cases

### 9.1 Unit – Finance Utilities

| Case                      | Input                           | Expected          |
| ------------------------- | ------------------------------- | ----------------- |
| Calc monthly student loan | P=22000, r=5 %, n=120           | \$233.10 ±0.01    |
| Calc mortgage headroom    | price 262 000, fee 2 %, dp 20 % | headroom = 53 448 |

### 9.2 Unit – Salary Random

* Run `randomInt` 1 000 times for `software_dev` → min ≥ 85 k, max ≤ 150 k.

### 9.3 Unit – Event Draw

* All weights 0 ⇒ only `no_event` chosen.
* Cooldown blocks card for N months.

### 9.4 Integration – Negative Cash Fail

1. Set cash -1, streak 5.
2. End month with net -10 → streak 6 → expect `gameOver`.

### 9.5 Integration – Mortgage Workflow

1. cash = 90 000.
2. `finance house sf 40` → expect cash new ≈ 90 000−(146 k×1.02×0.4)=29 784.
3. Loans array has mortgage balance ≈ 89 … k.
4. Monthly payment added to fixed costs.

### 9.6 Scenario – Teacher Low-Salary Survival

1. Seed salary = \$45 k.
2. Play 24 months with `pass`.
3. Assert cash never < 0 (buffer small but positive).
4. Assert negativeCashStreak = 0 at end.

### 9.7 Scenario – Tech Boom Investor

1. seed salary = 150 k Software Dev.
2. 2000-01 buy NVDA 10 000.
3. Simulate to 2025-12 with monthly price table.
4. Expected net worth > \$2 M (ballpark).

### 9.8 Scenario – PSP Developer Career Path

1. Choose `software_developer_psp` profession, salary = $120k.
2. Month 1: `psp project create "Web Application"`.
3. Month 2-6: Add tasks and track time consistently.
4. Month 12: Check productivity score ≥ 75, quality score ≥ 70.
5. Month 18: Trigger `psp_consulting_opportunity` event.
6. Expected total income 25% higher than base software developer.

### 9.9 Unit – PSP Productivity Calculation

- Track 40 hours over 4 tasks, estimate vs actual within 10%.
- Expected productivity score: 85-90 range.
- Track 2 defects in 1000 LOC project.
- Expected quality score: 80-85 range.

### 9.10 UI Smoke (via Cypress)

* Load PWA offline → dashboard shows age 24.
* Click *Buy Car* → trade-in pop-up shows starter value \$2 910.
* Progress bar counts down 60 s → triggers month end.
* PSP Developer: Click *PSP Dashboard* button → opens PSP system interface.
* PSP Dashboard shows current projects, tasks, and productivity metrics.

---

## 10 · Open Items

1. **Dynamic Interest-Rate Events** – adjust existing mortgages.
2. **Insurance Module** – health / car / house.
3. **Multiplayer** – peer leaderboard.

---

> **End of Spec**
> All constants & JSON samples are authoritative for Vibe Coding implementation; update revision number upon any future spec change.

```
::contentReference[oaicite:0]{index=0}
```
