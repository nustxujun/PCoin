--[[
	NPL.load("(gl)script/PCoin/OrphanPool.lua");
	local OrphanPool = commonlib.gettable("Mod.PCoin.OrphanPool");
]]

NPL.load("(gl)script/PCoin/Buffer.lua");
local Buffer = commonlib.gettable("Mod.PCoin.Buffer");

local OrphanPool = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.OrphanPool"));

function OrphanPool:ctor()
	self.pool = {};
end

-- find previous blocks in pool
function OrphanPool:trace(blockdetail)
	local trace = {};
	trace[#trace + 1] = blockdetail;

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

	local reverse = Buffer:new();
	local size = #trace;
	for i = size , 1 , -1 do
		reverse:push_back(trace[i]);
	end
	return reverse;
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

function OrphanPool:exist(hash)
	return self.pool[hash] ~= nil
end

function OrphanPool:report()
	echo("OrphanPool")
	echo("	orphan size:".. #self.pool)
	local q = self:unprocessed();
	echo("	unprocessed orphan size:" .. #q);
end