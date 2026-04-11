-- ============================================================
-- MISSIONE IRAQ 2026 - Script MOOSE v2.9.17
-- Autore: loreair
-- Nota: CAP RED gestito interamente dai file GCI separati
-- ============================================================

-- ============================================================
-- SEZIONE 1: PORTAEREI BLUE - AIRBOSS
-- Roosevelt (F-18) TACAN 71X ICLS 1
-- Washington (F-14) TACAN 73X ICLS 3
-- ============================================================

local Airboss_Roosevelt = AIRBOSS:New("CNV-71 ROOSEVELT", "Roosevelt")
Airboss_Roosevelt:SetTACAN(71, "CVN")
Airboss_Roosevelt:SetICLS(1)
Airboss_Roosevelt:SetMarshalRadio(305.0)
Airboss_Roosevelt:SetLSORadio(264.0)
Airboss_Roosevelt:SetMenuSingle(true)
Airboss_Roosevelt:Start()

local Airboss_Washington = AIRBOSS:New("CNV-73 WASHINGTON", "Washington")
Airboss_Washington:SetTACAN(73, "CVW")
Airboss_Washington:SetICLS(3)
Airboss_Washington:SetMarshalRadio(307.0)
Airboss_Washington:SetLSORadio(265.0)
Airboss_Washington:SetMenuSingle(true)
Airboss_Washington:Start()

-- ============================================================
-- SEZIONE 2: AWACS BLUE
-- ============================================================

local AWACS_Blue = AWACS:New(
  "BLUE_AWACS_01",
  "AwacsBlue",
  coalition.side.BLUE,
  AIRBASE.Iraq.Al_Asad_Airbase,
  "Darkstar",
  1
)

AWACS_Blue:SetRadioFrequency(270.0)
AWACS_Blue:SetRadioModulation(radio.modulation.AM)
AWACS_Blue:SetAltitude(30000)
AWACS_Blue:SetReportingName("Eagle")
AWACS_Blue:SetTACAN(1, "DAR")
AWACS_Blue:Start()

-- ============================================================
-- SEZIONE 3: MESSAGGI DI BRIEFING ALL'AVVIO
-- ============================================================

MESSAGE:New("MISSIONE ATTIVA - GCI RED attivo: H-3, Kirkuk, Mosul, Al Kut", 20, "INTEL"):ToAll()
MESSAGE:New("Roosevelt TACAN 71X ICLS 01 | Washington TACAN 73X ICLS 03", 20, "CARRIER OPS"):ToAll()
MESSAGE:New("AWACS DARKSTAR attivo su 270.0 AM - TACAN 1X DAR", 20, "AWACS"):ToAll()
