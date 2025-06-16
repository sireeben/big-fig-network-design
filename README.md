# Supply Chain Network Design Optimization – BigFig Case Study

## Overview
This project focuses on optimizing the supply chain network design for a manufacturing company, **BigFig**, using **mixed-integer linear programming (MILP)**. The goal was to **minimize total transportation costs** while meeting customer service level requirements and plant capacity constraints.

The project was developed as part of the **Manufacturing Systems and Supply Chain Design course at MIT** and explores practical network optimization strategies under various real-world constraints, including demand variability, capacity expansion opportunities, and regulatory impacts (such as the I-10 rule).

---

## Problem Statement
BigFig operates a network of bottling plants and serves a geographically diverse customer base. The challenge was to:
- **Minimize transportation distance (truck miles)**
- Meet all customer demand within plant capacity limits
- Explore the impact of regulatory constraints (I-10 rule in Florida)
- Evaluate the flexibility and robustness of the network under different demand scenarios

---

## Key Contributions
- Developed an **optimization model in Julia** using MILP.
- Simulated **different network design scenarios** incorporating demand growth, regulatory changes, and service level requirements.
- Conducted **sensitivity analysis** on demand variability and plant utilization.
- Provided **data-driven recommendations** including plant relocation, capacity expansion, and policy trade-offs.

---

## Tools and Technologies
- **Language:** Julia
- **Optimization Approach:** Mixed-Integer Linear Programming (MILP)
- **Scenario Planning:** Multi-case simulation to explore network flexibility and resilience

---

## Key Findings
- Relocating production to Fort Worth, TX and Orlando, FL can result in substantial transportation savings.
- Regulatory flexibility (lifting the I-10 constraint) could save approximately **200,000 truck miles per year.**
- The proposed network structure is **robust to demand fluctuations,** with sensitivity analysis showing manageable increases in truck miles under higher demand scenarios.

---
