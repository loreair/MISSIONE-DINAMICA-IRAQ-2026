-- ===== KIRKUK GCI SYSTEM =====
-- Sistema CAP + GCI per difesa dello spazio aereo di Kirkuk
-- CAP persistente (MiG-23MLD) + GCI reattivo (MiG-23MLD scramble)
-- Versione: 1.0 - Missione Iraq 2026
--
-- REQUISITI MISSION EDITOR:
--   STATIC OBJECT (RED): "RedAirWingKirkukCAP"  — piazzato a Kirkuk (< 5km dalla pista)
--   STATIC OBJECT (RED): "RedAirWingKirkukGCI"  — piazzato a Kirkuk (< 5km dalla pista)
--   GRUPPO template (RED, Late Activation): "RedCAPKirkuk"  — 2x MiG-23MLD, parcheggiato a Kirkuk
--   GRUPPO template (RED, Late Activation): "RedGCIKirkuk"  — 2x MiG-23MLD, parcheggiato a Kirkuk
--   Unità EW: "KirkukEW_01" (SA-10 SR o 1L13 EWR)
--   Border zone: trigger zone "KirkukBorder" (circolare 80km centrata su Kirkuk)

-- ==================================================
-- 1. CONFIGURAZIONE ZONA CONFINE
-- ==================================================
local BorderZone = nil

local triggerZone = trigger.misc.getZone("KirkukBorder")
if triggerZone then
    local zoneVec2 = { x = triggerZone.point.x, y = triggerZone.point.z }
    BorderZone = ZONE_RADIUS:New("KirkukBorderZone", zoneVec2, triggerZone.radius or 80000)
    env.info("KirkukGCI: Border zone configurata da trigger zone 'KirkukBorder'")
else
    env.warning("KirkukGCI: 'KirkukBorder' non trovato, uso zona default (80km da Kirkuk)")
    local kirkukVec2 = AIRBASE:FindByName(AIRBASE.Iraq.Kirkuk_Air_Base):GetVec2()
    BorderZone = ZONE_RADIUS:New("KirkukBorderDefault", kirkukVec2, 80000)
end

local capCenter = BorderZone:GetCoordinate()

-- ==================================================
-- 2. SQUADRONS
-- ==================================================

local sqCAP = SQUADRON:New("RedCAPKirkuk", 4, "Kirkuk-CAP-MiG23")
if not sqCAP then
    env.error("KirkukGCI: ERRORE - Gruppo template 'RedCAPKirkuk' non trovato nel ME!")
else
    sqCAP:AddMissionCapability({ AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    sqCAP:SetGrouping(2)
    sqCAP:SetTakeoffHot()
    sqCAP:SetFuelLowThreshold(0.3)
    sqCAP:SetFuelLowRefuel(false)
    sqCAP:SetTurnoverTime(15, 30)
    env.info("KirkukGCI: Squadron CAP MiG-23 configurato")
end

local sqGCI = SQUADRON:New("RedGCIKirkuk", 4, "Kirkuk-GCI-MiG23")
if not sqGCI then
    env.error("KirkukGCI: ERRORE - Gruppo template 'RedGCIKirkuk' non trovato nel ME!")
else
    sqGCI:AddMissionCapability({ AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    sqGCI:SetGrouping(2)
    sqGCI:SetTakeoffHot()
    sqGCI:SetFuelLowThreshold(0.3)
    sqGCI:SetFuelLowRefuel(false)
    sqGCI:SetTurnoverTime(10, 20)
    env.info("KirkukGCI: Squadron GCI MiG-23 configurato")
end

-- ==================================================
-- 3a. AIRWING CAP
-- ==================================================
local _anchorCAP = StaticObject.getByName("RedAirWingKirkukCAP")
if not _anchorCAP then
    env.error("KirkukGCI: ERRORE CRITICO - 'RedAirWingKirkukCAP' non trovato nel ME!")
    return
end

local AirWingCAP = AIRWING:New("RedAirWingKirkukCAP", "Kirkuk Red AirWing CAP")
if not AirWingCAP then
    env.error("KirkukGCI: ERRORE - AIRWING CAP non inizializzato.")
else
    AirWingCAP:SetTakeoffHot()
    AirWingCAP:SetDespawnAfterLanding()
    AirWingCAP:SetNumberCAP(1)
    if sqCAP then
        AirWingCAP:AddSquadron(sqCAP)
        AirWingCAP:NewPayload("RedCAPKirkuk", -1, { AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    end
    AirWingCAP:AddPatrolPointCAP(capCenter, 25000, 280, 90, 40)
    AirWingCAP:Start()
    env.info("KirkukGCI: AIRWING CAP avviato")
end

-- ==================================================
-- 3b. AIRWING GCI
-- ==================================================
local _anchorGCI = StaticObject.getByName("RedAirWingKirkukGCI")
if not _anchorGCI then
    env.error("KirkukGCI: ERRORE CRITICO - 'RedAirWingKirkukGCI' non trovato nel ME!")
    return
end

local AirWingGCI = AIRWING:New("RedAirWingKirkukGCI", "Kirkuk Red AirWing GCI")
if not AirWingGCI then
    env.error("KirkukGCI: ERRORE - AIRWING GCI non inizializzato.")
else
    AirWingGCI:SetTakeoffHot()
    AirWingGCI:SetDespawnAfterLanding()
    if sqGCI then
        AirWingGCI:AddSquadron(sqGCI)
        AirWingGCI:NewPayload("RedGCIKirkuk", -1, { AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    end
    AirWingGCI:Start()
    env.info("KirkukGCI: AIRWING GCI avviato")
end

-- ==================================================
-- 4. DETECTION + GCI REATTIVO
-- ==================================================
local DetectionSetGroup = SET_GROUP:New()
DetectionSetGroup:FilterPrefixes({ "KirkukEW" })
DetectionSetGroup:FilterStart()

local Detection = DETECTION_AREAS:New(DetectionSetGroup, 100000)
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
        if dist > 80000 then return end
        local now = timer.getTime()
        if gciLastScramble[gName] and (now - gciLastScramble[gName]) < GCI_COOLDOWN_SEC then return end
        gciLastScramble[gName] = now
        local gciAuftrag = AUFTRAG:NewINTERCEPT(grp)
        AirWingGCI:AddMission(gciAuftrag)
        MESSAGE:New("⚠️ KIRKUK GCI: SCRAMBLE intercettori su " .. gName, 15, "GCI"):ToAll()
        env.info(string.format("KirkukGCI: SCRAMBLE → %s (dist=%.0fkm)", gName, dist / 1000))
    end)
end

Detection:Start()

env.info("=== KIRKUK GCI SYSTEM ATTIVO ===")
MESSAGE:New("KIRKUK GCI SYSTEM ATTIVO - Intercettori MiG-23 in prontezza", 20, "GCI"):ToAll()
