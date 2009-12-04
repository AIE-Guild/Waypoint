﻿--[[-----------------------------------------------------------------------

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

--[[-----------------------------------------------------------------------

Control Utility Functions

--]]-----------------------------------------------------------------------


local function wpDisplayStatus()

    if Waypoint.enable then
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

    if Waypoint.enable then
        Waypoint.enable = false;
        this:UnregisterEvent("TRADE_SHOW");
    else
        Waypoint.enable = true;
        this:RegisterEvent("TRADE_SHOW");
    end

    wpDisplayStatus();

end

local function wpDisplayAutoClose()

    if Waypoint.auto_close then
        wpAutoCloseCheckButton:SetChecked(true);
    else
        wpAutoCloseCheckButton:SetChecked(false);
    end

end

local function wpUpdateAutoClose()

    if Waypoint.auto_close then
        Waypoint.auto_close = false;
    else
        Waypoint.auto_close = true;
    end

    wpDisplayAutoClose();

end

local function wpDisplayMsgText()

    wpMsgEditBox:SetText(Waypoint.message);
    wpMsgSaveButton:Disable();
    wpMsgCancelButton:Disable();

end

local function updateMsgText(msg)

    Waypoint.message = msg;
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
        if Waypoint == nil then
            Waypoint = {
                enable      = false,
                auto_close  = true,
                message     = "",
                contact     = {},
            }
        end

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
        if Waypoint.enable then
            this:RegisterEvent("TRADE_SHOW");
        end

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
        if Waypoint.auto_close then
            CloseTrade();
        end

        --
        -- whisper the individual
        --
        SendChatMessage(Waypoint.message, "WHISPER", nil, name);

        --
        -- add the contact to the list
        --
        local pos = nil;
        for i, str in ipairs(Waypoint.contact) do
            if str == name then
                pos = i;
                break;
            end
        end

        if pos == nil then
            table.insert(Waypoint.contact,
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
            Waypoint.contact = {};
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

    Waypoint.message = wpMsgEditBox:GetText();
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

    if Waypoint == nil then
        num = 0;
    else
        num = #(Waypoint.contact);
    end

    FauxScrollFrame_Update(wpConList, num, 6, 24);

    for line = 1, 7 do

        index = line + FauxScrollFrame_GetOffset(wpConList);

        if index <= num then

            text  = format("%s (%d) at %s",
                    Waypoint["contact"][index]["name"],
                    Waypoint["contact"][index]["level"],
                    Waypoint["contact"][index]["tstamp"]
                );
            getglobal("wpConEntry" .. line):SetText(text);
            getglobal("wpConEntry" .. line):Show();

        else

            getglobal("wpConEntry" .. line):Hide();

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

    table.sort(Waypoint.contact, function(a,b) return a.name < b.name end);
    wpUpdateConList();

end

function wpConLevelSortButton_OnClick()

    table.sort(Waypoint.contact, function(a,b) return a.level < b.level end);
    wpUpdateConList();

end

function wpConTimestampSortButton_OnClick()

    table.sort(Waypoint.contact, function(a,b) return a.tstamp < b.tstamp end);
    wpUpdateConList();

end

function wpConClearButton_OnClick()
    StaticPopup_Show("WAYPOINT_CLEAR_CONFIRM");
end
