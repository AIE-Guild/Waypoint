--[[-----------------------------------------------------------------------

Author      : Mark Rogaski
Create Date : 11/16/2009 1:36:31 PM

--]]-----------------------------------------------------------------------

--[[-----------------------------------------------------------------------

Slash Commands

--]]-----------------------------------------------------------------------

SLASH_WAYPOINT1 = "/wp";
SLASH_WAYPOINT2 = "/waypoint";

local function wpSlashCmd()
    wpFrame:Show();
end

SlashCmdList["WAYPOINT"] = wpSlashCmd;


--[[-----------------------------------------------------------------------

Control Utility Functions

--]]-----------------------------------------------------------------------


local function displayStatus()

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

local function updateStatus(flag)

    if Waypoint.enable then
        Waypoint.enable = false;
    else
        Waypoint.enable = true;
    end

    displayStatus();

end

local function displayAutoClose()

    if Waypoint.auto_close then
        wpAutoCloseCheckButton:SetChecked(false);
    else
        wpAutoCloseCheckButton:SetChecked(true);
    end

end

local function setAutoClose(flag)

    if Waypoint.auto_close then
        Waypoint.auto_close = false;
    else
        Waypoint.auto_close = true;
    end

    displayAutoClose();

end

local function displayMsgText()

    wpMsgEditBox:SetText(Waypoint.message);
    wpMsgSaveButton:Disable();
    wpMsgCancelButton:Disable();

end

local function updateMsgText(msg)

    Waypoint.message = msg;
    displayMsgText();

end


--[[-----------------------------------------------------------------------

Frame Event Functions

--]]-----------------------------------------------------------------------

function wpFrame_OnEvent()
    if event == "ADDON_LOADED" and arg1 == "Waypoint" then

        -- initialize the data if needed
        if Waypoint == nil then
            Waypoint = {
                enable      = false,
                auto_close  = true,
                message     = "",
                contact     = {},
            }

            -- Test data
            for i = 1, 24 do
                Waypoint["contact"][i] = {
                    name	= "Test" .. i,
                    level	= ((i * time()) % 80) + 1,
                    tstamp	= time(),
                }
            end

        end

    end

end

function wpFrame_OnLoad()
    -- Close window on ESC
    tinsert(UISpecialFrames,this:GetName());
end

function wpFrame_OnShow()

    -- make sure the everything displayed correctly
    displayStatus();
    displayAutoClose();
    displayMsgText();

end


--[[-----------------------------------------------------------------------

Control Event Functions

--]]-----------------------------------------------------------------------

function wpCloseButton_OnClick()

    wpFrame:Hide();

end

function wpToggleButton_OnClick()

    updateStatus(true);

end

function wpAutoCloseCheckButton_OnClick()

    updateAutoClose(true);

end

function wpMsgEditBox_OnTextChanged()

    wpMsgSaveButton:Enable();
    wpMsgCancelButton:Enable();

end

function wpMsgEditBox_OnHide()

    displayMsgText();

end

function wpMsgSaveButton_OnShow()
    wpMsgSaveButton:Disable();
end

function wpMsgSaveButton_OnClick()

    Waypoint.message = wpMsgEditBox:GetText();
    displayMsgText();

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
    displayMsgText();

end

function updateConList()

    local line;
    local offset;
    local entry;
    local text;
    local num = #(Waypoint.contact);

    FauxScrollFrame_Update(wpConList, num, 6, 24);

    for line = 1, 5 do

        offset = FauxScrollFrame_GetOffset(wpConList);
        if (line + offset) < num then

            entry = Waypoint["contact"][line + offset];
            text  = entry.name .. " (" .. entry.level .. "), " .. entry.tstamp;

            getglobal("wpConEntry" .. line):SetText(text);
            getglobal("wpConEntry" .. line):Show();

        else

            getglobal("wpConEntry" .. line):Hide();

        end

    end

end

function wpConList_OnVerticalScroll(self. offset)

    FauxScrollFrame_OnVerticalScroll(this, offset, 24, updateConList);

end

function wpConList_OnShow()

    updateConList();

end
