--[[
	NPL.load("(gl)script/PCoin/Database.lua");
	local Database = commonlib.gettable("Mod.PCoin.Database");
]]

NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/BlockDatabase.lua");
NPL.load("(gl)script/PCoin/TransactionDatabase.lua");
NPL.load("(gl)script/PCoin/SpendDatabase.lua");
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");

local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockDetail = commonlib.gettable("Mod.PCoin.BlockDetail");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local BlockDatabase = commonlib.gettable("Mod.PCoin.BlockDatabase");
local SpendDatabase = commonlib.gettable("Mod.PCoin.SpendDatabase");

local TransactionDatabase = commonlib.gettable("Mod.PCoin.TransactionDatabase");

local Database = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Database"));

Database.blocks = nil;
Database.transactions = nil;
Database.spends = nil;

function Database:ctor()
	self.blocks = nil;
	self.transactions = nil;
	self.spends = nil;
end

function Database.create(settings)
	local d = Database:new();
	d:init(settings.root, settings.sync)
	return d;
end

function Database:init(root, sync)
	self.db = TableDatabase:new():connect(root, function(result) end )
	self.db:EnableSyncMode(sync);

	self.blocks = BlockDatabase:new():init(self.db);
	self.transactions = TransactionDatabase:new():init(self.db);
	self.spends = SpendDatabase:new():init(self.db);
end

local function pushInputs(hash, inputs, db)
	for k,v in pairs(inputs) do
		local spendpoint = {hash = hash, index = k}
		db:store(v.preOutput, spendpoint);
	
	end

end

function Database:push(blockdetail)
	local txdb = self.transactions;
	local spdb = self.spends;
	local height = blockdetail:getHeight();

	for index,t in pairs(blockdetail.block.transactions) do
		local hash = t:hash();




		
		txdb:store( hash, height, index, t:toData());
	end


	self.blocks:store(blockdetail:getHash(), blockdetail:getHeight(), blockdetail.block:toData())
end

function Database:pop()
	local blocks = self.blocks;
	local h = blocks:getHeight();
	local err,blockdata = blocks:getBlockByHeight(h);
	local block = Block.create(blockdata.block)
	local blockdetail = BlockDetail.create(block);
	blockdetail:setHeight(blockdata.height);


	blocks:unlink(h);

	return blockdetail;
end

function Database:report()

end