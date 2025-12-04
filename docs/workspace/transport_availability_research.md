# Public Transportation Availability in the Philippines by Region

**Date:** December 4, 2025
**Status:** Complete

## Executive Summary
This report outlines the geographic availability of various public transportation modes in the Philippines to support the "PH Fare Calculator" app's filtering features. Key findings indicate that while traditional jeepneys and tricycles are nearly ubiquitous, modern transit systems like the EDSA Carousel and Light Rail Transit (LRT/MRT) are strictly limited to Metro Manila. App-based motorcycle taxis (TNVS) are expanding but still limited to key urban centers, whereas informal "habal-habal" remain a staple in rural Visayas and Mindanao.

## 1. Transport Mode Geographic Availability

| Transport Mode | Coverage Type | Geographic Availability | Notes |
| :--- | :--- | :--- | :--- |
| **Jeepney (Traditional)** | Nationwide | All Regions (Luzon, Visayas, Mindanao) | ubiquitous in both urban and rural areas; serves as the primary mode of transport. |
| **Jeepney (Modern)** | Selected Cities | Major Urban Centers (Metro Manila, Cebu, Davao, etc.) | Rollout is ongoing under the PUV Modernization Program; presence is growing but not yet universal. |
| **EDSA Carousel** | Metro Manila Only | Metro Manila (EDSA Corridor) | Strictly limited to the EDSA busway route (Monumento to PITX). |
| **Train (LRT/MRT)** | Metro Manila Only | Metro Manila (LRT-1, LRT-2, MRT-3) | PNR also operates primarily in Luzon (Metro Manila to Laguna/Bicol), though currently limited due to construction. |
| **Bus (City)** | Major Cities | Metro Manila, Metro Cebu, Metro Davao | Operates within metropolitan boundaries. |
| **Bus (Provincial)** | Nationwide | Inter-regional (Connects Luzon, Visayas, Mindanao) | Connects major provinces; RORO buses cross island groups. |
| **UV Express** | Major Regions | Metro Manila, Luzon Provinces, Metro Cebu, Davao | Point-to-point style service; common in urban centers and for commuting from nearby provinces to metros. |
| **Tricycle** | Nationwide | All Municipalities/Cities | Regulated by LGUs; serves local, short-distance routes everywhere. |
| **Taxi (White)** | Major Cities | Metro Manila, Baguio, Cebu, Davao, Iloilo, Bacolod | Generally available only in highly urbanized cities. |
| **TNVS (Car)** | Major Cities | Metro Manila, Cebu, Pampanga, Bacolod, Iloilo, Davao, CDO | Grab is the dominant player; strictly urban coverage. |
| **TNVS (Motorcycle)** | Selected Cities | Metro Manila, Metro Cebu, CDO | Angkas, JoyRide, Move It operate in specific allowed pilot areas only. |
| **Habal-habal** | Nationwide (Informal)| Rural Areas, Visayas, Mindanao, Upland Luzon | Informal motorcycle taxis; dominant in areas without tricycles or jeepneys. |
| **Ferry / Boat** | Nationwide | Inter-island | Critical for connecting islands in Visayas and Mindanao (e.g., Cebu-Bohol, Iloilo-Bacolod). |

## 2. Detailed Regional Restrictions

### A. EDSA Carousel (Busway)
*   **Region:** Metro Manila (National Capital Region)
*   **Route:** Exclusive median lane along EDSA, stretching from **Monumento (Caloocan)** in the north to **PITX (Parañaque)** in the south.
*   **Key Stops:** North Avenue, Quezon Avenue, Santolan, Ortigas, Guadalupe, Buendia, Ayala, Taft Avenue.
*   **Availability:** 24/7 service.
*   **Status:** **NOT** available in Visayas or Mindanao.

### B. Train Systems (LRT/MRT/PNR)
*   **LRT-1 (Light Rail Transit Line 1):**
    *   **Region:** Metro Manila (Luzon)
    *   **Route:** Baclaran (Pasay/Parañaque) to Roosevelt/FPJ (Quezon City), extending to Cavite (ongoing).
*   **LRT-2 (Light Rail Transit Line 2):**
    *   **Region:** Metro Manila (Luzon)
    *   **Route:** Recto (Manila) to Antipolo (Rizal).
*   **MRT-3 (Metro Rail Transit Line 3):**
    *   **Region:** Metro Manila (Luzon)
    *   **Route:** EDSA corridor, North Avenue to Taft Avenue.
*   **PNR (Philippine National Railways):**
    *   **Region:** Luzon Only.
    *   **Route:** Metro Manila to Laguna/Quezon (Bicol Express pending full revival).
*   **Visayas/Mindanao Status:** No operational public train systems exist in Visayas or Mindanao (Mindanao Railway Project is still in planning/early stages).

### C. Motorcycle Taxis: Formal vs. Informal
1.  **TNVS (App-based: Angkas, JoyRide, Move It):**
    *   **Legal Status:** Authorized Pilot Study.
    *   **Coverage:** Strictly limited to **Metro Manila**, **Metro Cebu**, and **Cagayan de Oro**.
    *   **Pricing:** Metered/App-calculated.
2.  **Habal-habal (Informal):**
    *   **Legal Status:** Unregulated / Informal.
    *   **Coverage:** Ubiquitous in **rural areas**, mountain provinces, and secondary cities in **Visayas and Mindanao** (e.g., Dumaguete, Tagbilaran, General Santos).
    *   **Pricing:** Negotiated ("Pakyaw") or informal fixed rates.

### D. Jeepneys: Traditional vs. Modern
*   **Traditional Jeepneys:** Still the dominant force nationwide. No restrictions; they operate in every province.
*   **Modern Jeepneys (PUVMP):**
    *   **Metro Manila:** High penetration on major rationalized routes.
    *   **Cebu & Davao:** Growing presence (e.g., Beep in Cebu).
    *   **Rural Areas:** Low penetration; rare in remote municipalities.

### E. Provincial Buses & RORO
*   **Provincial Buses:** Operate inter-regionally.
*   **RORO (Roll-on, Roll-off):** Crucial for "Nautical Highway" routes connecting Luzon -> Visayas -> Mindanao.
    *   **Eastern Nautical Highway:** Manila -> Bicol -> Samar -> Leyte -> Surigao.
    *   **Central Nautical Highway:** Manila -> Bicol -> Masbate -> Cebu -> Bohol -> CDO.
    *   **Western Nautical Highway:** Manila -> Batangas -> Mindoro -> Panay -> Negros -> Zamboanga.

## 3. Configuration Data Structure Recommendation

This data can be transformed into a JSON configuration for the `LocationFilter` feature:

```json
{
  "transport_modes": [
    {
      "id": "jeepney_traditional",
      "name": "Traditional Jeepney",
      "regions": ["ALL"]
    },
    {
      "id": "jeepney_modern",
      "name": "Modern Jeepney",
      "regions": ["NCR", "CEBU", "DAVAO", "MAJOR_CITIES"]
    },
    {
      "id": "edsa_carousel",
      "name": "EDSA Carousel",
      "regions": ["NCR"]
    },
    {
      "id": "train",
      "name": "LRT / MRT / PNR",
      "regions": ["NCR", "CALABARZON"]
    },
    {
      "id": "tricycle",
      "name": "Tricycle",
      "regions": ["ALL"]
    },
    {
      "id": "motorcycle_taxi_app",
      "name": "Motorcycle Taxi (App)",
      "regions": ["NCR", "CEBU", "CDO"]
    },
    {
      "id": "habal_habal",
      "name": "Habal-habal",
      "regions": ["RURAL", "VISAYAS", "MINDANAO"]
    }
  ]
}
```

## 4. Source Verification
*   **EDSA Carousel:** Verified as Metro Manila specific (Monumento to PITX).
*   **Trains:** Confirmed Luzon-only (NCR + nearby provinces). No trains in VisMin.
*   **Habal-habal:** Confirmed as the primary alternative in regions where formal TNVS is absent.