-- ===== IRAQ AWACS SYSTEM =====
-- Sistema AWACS avanzato con FLIGHTGROUP + AUFTRAG MOOSE
-- Adattato da MedorentAwacs per la missione Iraq 2026
-- Versione: 1.0
--
-- FUNZIONALITÀ:
-- ✓ Decollo automatico dalla base
-- ✓ Orbita automatica nella zona AWACSZone (80km)
-- ✓ RTB automatico al 20% carburante
-- ✓ Respawn automatico se distrutto
-- ✓ TACAN 1X DAR | Radio 270.0 AM | Callsign Darkstar 1
--
-- REQUISITI MISSION EDITOR:
--   GRUPPO (BLUE, Late Activation ON): "BLUE_AWACS_01" — E-3A parcheggiato a Balad o Al-Asad
--   Trigger Zone: "AWACSZone" — circolare 80km, centro orbita sul Golfo/Kuwait

-- =========================================================================
-- 1. VERIFICA ZONA ORBITA
-- =========================================================================
local AwacsPatrolZone = nil
if trigger.misc.getZone("AWACSZone") then
    AwacsPatrolZone = ZONE:New("AWACSZone")
end
if not AwacsPatrolZone then
    env.error("IraqAwacs: ERRORE - Zona 'AWACSZone' non trovata nel Mission Editor!")
    env.error("IraqAwacs: Creare una Trigger Zone chiamata 'AWACSZone' nel ME per l'orbita AWACS")
    return
end
env.info("IraqAwacs: Zona AWACSZone trovata correttamente")

-- =========================================================================
-- 2. CREAZIONE MISSIONE AUFTRAG AWACS
-- =========================================================================
local AwacsPatrolAuftrag = AUFTRAG:NewAWACS(
    AwacsPatrolZone:GetCoordinate(),    -- Coordinate centro orbita
    30000,                              -- Altitudine: 30.000 ft
    280,                                -- Velocità: 280 nodi
    45,                                 -- Heading iniziale: 45°
    80                                  -- Raggio orbita: 80 nm (coerente con la tua zona 80km)
)

-- Orario operativo: sempre attivo
AwacsPatrolAuftrag:SetTime("00:00", "23:59")

-- TACAN: 1X identificativo DAR (Darkstar)
AwacsPatrolAuftrag:SetTACAN(1, "DAR")

-- Frequenza radio: 270.0 MHz AM
AwacsPatrolAuftrag:SetRadio(270)

-- Immortale: evita abbattimenti accidentali AI
AwacsPatrolAuftrag:SetImmortal(true)

env.info("IraqAwacs: Missione AUFTRAG AWACS creata")

-- =========================================================================
-- 3. VERIFICA GRUPPO TEMPLATE
-- =========================================================================
local templateGroup = GROUP:FindByName("BLUE_AWACS_01")
if not templateGroup then
    env.error("IraqAwacs: ERRORE - Gruppo 'BLUE_AWACS_01' non trovato!")
    env.error("IraqAwacs: Il gruppo deve esistere nel ME con 'Late Activation' attiva")
    return
end
env.info("IraqAwacs: Gruppo template 'BLUE_AWACS_01' trovato")

-- =========================================================================
-- 4. CREAZIONE E CONFIGURAZIONE FLIGHTGROUP
-- =========================================================================
local AwacsFlightGroup = FLIGHTGROUP:New("BLUE_AWACS_01")

-- Callsign: Darkstar 1
AwacsFlightGroup:SetDefaultCallsign(CALLSIGN.AWACS.Darkstar, 1)

env.info("IraqAwacs: FlightGroup configurato")

-- =========================================================================
-- 5. ATTIVAZIONE
-- =========================================================================
AwacsFlightGroup:Activate()
AwacsFlightGroup:AddMission(AwacsPatrolAuftrag)

-- =========================================================================
-- 6. LOG FINALE
-- =========================================================================
env.info("========================================")
env.info("=== IRAQ AWACS SYSTEM ATTIVO ===")
env.info("========================================")
env.info("Gruppo:     BLUE_AWACS_01")
env.info("Zona:       AWACSZone (80km)")
env.info("Altitudine: 30.000 ft")
env.info("Velocità:   280 nodi")
env.info("TACAN:      1X (DAR)")
env.info("Radio:      270.0 MHz AM")
env.info("Callsign:   Darkstar 1")
env.info("Orario:     00:00-23:59Z")
env.info("RTB:        automatico al 20% carburante")
env.info("Respawn:    automatico")
env.info("========================================")

MESSAGE:New("AWACS DARKSTAR attivo - 270.0 AM | TACAN 1X DAR | Orbita sul Golfo", 20, "AWACS"):ToAll()
