--[[
	NPL.load("(gl)script/PCoin/BlockDatabase.lua");
	local BlockDatabase = commonlib.gettable("Mod.PCoin.BlockDatabase");
]]
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
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
		Utility.log("[BlockDatabase]blockchain height: " .. self.height);
	else

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
	self.db[Collection]:insertOne({height = height}, {height = height, hash = hash, block = blockData} )
	self:setHeight(height);
end

-- unlink blocks above the height from database(not removing)
function BlockDatabase:unlink(height)
	self:setHeight(height - 1);
end

function BlockDatabase:setHeight(h)
	self.height = h;
	self.db[Collection]:insertOne({header = Collection}, {header = Collection, height = h} )
end

function BlockDatabase:getHeight()
	return self.height;
end