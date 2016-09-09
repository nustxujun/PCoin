--[[
	NPL.load("(gl)script/PCoin/OrphanPool.lua");
	local OrphanPool = commonlib.gettable("Mod.PCoin.OrphanPool");
]]

local OrphanPool = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.OrphanPool"));

OrphanPool.pool = {};

function OrphanPool:trace(blockdetail)
	local trace = {};
	trace[1] = blockdetail;

	local pool = self.pool;
	local hash = blockdetail:getPreHash();
	local b = true;
	while(b) do
		b = pool[hash];
		if (b) then
			trace[#trace + 1] = b;
			hash = b:getPreHash();
		end
	end
	return trace;
end

function OrphanPool:add(blockdetail)
	local hash = blockdetail:getHash();
	local pool = self.pool
	if pool[hash] then
		return false--exist
	end

	pool[hash] = blockdetail;
	return true;
end

function OrphanPool:remove(blockdetail)
	self.pool[blockdetail:getHash()] = nil;
end

function OrphanPool:unprocessed()
	local ret = {}
	for k,v in pairs(self.pool) do
		if not v:processed() then
			ret[#ret + 1] = v;
		end
	end
	return ret;
end