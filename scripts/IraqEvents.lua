-- ===== IRAQ EVENTS SYSTEM =====
-- Notifiche decollo per tutti i gruppi della missione
-- Versione: 1.0 - Missione Iraq 2026
--
-- FUNZIONALITÀ:
-- ✓ Messaggio a tutti i giocatori quando un gruppo decolla
-- ✓ Distingue tra BLUE e RED
-- ✓ Mostra nome gruppo e base di partenza
-- ✓ Nessuna modifica al Mission Editor necessaria

-- =========================================================================
-- ANTI-SPAM: evita messaggi duplicati per la stessa unità
-- =========================================================================
local notificheInviate = {}
local COOLDOWN_SEC = 30  -- non ripetere la stessa notifica per 30 secondi

-- =========================================================================
-- EVENT HANDLER DECOLLO
-- =========================================================================
local IraqTakeoffHandler = EVENTHANDLER:New()
IraqTakeoffHandler:HandleEvent(EVENTS.Takeoff)

function IraqTakeoffHandler:OnEventTakeoff(EventData)

    -- Recupera unità e gruppo
    local unit = EventData.IniUnit
    local group = EventData.IniGroup
    if not unit or not unit:IsAlive() then return end
    if not group or not group:IsAlive() then return end

    local groupName = group:GetName()

    -- Anti-spam: non notificare lo stesso gruppo più volte in 30 secondi
    local now = timer.getTime()
    if notificheInviate[groupName] and (now - notificheInviate[groupName]) < COOLDOWN_SEC then
        return
    end
    notificheInviate[groupName] = now

    -- Recupera base di partenza
    local baseName = "base sconosciuta"
    local airbase = EventData.Place
    if airbase then
        baseName = airbase:GetName()
    end

    -- Recupera coalizione
    local coalizioneID = group:GetCoalition()

    -- Componi e invia messaggio
    if coalizioneID == coalition.side.BLUE then
        MESSAGE:New(
            "✈️ BLUE DECOLLO: " .. groupName .. " in decollo da " .. baseName,
            15, "OPERAZIONI"
        ):ToAll()
        env.info("IraqEvents: BLUE decollo → " .. groupName .. " da " .. baseName)

    elseif coalizioneID == coalition.side.RED then
        MESSAGE:New(
            "⚠️ INTEL RED: " .. groupName .. " in decollo da " .. baseName,
            15, "INTEL"
        ):ToAll()
        env.info("IraqEvents: RED decollo → " .. groupName .. " da " .. baseName)

    else
        -- Coalizione neutrale o sconosciuta
        MESSAGE:New(
            "ℹ️ NEUTRAL: " .. groupName .. " in decollo da " .. baseName,
            15, "INFO"
        ):ToAll()
        env.info("IraqEvents: NEUTRAL decollo → " .. groupName .. " da " .. baseName)
    end
end

-- =========================================================================
-- LOG AVVIO
-- =========================================================================
env.info("========================================")
env.info("=== IRAQ EVENTS SYSTEM ATTIVO ===")
env.info("Monitoraggio decolli attivo per tutte le coalizioni")
env.info("Anti-spam: cooldown " .. COOLDOWN_SEC .. " secondi per gruppo")
env.info("========================================")

MESSAGE:New("Sistema notifiche decollo ATTIVO", 10, "SISTEMA"):ToAll()
