-- Ni Karma System (NKS) for raid loot distribution
-- The Ni Karma System was designed by Vuelhering (stef+nks @swcp.com) and Qed of Icecrown
-- 
-- Plugin coded by Mavios of Icecrown (althar @gmail.com).  Thanks Mavios, you rock.
-- Code maintenance and additional programming by Mavios and Vuelhering
-- Instructions for use at http://www.knights-who-say-ni.com/NKS
-- 
-- Copyright 2006-2008, Mavios and Vuelhering, Knights who say Ni, Icecrown
-- 
-- Permission granted for use, modification, and distribution provided:
-- 1. Any distributions include the original distribution in its entirety, OR a working URL to freely get the entire original distribution is clearly listed in the documentation.
-- 2. Any modified distributions clearly mark YOUR changes, or document the changes somehow.
-- 3. Any modified distributions MUST NOT imply in any way that it is an official upgrade version of this software (such as NKS+ or Enhanced Karma System, or probably anything with "NKS" or "Karma" in the name).  If you want your changes in the official distribution, write (stef+nks @swcp.com) and it might get included.
-- 4. No fee is charged for any distribution of this software (modified or original).
-- 
-- Snippets of code "borrowed" (fewer than 100 total lines) can merely include the URL http://www.knights-who-say-ni.com/NKS and credit for the code used.
-- The Ni_Karma.toc file is granted to the public domain, so it can be updated without issue.



-- Globals
KarmaList = { };
KarmaConfig = { };

ROLLS_TO_DISPLAY = 17;
KARMA_SHOWTO_LEADER = 0;
KARMA_SHOWTO_PLAYER = 1;
KARMA_SHOWTO_RAID = 2;
ROLL_FRAME_ROLL_HEIGHT = 16;

KMSG.HELP1 = "Ni Karma System ";

-- Locals
local Active = false;
local Raid_Name = "";
local RollOff = false;
local Orig_ChatFrame_OnEvent;
local Orig_SetItemRef;
local Orig_LootFrameItem_OnClick;
local Version = "3.0 rel 01";  -- wow base patch - NKS release (nondecreasing)
local DataVersion = 1;
local RollList;
local OpenRoll = false;
local min_deduction = 0;
local max_deduction = 0;

local extratext = ""; -- used for Karma_GetNextTok

local configpanel = {};	-- interface config panel
local KarmaDefaults = {};

KarmaDefaults["VERSION"] = Version;
KarmaDefaults["SHOW_WHISPERS"] = false;
KarmaDefaults["NOTIFY_ON_CHANGE"] = true;
KarmaDefaults["MAX_KARMA_CLASS_DEDUCTION"] = 100;
KarmaDefaults["MIN_KARMA_CLASS_DEDUCTION"] = 25;
KarmaDefaults["MAX_KARMA_NONCLASS_DEDUCTION"] = 0;
KarmaDefaults["MIN_KARMA_NONCLASS_DEDUCTION"] = 0;
KarmaDefaults["ALLOW_NEGATIVE_KARMA"] = false;
KarmaDefaults["KARMA_ROUNDING"] = 5;
KarmaDefaults["DATAVERSION"] = 0;
KarmaDefaults["LASTUPDATE"] = "unknown";
KarmaDefaults["CURRENT RAID"] = nil; -- used to see if active or not

function Karma_OnLoad(event)

  this:RegisterEvent("VARIABLES_LOADED"); 
  this:RegisterEvent("CHAT_MSG_WHISPER"); 

  -- add command
  SlashCmdList["KARMA"] = Karma_command;
  SLASH_KARMA1 = "/km";
  SLASH_KARMA2 = "/karma";

  -- Capture chat echos for filtering
  Orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
  ChatFrame_OnEvent = Karma_ChatFrame_OnEvent;
end

-- This function captures the events sent to the WoW chat window
-- We are filtering out 'Karma: ' whisper echos to users
function Karma_ChatFrame_OnEvent(self,event,...)

  local Suppressed = false
  local cmd,extra = Karma_GetToken(arg1);
  cmd = Karma_StripTok(cmd);

  -- Check if enabled
  if (Active) then
    if (event == "CHAT_MSG_WHISPER_INFORM" and string.find(arg1, "KarmaBot: ")
        and (not KarmaConfig["SHOW_WHISPERS"])) then
      Suppressed = true;
     
    elseif (event == "CHAT_MSG_WHISPER" and cmd == "km" 
        and (not KarmaConfig["SHOW_WHISPERS"])) then
      Suppressed = true;

    end
  end

  if (not Suppressed) then
    Orig_ChatFrame_OnEvent(self,event,...);
  end
end

-- Main event handler
function Karma_OnEvent(event)

  if (event == "VARIABLES_LOADED") then
    Karma_message("Ni Karma System (www.knights-who-say-ni.com/NKS) ".. Version .. KMSG.LOADED);
    Karma_Config();

    if (KarmaConfig["DATAVERSION"] < DataVersion) then
	-- version conflict with data, needs to be updated!
		Karma_message(KMSG.VERMISMATCH1 .. KarmaConfig["VERSION"] .. KMSG.VERMISMATCH2);
		Karma_update_data_popup();
    end
	KarmaConfig["VERSION"] = Version;
  end

  if (not Active) then 
    return;
  end
    
  if (event == "CHAT_MSG_WHISPER" and string.lower(string.sub(arg1,1,2)) == "km") then
    local cmd, extra = Karma_GetToken(arg1);
    cmd = Karma_StripTok(cmd);
	Karma_debug(1, "debug: cmd" .. cmd .. " extra:" .. extra)
    Karma_Player_Request(string.lower(arg2), extra);
  end
end

function Karma_update_data_popup()
	  Karma_message(KMSG.VERMISMATCH1 .. KarmaConfig["DATAVERSION"]);
	  StaticPopup_Show("NKSVERSION");
end

-- Main command routine
function Karma_command(msg)

  if (msg) then
    local cmd, subcmd = Karma_GetToken(msg);
	cmd = Karma_StripTok(cmd);

	-- if out of date, popup conversion if any command is entered
	-- will force reentering command.
    if (KarmaConfig["DATAVERSION"] < DataVersion) then
	  Karma_update_data_popup();
	  return;
	end

    if (cmd == KMSG.CUSE or cmd == KMSG.CCREATE) then
      if (subcmd == "") then
        Karma_message(KMSG.USERAID);
        Karma_Help();
        return;
      end

	  if (cmd == KMSG.CCREATE) then
	    if (KarmaList[subcmd] == nil) then
		  KarmaList[subcmd] = {};
		  Karma_message(KMSG.CREATED .. subcmd .. ")");
		else
		  Karma_message(KMSG.EXISTS);
		end
	  end

	  if (KarmaList[subcmd] == nil) then		-- /km use failed, do nothing
        Karma_message(KMSG.NOTFOUND);
		return;
      end
      Raid_Name = subcmd;
      Active = true;
	  KarmaConfig["CURRENT RAID"] = Raid_Name;
      Karma_message(KMSG.USINGRAID .. Raid_Name .. ")");

    elseif (cmd == "help" or cmd == KMSG.HELP) then
      Karma_Help();

    elseif (cmd ==KMSG.COPTION) then
      Karma_Options(subcmd);
 
    elseif (cmd == KMSG.CCOMPACT) then
      Karma_Compact(subcmd);
      
    elseif (cmd == KMSG.CINFO) then
      if (Active) then
        Karma_message(KMSG.USINGRAID .. Raid_Name .. ")");
      else
        Karma_message(KMSG.DISABLED);
      end
	elseif (cmd == KMSG.CSPAM) then
	  Karma_message(KMSG.SPAM, KARMA_SHOWTO_RAID);
	elseif (not Active or cmd == KMSG.COFF) then
      Active = false;
	  KarmaRollFrame:Hide();
	  KarmaConfig["CURRENT RAID"] = nil;
      Karma_message(KMSG.DISABLED);
--
-- Active raid only at this point
--
    elseif (cmd == KMSG.CROLL) then
      KarmaRollFrame:Show();

    elseif (cmd == KMSG.CSHOW) then
      Karma_Show(subcmd);
      
    elseif (cmd == KMSG.CADD) then
      Karma_Add(subcmd, "P");

    elseif (cmd == KMSG.CADDITEM) then
      Karma_Add(subcmd, "I");

    else
      Karma_Help();

    end 
  end
end

function Karma_Config()
  if (KarmaConfig["VERSION"] == nil) then
    KarmaConfig["VERSION"] = KarmaDefaults.VERSION;
  end
  if (KarmaConfig["SHOW_WHISPERS"] == nil) then
    KarmaConfig["SHOW_WHISPERS"] = KarmaDefaults.SHOW_WHISPERS;
  end
  if (KarmaConfig["NOTIFY_ON_CHANGE"] == nil) then
    KarmaConfig["NOTIFY_ON_CHANGE"] = KarmaDefaults.NOTIFY_ON_CHANGE;
  end
  if (KarmaConfig["MAX_KARMA_CLASS_DEDUCTION"] == nil) then
    KarmaConfig["MAX_KARMA_CLASS_DEDUCTION"] = KarmaDefaults.MAX_KARMA_CLASS_DEDUCTION;
  end
  if (KarmaConfig["MIN_KARMA_CLASS_DEDUCTION"] == nil) then
    KarmaConfig["MIN_KARMA_CLASS_DEDUCTION"] = KarmaDefaults.MIN_KARMA_CLASS_DEDUCTION;
  end
  if (KarmaConfig["MAX_KARMA_NONCLASS_DEDUCTION"] == nil) then
    KarmaConfig["MAX_KARMA_NONCLASS_DEDUCTION"] = KarmaDefaults.MAX_KARMA_NONCLASS_DEDUCTION;
  end
  if (KarmaConfig["MIN_KARMA_NONCLASS_DEDUCTION"] == nil) then
    KarmaConfig["MIN_KARMA_NONCLASS_DEDUCTION"] = KarmaDefaults.MIN_KARMA_NONCLASS_DEDUCTION;
  end
  if (KarmaConfig["ALLOW_NEGATIVE_KARMA"] == nil) then
    KarmaConfig["ALLOW_NEGATIVE_KARMA"] = KarmaDefaults.ALLOW_NEGATIVE_KARMA;
  end
  if (KarmaConfig["KARMA_ROUNDING"] == nil) then
    KarmaConfig["KARMA_ROUNDING"] = KarmaDefaults.KARMA_ROUNDING;
  end
  if (KarmaConfig["DATAVERSION"] == nil) then
    KarmaConfig["DATAVERSION"] = KarmaDefaults.DATAVERSION;
  end
  if (KarmaConfig["LASTUPDATE"] == nil) then
    KarmaConfig["LASTUPDATE"] = KarmaDefaults.LASTUPDATE;
  end
  KarmaConfig["CURRENT RAID"] = nil; -- used to see if active or not
end

function Karma_Default_Config()
    KarmaConfig["VERSION"] = KarmaDefaults.VERSION;
    KarmaConfig["SHOW_WHISPERS"] = KarmaDefaults.SHOW_WHISPERS;
    KarmaConfig["NOTIFY_ON_CHANGE"] = KarmaDefaults.NOTIFY_ON_CHANGE;
    KarmaConfig["MAX_KARMA_CLASS_DEDUCTION"] = KarmaDefaults.MAX_KARMA_CLASS_DEDUCTION;
    KarmaConfig["MIN_KARMA_CLASS_DEDUCTION"] = KarmaDefaults.MIN_KARMA_CLASS_DEDUCTION;
    KarmaConfig["MAX_KARMA_NONCLASS_DEDUCTION"] = KarmaDefaults.MAX_KARMA_NONCLASS_DEDUCTION;
    KarmaConfig["MIN_KARMA_NONCLASS_DEDUCTION"] = KarmaDefaults.MIN_KARMA_NONCLASS_DEDUCTION;
    KarmaConfig["ALLOW_NEGATIVE_KARMA"] = KarmaDefaults.ALLOW_NEGATIVE_KARMA;
    KarmaConfig["KARMA_ROUNDING"] = KarmaDefaults.KARMA_ROUNDING;
    KarmaConfig["DATAVERSION"] = KarmaDefaults.DATAVERSION;
    KarmaConfig["LASTUPDATE"] = KarmaDefaults.LASTUPDATE;
end


configpanel.name = "Ni Karma System";
configpanel.okay =
		function (self)
			self.originalValue = MY_VARIABLE;
		end

configpanel.cancel =
		function (self)
			MY_VARIABLE = self.originalValue;
		end

function ConfigPanel_OnLoad (panel)
    local subpanel = CreateFrame("FRAME","Ni Karma System");
  -- panel = CreateFrame("FRAME", "ConfigPanel");
    panel.name = configpanel.name;
    panel.okay = configpanel.okay;
    panel.cancel = configpanel.cancel;
    panel.defaults = Karma_Default_Config;

	subpanel.name = "test subpanel"

    InterfaceOptions_AddCategory(panel);
end 



function Karma_Help()
  Karma_message(KMSG.HELP1 .. Version);
  Karma_message(KMSG.HELP2);
  Karma_message(KMSG.HELP3);
end

function Karma_Player_Help(player)
  Karma_message(KMSG.PLAYER_HELP1, KARMA_SHOWTO_PLAYER, player);
  Karma_message(KMSG.PLAYER_HELP2, KARMA_SHOWTO_PLAYER, player);
  Karma_message(KMSG.PLAYER_HELP3, KARMA_SHOWTO_PLAYER, player);
end

function Karma_Show(cmd)

  if (cmd ~= "") then
    -- Get name and optional TO
    local player, extra = Karma_GetToken(cmd);

    -- Check for class display
    if (string.find(KMSG.allclasses, "|" .. player .. "|", 1, true) ~= nil) then

	-- Loop through raid members, showing matching class
      local raidcnt = GetNumRaidMembers();
      for i = 1, raidcnt do
        local name, _, _, _, class = GetRaidRosterInfo(i);
        if (player == string.lower(class)) then
          Karma_Show_Detail(string.lower(name), extra);
        end
      end
      
    elseif (player == KMSG.ALL) then
      
      -- Loop through all raid members
      local raidcnt = GetNumRaidMembers();
      for i = 1, raidcnt do
        local name, _, _, _, class = GetRaidRosterInfo(i);
        Karma_Show_Detail(string.lower(name), extra);
      end
      
    else
      Karma_Show_Detail(player, extra);
    end

  else
    Karma_message(KMSG.BADCOMMAND);
    Karma_Help();
  end
end


-- return lowercase name/index, name as seen, and class
-- if not found in raid, return name/name/unknown
function Karma_Getstats(player_name)
  player = string.lower(player_name);  -- index is lowercase

  local fullname, class, i;
  local raidcnt = GetNumRaidMembers();
  for i = 1, raidcnt do
    fullname, _, _, _, class = GetRaidRosterInfo(i);
    if (string.lower(fullname) == player) then 
      return player, fullname, class;
    end
  end
  return player, player, "unknown";
end

function Karma_Newplayer(player_name)
  if (not Active) then
    return;
  end
  local player, name, class = Karma_Getstats(player_name);

  if (KarmaList[Raid_Name][player] ~= nil) then
	  Karma_message("Error in Karma_Newplayer - player " .. player .. " exists!");
	  return;
  end
  KarmaList[Raid_Name][player] = { };
  KarmaList[Raid_Name][player]["fullname"] = player;
  KarmaList[Raid_Name][player]["class"] = class;
  KarmaList[Raid_Name][player]["points"] = 0;
  KarmaList[Raid_Name][player]["lifetime"] = 0;
  KarmaList[Raid_Name][player]["lastadd"] = date();
  Karma_debug(1, "added " .. player .. " as " .. name .. "/" .. class);
end

function Karma_Show_Detail(player, msg)

  local ShowTo = 0;

  if (KarmaList[Raid_Name][player] == nil) then
    Karma_message(KMSG.PLAYER .. player .. KMSG.NOHISTORY);
    return;
  end

  -- process command string
  local cmd, extra = Karma_GetToken(msg);

  if (cmd == "") then
    cmd = KMSG.KARMA;
  elseif (cmd == "to") then
    cmd = KMSG.KARMA;
    ShowTo = KARMA_SHOWTO_PLAYER;
  elseif (cmd == "rd") then
    cmd = KMSG.KARMA;
    ShowTo = KARMA_SHOWTO_RAID;
  end
  if (extra == "to") then
    ShowTo = KARMA_SHOWTO_PLAYER;
  elseif (extra == "rd") then
    ShowTo = KARMA_SHOWTO_RAID;
  end

  -- perform command    
  if (cmd == KMSG.KARMA) then
    Karma_SendTotal(player, ShowTo)

  elseif (cmd == KMSG.ITEMS) then
    for id, event in pairs(KarmaList[Raid_Name][player]) do
      if (tonumber(id) and event["type"] == "I") then
        Karma_message("[".. event["DT"] .. "] " .. KarmaList[Raid_Name][player]["fullname"] .. ": " .. event["value"] .. KMSG.COST .. event["reason"], ShowTo, player);
      end
    end

  elseif (cmd == KMSG.HISTORY) then
    for id, event in pairs(KarmaList[Raid_Name][player]) do
      if (tonumber(id)) then
        
        Karma_message("[".. event["DT"] .. "] " .. KarmaList[Raid_Name][player]["fullname"] .. ": " .. event["value"] .. KMSG.COST .. event["reason"], ShowTo, player);
      end
    end

    -- Send final total
    Karma_SendTotal(player, ShowTo)
  else
    Karma_message(KMSG.BADCOMMAND);
    Karma_Help();
  end

end

function Karma_SendTotal(player, ShowTo)

  local pts = 0;
  if (KarmaList[Raid_Name][player]["points"] ~= nil) then
    pts = KarmaList[Raid_Name][player]["points"];
  end
      
  if (ShowTo == KARMA_SHOWTO_PLAYER) then
    Karma_message(KMSG.CURRENT1 .. pts, ShowTo, player);
  else
    Karma_message(KMSG.CURRENT2 .. KarmaList[Raid_Name][player]["fullname"] ..": " .. pts, ShowTo, player);
  end
end

function Karma_Add(cmd, add_type)

  if (cmd ~= "") then
    -- Check points
    local pointsstr, extra = Karma_GetToken(cmd); -- do not strip the points token :)

    if (pointsstr == "") then
      Karma_message(KMSG.ADDNOPOINTS1);
      return;
    end

    local points = tonumber(pointsstr);
    if (points == nil) then
      Karma_message(KMSG.ADDNOPOINTS2);
      return;
    end

    -- Get name
    local player, reason = Karma_GetToken(extra);

    if (player == KMSG.ALL) then
      -- Loop through raid members, only add to online players
      local raidcnt = GetNumRaidMembers();
	  local missedout = "";
	  local totalnames=0;
	  for i = 1, raidcnt do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i);
        if (online) then
          Karma_Add_Player(string.lower(name), points, reason, add_type);
        else
          Karma_Add_Player(string.lower(name), points, reason, add_type);
		  totalnames = totalnames + 1;
		  if (totalnames > 10) then
			  missedout = missedout .. "\n" .. name;
			  totalnames = 0;
		  else
			  missedout = missedout .. " " .. name;
		  end
        end
      end
      if (missedout ~= "") then
		  Karma_message(KMSG.OFFLINELIST .. missedout);
	  end

    else
      Karma_Add_Player(player, points, reason, add_type);
    end

  else
    Karma_message(KMSG.BADCOMMAND);
    Karma_Help();
  end
end

function Karma_Add_Player(player_name, points, reason, add_type)
        
  if (reason == "" and add_type == "I") then
    -- If adding an item, reason can't be empty, it should contain item link
    Karma_message(KMSG.ADDITEM);
    return;
  end

  if (player_name == KMSG.ALL) then
    Karma_debug(1, "Debug: bad call in Karma_Add_Player");
	return;
  end

  local player, fullname, class = Karma_Getstats(player_name);

  if (KarmaList[Raid_Name][player] == nil) then
	Karma_Newplayer(player);
  else
	-- fix previous errors of them being added while not in raid
    if (fullname ~= nil and fullname ~= "") then
      KarmaList[Raid_Name][player]["fullname"] = fullname;
	  --[[ Dys: Old code was
	  	  if (KarmaList[Raid_Name][player]["class"] ~= nil
			and KarmaList[Raid_Name][player]["class"] ~= "unknown") then
]]--
	-- DYS: If we have a valid class, overwrite the old one.
	  if class ~= "unknown" then
		KarmaList[Raid_Name][player]["class"] = class;
	  end
    end
  end

  Karma_Mod_Player(player, add_type, points, reason)
end

function Karma_Mod_Player(kplayer, ktype, kvalue, kreason)

  -- Find the last used entry number
  local lastid = 0, data;
  for id, data in pairs(KarmaList[Raid_Name][kplayer]) do
    if (tonumber(id)) then
      if (id > lastid) then
        lastid = id;
      end
    end
  end
  
  -- check if you can go negative
  if ((not KarmaConfig["ALLOW_NEGATIVE_KARMA"]) and (KarmaList[Raid_Name][kplayer]["points"] + kvalue) < 0 and kvalue < 0) then
    kvalue = -KarmaList[Raid_Name][kplayer]["points"];
  end

  -- Increment for new entry
  lastid = lastid + 1;
  KarmaList[Raid_Name][kplayer][lastid] = { };
  KarmaList[Raid_Name][kplayer][lastid]["DT"] = date();
  KarmaList[Raid_Name][kplayer][lastid]["type"] = ktype;
  KarmaList[Raid_Name][kplayer][lastid]["value"] = kvalue;
  KarmaList[Raid_Name][kplayer][lastid]["reason"] = kreason;

  -- Add to points
  KarmaList[Raid_Name][kplayer]["points"] = KarmaList[Raid_Name][kplayer]["points"] + kvalue;

  -- Add to lifetime karma: all point add/subtracts, but not item subtracts (spending karma)
  if (ktype == "P") then
	KarmaList[Raid_Name][kplayer]["lifetime"] = KarmaList[Raid_Name][kplayer]["lifetime"] + kvalue;
  end

  -- Notify self and the player
  local addsub = KMSG.ADDED;
  if (kvalue < 0) then
    addsub = KMSG.DEDUCTED;
    kvalue = abs(kvalue);
  else
	KarmaList[Raid_Name][kplayer]["lastadd"] = date();
  end

  local msg = kvalue .. addsub .. kreason;
  Karma_message(kplayer ..": ".. msg);
  if (KarmaConfig["NOTIFY_ON_CHANGE"]) then
    Karma_message(msg, KARMA_SHOWTO_PLAYER, kplayer);
  end
end


function Karma_Options(cmd)
  if (cmd ~= "") then
    -- Get option name and value
    local opt, setting = Karma_GetArgument(cmd);

    if (opt == "show") then
      if (KarmaConfig["SHOW_WHISPERS"]) then
        Karma_message(KMSG.SHOW_WHISPERS .. " = " .. KMSG.ON);
      else
        Karma_message(KMSG.SHOW_WHISPERS .. " = " .. KMSG.OFF);
      end
      if (KarmaConfig["NOTIFY_ON_CHANGE"]) then
        Karma_message(KMSG.NOTIFY_ON_CHANGE .. " = " .. KMSG.ON);
      else
        Karma_message(KMSG.NOTIFY_ON_CHANGE .. " = " .. KMSG.OFF);
      end
      if (KarmaConfig["ALLOW_NEGATIVE_KARMA"]) then
        Karma_message(KMSG.ALLOW_NEGATIVE_KARMA .. " = " .. KMSG.ON);
      else
        Karma_message(KMSG.ALLOW_NEGATIVE_KARMA .. " = " .. KMSG.OFF);
      end
      Karma_message(KMSG.MIN_KARMA_CLASS_DEDUCTION .. " = " .. KarmaConfig["MIN_KARMA_CLASS_DEDUCTION"]);
      Karma_message(KMSG.MAX_KARMA_CLASS_DEDUCTION .. " = " .. KarmaConfig["MAX_KARMA_CLASS_DEDUCTION"]);
      Karma_message(KMSG.MIN_KARMA_NONCLASS_DEDUCTION .. " = ".. KarmaConfig["MIN_KARMA_NONCLASS_DEDUCTION"]);
      Karma_message(KMSG.MAX_KARMA_NONCLASS_DEDUCTION .. " = ".. KarmaConfig["MAX_KARMA_NONCLASS_DEDUCTION"]);
      Karma_message(KMSG.KARMA_ROUNDING .. " = ".. KarmaConfig["KARMA_ROUNDING"]);
      return;
    end
        
    if (opt == "" or setting == "") then
      Karma_message(KMSG.BADCOMMAND);
      Karma_Help();

    else
      opt = string.upper(opt);
      -- Check if option exists
      if (KarmaConfig[opt] ~= nil) then
        -- It does, change setting
        if (opt == KMSG.SHOW_WHISPERS) then
          KarmaConfig[opt] = (string.upper(setting) == KMSG.ON);

        elseif (opt == KMSG.NOTIFY_ON_CHANGE) then
          KarmaConfig[opt] = (string.upper(setting) == KMSG.ON);

        elseif (opt == KMSG.ALLOW_NEGATIVE_KARMA) then
          KarmaConfig[opt] = (string.upper(setting) == KMSG.ON);

        elseif (opt == KMSG.MIN_KARMA_CLASS_DEDUCTION) then
          KarmaConfig[opt] = tonumber(setting);

        elseif (opt == KMSG.MAX_KARMA_CLASS_DEDUCTION) then
          KarmaConfig[opt] = tonumber(setting);

        elseif (opt == KMSG.MIN_KARMA_NONCLASS_DEDUCTION) then
          KarmaConfig[opt] = tonumber(setting);

        elseif (opt == KMSG.MAX_KARMA_NONCLASS_DEDUCTION) then
          KarmaConfig[opt] = tonumber(setting);

        elseif (opt == KMSG.KARMA_ROUNDING) then
          KarmaConfig[opt] = tonumber(setting);

        end
        
      else
        Karma_message(KMSG.BADOPTION);
        Karma_Help();
      end
    end
    
  else
    Karma_message(KMSG.BADCOMMAND);
    Karma_Help();
  end
end

function Karma_Player_Request(player, cmdline)

  if (KarmaList[Raid_Name][player] == nil) then
    Karma_message(KMSG.NORECORD, KARMA_SHOWTO_PLAYER, player);
    return;
  end

  if (cmdline ~= "") then
    local cmd, cmd1, cmd2, extra;
	cmd, extra = Karma_GetToken(cmdline);
    cmd1 = Karma_StripTok(Karma_GetNextTok());
	cmd2 = Karma_StripTok(Karma_GetNextTok());

    Karma_debug(1, "debug (player_request): " .. cmd .. "+" .. cmd1 .. "+" .. cmd2 .. "+e="..extra);

--  km show [karma [<class in raid>|<player in raid>]] | km show history | km show items [class] | km help

--	Figure out player and target for remote command
    if (cmd == KMSG.CSHOW) then
	  if (cmd1 == "") then
		Karma_Player_Request_Cmd(player, player, KMSG.KARMA, cmd2)
	  elseif (cmd1 == KMSG.KARMA or cmd1 == KMSG.ITEMS) then
		if (cmd2 == "") then
		  Karma_Player_Request_Cmd(player, player, cmd1, cmd2)
	    else
		-- km show karma <something>
		-- look through raid for a class or name
          Karma_debug(3, "searching raid for " .. cmd2);
		  local raidcnt = GetNumRaidMembers();
          for i = 1, raidcnt do
            local name, _, _, _, class = GetRaidRosterInfo(i);
            if (cmd2 == string.lower(class) or cmd2 == string.lower(name)) then
              Karma_Player_Request_Cmd(player, string.lower(name), cmd1, cmd2)
            end
          end
		end
	  elseif (cmd1 == KMSG.HISTORY) then
        Karma_Player_Request_Cmd(player, player, cmd1, cmd2)
	  end
    elseif (cmd == "help" or cmd == KMSG.HELP) then
      Karma_Player_Help(player);
    else
      Karma_message(KMSG.BADCOMMAND, KARMA_SHOWTO_PLAYER, player);
      Karma_Player_Help(player);
	end
  end
end


function Karma_Player_Request_Cmd(player, target, cmd1, cmd2)
  Karma_debug(2, "debug (player_req_cmd): "..player.. "+" .. target .. "+" .. cmd1 .. "+" .. cmd2);

  if (KarmaList[Raid_Name][target] == nil) then
    Karma_message(target .. KMSG.NOHISTORY, KARMA_SHOWTO_PLAYER, player);
	return;
  end

  if (cmd1 == KMSG.KARMA) then
    local pts = 0;
    if (KarmaList[Raid_Name][target] ~= nil) then
      pts = KarmaList[Raid_Name][target]["points"];

      if (player ~= target) then
        Karma_message(KMSG.CURRENT2 .. KarmaList[Raid_Name][target]["fullname"] ..": " .. pts, KARMA_SHOWTO_PLAYER, player);
      else
        Karma_message(KMSG.CURRENT1 .. pts, KARMA_SHOWTO_PLAYER, player);
      end
    end

  elseif (cmd1 == KMSG.HISTORY) then
	-- show only last 10, to prevent spamming (and logouts)
    local firstid, lastid=0;
    if (KarmaList[Raid_Name][target] ~= nil) then
	  lastid = #(KarmaList[Raid_Name][target])
    end

    if (lastid < 10) then
      firstid = 1;
    else
      firstid = lastid - 9;
    end

    if (player == target) then	-- not possible to get history of others (yet)
      Karma_message(KMSG.RECENT1, KARMA_SHOWTO_PLAYER, player);
    else
      Karma_message(KMSG.RECENT2 .. KarmaList[Raid_Name][target]["fullname"]..":", KARMA_SHOWTO_PLAYER, player);
    end

    for id = firstid, lastid do
      local event = KarmaList[Raid_Name][target][id]
      if event then
        if (tonumber(id)) then      
          if (player ~= target) then   
            Karma_message(KarmaList[Raid_Name][target]["fullname"] ..": [".. event["DT"] .. "] " .. event["value"] .. KMSG.COST .. event["reason"], KARMA_SHOWTO_PLAYER, player);
          else
            Karma_message(KMSG.YOU .. ": [".. event["DT"] .. "] " .. event["value"] .. KMSG.COST .. event["reason"], KARMA_SHOWTO_PLAYER, player);
          end
        end
      end
    end

  elseif (cmd1 == KMSG.ITEMS) then
    for id, event in pairs(KarmaList[Raid_Name][target]) do
      if (tonumber(id) and event["type"] == "I") then
        if (player ~= target) then   
          Karma_message(KarmaList[Raid_Name][target]["fullname"] ..": [".. event["DT"] .. "] " .. event["value"] .. KMSG.COST .. event["reason"], KARMA_SHOWTO_PLAYER, player);
        else
          Karma_message(KMSG.YOU .. ": [".. event["DT"] .. "] " .. event["value"] .. KMSG.COST .. event["reason"], KARMA_SHOWTO_PLAYER, player);
        end
      end
    end

  else
    Karma_message(KMSG.BADSHOW, KARMA_SHOWTO_PLAYER, player);
    Karma_Player_Help(player);
  end
end


-- return #sec of day   "07/18/06 20:24:20"
function Karma_convdate(sdate)
    local yr = tonumber(string.sub(sdate, 7, 8)) + 2000;
    local t= time({year=yr,month=string.sub(sdate, 1, 2),day=string.sub(sdate, 4, 5), hour=string.sub(sdate, 10, 11), min=string.sub(sdate, 13, 14), sec=string.sub(sdate, 16, 17)});
	return t;
end

-- Sort by date comparitor function
-- could be off by an hour if DST is on, but that's no big deal for sorting.
-- Time is relative :)
function KarmaList_Sort(a, b)
	if (not a) then
		return false;
	elseif (not b) then
		return true;
	else
		return (Karma_convdate(a.DT) < Karma_convdate(b.DT));
	end
end

function Karma_Compact(cmd)
  if (cmd ~= "") then
    -- Get option name and value
    local days = tonumber(cmd);

    for rname, rdata in pairs(KarmaList) do
	  Karma_message(KMSG.COMPACTING .. rname);
      for player, pdata in pairs(KarmaList[rname]) do
        -- Add totals entry if it doesn't exist
        if (KarmaList[rname][player][0] == nil) then
          KarmaList[rname][player][0] = { };
          KarmaList[rname][player][0]["type"] = "P";
          KarmaList[rname][player][0]["value"] = 0;
          KarmaList[rname][player][0]["reason"] = KMSG.OLDENTRIES;
        end
        KarmaList[rname][player][0]["DT"] = date();

        for id, data in pairs(KarmaList[rname][player]) do
          if (tonumber(id)) then
            if (id > 0) then
              local sdate = Karma_convdate(KarmaList[rname][player][id]["DT"]);
              local diff = (time() - sdate) / 86400;
              if ((KarmaList[rname][player][id]["type"] == "P") and (diff > days)) then
                KarmaList[rname][player][0]["value"] = KarmaList[rname][player][0]["value"] + KarmaList[rname][player][id]["value"];
                KarmaList[rname][player][id] = nil;
              end
            end
          end
        end
		table.sort(KarmaList[rname][player], KarmaList_Sort)
      end
    end
  end

  Karma_message(KMSG.COMPACTED);
end

function Karma_update_data()
  local oldver=KarmaConfig["DATAVERSION"];

  Karma_message(KMSG.UPDATING .. KarmaConfig["DATAVERSION"]);

-- update to version 1
  if (oldver == 0) then
    Karma_recompute_lifetime();
	KarmaConfig["LASTUPDATE"] = date();

    oldver = 1;		-- now using version 1
    KarmaConfig["DATAVERSION"] = oldver;
  end

-- update to version 2
  if (oldver == 1) then
	-- up to date for the moment!
  end

end


function Karma_recompute_lifetime()
  local rname, rdata, player, pdata;

  for rname, rdata in pairs(KarmaList) do
	for player, pdata in pairs(KarmaList[rname]) do
	  -- Add compressed karma entries if they doesn't exist
	  if (KarmaList[rname][player][0] == nil) then
		KarmaList[rname][player][0] = { };
		KarmaList[rname][player][0]["type"] = "P";
		KarmaList[rname][player][0]["value"] = 0;
		KarmaList[rname][player][0]["reason"] = KMSG.OLDENTRIES;
		KarmaList[rname][player][0]["DT"] = date();
	  end

	  if (KarmaList[rname][player]["lastadd"] == nil) then
		KarmaList[rname][player]["lastadd"] = "unknown";
	  end

	  KarmaList[rname][player]["lifetime"] = KarmaList[rname][player][0]["value"];

	  -- compute all the point additions to get lifetime karma
	  for id, data in pairs(KarmaList[rname][player]) do
		if (tonumber(id) and id > 0) then
		  if (KarmaList[rname][player][id]["type"] == "P") then
			KarmaList[rname][player]["lifetime"] = KarmaList[rname][player]["lifetime"] + KarmaList[rname][player][id]["value"];
		  end
		end
	  end
	  table.sort(KarmaList[rname][player], KarmaList_Sort)
	end
  end
end



-- Utility functions
function Karma_message(msg, ...)
-- spit out a message from Karmabot.  Split across newlines.
  local m;
  if (select('#', ...) > 0) then
    if (select('1', ...) == KARMA_SHOWTO_PLAYER) then
      -- This whisper can be filtered out of raid leader's chat
      for m in string.gmatch(msg, "([^\n]*)\n*") do
          if (m ~= "") then
            SendChatMessage("KarmaBot: ".. m, "WHISPER", this.language, select('2', ...));
          end
      end
    elseif (select('1', ...) == KARMA_SHOWTO_RAID) then
      -- This message will appear in raid chat
      for m in string.gmatch(msg, "([^\n]*)\n*") do
          if (m ~= "") then
            SendChatMessage("Karma: ".. m, "RAID", this.language, "");
          end
      end
    elseif (select('1', ...) == KARMA_SHOWTO_LEADER) then
      -- Add message to raid leader's chat
      if ( DEFAULT_CHAT_FRAME ) then
          for m in string.gmatch(msg, "([^\n]*)\n*") do
          if (m ~= "") then
            DEFAULT_CHAT_FRAME:AddMessage("Karma: ".. m, 1.0, 1.0, 0);
          end
        end
      end
    end

  else
    -- Add message to raid leader's chat
    if ( DEFAULT_CHAT_FRAME ) then
      for m in string.gmatch(msg, "([^\n]*)\n*") do
        if (m ~= "") then
          DEFAULT_CHAT_FRAME:AddMessage("Karma: ".. m, 1.0, 1.0, 0);
        end
      end
    end
  end
end



---------------------------------------
----    Karma Roll Window Routines ----
---------------------------------------
function KarmaRoll_OnLoad()
  this:RegisterEvent("VARIABLES_LOADED"); 
  this:RegisterEvent("CHAT_MSG_SYSTEM"); 
  this:RegisterEvent("CHAT_MSG_WHISPER"); 

  -- Capture shift+click on an item
  -- Orig_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick;
  -- ContainerFrameItemButton_OnClick = KarmaItem_OnClick;

  -- wow2.0 stuff for secure hooks
  -- hooksecurefunc([table,] "functionName", hookfunc) 
  hooksecurefunc( "ContainerFrameItemButton_OnClick", KarmaItem_OnClick) 
  hooksecurefunc( "HandleModifiedItemClick", KarmaLootItem_OnClick)
  hooksecurefunc( "SetItemRef", Karma_SetItemRef) 
end

-- Main event handler
function KarmaRoll_OnEvent(event)

  if (event == "VARIABLES_LOADED") then
    RollList = {};
    KarmaRollFrameItem:SetText("");
    KarmaRollFrameBaseCost:SetText("0");
    KarmaRollFrameBaseCost:SetNumeric(1);
    KarmaRollFrameFinalKarma:SetText("0");
    KarmaRollFrameFinalKarma:SetNumeric(1);

  elseif (Active and event == "CHAT_MSG_WHISPER") then
	local cmd, extra = Karma_GetToken(arg1);
	cmd = Karma_StripTok(cmd);
	local cmd2, extra2 = Karma_GetToken(extra);
	cmd2 = Karma_StripTok(cmd2);
	if (cmd == KMSG.BONUS or cmd == KMSG.NOBONUS or (cmd == KMSG.NOBONUS1 and cmd2 == KMSG.NOBONUS2)) then
      KarmaRoll_AddPlayer(arg2, cmd == KMSG.BONUS);
    end
  elseif (Active and event == "CHAT_MSG_SYSTEM" and string.find(arg1, KMSG.SYS.ROLLS) and string.find(arg1, "%(1%-100%)")) then 
    _, _, player_name, player_roll = string.find(arg1, "(.+) " .. KMSG.SYS.ROLLS .. " (%d+)");
    if (player_name ~= nil and player_roll ~= nil) then
      KarmaRoll_Roll(player_name, player_roll);
    end
  end 
end

-- A player declared intention to roll, add them to list
function KarmaRoll_AddPlayer(player_name, use_bonus)
  local player, name, class = Karma_Getstats(player_name);

  if (KarmaList[Raid_Name][player] == nil) then
    -- Add player
	Karma_Newplayer(player);
  end

  -- Check if they are already in list  
  for i=1, #(RollList) do
    if (RollList[i][1] == name) then
      if (RollList[i][4] > 0) then
		  Karma_message(KMSG.PLAYER .. name .. KMSG.ROLLED .. tostring(RollList[i][4]) .. KMSG.REROLLED);
	  end
	  table.remove(RollList, i);
      break;
    end
  end

  if (class) then
    -- Player is in the raid if we found their class
    if (KarmaList[Raid_Name][player]["points"] < 0) then
      use_bonus = true; -- always bonus if you're negative muahhaa
    end

    table.insert(RollList, {name, class, 0, 0, 0, use_bonus});
    if (not OpenRoll) then
	  if (use_bonus) then
		Karma_message(KMSG.REPLYBONUS1 .. KarmaList[Raid_Name][player]["points"] .. KMSG.REPLYBONUS2, KARMA_SHOWTO_PLAYER, player);
	  else
		Karma_message(KMSG.REPLYNOBONUS, KARMA_SHOWTO_PLAYER, player);
	  end
	end
	KarmaRollList_Update();

  else
    Karma_message(KMSG.PLAYER .. player_name .. KMSG.NOTINRAID);
  end
end

-- A /roll was detected, update the list if they are in it

function KarmaRoll_Roll(player_name, player_roll)
  local player=string.lower(player_name);
-- If it's an open (no bonus declaration required) roll then add them to the list when they /roll
  if (OpenRoll) then
    if (KarmaList[Raid_Name][string.lower(player_name)] == nil) then
      Karma_Newplayer(player_name);
    end
    KarmaRoll_AddPlayer(player_name, false)
  end

  for i=1, #(RollList) do
    if (string.lower(RollList[i][1]) == player) then
      RollList[i][4] = tonumber(player_roll);
      RollList[i][5] = RollList[i][3] + RollList[i][4];
      break;
    end
  end

  KarmaRollList_Update();
end

-- Sort the rolls
function KarmaRoll_Sort(a, b)
  if (a[5] == b[5]) then
    return (a[1] < b[1]);
  else
    return (a[5] > b[5]);
  end;
end

-- Update the display
function KarmaRollList_Update()

  local rollOffset = FauxScrollFrame_GetOffset(KarmaRollScrollFrame);
  local base_cost = tonumber(KarmaRollFrameBaseCost:GetText());
  if (base_cost == nil) then
	  base_cost = 0;
  end

  numRolls = #(RollList);

  --  (RollList, {player_name, class, karma_used, 0, karma_used, use_bonus});

    -- "nobonus" will use 2 * base cost of the item.  It will also force using bonus if
    -- your karma is less than this value, since it'll cost you anyway.
    -- ex: you have 20 pts on a 25-point class item.  It will force you to use bonus of 20 pts no matter what.
    -- ex: you have 120 pts, nobonusing on a 25-point class item.  It will use 50 karma (or 2x the min cost).
    -- ex: you have 120 pts, nobonusing a non-class item.  It will use 0 karma.

  for i=1, numRolls do
	local player,karma_used,use_bonus = RollList[i][1],RollList[i][3],RollList[i][6];
	player = string.lower(player);
	if (OpenRoll) then
      karma_used = 0;
    elseif (use_bonus) then
      karma_used = KarmaList[Raid_Name][player]["points"];
    else
      karma_used = min(2 * base_cost , KarmaList[Raid_Name][player]["points"]);
    end

	RollList[i][3] = karma_used;
    RollList[i][5] = RollList[i][3] + RollList[i][4];
  end
  
  table.sort(RollList, KarmaRoll_Sort);
  
  for i=1, ROLLS_TO_DISPLAY do
    rollIndex = rollOffset + i;
    button = getglobal("KarmaRollFrameButton"..i);
    button.rollIndex = rollIndex;
    local roll_info = RollList[rollIndex];
    if (roll_info ~= nil) then
      getglobal("KarmaRollFrameButton"..i.."Name"):SetText(roll_info[1]);
      getglobal("KarmaRollFrameButton"..i.."Class"):SetText(roll_info[2]);
      getglobal("KarmaRollFrameButton"..i.."Karma"):SetText(roll_info[3]);
      getglobal("KarmaRollFrameButton"..i.."Roll"):SetText(roll_info[4]);
      getglobal("KarmaRollFrameButton"..i.."Total"):SetText(roll_info[5]);
    end

	-- Lock the highlight if a roller is selected
    if ( KarmaRollFrame.selectedRoller == rollIndex ) then
      button:LockHighlight();
    -- Here are the guts: divide the karma by 2
    -- (and drop fractions to the nearest rounding value)
    -- This is the BASIS of the zero-sum property
      local final_value = ceil(roll_info[3] / 2 / KarmaConfig["KARMA_ROUNDING"]) * KarmaConfig["KARMA_ROUNDING"];
      local base_cost = tonumber(KarmaRollFrameBaseCost:GetText());
      if (base_cost == nil) then base_cost = 0; end
      if (final_value < base_cost) then
        KarmaRollFrameFinalKarma:SetText(base_cost);
      else
        if (max_deduction > 0 and max_deduction < final_value) then
          final_value = max_deduction;
        end
        KarmaRollFrameFinalKarma:SetText(final_value);
      end
    else
      button:UnlockHighlight();
    end

    if ( rollIndex > numRolls ) then
      button:Hide();
    else
      button:Show();
    end
  end  
  
  -- Enable/disable buttons
  if (KarmaRollFrame.selectedRoller ~= nil and KarmaRollFrame.selectedRoller > 0 and
      KarmaRollFrameItem:GetText() ~= "") then
    KarmaRollFrameAwardButton:Enable();
  else
    KarmaRollFrameAwardButton:Disable();
  end
  
  -- ScrollFrame stuff
  FauxScrollFrame_Update(KarmaRollScrollFrame, numRolls, ROLLS_TO_DISPLAY, ROLL_FRAME_ROLL_HEIGHT );

end

-- Generic click handler for roller list
function KarmaRollFrameRollButton_OnClick(button)

  if ( button == "LeftButton" ) then
    KarmaRollFrame.selectedRoller = getglobal("KarmaRollFrameButton"..this:GetID()).rollIndex;
    KarmaRollList_Update();
  else
    -- Remove from list
    local roller = getglobal("KarmaRollFrameButton"..this:GetID()).rollIndex
    table.remove(RollList, roller);

    -- If we removed the last one, move bar up
    if (KarmaRollFrame.selectedRoller > #(RollList)) then
      KarmaRollFrame.selectedRoller = #(RollList);
    end
    KarmaRollList_Update();
  end
  
end

-- Clear the rollers list
function KarmaRollFrame_Clear()
  RollList = {};
  KarmaRollFrame.selectedRoller = 0;
  Karma_Clearitem();
  KarmaRollList_Update();
end

-- Declare winner
function KarmaRollFrameAwardButton_OnClick()
-- DYS: Minor modifications here
  local player = RollList[KarmaRollFrame.selectedRoller][1];
  local value = -tonumber(KarmaRollFrameFinalKarma:GetText());
  if (KarmaRollFrameItem:GetText() == "") then
    -- If adding an item, reason can't be empty, it should contain item link
    Karma_message(KMSG.ADDITEM);
    return;
  end
  local my_value2 = KarmaRollFrameFinalKarma:GetText();
  Karma_message(player .. KMSG.WINS .. KarmaRollFrameItem:GetText() .. KMSG.PAYING .. RollList[KarmaRollFrame.selectedRoller][3] .. " Karma. (rolled " .. RollList[KarmaRollFrame.selectedRoller][5]-RollList[KarmaRollFrame.selectedRoller][3] .. ") His/her total including roll is " .. RollList[KarmaRollFrame.selectedRoller][5] .. " (She/he lost ) " .. my_value2 .. " karma." , KARMA_SHOWTO_RAID);
  Karma_Add_Player(string.lower(player), value, KarmaRollFrameItem:GetText(), "I");
  TakeScreenshot()
  KarmaRollFrameAwardButton:Disable();

end

-- DYS: Announce button added
function KarmaRollFrame_RWAnnounce()
	local msg = "Please declare on " .. KarmaRollFrameItem:GetText() .. " to " .. UnitName("player") .. " and " .. UnitName("player") .. " only!";
	SendChatMessage(msg, "RAID_WARNING");
end

-- hooked with hooksecurefunc

function Karma_SetItemRef(link, text, button)
  Karma_update_rollframe(ItemRefTooltip, text);
end

function KarmaLootItem_OnClick(link)
  Karma_update_rollframe(GameTooltip, link);
end


function KarmaItem_OnClick(self,button)
  -- Karma_debug(3, "itemclick: button="..button);
  if ( button == "LeftButton" ) then
	if ( IsShiftKeyDown() ) then
	  Karma_update_rollframe(GameTooltip,
			GetContainerItemLink(this:GetParent():GetID(), this:GetID()));
    end
  end
end


function Karma_AddItemToText(TipFrame)
  TipFrame:Show();
  min_deduction = KarmaConfig["MIN_KARMA_NONCLASS_DEDUCTION"];
  max_deduction = KarmaConfig["MAX_KARMA_NONCLASS_DEDUCTION"];
  if (TipFrame:IsVisible()) then
	local numlines = TipFrame:NumLines();
    for n=1, numlines do
      local text_field = getglobal(TipFrame:GetName().."TextLeft".. n);
      if (text_field and text_field:IsVisible()) then
        local item_text = text_field:GetText();
        if (strfind(item_text, "Classes:")) then
          min_deduction = KarmaConfig["MIN_KARMA_CLASS_DEDUCTION"];
          max_deduction = KarmaConfig["MAX_KARMA_CLASS_DEDUCTION"];
          break;
        end
      end
    end
  end
  KarmaRollFrameBaseCost:SetText(min_deduction);
end


function Karma_Clearitem()
  KarmaRollFrameItem:SetText("");
  KarmaRollFrameBaseCost:SetText("0");
  KarmaRollFrameFinalKarma:SetText("0");
  KarmaRollList_Update();
end


function Karma_update_rollframe(tooltip, link)
	Karma_debug(3, "update rollframe: link="..link);	  

	-- there's one goofy bug here, if you have a tooltip up and click a link in chat, this
	-- will not search the tooltip for "Classes:" correctly (as it will hide the tooltip).
	if (string.match(link, "item:") and KarmaRollFrameItem:GetText() == "") then
		Karma_Clearitem();
		Karma_AddItemToText(tooltip);
		KarmaRollFrameItem:SetText(link);
	end
end


function KarmaRoll_OpenToggle()
	OpenRoll = not OpenRoll;
	KarmaRollFrameOpenCheckButton.checked = OpenRoll;
end


-- Strip off a token
-- Return the lowercase token and remainder of line
function Karma_GetToken(msg)
  if (msg) then
    local a,b,token,extra= string.find(msg, "([^%s]+)%s*(.*)");
	if (a) then
      token= string.lower(token);
	  extratext = extra;
	  Karma_debug(5, "gettoken: t="..token.."|"..extratext);	  
      return token, extra;
    end
  end
  return "", "";
end

function Karma_GetNextTok()
-- Note that it's possible, although unlikely, to get a race condition
-- if a chat message somehow gets to you between calls to Karma_GetToken
  local tok;
  tok, extra = Karma_GetToken(extratext);
  extratext = extra;
  return tok;
end

-- get rid of punctuation on tokens
function Karma_StripTok(token)
	local a,b,newtok = string.find(token, "([^%s%p]+)");
	if (not a) then
		newtok = "";
	end
	if (string.len(token) > 0) then
	    Karma_debug(5, "striptok: "..token..">"..newtok);
	end
	return newtok;
end

function Karma_debug(level, msg)
    if (Karma_debuglevel ~= nil and Karma_debuglevel >= level) then
		Karma_message(msg)
    end
end
------------------------------------------------------------------------------------------
-- Command helper routines
-- Created by Tigerheart (http://www.wowwiki.com/HOWTO:_Extract_Info_from_a_Slash_Command)
 
function Karma_GetArgument(msg)
  if (msg) then
    local a,b=string.find(msg, "[^=]+");
    if (not ((a==nil) and (b==nil))) then
      local cmd=string.lower(string.sub(msg,a,b)); 
      return cmd, string.sub(msg, string.find(cmd,"$")+1);
    else  
      return "", "";
    end
  end
  return "", "";
end
