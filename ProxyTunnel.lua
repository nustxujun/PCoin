--[[
	NPL.load("(gl)script/PCoin/ProxyTunnel.lua");
	local ProxyTunnel = commonlib.gettable("Mod.PCoin.ProxyTunnel");
]]
NPL.load("(gl)script/PCoin/Proxy.lua");

local ProxyTunnel = commonlib.inherit(commonlib.gettable("Mod.PCoin.Proxy"),commonlib.gettable("Mod.PCoin.ProxyTunnel"));

function ProxyTunnel:send(nid, msg)
	self.tunnel:Send(nid, msg);
end
