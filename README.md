# SACCO Deposit Reconciliation & Exception Detection Model

## Business Context
Members deposit funds via digital QR-linked mobile forms, which tellers subsequently post to the operational ledger[cite: 2]. Manual reconciliation introduces critical financial risks: unposted deposits, double postings, and monetary amount mismatches[cite: 2]. This repository provides an automated T-SQL and Power BI solution to detect, classify, and audit deposit discrepancies while maintaining strict data privacy (PII-safe synthetic data).

## Tech Stack & Tools
* **Database Engine:** Microsoft SQL Server (T-SQL) / SSMS[cite: 1]
* **Visualization & Modeling:** Power BI Desktop (PL-300 Star Schema Standards)
* **Version Control:** Git & GitHub

## Data Privacy & Honesty Note
* **Synthetic Data Only:** All member names, branch details, QR references, and monetary amounts in this repository are entirely fabricated to mirror real-world SACCO structures without exposing sensitive personal identifiable information (PII)[cite: 1, 2].

## Setup Instructions
1. Clone the repository to your local machine:
   ```bash
   git clone [https://github.com/gikonyon/sacco-deposit-reconciliation.git](https://github.com/gikonyon/sacco-deposit-reconciliation.git)
