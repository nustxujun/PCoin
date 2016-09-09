--[[
	NPL.load("(gl)script/PCoin/Database.lua");
	local Database = commonlib.gettable("Mod.PCoin.Database");
]]

NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/BlockDatabase.lua");
NPL.load("(gl)script/PCoin/Block.lua");

local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockDetail = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDetail"));
local BlockDatabase = commonlib.gettable("Mod.PCoin.BlockDatabase");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local Database = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Database"));

Database.blocks = nil;

function Database.create(settings)
	local d = Database:new();
	d:init(settings.root, settings.sync)
	return d;
end

function Database:ctor()

end

function Database:init(root, sync)
	self.db = TableDatabase:new():connect(root, function(result) end )
	self.db:EnableSyncMode(sync);

	self.blocks = BlockDatabase:new():init(self.db);
end

function Database:push(blockdetail)
	



	self.blocks:store(blockdetail)

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

