--[[
	NPL.load("(gl)script/PCoin/Script.lua");
	local Script = commonlib.gettable("Mod.PCoin.Script");
]]

NPL.load("(gl)script/Pcoin/sha256.lua");
local Encoding = commonlib.gettable("System.Encoding");
local hash = Encoding.sha256;

local Script = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Script"));

function Script:ctor()
	self.operations = nil
end

function Script.create(data)
	local s = Script:new();
	s:fromData(data)
	return s;
end

function Script:fromData(data)
	self.operations = data;
end

function Script:toData()
	return self.operations;
end

--static 
function Script.verify(outscript, inscript)
	return outscript.operations == hash(inscript.operations,"string")
end
