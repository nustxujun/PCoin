--[[
	NPL.load("(gl)script/PCoin/Transaction.lua");
	local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
]]

NPL.load("(gl)script/PCoin/Input.lua");
NPL.load("(gl)script/PCoin/Output.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Constants.lua");
NPL.load("(gl)script/PCoin/Script.lua");
NPL.load("(gl)script/PCoin/Point.lua");

local Point = commonlib.gettable("Mod.PCoin.Point");
local Script = commonlib.gettable("Mod.PCoin.Script");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local hashfunc = Utility.bitcoinHash;
local Output = commonlib.gettable("Mod.PCoin.Output");
local Input = commonlib.gettable("Mod.PCoin.Input");

local Transaction = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Transaction"));

function Transaction:ctor()
	self.version = Constants.curVersion;
	self.inputs = {};
	self.outputs= {};
	self.locktime = nil;
end

function Transaction.create(data)
	local t = Transaction:new();
	t:fromData(data)
	return t;
end

function Transaction:fromData(data)
	self.version = data.version;
	self.locktime = data.locktime;

	local inputs = self.inputs
	local outputs = self.outputs
	
	for k,v in pairs(data.inputs) do
		inputs[#inputs + 1] = Input.create(v);
	end

	for k,v in pairs(data.outputs) do
		outputs[#outputs + 1] = Output.create(v);
	end
end

function Transaction:toData()
	local inputs = {}
	for k,v in pairs(self.inputs) do
		inputs[#inputs + 1] = v:toData();
	end
	local outputs = {}
	for k,v in pairs(self.outputs) do
		outputs[#outputs + 1] = v:toData();
	end

	return {version = self.version, locktime = self.locktime, inputs = inputs, outputs = outputs}
end

function Transaction:hash()
	if not self.hashvalue then
		self.hashvalue = hashfunc(self:toData());
	end
	return self.hashvalue
end

function Transaction:isCoinBase()
	return false;
end

function Transaction:isOnePiece()
	return #self.inputs == 1 and self.inputs[1].preOutput:isNull();
end

function Transaction:totalOutputValue()
	local total = 0;
	for k,v in pairs(self.outputs) do 
		total = total + v.value;
	end
	return total;
end

function Transaction.ONEPIECE()
	local tx = Transaction:new()
	tx.version = Constants.curVersion;
	
	local input = Input:new()
	input.script = Script.create("");
	input.preOutput = Point:new()
	tx.inputs[1] = input;

	local output = Output:new()
	output.value = Constants.maxMoney;
	output.script = Script.create("276b001138a77af339c5940af1b5ba30fcf5f75a6353ac47bf7a0fad"); 
	tx.outputs[1] = output;

	return tx
end