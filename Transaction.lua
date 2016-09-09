--[[
	NPL.load("(gl)script/PCoin/Transaction.lua");
	local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
]]

NPL.load("(gl)script/PCoin/Input.lua");
NPL.load("(gl)script/PCoin/Output.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local hashfunc = Utility.bitcoinHash;
local Output = commonlib.gettable("Mod.PCoin.Output");
local Input = commonlib.gettable("Mod.PCoin.Input");

local Transaction = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Transaction"));

Transaction.version = nil;
Transaction.inputs = {};
Transaction.outputs= {};
Transaction.locktime = nil;


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

function Transaction:toData(data)

end

function Transaction:hash()
	if not self.hashvalue then
		self.hashvalue = hashfunc(self:toData());
	end
	return self.hashvalue
end

function Transaction:isCoinBase()
	return #input == 1 and input[1].preOuput:isNull();
end