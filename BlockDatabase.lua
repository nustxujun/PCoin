--[[
	NPL.load("(gl)script/PCoin/BlockDatabase.lua");
	local BlockDatabase = commonlib.gettable("Mod.PCoin.BlockDatabase");
]]
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/Block.lua");

local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockDetail = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDetail"));
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local BlockDatabase = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDatabase"));

local Collection = "Blocks";

function BlockDatabase:ctor()
	self.db = nil;
	self.height = 0;
end

function BlockDatabase:init(db)
	self.db = db;
	local err, data = self.db[Collection]:findOne({header=Collection})
	if data then
		self.height = data.height 
		echo("local blocks height: " .. self.height);
	else
		echo("generate genesis block");
		self:setHeight(1);
		local genesis = Block.genesis();

		self:store(genesis.header:hash(), 1, genesis:toData())
	end
	return self;
end

function BlockDatabase:getBlockByHash(hashvalue, callback)
	local err, data = self.db[Collection]:findOne({hash = hashvalue}, callback);
	if data and data.height >self.height then	
		data = nil;
	end
	return err, data;
end

function BlockDatabase:getBlockByHeight(height,callback)
	if height > self.height then
		return 
	end

	return self.db[Collection]:findOne({height = height}, callback);
end


function BlockDatabase:store(hash, height, blockData )
	self.db[Collection]:insertOne({height = height}, {height = height, hash = blockdetail:getHash(), block = blockData} )
end

-- unlink blocks above the height from database(not removing)
function BlockDatabase:unlink(height)
	self:setHeight(height - 1);
end

function BlockDatabase:setHeight(h)
	echo("error...setheight.. "..h)
	self.height = h;
	self.db[Collection]:insertOne({header = Collection}, {header = Collection, height = h} )
end

function BlockDatabase:getHeight()
	return self.height;
end