--[[
	NPL.load("(gl)script/PCoin/TransactionPool.lua");
	local TransactionPool = commonlib.gettable("Mod.PCoin.TransactionPool");
]]

NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
NPL.load("(gl)script/PCoin/Buffer.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Buffer = commonlib.gettable("Mod.PCoin.Buffer");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
local validator = ValidateTransaction.validate; 

local TransactionPool = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.TransactionPool"));

function TransactionPool:ctor()
	self.chain = nil -- blockchain
	self.trans = nil;
end

function TransactionPool.create(chain, settings)
	local t = TransactionPool:new()
	t:init(chain, settings);
	return t;
end

function TransactionPool:init(chain,settings)
	self.chain = chain;
	self.capacity = settings.capacity;
	self.trans = Buffer:new();

	chain:setHandler(function (...) self:notifyReorganize(...); end);
end

function TransactionPool:store(transaction)
	local ret = validator(transaction, self, self.chain);
	
	if ret then
		Utility.log("[TransactionPool] failed to store transaction, reason: %s", ret);	
		return false-- invalid
	end

	self:add(transaction);
	Utility.log("[TransactionPool] accept a transaction, hash: %s, inputs: %d, outputs: %d", 
		Utility.HashBytesToString(transaction:hash()),
		#transaction.inputs,
		#transaction.outputs);	
	
	return true
end

function TransactionPool:get(hash)
	local index, tx = self.trans:find(function (t) return t:hash() == hash ;end)
	return tx;
end

function TransactionPool:getAll()
	local ret = {}
	for k,v in self.trans:iterator() do
		ret[#ret + 1] = v;
	end
	return ret;
end

-- tx will be found with hash if index is nil
function TransactionPool:remove(tran, index)
	local hash = tran:hash();
	if self:removeSingle(hash, index) then
		self:removeDependencies(hash)
	end
end

function TransactionPool:add(tran)
	local trans = self.trans
	if trans:size() > self.capacity then
		self:remove(trans:front(), 1);
	end
	trans:push_back(tran);
end

function TransactionPool:removeSingle(hash, index)
	local trans = self.trans
	if not index then
		local t;
		t, index = trans:find( function (t)  return t:hash() == hash ; end)
	end

	if not index then
		return false;
	end	

	Utility.log("[TransactionPool] remove transaction from pool, hash: %s", Utility.HashBytesToString(hash));	
	trans:erase(index);
	return true;
end

function TransactionPool:removeDependencies(hash)
	local deps = {}
	for k,v in self.trans:iterator() do
		for j,k in v.inputs do
			if k.preOutput.hash == hash then
				deps[#deps + 1] = v;
				break;
			end
		end
	end

	for k,v in pairs(deps) do
		self:remove(v);
	end
end

local events = {};

events.PushBlock = 
function (pool, blockdetail)
	for i, t in pairs(blockdetail.block.transactions) do
		pool:remove(t)
	end

end

events.PopBlock = 
function (pool, blockdetail)
	for i, t in pairs(blockdetail.block.transactions) do
		pool:push(t)
	end
end



function TransactionPool:notifyReorganize(event, ... )
	local e = events[event]
	if e then
		e(self, ...);
	end
end







function TransactionPool:report()
	echo("TransactionPool")
	echo(	self.trans:size() .. " transactions in pool");
end