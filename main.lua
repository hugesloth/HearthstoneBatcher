local _, addon = ...

-- Allows you to set your hearthstone as you teleport away to your previous location at the end of the hearthstone cast.
-- Only works if the binding confirmation and the HS spell cast are processed in the same batch (<10ms as of patch 1.14)
local HSframe = CreateFrame("Frame");
local currentFPS = GetCVar("maxfps")
local HSstart = 0
local batchingWindow = 0.006
local bindConfirmation = string.gsub(CONFIRM_BINDER,"%%s",".-")

HSBATCH_ENABLED = true

local ConfirmBinder
if C_PlayerInteractionManager and C_PlayerInteractionManager.ConfirmationInteraction and Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Binder then
    ConfirmBinder = function()
        return C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.Binder)
    end
else
    ConfirmBinder = _G.ConfirmBinder
end

local function ResetStuff()
    HSframe:SetScript("OnUpdate", nil)
    SetCVar("maxfps", currentFPS)
    HSstart = 0
end

local function SwitchBindLocation()
    if GetTime() - HSstart > 10 - batchingWindow then
        ConfirmBinder()
        ResetStuff()
        print('New Hearthstone Bind Successful')
    end
end

local function StartHSTimer()
    if HSBATCH_ENABLED == true and HSstart == 0 then
        --print('start-hs')
        print('Hearthstone Used with Dialog Window Open. Will swap bind location on cast completion.')
        local size = 6
        batchingWindow = size / 1e3
        currentFPS = GetCVar("maxfps")
        HSstart = GetTime()
        HSframe:SetScript("OnUpdate", SwitchBindLocation)
        local bind = _G.StaticPopup1 and _G.StaticPopup1.text and
                            _G.StaticPopup1.text:GetText() or ""
        if bind:find(bindConfirmation) then
            SetCVar("maxfps", "250")
            --addon.StartTimer(10-batchingWindow,"Hearthstone")
        end
    end
end

if _G.C_Container and _G.C_Container.UseContainerItem then -- DF+
    hooksecurefunc(C_Container, "UseContainerItem", function(...)
        if (C_Container.GetContainerItemID(...) == 6948) then
            StartHSTimer()
        end
    end)
else
    hooksecurefunc("UseContainerItem", function(...)
        if _G.GetContainerItemID(...) == 6948 then StartHSTimer() end
    end)
end

hooksecurefunc("UseAction", function(...)
    local event, id = GetActionInfo(...)
    --print(event,id,IsCurrentSpell(id))
    if event == "item" and id == 6948 or
        event == "macro" and (IsCurrentSpell(8690) or IsCurrentSpell(556)) or
        event == "spell" and id == 556 then StartHSTimer() end
end)

SLASH_HSBATCH1= "/hsb"
SLASH_HSBATCH2= "/hsbatch"
function SlashCmdList.HSBATCH(msg, editbox)
    if HSBATCH_ENABLED then
        print('HearthstoneBatcher Disabled.')
        HSBATCH_ENABLED = false
        ResetStuff()
    else
        print('HearthstoneBatcher Enabled.')
        HSBATCH_ENABLED = true
	end
end