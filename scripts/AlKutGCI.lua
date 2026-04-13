-- ===== AL KUT GCI SYSTEM =====
-- Sistema CAP + GCI per difesa dello spazio aereo di Al Kut
-- CAP persistente (MiG-29) + GCI reattivo (MiG-29 scramble)
-- Versione: 1.2 - Missione Iraq 2026
--
-- REQUISITI MISSION EDITOR:
--   STATIC OBJECT (RED): "RedAirWingAlKutCAP"  — piazzato ad Al Kut (< 5km dalla pista)
--   STATIC OBJECT (RED): "RedAirWingAlKutGCI"  — piazzato ad Al Kut (< 5km dalla pista)
--   GRUPPO template (RED, Late Activation): "RedCAPAlKut"  — 2x MiG-29A, parcheggiato ad AL KUT
--   GRUPPO template (RED, Late Activation): "RedGCIAlKut"  — 2x MiG-29A, parcheggiato ad AL KUT
--   Unità EW: qualsiasi unità con prefisso "AlKutEW"
--   Border zone: trigger zone "AlKutBorder" (circolare 106km centrata su Al Kut)

-- ==================================================
-- 1. CONFIGURAZIONE ZONA CONFINE
-- ==================================================
local BorderZone = nil

local triggerZone = trigger.misc.getZone("AlKutBorder")
if triggerZone then
    local zoneVec2 = { x = triggerZone.point.x, y = triggerZone.point.z }
    BorderZone = ZONE_RADIUS:New("AlKutBorderZone", zoneVec2, triggerZone.radius or 106000)
    env.info("AlKutGCI: Border zone configurata da trigger zone 'AlKutBorder'")
else
    env.warning("AlKutGCI: 'AlKutBorder' non trovato, uso zona default (106km da Al Kut)")
    local alKutVec2 = AIRBASE:FindByName("Al Kut Airfield"):GetVec2()
    BorderZone = ZONE_RADIUS:New("AlKutBorderDefault", alKutVec2, 106000)
end

local capCenter = BorderZone:GetCoordinate()

-- ==================================================
-- 2. SQUADRONS
-- ==================================================

local sqCAP = SQUADRON:New("RedCAPAlKut", 4, "AlKut-CAP-MiG29")
if not sqCAP then
    env.error("AlKutGCI: ERRORE - Gruppo template 'RedCAPAlKut' non trovato nel ME!")
else
    sqCAP:AddMissionCapability({ AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    sqCAP:SetGrouping(2)
    sqCAP:SetTakeoffHot()
    sqCAP:SetFuelLowThreshold(0.3)
    sqCAP:SetFuelLowRefuel(false)
    sqCAP:SetTurnoverTime(15, 30)
    env.info("AlKutGCI: Squadron CAP MiG-29 configurato")
end

local sqGCI = SQUADRON:New("RedGCIAlKut", 4, "AlKut-GCI-MiG29")
if not sqGCI then
    env.error("AlKutGCI: ERRORE - Gruppo template 'RedGCIAlKut' non trovato nel ME!")
else
    sqGCI:AddMissionCapability({ AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    sqGCI:SetGrouping(2)
    sqGCI:SetTakeoffHot()
    sqGCI:SetFuelLowThreshold(0.3)
    sqGCI:SetFuelLowRefuel(false)
    sqGCI:SetTurnoverTime(10, 20)
    env.info("AlKutGCI: Squadron GCI MiG-29 configurato")
end

-- ==================================================
-- 3a. AIRWING CAP
-- ==================================================
local _anchorCAP = StaticObject.getByName("RedAirWingAlKutCAP")
if not _anchorCAP then
    env.error("AlKutGCI: ERRORE CRITICO - 'RedAirWingAlKutCAP' non trovato nel ME!")
    return
end

local AirWingCAP = AIRWING:New("RedAirWingAlKutCAP", "AlKut Red AirWing CAP")
if not AirWingCAP then
    env.error("AlKutGCI: ERRORE - AIRWING CAP non inizializzato.")
else
    AirWingCAP:SetTakeoffHot()
    AirWingCAP:SetDespawnAfterLanding()
    AirWingCAP:SetNumberCAP(1)
    if sqCAP then
        AirWingCAP:AddSquadron(sqCAP)
        AirWingCAP:NewPayload("RedCAPAlKut", -1, { AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    end
    AirWingCAP:AddPatrolPointCAP(capCenter, 25000, 300, 90, 40)
    AirWingCAP:Start()
    env.info("AlKutGCI: AIRWING CAP avviato")
end

-- ==================================================
-- 3b. AIRWING GCI
-- ==================================================
local _anchorGCI = StaticObject.getByName("RedAirWingAlKutGCI")
if not _anchorGCI then
    env.error("AlKutGCI: ERRORE CRITICO - 'RedAirWingAlKutGCI' non trovato nel ME!")
    return
end

local AirWingGCI = AIRWING:New("RedAirWingAlKutGCI", "AlKut Red AirWing GCI")
if not AirWingGCI then
    env.error("AlKutGCI: ERRORE - AIRWING GCI non inizializzato.")
else
    AirWingGCI:SetTakeoffHot()
    AirWingGCI:SetDespawnAfterLanding()
    if sqGCI then
        AirWingGCI:AddSquadron(sqGCI)
        AirWingGCI:NewPayload("RedGCIAlKut", -1, { AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    end
    AirWingGCI:Start()
    env.info("AlKutGCI: AIRWING GCI avviato")
end

-- ==================================================
-- 4. DETECTION + GCI REATTIVO
-- ==================================================
local DetectionSetGroup = SET_GROUP:New()
DetectionSetGroup:FilterPrefixes({ "AlKutEW" })
DetectionSetGroup:FilterStart()

local Detection = DETECTION_AREAS:New(DetectionSetGroup, 60000)
local gciLastScramble = {}
local GCI_COOLDOWN_SEC = 300

function Detection:OnAfterDetectedItem(From, Event, To, DetectedItem)
    if not AirWingGCI then return end
    if not DetectedItem or not DetectedItem.Set then return end
    local dispatched = {}
    DetectedItem.Set:ForEachUnit(function(unit)
        if not unit or not unit:IsAlive() then return end
        local grp = unit:GetGroup()
        if not grp or not grp:IsAlive() then return end
        local gName = grp:GetName()
        if dispatched[gName] then return end
        dispatched[gName] = true
        if grp:GetCoalition() ~= coalition.side.BLUE then return end
        local threatCoord = grp:GetCoordinate()
        if not threatCoord then return end
        local dist = BorderZone:GetCoordinate():Get2DDistance(threatCoord)
        if dist > 106000 then return end
        local now = timer.getTime()
        if gciLastScramble[gName] and (now - gciLastScramble[gName]) < GCI_COOLDOWN_SEC then return end
        gciLastScramble[gName] = now
        local gciAuftrag = AUFTRAG:NewINTERCEPT(grp)
        AirWingGCI:AddMission(gciAuftrag)
        MESSAGE:New("⚠️ AL KUT GCI: SCRAMBLE intercettori su " .. gName, 15, "GCI"):ToAll()
        env.info(string.format("AlKutGCI: GCI SCRAMBLE → %s (dist=%.0fkm)", gName, dist / 1000))
    end)
end

Detection:Start()

env.info("========================================")
env.info("=== AL KUT GCI SYSTEM ATTIVO ===")
env.info("========================================")
env.info("CAP: 1 volo MiG-29 permanente (2 aerei, Hot Start)")
env.info("GCI: 2x MiG-29 per intercetto, cooldown 5min")
env.info("Detection EW: prefisso 'AlKutEW', raggio 60km")
env.info("Border Zone: " .. (BorderZone and BorderZone:GetName() or "NON CONFIGURATA!"))
env.info("AirWing CAP: " .. (AirWingCAP and "ATTIVO" or "ERRORE!"))
env.info("AirWing GCI: " .. (AirWingGCI and "ATTIVO" or "ERRORE!"))
env.info("========================================")

MESSAGE:New("AL KUT GCI SYSTEM ATTIVO - Intercettori in prontezza", 20, "GCI"):ToAll()
