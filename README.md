# ⚾ Major League Baseball SQL Analytics

This project analyses Major League Baseball data using advanced SQL techniques. It demonstrates real-world querying skills, analytical thinking, and data storytelling using SQL only.

## 📌 Skills Demonstrated

- Joins (INNER, LEFT)
- Aggregations & Grouping
- CTEs & Subqueries
- Window Functions (`RANK()`, `ROW_NUMBER()`, `LAG`)
- Case Statements
- Temporal Filtering
- Binning & Bucketing (`FLOOR(year/10)*10`)
- Business Insights using SQL

## 📂 Sections

### 🏫 1. School Analysis
- How many schools produced MLB players each decade?
- Top schools that produced the most players
- Top 3 schools per decade using `ROW_NUMBER()`

### 💰 2. Salary Analysis
- Top 20% teams by average annual salary using `NTILE()`
- Cumulative team spending over years
- When did each team surpass $1B spend?

### 🦳 3. Player Career Analysis
- Calculate age at debut, final game, and career length
- Players who started & ended on the same team
- Players with careers over 10 years

### ⚖️ 4. Player Comparison Analysis
- Players with same birthday
- % of players batting right/left/both per team
- Height & weight trends by debut decade

## 🗃️ Data
Pre-loaded into MySQL with the following schema:

- `players(playerID, name, birth info, debut, finalGame, etc.)`
- `salaries(yearID, teamID, playerID, salary)`
- `schools(playerID, schoolID, yearID)`
- `school_details(schoolID, name_full, city, state, country)`

## 📊 Example Output

- **Top 5 Schools Producing Players**  
```sql
SELECT sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
FROM schools s
JOIN school_details sd ON s.schoolID = sd.schoolID
GROUP BY sd.name_full
ORDER BY num_players DESC
LIMIT 5;
```

- **Cumulative Spend Over Time (in $M)**  
```sql
SELECT yearID, teamID, 
       SUM(salary) OVER(PARTITION BY teamID ORDER BY yearID) / 1e6 AS cumulative_spend_millions
FROM salaries;
```

- **Top 20% of teams in terms of average annual spending**
```sql
WITH ts AS (
    SELECT yearID, teamID, SUM(salary) AS total_spend
    FROM salaries
    GROUP BY yearID, teamID
),
nt AS (
    SELECT teamID, AVG(total_spend) AS avg_spend,
           NTILE(5) OVER (ORDER BY AVG(total_spend) DESC) AS pct
    FROM ts
    GROUP BY teamID
)
SELECT teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions
FROM nt
WHERE pct = 1;
```

## 💡 Insight Highlights

- USC produced the most MLB players across decades
- Several teams hit $1B in cumulative salary post-2000s
- Avg player height/weight peaked in the 1990s
- 50+ players had same birthdays across years

## 🧠 Learnings

This project helped reinforce best practices in:
- Writing modular SQL scripts
- Using analytics functions to find patterns
- Cleaning and preparing large datasets for analysis
- Telling data stories with SQL only

---
