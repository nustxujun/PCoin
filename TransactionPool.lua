--[[
	NPL.load("(gl)script/PCoin/TransactionPool.lua");
	local TransactionPool = commonlib.gettable("Mod.PCoin.TransactionPool");
]]

NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
NPL.load("(gl)script/PCoin/Buffer.lua");

local Buffer = commonlib.gettable("Mod.PCoin.Buffer");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
local validator = ValidateTransaction.validate; 

local TransactionPool = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.TransactionPool"));

function TransactionPool:ctor()
	self.chain = nil -- blockchain
	self.trans = nil;
end

function TransactionPool.create(chain, capacity)
	local t = TransactionPool:new()
	t:init(chain, capacity);
	return t;
end

function TransactionPool:init(chain,capacity)
	self.chain = chain;
	self.capacity = capacity;
	sellf.trans = Buffer:new();
end

function TransactionPool:store(transaction)

	local ret = validator(transaction, self, self.chain);
	if ret then
		return -- invalid
	end

	self:add(transaction);
end

function TransactionPool:get(hash)
	local index, tx = self.trans:find(function (t) return t:hash() == hash ;end)
	return tx;
end

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
	index = index or trans:find(
		function (t)  
			return t:hash() == hash ;
		end)

	if not index then
		return false;
	end	
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

function TransactionPool:report()
	echo("TransactionPool")
end