# Product Requirements Document (PRD): Nationwide Philippines Fare Calculator App

## Document Information
- **Product Name**: PH Fare Calculator (working title)
- **Version**: 2.0 (Consolidated Final Draft)
- **Date**: November 20, 2025
- **Author**: MasuRii
- **Status**: Ready for Development
- **Purpose**: To build a cross-platform mobile application that provides accurate fare estimates for public transport across the Philippines. It serves as a budgeting and anti-scam tool for tourists, expats, and locals, addressing the unique challenges of an archipelagic transport system.

## 1. Executive Summary
The PH Fare Calculator is a Flutter-based mobile app designed to fill the gap between city-specific transit apps (like Sakay.ph) and the lack of information in the provinces. Unlike navigation apps that focus on "How to get there," this app focuses on "How much it costs."

It solves the technical complexity of the Philippines' geography using a **Hybrid Calculation Engine**: combining distance-based formulas for road traffic (Jeeps, Taxis) with static database lookups for fixed lines (Trains, Ferries). Key differentiators include specific "Scam Protection" indicators for tourists and "Offline Reference" capabilities.

## 2. Target Audience & Personas
- **Primary Users**: Tourists, Expats, and "Local Migrants" (e.g., students moving to the city).
- **Personas**:
  - **Tourist Alex**: 28, US Backpacker. Needs to know if the taxi meter is riggged or if the tricycle driver is overcharging. **Feature Need**: "Scam Detector" / Fair Price Range.
  - **Expat Maria**: 35, relocator to Davao. Wants to compare the cost of a Yellow Taxi vs. White Taxi vs. Grab/Van from the airport. **Feature Need**: Multi-mode price comparison.
  - **Local Newbie Juan**: 20, student. Needs the cheapest way to get home to the province. **Feature Need**: Bus vs. Jeepney cost analysis.

## 3. Business Objectives
- **Adoption**: 10,000 downloads in first 6 months via organic travel forums and expat groups.
- **Trust**: Establish the app as the "Check price before you ride" standard.
- **Sustainability**: Operate on free tier APIs (OpenStreetMap/OSRM) initially, with architecture ready to scale to paid tiers (Mapbox) or self-hosted solutions if traffic spikes.
- **Data Strategy**: Long-term goal to crowd-source fare data (Waze-style) to improve provincial accuracy.

## 4. Key Features & Logic
### A. Core User Features
1.  **Smart Nationwide Search**:
    *   Input fields must support "City, Province" disambiguation (e.g., *San Jose, Antique* vs. *San Jose, Nueva Ecija*).
2.  **The "Scam Detector" (Fair Price Indicator)**:
    *   Displays results in a visual range.
    *   **Green**: Standard Regulated Fare.
    *   **Yellow**: Traffic/Peak adjustment.
    *   **Red**: "Tourist Trap" threshold (e.g., >30% above regulatory rate).
3.  **Comparison View**: Side-by-side cost of Luxury (Taxi/Grab) vs. Economy (Jeep/Bus).
4.  **Offline Reference**:
    *   Users cannot calculate *new* routes offline, but can view **Saved Routes** and **Static Cheat Sheets** (e.g., "Taxi Meter Guide," "LRT Station Matrix").

### B. Hybrid Calculation Engine (The "Brain")
The app uses two distinct methods depending on the transport mode selected.

#### **Method 1: Dynamic Formula (Distance-Based)**
*Used for: Jeeps, Buses, Taxis, Vans.*
*   **Input**: Origin/Dest Geocoordinates from OSRM.
*   **Logic**: `(Road Distance x 1.15 Variance) * Rate + Base Fare`
    *   *Note*: The 1.15 multiplier accounts for public transport taking longer/winding routes compared to the direct car routes returned by OSRM.

#### **Method 2: Static Matrix (Lookup Table)**
*Used for: Trains and Inter-island Ferries.*
*   **Input**: Specific Station or Port names.
*   **Logic**: Match Origin/Dest to a JSON database of fixed prices. Distance APIs are unreliable here (e.g., rail distance ≠ road distance; ferry price ≠ distance).

## 5. Detailed Transport Modes & Rates (Data Source: Nov 2025)
*App must allow remote updates (via Firebase) to these values without app store re-submission.*

| Category | Mode | Sub-Type | Base Fare (₱) | Per KM / Add-on | Key Logic/Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Road** | **Jeepney** | Traditional | 14.00 | 1.75 | Standard formula. +20% toggle for Provinces. |
| **Road** | **Jeepney** | Modern (PUJ) | 16.00 | 2.00 | Aircon standard. Higher base. |
| **Road** | **Bus** | Traditional | 13.00 | 2.00 - 2.20 | Provincial Buses: Min 15 + 2.20/km. |
| **Road** | **Bus** | Aircon | 15.00 | 2.50 | **User Input**: "Aircon" toggle required. |
| **Road** | **Taxi** | **White (Regular)** | 45.00 | ~13.50/km | Formula: Flagdown + (Dist/300m * 4). Includes wait time buffer. |
| **Road** | **Taxi** | **Yellow (Airport)** | **75.00** | **~20.00/km** | **Critical**: Higher flagdown & rate. Show this as default if Origin = Airport. |
| **Road** | **Van** | UV Express | 20.00 | 3.00 | Point-to-Point nature implies higher per-km rate. |
| **Road** | **Tricycle** | Local/Special | N/A | N/A | **Warning UI**: "Fares are negotiated (Pakyaw). Expect ₱20-50 per km." |
| **Rail** | **Train** | MRT-3 | 13.00 | Max 28.00 | **Matrix**: North Ave to Taft lookup. |
| **Rail** | **Train** | LRT-1 (Ext) | 16.25 | Max ~35.00 | **Matrix**: Includes new Cavite stations (Pitx, MIA, etc.). |
| **Rail** | **Train** | LRT-2 | 13.00 | Max 25.00 | **Matrix**: Antipolo to Recto lookup. |
| **Sea** | **Ferry** | RORO/FastCraft | N/A | Variable | **Matrix**: Top 20 routes (e.g., Batangas-Calapan: ~₱500). Others show "Check Operator". |

## 6. Functional Requirements & User Flows
1.  **Onboarding**: Splash screen with Language select (EN/Tagalog) + "Estimates Only" Disclaimer.
2.  **Search Flow**:
    *   User enters Origin/Dest.
    *   **Logic Check**:
        *   If Land-to-Land: Run OSRM API -> Apply Road Formulas.
        *   If Land-to-Land (Rail available): Check if points are near train stations -> Suggest Train Matrix.
        *   If Land-to-Sea (Island Crossing): Check Ferry Matrix -> If not found, show "Route requires Ferry - Estimate Unavailable."
3.  **Results Display**:
    *   Show "Recommended" (Cheapest or Fastest).
    *   Show breakdown: Base Fare + Distance Charge.
    *   "Share" button (Text/Image) to send estimate to friends.
4.  **Settings**:
    *   Toggle: **"Provincial Mode"** (Adds 10-20% variance to formulas for rural areas).
    *   Toggle: **"Traffic Factor"** (Low/Medium/High - adjusts time and wait-time charges for taxis).

## 7. Non-Functional Requirements
- **Accuracy**: Road estimates aim for ±15% accuracy of regulated meter/fare.
- **Latency**: Calculations under 2 seconds.
- **Offline Capabilities**: App must cache the "Base Fare" and "Matrix" JSONs locally (Hive/Isar) so users can look up *rates* even if they can't route *distances*.
- **Accessibility**: High contrast mode; VoiceOver support for visually impaired.
- **Scalability**: Backend abstraction layer to swap OSRM for Mapbox/Google if free limits are hit.

## 8. Technical Stack
- **Frontend**: Flutter (v3.16+).
- **Language**: Dart (v3.2+).
- **Mapping/Routing**:
  - **OpenStreetMap (OSM)** for map tiles (`flutter_map` package).
  - **OSRM (Open Source Routing Machine)** for distance calculation (starting with public demo servers, moving to self-hosted if needed).
- **Backend (Lightweight)**:
  - **Firebase Remote Config**: To store and update Fare Formulas/Matrices instantly.
  - **Firebase Analytics**: To track which routes are most searched.
- **Local Storage**: Hive (NoSQL) for saving favorite routes and offline data.

## 9. Assumptions & Risks
- **Assumption**: The "Yellow Taxi" rates remain stable at ₱75 flagdown through 2025.
- **Risk**: **Inter-Island Routing**. OSRM often fails to route across water.
    - *Mitigation*: If OSRM fails, the app catches the exception and asks the user: "Are you crossing islands? Please check our Ferry Guide."
- **Risk**: **Fuel Price Surges**. Sudden fare hikes by LTFRB.
    - *Mitigation*: In-app banner system controlled via Firebase to display "Warning: Fares increased by ₱2 today due to fuel."

## 10. Timeline (6 Weeks)
- **Week 1: Data Engineering**. Building the JSON matrices for Trains (Station-to-Station) and Ferries. Setting up the Fare Formulas.
- **Week 2: Core Dev**. Flutter project setup. OSRM API integration. Implementing the "Hybrid Engine."
- **Week 3: UI/UX**. Building the Input screens and the "Scam Detector" result cards.
- **Week 4: Refinement**. Adding the "Yellow Taxi" logic and "Provincial Toggle." Handling "No Route" errors.
- **Week 5: Offline & Testing**. Implementing Hive caching. Beta testing with local commuters.
- **Week 6: Deployment**. Play Store release. Marketing on Reddit (r/Philippines, r/travel).

## 11. Appendix: Future Scope (Post-Launch)
- **Crowd-Sourcing**: "Report your Fare" button to build a real-world database.
- **Multilingual**: Add Cebuano, Ilocano support.
- **Jeepney Route Mapping**: Community-driven mapping of specific jeepney routes (like Sakay.ph but for provinces).