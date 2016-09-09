--[[
	NPL.load("(gl)script/PCoin/Script.lua");
	local Script = commonlib.gettable("Mod.PCoin.Script");
]]

local Script = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Script"));

function Script.create(data)
	local s = Script:new();
	s:fromData(data)
	return s;
end

function Script:fromData(data)
end

function Script:toData()
end


