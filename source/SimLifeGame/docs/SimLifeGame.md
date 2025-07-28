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
}
```

*At start*: `grossAnnual = rnd(range)`.

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

## 6 · Events (53 cards)

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

*Monthly draw*: build `eligiblePool`, add `no_event`, weighted pick.

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

### 9.8 UI Smoke (via Cypress)

* Load PWA offline → dashboard shows age 24.
* Click *Buy Car* → trade-in pop-up shows starter value \$2 910.
* Progress bar counts down 60 s → triggers month end.

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
