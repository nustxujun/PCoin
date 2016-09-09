--[[
	NPL.load("(gl)script/PCoin/BlockChain.lua");
	local BlockChain = commonlib.gettable("Mod.PCoin.BlockChain");
]]

NPL.load("(gl)script/PCoin/Database.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Organizer.lua");

local Organizer = commonlib.gettable("Mod.PCoin.Organizer");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local blockwork = Utility.blockWork;
local log = Utility.log;
local Database = commonlib.gettable("Mod.PCoin.Database");

local BlockChain = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockChain"));

BlockChain.database = nil;
BlockChain.blocks = nil;
BlockChain.organizer = nil;

function BlockChain.create(settings)
	local bc = BlockChain:new()
	bc:init(settings)
	return bc;
end

function BlockChain:ctor()
end

function BlockChain:init(settings)
	self.database = Database.create(settings.database);
	self.blocks = self.database.blocks; -- BlockDatabase;
	self.organizer = Organizer.create(self);
end

function BlockChain:getHeight(hashvalue)
	local blocks = self.blocks;
	local top = #blocks;
	for i = top, 1, -1 do
		if blocks[i]:getHash() == hashvalue then
			return i;
		end
	end
end

function BlockChain:store(blockdetail)
	local blocks = self.blocks;
	local err, blockdata = blocks:getBlockByHash(blockdetail:getHash());
	if  blockdata then
		return false-- exist;
	end

	if not self.organizer:add(blockdetail) then
		return false;
	end

	self.organizer:organize();

end

function BlockChain:fetchTransaction(hash)
	
end

-- get block work from HEIGHT to TOP
function BlockChain:getDifficulty(height)
	local blocks = self.database.blocks;
	local top = blocks:getHeight();
	if not top then
		return 0;
	end

	local diff = 0;
	for i = height, top do
		local err, blockdata = blocks:getBlockByHeight(i);
		diff = diff + blockwork(blockdata.header.bits);
	end

	return diff;
end


--[[internal]]

function BlockChain:push(blockdetail)
	self.database:push(blockdetail);
end

-- remove and return blocks above the given height
function BlockChain:pop(height --[[default: top]])
	local ret = {}
	local db = self.database;
	local blocks = self.blocks;
	local top = blocks:getHeight();
	height = height or top; 
	while height <= top do 
		ret[#ret + 1] = db:pop();
		top = blocks:getHeight();
	end
	return ret;
end
