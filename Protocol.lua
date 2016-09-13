--[[
	NPL.load("(gl)script/PCoin/Protocol.lua");
	local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
]]

local Protocol = commonlib.gettable("Mod.PCoin.Protocol");

local type = 
{
	request = 1,
	response = 2,
	broadcast = 3,
	notify = 4
}

local protocols = 
{
	"ping"
	"version"
	"node_address"
	"block",
	"block_header",
	"transaction",
	"",
}

local protocolmap = {}
for i,p in ipairs(protocols) do
	protocolmap[p] = i; 
end

local function getProtocolName(i)
	return protocols[i];
end

local function getProtocolID(name)
	return protocolmap[name];
end




function Protocol.requestBlock()

end

function 