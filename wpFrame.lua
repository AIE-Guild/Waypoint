--[[-----------------------------------------------------------------------

    $Id$

    Copyright (c) 2009; Mark Rogaski.

    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.

        * Neither the name of the copyright holder nor the names of any
          contributors may be used to endorse or promote products derived
          from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--]]-----------------------------------------------------------------------

wpVersion = "0.9.02";


--[[-----------------------------------------------------------------------

Control Utility Functions

--]]-----------------------------------------------------------------------


local function wpDisplayStatus()

    if wpConfig.enable then
        wpToggleButton:SetText("Disable");
        wpStatusText:SetText("Enabled");
        wpStatusText:SetTextColor(0, 1, 0, 1);
    else
        wpToggleButton:SetText("Enable");
        wpStatusText:SetText("Disabled");
        wpStatusText:SetTextColor(1, 0, 0, 1);
    end

end

local function wpUpdateStatus(flag)

    if wpConfig.enable then
        wpConfig.enable = false;
        this:UnregisterEvent("TRADE_SHOW");
    else
        wpConfig.enable = true;
        this:RegisterEvent("TRADE_SHOW");
    end

    wpDisplayStatus();

end

local function wpDisplayAutoClose()

    if wpConfig.auto_close then
        wpAutoCloseCheckButton:SetChecked(true);
    else
        wpAutoCloseCheckButton:SetChecked(false);
    end

end

local function wpUpdateAutoClose()

    if wpConfig.auto_close then
        wpConfig.auto_close = false;
    else
        wpConfig.auto_close = true;
    end

    wpDisplayAutoClose();

end

local function wpDisplayMsgText()

    wpMsgEditBox:SetText(wpConfig.message);
    wpMsgSaveButton:Disable();
    wpMsgCancelButton:Disable();

end

local function updateMsgText(msg)

    wpConfig.message = msg;
    wpDisplayMsgText();

end


--[[-----------------------------------------------------------------------

Frame Event Functions

--]]-----------------------------------------------------------------------

function wpFrame_OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Waypoint" then

        --
        -- initialize the data if needed
        --
        if wpConfig == nil then
            wpConfig = {
                enable      = false,
                auto_close  = true,
                message     = "",
                contact     = {},
            }
        end

        --
        -- check config file version
        --
        wpConfig.version = wpVersion;

        --
        -- make sure the everything displayed correctly
        --
        wpDisplayStatus();
        wpDisplayAutoClose();
        wpDisplayMsgText();
        wpUpdateConList();

        --
        -- listen for trade windows, if enabled
        --
        if wpConfig.enable then
            this:RegisterEvent("TRADE_SHOW");
        end

        ChatFrame1:AddMessage(string.format("|cffff6600Waypoint v%s loaded:|r type /waypoint or /wp.", wpVersion))

    elseif event == "TRADE_SHOW" then

        --
        -- gather contact info
        --
        name, realm = UnitName("NPC");
        level       = UnitLevel("NPC");
        tstamp      = date("%Y-%m-%d %H:%M:%S");

        --
        -- include realm if on a cross-realm server
        --
        if not realm == nil then
            name = name .. "-" .. realm;
        end

        --
        -- check for auto-close
        --
        if wpConfig.auto_close then
            CloseTrade();
        end

        --
        -- whisper the individual
        --
        SendChatMessage(wpConfig.message, "WHISPER", nil, name);

        --
        -- add the contact to the list
        --
        local pos = nil;
        for i, p in ipairs(wpConfig.contact) do
            if p.name == name then
                pos = i;
                break;
            end
        end

        if pos == nil then
            table.insert(wpConfig.contact,
                    { name = name, level = level, tstamp = tstamp });
        end

        wpUpdateConList();

    end

end

function wpFrame_OnLoad()

    --
    -- set up slash commands
    --
    SLASH_WAYPOINT1 = "/wp";
    SLASH_WAYPOINT2 = "/waypoint";

    local function wpSlashCmd(arg1, arg2)
        wpFrame:Show();
    end

    SlashCmdList["WAYPOINT"] = wpSlashCmd;

    --
    -- set up pop-up dialogs
    --
    StaticPopupDialogs["WAYPOINT_CLEAR_CONFIRM"] = {
        text = "Do you want to clear the contact data?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            wpConfig.contact = {};
            wpUpdateConList();
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    --
    -- trap the events we are interested in
    --
    this:RegisterEvent("ADDON_LOADED");

    --
    -- Close window on ESC
    --
    tinsert(UISpecialFrames,this:GetName());

    --
    -- Wait until the saved variables are loaded
    --
    this:Hide();

end

function wpFrame_OnShow()

    --
    -- make sure the everything displayed correctly
    --
    wpDisplayStatus();
    wpDisplayAutoClose();
    wpDisplayMsgText();
    wpUpdateConList();

end


--[[-----------------------------------------------------------------------

Control Event Functions

--]]-----------------------------------------------------------------------

function wpCloseButton_OnClick()

    wpFrame:Hide();

end

function wpToggleButton_OnClick()

    wpUpdateStatus(true);

end

function wpAutoCloseCheckButton_OnClick()

    wpUpdateAutoClose(true);

end

function wpMsgEditBox_OnTextChanged()

    wpMsgSaveButton:Enable();
    wpMsgCancelButton:Enable();

end

function wpMsgEditBox_OnHide()

    wpDisplayMsgText();

end

function wpMsgSaveButton_OnShow()
    wpMsgSaveButton:Disable();
end

function wpMsgSaveButton_OnClick()

    wpConfig.message = wpMsgEditBox:GetText();
    wpDisplayMsgText();

end

function wpMsgCancelButton_OnShow()
    wpMsgCancelButton:Disable();
end

function wpMsgClearButton_OnClick()

    wpMsgEditBox:SetText("");

end

function wpMsgCancelButton_OnClick()

    wpMsgSaveButton:Disable();
    wpMsgCancelButton:Disable();
    wpDisplayMsgText();

end

function wpUpdateConList()

    local line;
    local offset;
    local entry;
    local text;
    local num;

    if wpConfig == nil then
        num = 0;
    else
        num = #(wpConfig.contact);
    end

    FauxScrollFrame_Update(wpConList, num, 6, 24);

    for line = 1, 7 do

        index = line + FauxScrollFrame_GetOffset(wpConList);

        if index <= num then

            text = format("%s (%d) at %s",
                    wpConfig["contact"][index]["name"],
                    wpConfig["contact"][index]["level"],
                    wpConfig["contact"][index]["tstamp"]
                );
            getglobal("wpConEntry" .. line):SetText(text);
            getglobal("wpConEntry" .. line):Show();

        else

            getglobal("wpConEntry" .. line):SetText("");
            getglobal("wpConEntry" .. line):Show();
            --getglobal("wpConEntry" .. line):Hide();

        end

    end

end

function wpConList_OnVerticalScroll(offset)

    FauxScrollFrame_OnVerticalScroll(this, offset, 24, wpUpdateConList);

end

function wpConList_OnShow()

    wpUpdateConList();

end

function wpConNameSortButton_OnClick()

    table.sort(wpConfig.contact, function(a,b) return a.name < b.name end);
    wpUpdateConList();

end

function wpConLevelSortButton_OnClick()

    table.sort(wpConfig.contact, function(a,b) return a.level < b.level end);
    wpUpdateConList();

end

function wpConTimestampSortButton_OnClick()

    table.sort(wpConfig.contact, function(a,b) return a.tstamp < b.tstamp end);
    wpUpdateConList();

end

function wpConClearButton_OnClick()
    StaticPopup_Show("WAYPOINT_CLEAR_CONFIRM");
end
