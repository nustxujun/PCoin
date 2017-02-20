--[[
    NPL.load("(gl)script/PCoin/Proxy.lua");
	local Proxy = commonlib.gettable("Mod.PCoin.Proxy");
]]

local Proxy = commonlib.inherit(nil,commonlib.gettable("Mod.PCoin.Proxy"));
NPL.load("(gl)script/PCoin/Network.lua");
local Network = commonlib.gettable("Mod.PCoin.Network");

function Proxy:send(msg)
 -- pure virtual
end

function Proxy:pickMessage(msg)
	if msg.service == "PCoin" then
		Network.receive(msg);
		return true;
	else
		return false;
	end
end