# MISSIONE DINAMICA IRAQ 2026 🇮🇶

Missione dinamica per **DCS World** ambientata in Iraq, scritta con **MOOSE 2026-03-31**.

---

## 🔵 Coalizione BLUE

### Basi aeree
| Base | Velivoli | Tipo slot |
|---|---|---|
| **Balad Airbase** | F-16C, F/A-18C, F-14B, F-4E, A-10C | CLIENT |
| **Al-Asad Airbase** | Aerei vintage | CLIENT |
| **Al-Taji Airport** | AH-64D Apache, UH-60 Cargo | CLIENT |

### Portaerei
| Carrier | Velivoli | TACAN | ICLS | Marshal | LSO |
|---|---|---|---|---|---|
| **CVN-71 ROOSEVELT** | F/A-18C Hornet | 71X CVN | CH 1 | 305.0 AM | 264.0 AM |
| **CVN-73 WASHINGTON** | F-14B Tomcat | 51X CVW | CH 3 | 307.0 AM | 265.0 AM |

### AWACS
| Callsign | Frequenza | TACAN | Orbita |
|---|---|---|---|
| **Darkstar** (E-3A) | 270.0 AM | 1X DAR | Golfo Persico / Kuwait |

---

## 🔴 Coalizione RED — CAP + GCI Dinamico MOOSE

| Base | Velivolo CAP | Velivolo GCI | Gruppo CAP | Gruppo GCI | EW |
|---|---|---|---|---|---|
| **H-3 Main Airbase** | MiG-29A | MiG-29A | `RedCAPH3` | `RedGCIH3` | `H3EW_01` |
| **Kirkuk Air Base** | MiG-23MLD | MiG-23MLD | `RedCAPKirkuk` | `RedGCIKirkuk` | `KirkukEW_01` |
| **Mosul Airport** | MiG-21Bis | MiG-21Bis | `RedCAPMosul` | `RedGCIMosul` | `MosulEW_01` |
| **Al Kut Airfield** | MiG-29A | MiG-29A | `RedCAPAlKut` | `RedGCIAlKut` | `AlKutEW_01` |

### Static Object RED richiesti per ogni base (8 totali)
| Base | Static #1 | Static #2 |
|---|---|---|
| H-3 | `RedAirWingH3CAP` | `RedAirWingH3GCI` |
| Kirkuk | `RedAirWingKirkukCAP` | `RedAirWingKirkukGCI` |
| Mosul | `RedAirWingMosulCAP` | `RedAirWingMosulGCI` |
| Al Kut | `RedAirWingAlKutCAP` | `RedAirWingAlKutGCI` |

---

## 📶 Frequenze radio complete

| Servizio | Frequenza | Note |
|---|---|---|
| AWACS Darkstar | 270.0 AM | Copertura teatro |
| Roosevelt Marshal | 305.0 AM | F/A-18C |
| Roosevelt LSO | 264.0 AM | F/A-18C |
| Washington Marshal | 307.0 AM | F-14B |
| Washington LSO | 265.0 AM | F-14B |
| GCI RED H-3 | — | MOOSE GCICAP automatico |

---

## 📁 Struttura script

```
/scripts
  missione_iraq.lua     ← Script principale (AIRBOSS + messaggi briefing)
  H3GCI.lua             ← GCI/CAP H-3 (MiG-29A) — MOOSE SQUADRON v1.4
  KirkukGCI.lua         ← GCI/CAP Kirkuk (MiG-23MLD) — MOOSE SQUADRON v1.2
  MosulGCI.lua          ← GCI/CAP Mosul (MiG-21Bis) — MOOSE SQUADRON v1.3
  AlKutGCI.lua          ← GCI/CAP Al Kut (MiG-29A) — MOOSE SQUADRON v1.2
  AlKutCapture.lua      ← Zona cattura dinamica Al Kut — v1.0 ★ NUOVO
  IraqAwacs.lua         ← AWACS BLU Darkstar (E-3A) v1.0
  IraqEvents.lua        ← Sistema eventi missione
```

---

## ⚙️ Trigger nel Mission Editor

| N° | Condizione | Azione | File |
|---|---|---|---|
| 1 | MISSION START | DO SCRIPT FILE | `Moose_.lua` |
| 2 | TIME MORE 5 | DO SCRIPT FILE | `missione_iraq.lua` |
| 3 | TIME MORE 10 | DO SCRIPT FILE | `H3GCI.lua` |
| 4 | TIME MORE 10 | DO SCRIPT FILE | `KirkukGCI.lua` |
| 5 | TIME MORE 10 | DO SCRIPT FILE | `MosulGCI.lua` |
| 6 | TIME MORE 10 | DO SCRIPT FILE | `AlKutGCI.lua` |
| 7 | TIME MORE 10 | DO SCRIPT FILE | `AlKutCapture.lua` |
| 8 | TIME MORE 10 | DO SCRIPT FILE | `IraqAwacs.lua` |
| 9 | TIME MORE 10 | DO SCRIPT FILE | `IraqEvents.lua` |
| 10 | TIME MORE 43200 | DO SCRIPT | `net.load_next_mission()` |

> ⚠️ `AlKutCapture.lua` va caricato **dopo** `AlKutGCI.lua` (stesso TIME MORE 10, trigger separato).
> ⚠️ La missione va inserita **due volte** nella playlist del server per garantire il restart corretto.

---

## 🛠️ Requisiti ME — Checklist completa

### Trigger Zone (6)
- [ ] `H3Border` — circolare **106km** centrata su H-3
- [ ] `KirkukBorder` — circolare **106km** centrata su Kirkuk
- [ ] `MosulBorder` — circolare **106km** centrata su Mosul
- [ ] `AlKutBorder` — circolare **106km** centrata su Al Kut
- [ ] `AWACSZone` — zona orbita AWACS sul Golfo
- [ ] `AlKutCaptureZone` — circolare **8km** centrata su Al Kut ★ NUOVO

### Static Object RED (8) — entro 5km dalla pista
- [ ] `RedAirWingH3CAP` e `RedAirWingH3GCI` ad H-3
- [ ] `RedAirWingKirkukCAP` e `RedAirWingKirkukGCI` a Kirkuk
- [ ] `RedAirWingMosulCAP` e `RedAirWingMosulGCI` a Mosul
- [ ] `RedAirWingAlKutCAP` e `RedAirWingAlKutGCI` ad Al Kut

### Gruppi template RED (8) — Late Activation, Hot Start
- [ ] `RedCAPH3` e `RedGCIH3` — 2× MiG-29A ad H-3
- [ ] `RedCAPKirkuk` e `RedGCIKirkuk` — 2× MiG-23MLD a Kirkuk
- [ ] `RedCAPMosul` e `RedGCIMosul` — 2× MiG-21Bis a Mosul
- [ ] `RedCAPAlKut` e `RedGCIAlKut` — 2× MiG-29A ad Al Kut

### Gruppi template GROUND — Zona Cattura Al Kut ★ NUOVO
- [ ] `RedGroundAlKut` — RED, Late Activation, **dentro** `AlKutCaptureZone`: 2× T-72B + 2× BTR-80, nessun waypoint
- [ ] `BlueConvoyAlKut` — BLUE, Late Activation, **~30km a SUD** di Al Kut: 2× M1A2 + 2× M2 Bradley, waypoint verso Al Kut
- [ ] `BlueAAAlKut` — BLUE, Late Activation, dentro la zona: 1× Avenger + 1× MANPAD (template, spawna lo script)
- [ ] `RedReinforcementsAlKut` — RED, Late Activation, **~15km a NORD** di Al Kut: 2× T-72B + 2× BMP-1 (rinforzi on-demand)

### Unità EW RED (4) — attive da subito (NO Late Activation)
- [ ] `H3EW_01` — 1L13 EWR ad H-3
- [ ] `KirkukEW_01` — 1L13 EWR a Kirkuk
- [ ] `MosulEW_01` — 1L13 EWR a Mosul
- [ ] `AlKutEW_01` — 1L13 EWR ad Al Kut

### Unità BLUE
- [ ] `CVN-71 ROOSEVELT` — portaerei nel Golfo
- [ ] `CVN-73 WASHINGTON` — portaerei nel Golfo
- [ ] `BLUE_AWACS_01` — E-3A (Late Activation ON)

---

## 🚧 Stato sviluppo

- [x] Basi BLUE definite (Balad, Al-Asad, Al-Taji)
- [x] Portaerei con AIRBOSS (Roosevelt 71X, Washington 51X)
- [x] CAP + GCI RED dinamico MOOSE — 4 basi
- [x] AWACS BLUE Darkstar 270.0 AM
- [x] Restart automatico ogni 12 ore
- [x] Fix COHORT→SQUADRON su tutti i GCI
- [x] Fix raggio detection 100km→60km
- [x] Fix TACAN Washington 73X→51X
- [x] Border zones allargate a 106km
- [x] Fix errore sintassi MosulGCI (cooldown) — v1.3
- [x] Zona cattura dinamica Al Kut (AlKutCapture.lua) — v1.0
- [ ] Zone di cattura per H-3, Kirkuk, Mosul
- [ ] CSAR con elicotteri

---

## 📋 Changelog

| Data | Versione | Modifica |
|---|---|---|
| 13 Apr 2026 | 1.6 | Aggiunge AlKutCapture.lua v1.0: zona cattura dinamica Al Kut con convoglio BLUE, difesa RED, rinforzi, contrattacco e integrazione GCI |
| 13 Apr 2026 | 1.5 | Fix MosulGCI: errore sintassi riga cooldown — v1.3 |
| 13 Apr 2026 | 1.4 | Border zones allargate 80km→106km su tutti i GCI |
| 12 Apr 2026 | 1.3 | Fix COHORT→SQUADRON H3GCI, raggio detection 100→60km tutti GCI, TACAN Washington 73X→51X |
| 11 Apr 2026 | 1.2 | Fix Roosevelt AIRBOSS, GCI Kirkuk e Mosul avviati |
| 11 Apr 2026 | 1.1 | Setup iniziale GCI/CAP sistema 4 basi |

---

## 🛠️ Requisiti software
- DCS World con mappa **Iraq**
- Moduli: F-16C, F/A-18C, F-14B, A-10C, AH-64D, F-4E, Supercarrier
- MOOSE **2026-03-31** ([download](https://github.com/FlightControl-Master/MOOSE_INCLUDE))
