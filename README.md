# MISSIONE DINAMICA IRAQ 2026 🇮🇶

Missione dinamica per **DCS World** ambientata in Iraq, scritta con **MOOSE 2.9.17**.

---

## 🔵 Coalizione BLUE

### Basi aeree
| Base | Velivoli | Tipo slot |
|---|---|---|
| **Balad Airbase** | F-16C, F-18C, F-14B, F-4E, A-10C | CLIENT |
| **Al-Asad Airbase** | Aerei vintage | CLIENT |
| **Al-Taji Airport** | AH-64D Apache, UH-60 Cargo | CLIENT |

### Portaerei
| Carrier | Velivoli | TACAN | ICLS |
|---|---|---|---|
| **CNV-71 ROOSEVELT** | F-18C Hornet | 71X | CH 1 |
| **CNV-73 WASHINGTON** | F-14B Tomcat | 73X | CH 3 |

### AWACS
| Callsign | Frequenza | TACAN | Orbita |
|---|---|---|---|
| **Darkstar** (E-3A) | 270.0 AM | 1X DAR | Golfo Persico / Kuwait |

---

## 🔴 Coalizione RED — CAP Dinamico

| Base | Velivolo | Gruppo ME |
|---|---|---|
| H-3 Main Airbase | MiG-29A | `RED_MiG29_H3_01` |
| Kirkuk Air Base | MiG-23MLD | `RED_MiG23MLD_KIRKUK_01` |
| Mosul Airport | MiG-21Bis | `RED_MiG21Bis_MOSUL_01` |
| Al Kut Airfield | MiG-29A | `RED_MiG29_AL KUT_01` |

---

## 📶 Frequenze radio

| Servizio | Frequenza | Note |
|---|---|---|
| AWACS Darkstar | 270.0 AM | Copertura teatro |
| Roosevelt Marshal | 305.0 AM | F-18 |
| Roosevelt LSO | 264.0 AM | F-18 |
| Washington Marshal | 307.0 AM | F-14 |
| Washington LSO | 265.0 AM | F-14 |

---

## 📁 Struttura file

```
/scripts
  Moose_.lua          ← Framework MOOSE 2.9.17
  missione_iraq.lua   ← Script principale missione
/docs
  briefing.md         ← Briefing missione
```

---

## ⚙️ Trigger nel Mission Editor

| N° | Condizione | Azione | File |
|---|---|---|---|
| 1 | MISSION START | DO SCRIPT FILE | `Moose_.lua` |
| 2 | TIME MORE 3 | DO SCRIPT FILE | `missione_iraq.lua` |

---

## 🛠️ Requisiti
- DCS World con mappa **Iraq**
- Moduli: F-16C, F/A-18C, F-14B, A-10C, AH-64D, F-4E
- MOOSE **2.9.17** ([download](https://github.com/FlightControl-Master/MOOSE_INCLUDE))

---

## 🚧 Stato sviluppo
- [x] Basi BLUE definite
- [x] Portaerei con AIRBOSS
- [x] CAP RED dinamico con respawn
- [x] AWACS BLUE Darkstar
- [ ] Zone di cattura dinamiche
- [ ] CSAR con elicotteri
