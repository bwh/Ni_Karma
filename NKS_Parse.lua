-- Ni Karma System (NKS) for raid loot distribution
-- The Ni Karma System was designed by Vuelhering (stef+nks @swcp.com) and Qed of Icecrown
-- 
-- Plugin coded by Mavios of Icecrown (althar @gmail.com).  Thanks Mavios, you rock.
-- Code maintenance and additional programming by Mavios and Vuelhering
-- Instructions for use at http://www.knights-who-say-ni.com/NKS
-- 
-- Copyright 2006-2009, Mavios and Vuelhering, Knights who say Ni, Icecrown
-- 
-- Permission granted for use, modification, and distribution provided:
-- 1. Any distributions include the original distribution in its entirety, OR a working URL to freely get the entire original distribution is clearly listed in the documentation.
-- 2. Any modified distributions clearly mark YOUR changes, or document the changes somehow.
-- 3. Any modified distributions MUST NOT imply in any way that it is an official upgrade version of this software (such as NKS+ or Enhanced Karma System, or probably anything with "NKS" or "Karma" in the name).  If you want your changes in the official distribution, write (stef+nks @swcp.com) and it might get included.
-- 4. No fee is charged for any distribution of this software (modified or original).
-- 
-- Snippets of code "borrowed" (fewer than 100 total lines) can merely include the URL http://www.knights-who-say-ni.com/NKS and credit for the code used.

-- Strip off a token
-- Return the lowercase token and remainder of line


Karma_GetToken = Ni_GetToken
Karma_StripTok = Ni_StripTok
Karma_debug = Ni_Debug

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
