--[[-----------------------------------------------------------------------

Author : Mikk
Source : http://www.wowwiki.com/GameTime:Get

--]]-----------------------------------------------------------------------

Waypoint_GameTime = {

  -----------------------------------------------------------
  -- function Waypoint_GameTime:Get()
  --
  -- Return game time as (h,m,s) where s has 3 decimals of
  -- precision (though it's only likely to be precise down
  -- to ~20th of seconds since we're dependent on frame
  -- refreshrate).
  --
  -- During the first minute of play, the seconds will
  -- consistenly be "00", since we haven't observed any
  -- minute changes yet.
  --
  --

  Get = function(self)
  	if(self.LastMinuteTimer == nil) then
  		local h,m = GetGameTime();
  		return h,m,0;
  	end
  	local s = GetTime() - self.LastMinuteTimer;
  	if(s>59.999) then
  		s=59.999;
  	end
  	return self.LastGameHour, self.LastGameMinute, s;
  end,


  -----------------------------------------------------------
  -- function Waypoint_GameTime:OnUpdate()
  --
  -- Called by: Private frame <OnUpdate> handler
  --
  -- Construct high precision server time by polling for
  -- server minute changes and remembering GetTime() when it
  -- last did
  --

  OnUpdate = function(self)
  	local h,m = GetGameTime();
  	if(self.LastGameMinute == nil) then
  		self.LastGameHour = h;
  		self.LastGameMinute = m;
  		return;
  	end
  	if(self.LastGameMinute == m) then
  		return;
  	end
  	self.LastGameHour = h;
  	self.LastGameMinute = m;
  	self.LastMinuteTimer = GetTime();
  end,

  -----------------------------------------------------------
  -- function Waypoint_GameTime:Initialize()
  --
  -- Create frame to pulse OnUpdate() for us
  --

  Initialize = function(self)
  	self.Frame = CreateFrame("Frame");
  	self.Frame:SetScript("OnUpdate", function() self:OnUpdate(); end);
  end
}

Waypoint_GameTime:Initialize();
