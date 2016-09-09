--[[
	NPL.load("(gl)script/PCoin/Output.lua");
	local Output = commonlib.gettable("Mod.PCoin.Output");
]]


NPL.load("(gl)script/PCoin/Script.lua");

local Script = commonlib.gettable("Mod.PCoin.Script");
local Output = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Output"));

Output.value = nil;
Output.script = nil;

function Output.create(data)
	local i = Output:new()
	i:fromData(data)
	return i;
end

function Output:fromData(data)
	self.script = Script.create(data.script);
	self.value = data.value;
end

function Output:toData()
	return {script = self.script:toData(), value = self.value};
end
