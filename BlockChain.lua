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

function BlockChain:ctor()
	self.database = nil;
	self.blocks = nil;
	self.transactions = nil;
	self.spends = nil;
	self.organizer = nil;
end

function BlockChain.create(settings)
	local bc = BlockChain:new()
	bc:init(settings)
	return bc;
end

function BlockChain:init(settings)
	self.database = Database.create(settings.database);
	self.blocks = self.database.blocks; -- BlockDatabase;
	self.transactions = self.database.transactions; -- TransactionDatabase;
	self.spends = self.database.spends;
	self.organizer = Organizer.create(self);
end

-- get block height by hash, default top
function BlockChain:getHeight(hashvalue)
	if not hashvalue then 
		return self.blocks:getHeight();
	end
	local data = self:fetchBlockDataByHash(hashvalue);

	if data then
		return data.height;
	else
		return nil;
	end;
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
	return true;
end

-- get block work from HEIGHT to TOP
-- default to return the whole chain difficulty
function BlockChain:getDifficulty(height)
	local blocks = self.database.blocks;
	local top = blocks:getHeight();
	if not top then
		return 0;
	end
	height = height or 1;

	local diff = 0;
	for i = height, top do
		local err, blockdata = blocks:getBlockByHeight(i);
		diff = diff + blockwork(blockdata.block.header.bits);
	end

	return diff;
end

function BlockChain:fetchBlockDataByHeight(height)
	local err, data = self.blocks:getBlockByHeight(height);
	return data;
end

function BlockChain:fetchBlockDataByHash(hash)
	local err, data = self.blocks:getBlockByHash(hash);
	return data;
end

function BlockChain:fetchTransactionData(hash)
	local err, data = self.transactions:get(hash)
	return data;
end

function BlockChain:fetchSpendData(outpoint)
	local err, data = self.spends:get(outpoint);
	return data;
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

function BlockChain:report()
	echo("BlockChain report:")
	local top = self:getHeight();
	echo("	height:" .. top .. " current target:" .. tostring(self:getDifficulty(top)));
	
	self.organizer:report();
	self.database:report()
end



--------------------------------------------------------------------------
function BlockChain.test()
	echo("BlockChain Test")
	NPL.load("(gl)script/PCoin/Settings.lua");
	local Settings = commonlib.gettable("Mod.PCoin.Settings");
	NPL.load("(gl)script/PCoin/Block.lua");
	local Block = commonlib.gettable("Mod.PCoin.Block");
	local BlockDetail = commonlib.gettable("Mod.PCoin.BlockDetail");

	echo("	create block chain")
	local bc = BlockChain.create(Settings.BlockChain);
	echo("	get top")
	local height = bc:getHeight(Block.genesis().header:hash());
	local bd = BlockDetail.create(Block.genesis());
	echo("	store block")
	bc:store(bd);

	local difficulty = bc:getDifficulty();

	bc:report();
end