-- ===== MOSUL GCI SYSTEM =====
-- Sistema CAP + GCI per difesa dello spazio aereo di Mosul
-- CAP persistente (MiG-21Bis) + GCI reattivo (MiG-21Bis scramble)
-- Versione: 1.1 - Missione Iraq 2026
--
-- REQUISITI MISSION EDITOR:
--   STATIC OBJECT (RED): "RedAirWingMosulCAP"  — piazzato a Mosul (< 5km dalla pista)
--   STATIC OBJECT (RED): "RedAirWingMosulGCI"  — piazzato a Mosul (< 5km dalla pista)
--   GRUPPO template (RED, Late Activation): "RedCAPMosul"  — 2x MiG-21Bis, parcheggiato a Mosul
--   GRUPPO template (RED, Late Activation): "RedGCIMosul"  — 2x MiG-21Bis, parcheggiato a Mosul
--   Unità EW: "MosulEW_01" (SA-10 SR o 1L13 EWR)
--   Border zone: trigger zone "MosulBorder" (circolare 80km centrata su Mosul)

-- ==================================================
-- 1. CONFIGURAZIONE ZONA CONFINE
-- ==================================================
local BorderZone = nil

local triggerZone = trigger.misc.getZone("MosulBorder")
if triggerZone then
    local zoneVec2 = { x = triggerZone.point.x, y = triggerZone.point.z }
    BorderZone = ZONE_RADIUS:New("MosulBorderZone", zoneVec2, triggerZone.radius or 80000)
    env.info("MosulGCI: Border zone configurata da trigger zone 'MosulBorder'")
else
    env.warning("MosulGCI: 'MosulBorder' non trovato, uso zona default (80km da Mosul)")
    local mosulVec2 = AIRBASE:FindByName(AIRBASE.Iraq.Mosul_International_Airport):GetVec2()
    BorderZone = ZONE_RADIUS:New("MosulBorderDefault", mosulVec2, 80000)
end

local capCenter = BorderZone:GetCoordinate()

-- ==================================================
-- 2. SQUADRONS
-- ==================================================

local sqCAP = SQUADRON:New("RedCAPMosul", 4, "Mosul-CAP-MiG21")
if not sqCAP then
    env.error("MosulGCI: ERRORE - Gruppo template 'RedCAPMosul' non trovato nel ME!")
else
    sqCAP:AddMissionCapability({ AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    sqCAP:SetGrouping(2)
    sqCAP:SetTakeoffHot()
    sqCAP:SetFuelLowThreshold(0.3)
    sqCAP:SetFuelLowRefuel(false)
    sqCAP:SetTurnoverTime(15, 30)
    env.info("MosulGCI: Squadron CAP MiG-21 configurato")
end

local sqGCI = SQUADRON:New("RedGCIMosul", 4, "Mosul-GCI-MiG21")
if not sqGCI then
    env.error("MosulGCI: ERRORE - Gruppo template 'RedGCIMosul' non trovato nel ME!")
else
    sqGCI:AddMissionCapability({ AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    sqGCI:SetGrouping(2)
    sqGCI:SetTakeoffHot()
    sqGCI:SetFuelLowThreshold(0.3)
    sqGCI:SetFuelLowRefuel(false)
    sqGCI:SetTurnoverTime(10, 20)
    env.info("MosulGCI: Squadron GCI MiG-21 configurato")
end

-- ==================================================
-- 3a. AIRWING CAP
-- ==================================================
local _anchorCAP = StaticObject.getByName("RedAirWingMosulCAP")
if not _anchorCAP then
    env.error("MosulGCI: ERRORE CRITICO - 'RedAirWingMosulCAP' non trovato nel ME!")
    return
end

local AirWingCAP = AIRWING:New("RedAirWingMosulCAP", "Mosul Red AirWing CAP")
if not AirWingCAP then
    env.error("MosulGCI: ERRORE - AIRWING CAP non inizializzato.")
else
    AirWingCAP:SetTakeoffHot()
    AirWingCAP:SetDespawnAfterLanding()
    AirWingCAP:SetNumberCAP(1)
    if sqCAP then
        AirWingCAP:AddSquadron(sqCAP)
        AirWingCAP:NewPayload("RedCAPMosul", -1, { AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT }, 90)
    end
    AirWingCAP:AddPatrolPointCAP(capCenter, 22000, 260, 90, 40)
    AirWingCAP:Start()
    env.info("MosulGCI: AIRWING CAP avviato")
end

-- ==================================================
-- 3b. AIRWING GCI
-- ==================================================
local _anchorGCI = StaticObject.getByName("RedAirWingMosulGCI")
if not _anchorGCI then
    env.error("MosulGCI: ERRORE CRITICO - 'RedAirWingMosulGCI' non trovato nel ME!")
    return
end

local AirWingGCI = AIRWING:New("RedAirWingMosulGCI", "Mosul Red AirWing GCI")
if not AirWingGCI then
    env.error("MosulGCI: ERRORE - AIRWING GCI non inizializzato.")
else
    AirWingGCI:SetTakeoffHot()
    AirWingGCI:SetDespawnAfterLanding()
    if sqGCI then
        AirWingGCI:AddSquadron(sqGCI)
        AirWingGCI:NewPayload("RedGCIMosul", -1, { AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP }, 90)
    end
    AirWingGCI:Start()
    env.info("MosulGCI: AIRWING GCI avviato")
end

-- ==================================================
-- 4. DETECTION + GCI REATTIVO (FIX: raggio 100km → 60km)
-- ==================================================
local DetectionSetGroup = SET_GROUP:New()
DetectionSetGroup:FilterPrefixes({ "MosulEW" })
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
        if dist > 80000 then return end
        local now = timer.getTime()
        if gciLastScramble[gName] and (now - gciLastScramble[gName]) < GCI_COOLDOWN_SEC then return end
        gciLastScramble[gName] = now
        local gciAuftrag = AUFTRAG:NewINTERCEPT(grp)
        AirWingGCI:AddMission(gciAuftrag)
        MESSAGE:New("⚠️ MOSUL GCI: SCRAMBLE intercettori su " .. gName, 15, "GCI"):ToAll()
        env.info(string.format("MosulGCI: SCRAMBLE → %s (dist=%.0fkm)", gName, dist / 1000))
    end)
end

Detection:Start()

env.info("=== MOSUL GCI SYSTEM ATTIVO ===")
MESSAGE:New("MOSUL GCI SYSTEM ATTIVO - Intercettori MiG-21 in prontezza", 20, "GCI"):ToAll()
