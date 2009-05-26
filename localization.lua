
-- Ni Karma System localization file
-- Got a translation?  Send it to me at stef+nks@ swcp.com
-- otherwise, I'm going to translate it using google, and that can't be good! :-)


-----------------------------------------------
-- Don't change this stuff here - same for all locales
-----------------------------------------------
KMSG = { };
BINDING_HEADER_KARMA = "Ni Karma System";

-- Only for local output, doesn't work in tells
local BLU = "|cff6666ff";
local GRY = "|cff999999";
local GRE = "|cff66cc33";
local RED = "|cffcc6666";
local ORN = "|cffcc9933";
local YEL = "|cffffff00";

-----------------------------------------------
-- English localization (Default)
-----------------------------------------------
BINDING_NAME_ROLLWINDOW = "Open/Close Roll Window";

KMSG.LOADED = " loaded."
KMSG.VERMISMATCH1 = RED .. "Ni Karma System Warning:" .. YEL .."  Need to upgrade from database version "
KMSG.VERMISMATCH = RED .. "Ni Karma System Warning:\n" .. YEL .."Database version is outdated.  New databases may not be backward compatible with older program versions!\nClick OKAY to upgrade the database."
KMSG.UPDATING = "Updating data from version "
--
-- silliness:
StaticPopupDialogs["NKSVERSION"] = {
	text = KMSG.VERMISMATCH,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		Karma_update_data();
	end,
	timeout = 30,
	whileDead = 1,
	hideOnEscape = 1
};


--commands
KMSG.CUSE = "use"
KMSG.CCREATE = "create"
KMSG.COPTION = "option"
KMSG.CCOMPACT = "compact"
KMSG.CINFO = "info"
KMSG.COFF = "off"
KMSG.CROLL = "roll"
KMSG.CSHOW = "show"
KMSG.CADD = "add"
KMSG.CSUB = "sub"
KMSG.CADDITEM = "additem"
KMSG.CSPAM = "spam"

KMSG.BONUS = "bonus"
KMSG.NOBONUS = "nobonus"
-- for splitting the words... allow "no bonus" in addition to "nobonus"
KMSG.NOBONUS1 = "no"
KMSG.NOBONUS2 = "bonus"
KMSG.REPLYBONUS1 = "Your Karma of "
KMSG.REPLYBONUS2 = " will be added to your roll"
KMSG.REPLYNOBONUS = "Not using Karma on next roll"

-- command arguments, including player commands
KMSG.HELP = "help"
KMSG.ALL = "all"
KMSG.HISTORY = "history"
KMSG.ITEMS = "items"
KMSG.KARMA = "karma"

KMSG.HELP2 = "Fields in [brackets] are optional\nThe database name is case sensitive";
KMSG.HELP3 = "/KM command\nCommands:\n  HELP\n  OFF\n  INFO\n  ROLL\n  CREATE database\n  USE database\n  SHOW (playername\|class\|ALL) [KARMA\|ITEMS\|HISTORY] [TO\|RD]\n  ADD [-]# (ALL, player) [reason]\n  ADDITEM [-]# (ALL, player) itemlink [comment]\n  OPTION SHOW \| setting=ON\|OFF\|#\n  COMPACT #ofdays\n  SPAM";

-- player messages when sending "km <command>" tells to the loot master
KMSG.PLAYER_HELP1 = "Ni Karma System Help"
KMSG.PLAYER_HELP2 = "Fields in [brackets] are optional"
KMSG.PLAYER_HELP3 = "/t <loot_master> <command>\n  km show\n  km show [karma [class/player]]\n  km show history\n  km show items [class/player\]\n  km help\t  To get your karma, use \"km show\".  To get a list of the warrior karma in the raid, use \"km show karma warrior\""

-- the following is a FAST description of the system, and can be spammed for new players with /km spam.
KMSG.SPAM = "The Ni Karma System adds your Karma score to a /roll (1-100 + bonus) when you send me a tell of \"" .. KMSG.BONUS .. "\" and does a normal roll (1-100) when you send me a tell of \"" .. KMSG.NOBONUS .. "\".\nWhen asked to declare on items, send me only \"" .. KMSG.BONUS .. "\" or \"" .. KMSG.NOBONUS .. "\", and /roll when told.\nOnly those within 50 karma of the highest \"bonus\" score can roll.\nIf you win and are using Karma bonus, you lose half.  There is no loss if you don't use bonus, or don't win, but class-specific items have a min/max loss, usually 25/100 pts."

KMSG.NORAID = "No active raid";
KMSG.BADCOMMAND = "Invalid Command";

KMSG.YOU = "You"
KMSG.PLAYER = "Player: "
KMSG.NOHISTORY = " is not in raid history"
KMSG.CURRENT1 = "Your current Karma: "
KMSG.CURRENT2 = "Current Karma of "

KMSG.ADDNOPOINTS1 = "You must specify amount of karma to ADD"
KMSG.ADDNOPOINTS2 = "Karma to ADD must be a number (positive or negative)"
KMSG.OFFLINELIST = "Offline (no karma added): "

KMSG.ADDITEM = "You must specify an item"
KMSG.USERAID = "You must specify a database"
KMSG.NOTFOUND = "Database not found.  (Check your spelling and capitalization, or " .. BLU .. "/km create <dbname>"..YEL.." to create a new database)"
KMSG.EXISTS = "Database already exists and will not be created again"
KMSG.CREATED = "Creating new database ("
KMSG.USINGRAID = "Karma running on database ("
KMSG.DISABLED = "Karma is off.  " .. BLU .. "/km use <Database>" .. YEL .. " to load one, or " .. BLU .. "/km create <Database>" .. YEL .. " to create a new database"

KMSG.ON = "ON" -- uppercase
KMSG.OFF = "OFF"

-- options are ONLY the words, do not use for table indices
KMSG.SHOW_WHISPERS = "SHOW_WHISPERS"
KMSG.NOTIFY_ON_CHANGE = "NOTIFY_ON_CHANGE"
KMSG.ALLOW_NEGATIVE_KARMA = "ALLOW_NEGATIVE_KARMA"
KMSG.MIN_KARMA_CLASS_DEDUCTION = "MIN_KARMA_CLASS_DEDUCTION"
KMSG.MAX_KARMA_CLASS_DEDUCTION = "MAX_KARMA_CLASS_DEDUCTION"
KMSG.MIN_KARMA_NONCLASS_DEDUCTION = "MIN_KARMA_NONCLASS_DEDUCTION"
KMSG.MAX_KARMA_NONCLASS_DEDUCTION = "MAX_KARMA_NONCLASS_DEDUCTION"
KMSG.KARMA_ROUNDING = "KARMA_ROUNDING"
KMSG.BADOPTION = "Unknown option"

KMSG.NORECORD = "No record of you in current database"

KMSG.RECENT1 = "Your recent events:"
KMSG.RECENT2 = "Recent events for "

KMSG.DEDUCTED = " karma deducted for "
KMSG.ADDED = " karma added for "
KMSG.COST = " karma for "
KMSG.BADSHOW = "Invalid SHOW command"

KMSG.COMPACTING = "Compacting old entries for "
KMSG.COMPACTED = "Compact complete"
KMSG.ROLLED = " roll "
KMSG.REROLLED = " rerolled."
KMSG.NOTINRAID = " tried to join roll list but is not in the raid"
KMSG.WINS = " is the winner of "
KMSG.PAYING = " using "
KMSG.TOTAL = " karma for a total of "

-- compacted entry
KMSG.OLDENTRIES = "Karma From Old Entries"

-- OLD: not really a message, but will have localization issues
-- OLD: I'm using '|' for string searching, so it should have those at each end of each word
-- OLD: KMSG.allclasses = "|druid|hunter|mage|paladin|priest|rogue|shaman|warlock|warrior|";


--
-- KMSG.CLASS.localname = "db_class"
-- You can have multiple localnames and aliases if you like.
--
KMSG.CLASS = { }

-- This section has two parts.  First you must have the all classes as returned by GetRaidRosterInfo
-- mapped to the english version.
-- Next, you can have aliases, mapping to the appropriate english version.
-- ex:
-- ["hexenmeister"] = "Warlock",
-- ["hexenmeisterin"] = "Warlock",
-- ["warlock"] = "Warlock"
-- ["dk"] = "Death Knight"
--
-- I didn't add all the languages here, because someone on the US client might name their warlock "Hexenmeister"
-- Add the local names as needed based on GetLocale()
--
KMSG.CLASS.druid = "Druid"
KMSG.CLASS.hunter = "Hunter"
KMSG.CLASS.mage = "Mage"
KMSG.CLASS.paladin = "Paladin"
KMSG.CLASS.priest = "Priest"
KMSG.CLASS.rogue = "Rogue"
KMSG.CLASS.shaman = "Shaman"
KMSG.CLASS.warlock = "Warlock"
KMSG.CLASS.warrior = "Warrior"
KMSG.CLASS["death knight"] = "Death Knight"
-- aliases for the command /km show <class>
KMSG.CLASS.deathknight = "Death Knight"
KMSG.CLASS.dk = "Death Knight"

-- roll window
KMSG.ROLL = { };
KMSG.ROLL.MIN = "Min Karma:"
KMSG.ROLL.MAX = "Max"

-- system output
KMSG.SYS = { };
KMSG.SYS.ROLLS = "rolls"


-----------------------------------------------
-- German localization
-----------------------------------------------
if ( GetLocale() == "deDE" ) then

-- system output
KMSG.SYS.ROLLS = "w\195\188rfelt. Ergebnis:"

-- German names from Alexander 'Bl4ckSh33p' Spielvogel and his brother ESN
-- Thanks!
-- English names from above should also work.
KMSG.CLASS = {
	["hexenmeister"] = "Warlock",
	["hexenmeisterin"] = "Warlock",
	["krieger"] = "Warrior",
	["kriegerin"] = "Warrior",
	["j\195\164ger"] = "Hunter",
	["j\195\164gerin"] = "Hunter",
	["magier"] = "Mage",
	["magierin"] = "Mage",
	["priester"] = "Priest",
	["priesterin"] = "Priest",
	["druide"] = "Druid",
	["druidin"] = "Druid",
	["paladin"] = "Paladin",
	["schamane"] = "Shaman",
	["schamanin"] = "Shaman",
	["schurke"] = "Rogue",
	["schurkin"] = "Rogue",
	["todesritter"] = "Death Knight",
}


-----------------------------------------------
-- French localization
-----------------------------------------------
elseif ( GetLocale() == "frFR" ) then


end

