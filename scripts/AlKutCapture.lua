-- ===================================================================
-- AL KUT CAPTURE ZONE SYSTEM
-- Zona di cattura dinamica per Al Kut Airfield
-- Versione: 1.0 — Missione Iraq 2026
-- Dipende da: AlKutGCI.lua (deve essere caricato prima)
-- ===================================================================
--
-- REQUISITI MISSION EDITOR:
--   TRIGGER ZONE:  "AlKutCaptureZone"   — circolare 8km centrata su Al Kut
--   GRUPPO RED  (Late Activation): "RedGroundAlKut"   — 2x T-72B + 2x BTR-80, FERMI dentro la zona
--   GRUPPO BLUE (Late Activation): "BlueConvoyAlKut"  — 2x M1A2 + 2x M2 Bradley, ~30km a SUD, waypoint verso Al Kut
--   GRUPPO BLUE (Late Activation): "BlueAAAlKut"      — 1x Avenger + 1x MANPAD, dentro la zona (template per spawn post-cattura)
--   GRUPPO RED  (Late Activation): "RedReinforcementsAlKut" — 2x T-72B + 2x BMP-1, ~15km a NORD (rinforzi RED)
--
-- VARIABILI GLOBALI ESPORTATE (usate da AlKutGCI.lua):
--   AlKutCaptured  (boolean) — true quando BLUE controlla la zona
-- ===================================================================

-- ==================================================
-- CONFIGURAZIONE
-- ==================================================
local ALKUT_ZONE_NAME       = "AlKutCaptureZone"
local ALKUT_ZONE_RADIUS     = 8000          -- metri
local REINFORCE_DELAY_SEC   = 180           -- secondi prima che spawni il rinforzo RED (3 min)
local COUNTERATTACK_DELAY   = 600           -- secondi prima del contrattacco RED dopo cattura (10 min)

-- Variabile globale di stato (letta da AlKutGCI.lua)
AlKutCaptured = false

-- ==================================================
-- 1. VERIFICA ZONA
-- ==================================================
local captureZoneTrigger = trigger.misc.getZone(ALKUT_ZONE_NAME)
if not captureZoneTrigger then
    env.error("AlKutCapture: ERRORE CRITICO - Trigger Zone '" .. ALKUT_ZONE_NAME .. "' non trovata nel ME!")
    return
end

local zoneVec2 = { x = captureZoneTrigger.point.x, y = captureZoneTrigger.point.z }
local AlKutZone = ZONE_RADIUS:New(ALKUT_ZONE_NAME, zoneVec2, captureZoneTrigger.radius or ALKUT_ZONE_RADIUS)
env.info("AlKutCapture: Zona '" .. ALKUT_ZONE_NAME .. "' configurata (r=" .. (captureZoneTrigger.radius or ALKUT_ZONE_RADIUS) .. "m)")

-- ==================================================
-- 2. SPAWN INIZIALE DIFESA RED
-- ==================================================
local spawnRedGround = SPAWN:New("RedGroundAlKut")
if not spawnRedGround then
    env.error("AlKutCapture: ERRORE - Gruppo template 'RedGroundAlKut' non trovato nel ME!")
    return
end
spawnRedGround:Spawn()
env.info("AlKutCapture: Difesa RED Al Kut spawned (RedGroundAlKut)")

-- ==================================================
-- 3. AVVIO CONVOGLIO BLUE
-- ==================================================
local spawnBlueConvoy = SPAWN:New("BlueConvoyAlKut")
if not spawnBlueConvoy then
    env.warning("AlKutCapture: ATTENZIONE - Gruppo 'BlueConvoyAlKut' non trovato. Convoglio non avviato.")
else
    spawnBlueConvoy:Spawn()
    env.info("AlKutCapture: Convoglio BLUE avviato (BlueConvoyAlKut)")
    MESSAGE:New("📡 INTEL: Rilevato convoglio corazzato BLUE in avanzata verso Al Kut", 25, "INTEL"):ToAll()
end

-- ==================================================
-- 4. ZONA CATTURA — ZONE_CAPTURE_COALITION
-- ==================================================
local CaptureZone = ZONE_CAPTURE_COALITION:New(AlKutZone, coalition.side.RED)

if not CaptureZone then
    env.error("AlKutCapture: ERRORE CRITICO - ZONE_CAPTURE_COALITION non inizializzato!")
    return
end

-- Imposta frequenza di polling (ogni 30 secondi controlla lo stato)
CaptureZone:SetSmokeZone(false)
env.info("AlKutCapture: ZONE_CAPTURE_COALITION inizializzato — proprietà iniziale: RED")

-- ==================================================
-- 5. HANDLER: ZONA ATTACCATA (BLUE entra)
-- ==================================================
function CaptureZone:OnAfterAttacked(From, Event, To, AttackerCoalition)
    env.info("AlKutCapture: ZONA ATTACCATA da coalizione " .. tostring(AttackerCoalition))

    MESSAGE:New("🔴 AL KUT SOTTO ATTACCO! Forze BLUE avanzano sulla base!", 30, "COMBAT"):ToAll()
    MESSAGE:New("⚔️  PILOTI: supporto CAS richiesto su Al Kut — zona calda!", 20, "COMBAT"):ToCoalition(coalition.side.BLUE)
    MESSAGE:New("🚨 DIFESA AL KUT: intercetta le forze di terra nemiche!", 20, "COMBAT"):ToCoalition(coalition.side.RED)

    -- Marker F10 — zona in combattimento
    trigger.action.markToAll(1001, "⚔️ AL KUT — COMBATTIMENTO IN CORSO", captureZoneTrigger.point, false, "Zona contesa")

    -- Spawn rinforzi RED dopo REINFORCE_DELAY_SEC secondi
    TIMER:New(function()
        local spawnReinforce = SPAWN:New("RedReinforcementsAlKut")
        if spawnReinforce then
            spawnReinforce:Spawn()
            MESSAGE:New("🔴 INTEL: Rinforzi corazzati RED in avanzata su Al Kut!", 20, "INTEL"):ToAll()
            env.info("AlKutCapture: Rinforzi RED spawned (RedReinforcementsAlKut)")
        else
            env.warning("AlKutCapture: Gruppo 'RedReinforcementsAlKut' non trovato — rinforzi RED non spawned.")
        end
    end):Start(REINFORCE_DELAY_SEC)
end

-- ==================================================
-- 6. HANDLER: ZONA VUOTA (terra di nessuno)
-- ==================================================
function CaptureZone:OnAfterEmpty(From, Event, To)
    env.info("AlKutCapture: Zona Al Kut — EMPTY (nessun presidio)")
    MESSAGE:New("⚠️  AL KUT: zona non presidiata — chi arriva prima la conquista!", 20, "INTEL"):ToAll()

    -- Rimuovi marker precedente e aggiorna
    trigger.action.removeMark(1001)
    trigger.action.markToAll(1001, "❓ AL KUT — TERRA DI NESSUNO", captureZoneTrigger.point, false, "Zona non presidiata")
end

-- ==================================================
-- 7. HANDLER: ZONA CONQUISTATA DA BLUE
-- ==================================================
function CaptureZone:OnAfterCaptured(From, Event, To, AttackerCoalition)
    if AttackerCoalition ~= coalition.side.BLUE then return end

    AlKutCaptured = true
    env.info("AlKutCapture: AL KUT CONQUISTATA DA BLUE!")

    -- Messaggi
    MESSAGE:New("✅ AL KUT CONQUISTATA! La base è sotto controllo BLUE!", 45, "OBIETTIVO"):ToAll()
    MESSAGE:New("🔵 PILOTI BLUE: Al Kut è operativa — difendete la posizione!", 25, "OBIETTIVO"):ToCoalition(coalition.side.BLUE)
    MESSAGE:New("❌ ATTENZIONE: Al Kut perduta! Ricacciare le forze nemiche!", 25, "OBIETTIVO"):ToCoalition(coalition.side.RED)

    -- Aggiorna marker F10
    trigger.action.removeMark(1001)
    trigger.action.markToCoalition(1002, "✅ AL KUT — BASE BLUE", captureZoneTrigger.point, coalition.side.BLUE, false, "Base conquistata")

    -- Ferma il GCI RED (se AirWingCAP e AirWingGCI sono globali da AlKutGCI.lua)
    if AirWingCAP then
        AirWingCAP:Stop()
        env.info("AlKutCapture: AirWing CAP Al Kut fermato.")
    end
    if AirWingGCI then
        AirWingGCI:Stop()
        env.info("AlKutCapture: AirWing GCI Al Kut fermato.")
    end

    -- Spawn difesa AA BLUE
    local spawnBlueAA = SPAWN:New("BlueAAAlKut")
    if spawnBlueAA then
        spawnBlueAA:Spawn()
        env.info("AlKutCapture: Difesa AA BLUE spawned (BlueAAAlKut)")
        MESSAGE:New("🔵 Difesa contraerea BLUE dispiegata su Al Kut!", 15, "LOGISTICA"):ToCoalition(coalition.side.BLUE)
    else
        env.warning("AlKutCapture: Gruppo 'BlueAAAlKut' non trovato — AA BLUE non spawned.")
    end

    -- Imposta flag ME (può essere usato per trigger ulteriori nel ME)
    trigger.action.setUserFlag("AlKutCaptured", 1)
    env.info("AlKutCapture: Flag ME 'AlKutCaptured' = 1")

    -- Contrattacco RED automatico dopo COUNTERATTACK_DELAY secondi
    TIMER:New(function()
        if AlKutCaptured then  -- ancora in mano BLUE
            local spawnCounter = SPAWN:New("RedReinforcementsAlKut")
            if spawnCounter then
                spawnCounter:Spawn()
                MESSAGE:New("🔴 INTEL: Contrattacco RED in corso su Al Kut!", 25, "INTEL"):ToAll()
                env.info("AlKutCapture: Contrattacco RED spawned dopo cattura BLUE")
            end
        end
    end):Start(COUNTERATTACK_DELAY)
end

-- ==================================================
-- 8. HANDLER: ZONA RICONQUISTATA DA RED
-- ==================================================
function CaptureZone:OnAfterCaptured_RED(From, Event, To, AttackerCoalition)
    -- Nota: OnAfterCaptured viene chiamato per qualsiasi coalizione
    -- Gestiamo la riconquista RED qui controllando AttackerCoalition
end

-- Override generico per cattura RED
local _originalOnAfterCaptured = CaptureZone.OnAfterCaptured
function CaptureZone:OnAfterCaptured(From, Event, To, AttackerCoalition)
    if AttackerCoalition == coalition.side.RED and AlKutCaptured then
        -- RED riconquista la base
        AlKutCaptured = false
        trigger.action.setUserFlag("AlKutCaptured", 0)

        env.info("AlKutCapture: Al Kut RICONQUISTATA da RED!")
        MESSAGE:New("🔴 AL KUT RICONQUISTATA DA RED! La base è tornata nemica.", 40, "OBIETTIVO"):ToAll()

        -- Riavvia GCI se possibile
        if AirWingCAP then
            AirWingCAP:Start()
            env.info("AlKutCapture: AirWing CAP Al Kut riavviato.")
        end
        if AirWingGCI then
            AirWingGCI:Start()
            env.info("AlKutCapture: AirWing GCI Al Kut riavviato.")
        end

        -- Aggiorna marker
        trigger.action.removeMark(1002)
        trigger.action.markToAll(1001, "🔴 AL KUT — BASE RED", captureZoneTrigger.point, false, "Base riconquistata")

        return
    end

    -- Altrimenti esegui logica BLUE normale
    _originalOnAfterCaptured(self, From, Event, To, AttackerCoalition)
end

-- ==================================================
-- 9. AVVIO
-- ==================================================
CaptureZone:Start()

-- Marker iniziale F10
trigger.action.markToAll(1001, "🔴 AL KUT — BASE RED", captureZoneTrigger.point, false, "Zona controllata da RED")

env.info("============================================")
env.info("=== AL KUT CAPTURE ZONE SYSTEM ATTIVO ===")
env.info("============================================")
env.info("Zona: " .. ALKUT_ZONE_NAME)
env.info("Stato iniziale: RED (Guarded)")
env.info("Difesa RED: RedGroundAlKut (spawned)")
env.info("Convoglio BLUE: BlueConvoyAlKut (in marcia)")
env.info("Rinforzi RED: RedReinforcementsAlKut (on-demand)")
env.info("Contrattacco RED post-cattura: +" .. COUNTERATTACK_DELAY .. "s")
env.info("============================================")

MESSAGE:New("AL KUT: sistema zona cattura attivo — la base è presidiata da forze RED", 20, "SISTEMA"):ToAll()
