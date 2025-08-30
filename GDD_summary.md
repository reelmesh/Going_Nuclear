# GDD Summary

## Vision & Gameplay
- **High Concept**: A satirical, turn-based grand strategy game inspired by the 1989 card game "Nuclear War."
- **Core Loop**: Manage resources, build an arsenal via a card-based system, and use various warfare tactics to be the last faction standing.
- **Phases**: 
  1. **Deterrence & Escalation**: Focus on espionage and InfoWar.
  2. **Open Conflict**: Direct military attacks are allowed.

## Factions
- **USA (Freedom Inc.)**: Unpredictable and aggressive, with economic sanction abilities.
- **Russia (The Iron Bear)**: Methodical and defensive, with a focus on counter-intelligence.
- **China (The Dragon Ascendant)**: Patient and expansionist, with economic manipulation capabilities.
- **North Korea (The Hermit Kingdom)**: Fanatical and unpredictable, with a high tolerance for population loss.
- **Other Factions**: UK, India, Pakistan, Iran, Israel.

## Cards
- **Categories**: Delivery, Payload, InfoWar, Utility, Defense.
- **Examples**:
  - **Delivery**: ICBM, SLBM, Strategic Bomber.
  - **Payload**: Standard Warhead, EMP Warhead, Dirty Bomb.
  - **InfoWar**: Viral Disinformation, Deepfake Scandal.
  - **Utility**: Intelligence Agency, Sabotage, Diplomatic Summit.
  - **Defense**: ABM Silos, Counter-Propaganda, Hardened Bunkers.

## Technical Details
- **Engine**: Godot 4.4.
- **UI**: 3D interactive console.
- **Singletons**: `GameManager`, `CardDatabase`, `FactionDatabase`, `Logger`, `EventBus`.
- **Data**: Game data is stored in `.tres` files (`data/cards` and `data/factions`).
- **AI**: Faction AI is driven by distinct personalities (e.g., Aggressive, Defensive).
