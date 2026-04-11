-- ===== H-3 MAIN GCI SYSTEM =====
-- Sistema CAP + GCI per difesa dello spazio aereo di H-3
-- CAP persistente (MiG-29A) + GCI reattivo (MiG-29A scramble)
-- Versione: 1.1 - Missione Iraq 2026
--
-- REQUISITI MISSION EDITOR:
--   STATIC OBJECT (RED): "RedAirWingH3CAP"  — piazzato a H-3 (< 5km dalla pista)
--   STATIC OBJECT (RED): "RedAirWingH3GCI"  — piazzato a H-3 (< 5km dalla pista)
--   GRUPPO template (RED, Late Activation): "RedCAPH3"  — 2x MiG-29A, parcheggiato a H-3
--   GRUPPO template (RED, Late Activation): "RedGCIH3"  — 2x MiG-29A, parcheggiato a H-3
--   Unità EW: "H3EW_01" (SA-10 SR o 1L13 EWR)
--   Border zone: trigger zone "H3Border" (circolare 80km centrata su H-3)

-- ==================================================
-- 1. CONFIGURAZIONE ZONA CONFINE
-- ==================================================
local BorderZone = nil

local triggerZone = trigger.misc.getZone("H3Border")
if triggerZone then
    local zoneVec2 = { x = triggerZone.point.x, y = triggerZone.point.z }
    BorderZone = ZONE_RADIUS:New("H3BorderZone", zoneVec2, triggerZone.radius or 80000)
    env.info("H3GCI: Border zone configurata da trigger zone 'H3Border'")
else
    env.warning("H3GCI: 'H3Border' non trovato, uso zona default (80km da H-3)")
    local h3Vec2 = AIRBASE:FindByName(AIRBASE.Iraq.H_3_Main_Airbase):GetVec2()
    BorderZone = ZONE_RADIUS:New("H3BorderDefault", h3Vec2, 80000)
end

local capCenter = BorderZone:GetCoordinate()

-- ==================================================
-- 2. COHORTS (ex SQUADRON — fix MOOSE 2.9.x)
-- ==================================================

-- FIX: SQUADRON:New() è deprecato in MOOSE 2.9.x, usare COHORT:New()
local sqCAP = COHORT:New("RedCAPH3", 4, "H3-CAP-MiG29")
if not sqCAP then
    env.error("H3GCI: ERRORE - Gruppo template 'RedCAPH3' non trovato nel ME!")
else
    sqCAP:AddMissionCapability({ AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    sqCAP:SetGrouping(2)
    sqCAP:SetTakeoffHot()
    sqCAP:SetFuelLowThreshold(0.3)
    sqCAP:SetFuelLowRefuel(false)
    sqCAP:SetTurnoverTime(15, 30)
    env.info("H3GCI: Squadron CAP MiG-29 configurato")
end

local sqGCI = COHORT:New("RedGCIH3", 4, "H3-GCI-MiG29")
if not sqGCI then
    env.error("H3GCI: ERRORE - Gruppo template 'RedGCIH3' non trovato nel ME!")
else
    sqGCI:AddMissionCapability({ AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    sqGCI:SetGrouping(2)
    sqGCI:SetTakeoffHot()
    sqGCI:SetFuelLowThreshold(0.3)
    sqGCI:SetFuelLowRefuel(false)
    sqGCI:SetTurnoverTime(10, 20)
    env.info("H3GCI: Squadron GCI MiG-29 configurato")
end

-- ==================================================
-- 3a. AIRWING CAP
-- ==================================================
local _anchorCAP = StaticObject.getByName("RedAirWingH3CAP")
if not _anchorCAP then
    -- FIX: rimosso "return" — non bloccare il GCI se CAP manca
    env.error("H3GCI: ERRORE CRITICO - 'RedAirWingH3CAP' non trovato nel ME!")
end

local AirWingCAP = nil
if _anchorCAP then
    AirWingCAP = AIRWING:New("RedAirWingH3CAP", "H3 Red AirWing CAP")
    if not AirWingCAP then
        env.error("H3GCI: ERRORE - AIRWING CAP non inizializzato.")
    else
        AirWingCAP:SetTakeoffHot()
        AirWingCAP:SetDespawnAfterLanding()
        AirWingCAP:SetNumberCAP(1)
        if sqCAP then
            AirWingCAP:AddSquadron(sqCAP)
            -- FIX: NewPayload vuole il tipo aereo, non il nome gruppo
            AirWingCAP:NewPayload("MiG-29 Fulcrum", -1, { AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
        end
        AirWingCAP:AddPatrolPointCAP(capCenter, 27000, 300, 90, 40)
        AirWingCAP:Start()
        env.info("H3GCI: AIRWING CAP avviato")
    end
end

-- ==================================================
-- 3b. AIRWING GCI
-- ==================================================
local _anchorGCI = StaticObject.getByName("RedAirWingH3GCI")
if not _anchorGCI then
    -- FIX: rimosso "return" — logga l'errore ma non bloccare il resto
    env.error("H3GCI: ERRORE CRITICO - 'RedAirWingH3GCI' non trovato nel ME!")
end

local AirWingGCI = nil
if _anchorGCI then
    AirWingGCI = AIRWING:New("RedAirWingH3GCI", "H3 Red AirWing GCI")
    if not AirWingGCI then
        env.error("H3GCI: ERRORE - AIRWING GCI non inizializzato.")
    else
        AirWingGCI:SetTakeoffHot()
        AirWingGCI:SetDespawnAfterLanding()
        if sqGCI then
            AirWingGCI:AddSquadron(sqGCI)
            -- FIX: NewPayload vuole il tipo aereo, non il nome gruppo
            AirWingGCI:NewPayload("MiG-29 Fulcrum", -1, { AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
        end
        AirWingGCI:Start()
        env.info("H3GCI: AIRWING GCI avviato")
    end
end

-- ==================================================
-- 4. DETECTION + GCI REATTIVO
-- ==================================================
local DetectionSetGroup = SET_GROUP:New()
DetectionSetGroup:FilterPrefixes({ "H3EW" })
DetectionSetGroup:FilterStart()

local Detection = DETECTION_AREAS:New(DetectionSetGroup, 100000)
local gciLastScramble = {}
local GCI_COOLDOWN_SEC = 300

-- FIX: OnAfterDetectedItem non esiste in MOOSE 2.9.x — usare OnAfterDetected con ForEachGroup
function Detection:OnAfterDetected(From, Event, To, DetectedSet)
    if not AirWingGCI then return end
    if not DetectedSet then return end
    local dispatched = {}
    DetectedSet:ForEachGroup(function(grp)
        if not grp or not grp:IsAlive() then return end
        local gName = grp:GetName()
        if dispatched[gName] then return end
        dispatched[gName] = true
        if grp:GetCoalition() ~= coalition.side.BLUE then return end
        local threatCoord = grp:GetCoordinate()
        if not threatCoord then return end
        local dist = BorderZone:GetCoordinate():Get2DDistance(threatCoord)
        if dist > 80000 then return end
        local now = timer.getTime()
        if gciLastScramble[gName] and (now - gciLastScramble[gName]) < GCI_COOLDOWN_SEC then return end
        gciLastScramble[gName] = now
        local gciAuftrag = AUFTRAG:NewINTERCEPT(grp)
        AirWingGCI:AddMission(gciAuftrag)
        MESSAGE:New("⚠️ H-3 GCI: SCRAMBLE intercettori su " .. gName, 15, "GCI"):ToAll()
        env.info(string.format("H3GCI: SCRAMBLE → %s (dist=%.0fkm)", gName, dist / 1000))
    end)
end

Detection:Start()

env.info("=== H-3 GCI SYSTEM ATTIVO ===")
MESSAGE:New("H-3 GCI SYSTEM ATTIVO - Intercettori MiG-29 in prontezza", 20, "GCI"):ToAll()
