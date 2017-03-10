--[[
	NPL.load("(gl)script/PCoin/Block.lua");
	local Block = commonlib.gettable("Mod.PCoin.Block");
]]

NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");

local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local bitcoinHash = Utility.bitcoinHash;

local BlockHeader = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockHeader"));
local Block = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Block"));
local BlockDetail = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDetail"));

-- genesis block------------------------
function Block.genesis()
	local genesis = 
	{
		header = 
		{
			version = 1000,
			preBlockHash = "",
			merkle = "",
			timestamp = 0,
			nonce = 0;
			bits = Constants.maxTarget:getCompact();
		}
	}
	local b = Block.create(genesis)
	b.transactions = {}
	b.transactions[#b.transactions + 1] = Transaction.ONEPIECE();

	return b;
end
----------------------------------------

-- HEADER 
function BlockHeader.create(data)
	local h = BlockHeader:new();
	h:fromData(data);
	return h;
end

function BlockHeader:ctor()
	self.version = nil;
	self.preBlockHash = nil;
	self.merkle = nil;
	self.timestamp= nil;
	self.nonce= nil;
	self.bits = nil;
	self.hashvalue = nil;
end

function BlockHeader:fromData(data)
	self.version = data.version;
	self.preBlockHash = data.preBlockHash;
	self.merkle= data.merkle;
	self.timestamp = data.timestamp;
	self.nonce = data.nonce;
	self.bits= data.bits;

	return self;
end

function BlockHeader:toData()
	return 
	{
		version = self.version,
		preBlockHash = self.preBlockHash,
		merkle = self.merkle,
		timestamp = self.timestamp,
		nonce = self.nonce,
		bits = self.bits;
	}
end

function BlockHeader:hash(refresh)
	if refresh or not self.hashvalue then
		self.hashvalue = bitcoinHash(self:toData());
	end
	return self.hashvalue
end


-- BLOCK ------------------------------------------------------

function Block:ctor()
	self.header = nil;
	self.transactions = {};
end

function Block.create(data)
	local b = Block:new();
	b:fromData(data);
	return b;
end

function Block:fromData(data)
	self.header = BlockHeader.create(data.header);
	self.transactions = {}
	local trans = self.transactions
	for k,v in pairs(data.transactions or {}) do
		-- parse transaction outside
		trans[#trans + 1] = v;
	end
end

function Block:toData(fullData)
	local trans = {};
	if fullData then
		for k,v in pairs(self.transactions) do
			trans[#trans + 1] = v:toData();
		end
	else
		-- save hash to db
		-- get tx data from txdb with the hashes
		for k,v in pairs(self.transactions) do
			trans[#trans + 1] = v:hash();
		end
	end

	return 
	{
		header = self.header:toData(),
		transactions = trans,
	}
end

local function buildMerkleTree(merkle)
	if #merkle == 0 then
		return "0";
	end

	while #merkle > 1 do
		local size = #merkle;
		if size % 2 ~= 0 then
			merkle[#merkle + 1] = merkle[size];
			size = size + 1;
		end

		local newMerkle = {};
		for i = 1, size, 2 do
			local newroot = bitcoinHash(merkle[i] .. merkle[i+1]);
			newMerkle[#newMerkle + 1] = newroot;
		end
		merkle = newMerkle;
	end

	return merkle[1];
end

function Block:generateMerkleRoot()
	local hashs = {}
	for k,v in pairs(self.transactions) do
		hashs[#hashs + 1] = v:hash();
	end

	return buildMerkleTree(hashs)
end

-- BLOCK_DETAIL------------------------------------------------
function BlockDetail.create(block)
	local b = BlockDetail:new()
	b.block = block;
	return b;
end

function BlockDetail:ctor()
	self.block = nil;
	self.height = nil;
	self.processed = nil;
end

function BlockDetail:getPreHash()
	return self.block.header.preBlockHash;
end

function BlockDetail:getHash()
	return self.block.header:hash();
end

function BlockDetail:getHeight()
	return self.height
end

function BlockDetail:setHeight(h)
	self.height = h;
end

function BlockDetail:setProcessed()
	self.isProcessed = true;
end

function BlockDetail:processed()
	return self.isProcessed;
end

function BlockDetail:setInvalid()
	return self.invalid
end

function BlockDetail:isValid()
	return not self.invalid;
end


---------------------------------------------------------------------------------

function Block.test()
	echo("BlockHeader Test");
	local data = {}
	local header = BlockHeader.create(data);
	header:hash();
	echo(header:toData());

	echo("Block Test");
	local genesis = Block.genesis();
	echo(genesis:toData());
	genesis:generateMerkleRoot();
end

