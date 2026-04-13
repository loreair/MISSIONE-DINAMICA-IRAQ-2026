-- ===================================================================
-- AL KUT CAPTURE ZONE SYSTEM
-- Zona di cattura dinamica per Al Kut Airfield
-- Versione: 1.1 — Missione Iraq 2026
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
local REINFORCE_DELAY_SEC   = 180           -- secondi prima che spawni il rinforzo RED (3 min)
local COUNTERATTACK_DELAY   = 600           -- secondi prima del contrattacco RED dopo cattura (10 min)

-- Variabile globale di stato (letta da AlKutGCI.lua)
AlKutCaptured = false

-- ==================================================
-- 1. VERIFICA ZONA
-- FIX v1.1: ZONE:New() legge direttamente la trigger zone dal ME
-- Non servono manipolazioni manuali di coordinate
-- ==================================================
local AlKutZone = ZONE:New(ALKUT_ZONE_NAME)
if not AlKutZone then
    env.error("AlKutCapture: ERRORE CRITICO - Trigger Zone '" .. ALKUT_ZONE_NAME .. "' non trovata nel ME!")
    return
end

-- Punto centrale per i marker F10 (usando API DCS nativa)
local captureZoneTrigger = trigger.misc.getZone(ALKUT_ZONE_NAME)
env.info("AlKutCapture: Zona '" .. ALKUT_ZONE_NAME .. "' configurata con ZONE:New()")

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
    MESSAGE:New("\xF0\x9F\x93\xA1 INTEL: Rilevato convoglio corazzato BLUE in avanzata verso Al Kut", 25, "INTEL"):ToAll()
end

-- ==================================================
-- 4. ZONA CATTURA — ZONE_CAPTURE_COALITION
-- FIX v1.1: usa AlKutZone creata con ZONE:New()
-- ==================================================
local CaptureZone = ZONE_CAPTURE_COALITION:New(AlKutZone, coalition.side.RED)

if not CaptureZone then
    env.error("AlKutCapture: ERRORE CRITICO - ZONE_CAPTURE_COALITION non inizializzato!")
    return
end

CaptureZone:SetSmokeZone(false)
env.info("AlKutCapture: ZONE_CAPTURE_COALITION inizializzato — proprietà iniziale: RED")

-- ==================================================
-- 5. HANDLER: ZONA ATTACCATA (BLUE entra)
-- ==================================================
function CaptureZone:OnAfterAttacked(From, Event, To, AttackerCoalition)
    env.info("AlKutCapture: ZONA ATTACCATA da coalizione " .. tostring(AttackerCoalition))

    MESSAGE:New("\xF0\x9F\x94\xB4 AL KUT SOTTO ATTACCO! Forze BLUE avanzano sulla base!", 30, "COMBAT"):ToAll()
    MESSAGE:New("\xE2\x9A\x94\xEF\xB8\x8F  PILOTI: supporto CAS richiesto su Al Kut — zona calda!", 20, "COMBAT"):ToCoalition(coalition.side.BLUE)
    MESSAGE:New("\xF0\x9F\x9A\xA8 DIFESA AL KUT: intercetta le forze di terra nemiche!", 20, "COMBAT"):ToCoalition(coalition.side.RED)

    if captureZoneTrigger then
        trigger.action.markToAll(1001, "AL KUT — COMBATTIMENTO IN CORSO", captureZoneTrigger.point, false, "Zona contesa")
    end

    -- Spawn rinforzi RED dopo REINFORCE_DELAY_SEC secondi
    TIMER:New(function()
        local spawnReinforce = SPAWN:New("RedReinforcementsAlKut")
        if spawnReinforce then
            spawnReinforce:Spawn()
            MESSAGE:New("\xF0\x9F\x94\xB4 INTEL: Rinforzi corazzati RED in avanzata su Al Kut!", 20, "INTEL"):ToAll()
            env.info("AlKutCapture: Rinforzi RED spawned (RedReinforcementsAlKut)")
        else
            env.warning("AlKutCapture: Gruppo 'RedReinforcementsAlKut' non trovato.")
        end
    end):Start(REINFORCE_DELAY_SEC)
end

-- ==================================================
-- 6. HANDLER: ZONA VUOTA (terra di nessuno)
-- ==================================================
function CaptureZone:OnAfterEmpty(From, Event, To)
    env.info("AlKutCapture: Zona Al Kut — EMPTY")
    MESSAGE:New("\xE2\x9A\xA0\xEF\xB8\x8F  AL KUT: zona non presidiata — chi arriva prima la conquista!", 20, "INTEL"):ToAll()

    trigger.action.removeMark(1001)
    if captureZoneTrigger then
        trigger.action.markToAll(1001, "AL KUT — TERRA DI NESSUNO", captureZoneTrigger.point, false, "Zona non presidiata")
    end
end

-- ==================================================
-- 7. HANDLER: ZONA CATTURATA (BLUE o RED)
-- FIX v1.1: unico handler con if/else — no doppio override
-- ==================================================
function CaptureZone:OnAfterCaptured(From, Event, To, AttackerCoalition)

    -- === BLUE conquista Al Kut ===
    if AttackerCoalition == coalition.side.BLUE then
        AlKutCaptured = true
        env.info("AlKutCapture: AL KUT CONQUISTATA DA BLUE!")

        MESSAGE:New("\xE2\x9C\x85 AL KUT CONQUISTATA! La base e' sotto controllo BLUE!", 45, "OBIETTIVO"):ToAll()
        MESSAGE:New("\xF0\x9F\x94\xB5 PILOTI BLUE: Al Kut e' operativa — difendete la posizione!", 25, "OBIETTIVO"):ToCoalition(coalition.side.BLUE)
        MESSAGE:New("\xE2\x9D\x8C ATTENZIONE: Al Kut perduta! Ricacciare le forze nemiche!", 25, "OBIETTIVO"):ToCoalition(coalition.side.RED)

        trigger.action.removeMark(1001)
        if captureZoneTrigger then
            trigger.action.markToCoalition(1002, "AL KUT — BASE BLUE", captureZoneTrigger.point, coalition.side.BLUE, false, "Base conquistata")
        end

        -- Ferma GCI RED Al Kut
        if AirWingCAP then AirWingCAP:Stop(); env.info("AlKutCapture: AirWing CAP fermato.") end
        if AirWingGCI then AirWingGCI:Stop(); env.info("AlKutCapture: AirWing GCI fermato.") end

        -- Spawn difesa AA BLUE
        local spawnBlueAA = SPAWN:New("BlueAAAlKut")
        if spawnBlueAA then
            spawnBlueAA:Spawn()
            MESSAGE:New("\xF0\x9F\x94\xB5 Difesa contraerea BLUE dispiegata su Al Kut!", 15, "LOGISTICA"):ToCoalition(coalition.side.BLUE)
            env.info("AlKutCapture: BlueAAAlKut spawned.")
        end

        trigger.action.setUserFlag("AlKutCaptured", 1)

        -- Contrattacco RED dopo COUNTERATTACK_DELAY
        TIMER:New(function()
            if AlKutCaptured then
                local spawnCounter = SPAWN:New("RedReinforcementsAlKut")
                if spawnCounter then
                    spawnCounter:Spawn()
                    MESSAGE:New("\xF0\x9F\x94\xB4 INTEL: Contrattacco RED in corso su Al Kut!", 25, "INTEL"):ToAll()
                    env.info("AlKutCapture: Contrattacco RED spawned.")
                end
            end
        end):Start(COUNTERATTACK_DELAY)

    -- === RED riconquista Al Kut ===
    elseif AttackerCoalition == coalition.side.RED and AlKutCaptured then
        AlKutCaptured = false
        trigger.action.setUserFlag("AlKutCaptured", 0)

        env.info("AlKutCapture: Al Kut RICONQUISTATA da RED!")
        MESSAGE:New("\xF0\x9F\x94\xB4 AL KUT RICONQUISTATA DA RED! La base e' tornata nemica.", 40, "OBIETTIVO"):ToAll()

        if AirWingCAP then AirWingCAP:Start(); env.info("AlKutCapture: AirWing CAP riavviato.") end
        if AirWingGCI then AirWingGCI:Start(); env.info("AlKutCapture: AirWing GCI riavviato.") end

        trigger.action.removeMark(1002)
        if captureZoneTrigger then
            trigger.action.markToAll(1001, "AL KUT — BASE RED", captureZoneTrigger.point, false, "Base riconquistata")
        end
    end
end

-- ==================================================
-- 8. AVVIO
-- ==================================================
CaptureZone:Start()

if captureZoneTrigger then
    trigger.action.markToAll(1001, "AL KUT — BASE RED", captureZoneTrigger.point, false, "Zona controllata da RED")
end

env.info("============================================")
env.info("=== AL KUT CAPTURE ZONE SYSTEM v1.1 ATTIVO ===")
env.info("============================================")
env.info("Zona: " .. ALKUT_ZONE_NAME)
env.info("Fix: ZONE:New() — polling ZONE_CAPTURE_COALITION attivo")
env.info("Fix: OnAfterCaptured unico handler if/else")
env.info("Stato iniziale: RED (Guarded)")
env.info("Contrattacco RED post-cattura: +" .. COUNTERATTACK_DELAY .. "s")
env.info("============================================")

MESSAGE:New("AL KUT: sistema zona cattura v1.1 attivo", 20, "SISTEMA"):ToAll()
