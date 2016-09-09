--[[
	NPL.load("(gl)script/PCoin/Input.lua");
	local Input = commonlib.gettable("Mod.PCoin.Input");
]]


NPL.load("(gl)script/PCoin/Point.lua");
NPL.load("(gl)script/PCoin/Script.lua");

local Script = commonlib.gettable("Mod.PCoin.Script");
local Point = commonlib.gettable("Mod.PCoin.Point");
local Input = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Input"));

Input.preOutput = nil;
Input.script = nil;
Input.sequence = nil;

function Input.create(data)
	local i = Input:new()
	i:fromData(data)
	return i;
end

function Input:fromData(data)
	-- if the transaction is coinbase, data.preOutput is {} 
	self.preOutput = Point.create(data.preOutput);
	self.script = Script.create(data.script);
	self.sequence = data.sequence;
end

function Input:toData()
	return {preOutput = self.preOutput:toData(), script = self.script:toData(), sequence = self.sequence};
end
