# Data Models for PH Fare Calculator

This document outlines the JSON data structures for the Hybrid Calculation Engine, as specified in the Product Requirements Document. These models are designed to be stored in Firebase Remote Config for easy updates without requiring an app store submission.

## 1. Fare Formulas (Distance-Based)

This structure is used for transport modes where the fare is calculated based on distance traveled. This includes Jeepneys, Buses, Taxis, and Vans.

### JSON Structure

```json
{
  "fare_formulas": {
    "jeepney": [
      {
        "sub_type": "Traditional",
        "base_fare": 14.00,
        "per_km_rate": 1.75,
        "provincial_multiplier": 1.20,
        "notes": "Standard formula. +20% toggle for Provinces."
      },
      {
        "sub_type": "Modern (PUJ)",
        "base_fare": 16.00,
        "per_km_rate": 2.00,
        "notes": "Aircon standard. Higher base."
      }
    ],
    "bus": [
      {
        "sub_type": "Traditional",
        "base_fare": 13.00,
        "per_km_rate": 2.20,
        "minimum_fare": 15.00,
        "notes": "Provincial Buses: Min 15 + 2.20/km."
      },
      {
        "sub_type": "Aircon",
        "base_fare": 15.00,
        "per_km_rate": 2.50,
        "notes": "User Input: 'Aircon' toggle required."
      }
    ],
    "taxi": [
      {
        "sub_type": "White (Regular)",
        "base_fare": 45.00,
        "per_km_rate": 13.50,
        "notes": "Formula: Flagdown + (Dist/300m * 4). Includes wait time buffer."
      },
      {
        "sub_type": "Yellow (Airport)",
        "base_fare": 75.00,
        "per_km_rate": 20.00,
        "notes": "Critical: Higher flagdown & rate. Show this as default if Origin = Airport."
      }
    ],
    "van": [
      {
        "sub_type": "UV Express",
        "base_fare": 20.00,
        "per_km_rate": 3.00,
        "notes": "Point-to-Point nature implies higher per-km rate."
      }
    ]
  }
}
```

### Field Descriptions

-   `sub_type`: (String) The specific type of the transport mode (e.g., "Traditional", "Modern (PUJ)").
-   `base_fare`: (Number) The initial charge when a ride starts (flag-down rate).
-   `per_km_rate`: (Number) The cost for each kilometer traveled.
-   `provincial_multiplier`: (Number, Optional) A multiplier to adjust fares for provincial routes.
-   `minimum_fare`: (Number, Optional) A minimum fare for certain routes (e.g., provincial buses).
-   `notes`: (String) Additional information or logic notes for the developers.

## 2. Static Matrix (Lookup Tables)

This structure is used for transport modes with fixed prices between specific origins and destinations, such as Trains (MRT, LRT) and Ferries.

### JSON Structure

```json
{
  "static_matrix": {
    "trains": {
      "MRT-3": [
        { "origin": "North Avenue", "destination": "Taft Avenue", "price": 28.00 },
        { "origin": "Taft Avenue", "destination": "North Avenue", "price": 28.00 }
      ],
      "LRT-1": [
        { "origin": "Baclaran", "destination": "Fernando Poe Jr.", "price": 35.00 },
        { "origin": "Fernando Poe Jr.", "destination": "Baclaran", "price": 35.00 }
      ],
      "LRT-2": [
        { "origin": "Antipolo", "destination": "Recto", "price": 25.00 },
        { "origin": "Recto", "destination": "Antipolo", "price": 25.00 }
      ]
    },
    "ferries": [
      {
        "origin": "Batangas",
        "destination": "Calapan",
        "price": 500.00,
        "operator": "Various",
        "notes": "Price is an estimate and can vary by operator."
      }
    ]
  }
}
```

### Field Descriptions

-   `origin`: (String) The starting point of the route (e.g., a specific train station or port).
-   `destination`: (String) The ending point of the route.
-   `price`: (Number) The fixed fare for the specified origin-destination pair.
-   `operator`: (String, Optional) The company operating the route, if applicable.
-   `notes`: (String, Optional) Any additional useful information about the route or fare.