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


--{item="desc", height=1}
local Header = "BlocksDesc";
local Collection = "Blocks";

BlockDatabase.db = nil;
BlockDatabase.height = 0;

function BlockDatabase:ctor()
end

function BlockDatabase:init(db)
	self.db = db;
	local err, data = self.db[Header]:findOne({item="desc"})
	if data then
		self.height = data.height 
		echo("local blocks height: " .. self.height);
	else
		echo("generate genesis block");
		self:setHeight(1);
		local bd = BlockDetail.create(Block.genesis());
		bd:setHeight(1);
		self:store(bd)
	end
	return self;
end

function BlockDatabase:getBlockByHash(hashvalue, callback)
	return self.db[Collection]:findOne({hash = hashvalue}, callback);
end

function BlockDatabase:getBlockByHeight(height,callback)
	return self.db[Collection]:findOne({height = height}, callback);
end


function BlockDatabase:store(blockdetail)
	local height = blockdetail:getHeight();
	self.db[Collection]:insertOne({height = height}, {height = height, hash = blockdetail:getHash(), block = blockdetail.block:toData()} )
end

-- unlink blocks above the height from database(not removing)
function BlockDatabase:unlink(height)
	self:setHeight(height - 1);
end

function BlockDatabase:setHeight(h)
	echo("error...setheight.. "..h)
	self.height = h;
	self.db[Header]:insertOne({item = "desc"}, {item="desc", height = h} )
end

function BlockDatabase:getHeight()
	return self.height;
end