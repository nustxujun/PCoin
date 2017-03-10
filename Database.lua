--[[
	NPL.load("(gl)script/PCoin/Database.lua");
	local Database = commonlib.gettable("Mod.PCoin.Database");
]]

NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/BlockDatabase.lua");
NPL.load("(gl)script/PCoin/TransactionDatabase.lua");
NPL.load("(gl)script/PCoin/SpendDatabase.lua");
NPL.load("(gl)script/PCoin/HistoryDatabase.lua");
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/Wallet/PaymentAddress.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");

local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Block = commonlib.gettable("Mod.PCoin.Block");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local BlockDatabase = commonlib.gettable("Mod.PCoin.BlockDatabase");
local SpendDatabase = commonlib.gettable("Mod.PCoin.SpendDatabase");
local HistoryDatabase = commonlib.gettable("Mod.PCoin.HistoryDatabase");
local PaymentAddress = commonlib.gettable("Mod.PCoin.Wallet.PaymentAddress");

local TransactionDatabase = commonlib.gettable("Mod.PCoin.TransactionDatabase");

local Database = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Database"));

function Database:ctor()
	self.blocks = nil;
	self.transactions = nil;
	self.spends = nil;
	self.historys = nil;
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
	self.historys = HistoryDatabase:new():init(self.db);


	if self.blocks:getHeight() == 0 then
		Utility.log("[Database]generate genesis block");
		local genesis = Block.genesis();
		self:push(genesis, 1);
	end


end

local function pushInputs(hash, inputs, db)
	for k,v in pairs(inputs) do
		local spendpoint = {hash = hash, index = k}
		db:store(v.preOutput, spendpoint);
	
	end

end

local function pushOutput(hash, outputs, db, height )
	for k,v in pairs(outputs) do
		local outpoint = {hash = hash, index = k}
		local address = PaymentAddress.create(v.script);

		db:store(address:hash(), outpoint, v.value, height );
	end
end

function Database:push(block, height )
	local txdb = self.transactions;
	for index,t in pairs(block.transactions) do
		local hash = t:hash();

		pushInputs(hash, t.inputs, self.spends);
		pushOutput(hash, t.outputs, self.historys,height);


		txdb:store( hash, height, index, t:toData());
	end

	self.blocks:store(block.header:hash(), height, block:toData())
end






local function popInputs(inputs, db)
	for k,v in pairs(inputs) do
		db:remove(v.preOutput);
	end
end

local function popOutputs(outputs, db )
	for k,v in pairs(outputs) do
		local address = PaymentAddress.create(v.script);
		db:remove(address:hash());
	end
end


function Database:pop()
	local blocks = self.blocks;
	local txdb = self.transactions;
	local h = blocks:getHeight();
	local err,blockdata = blocks:getBlockByHeight(h);
	local block = Block.create(blockdata.block)
	local txs = block.transactions
	block.transactions = {};
	for i, hash in pairs(txs) do 
		local err, data = txdb:get(hash);
		local t = Transaction:new();
		if data then
			t:fromData(data.transaction);
			popInputs(t.inputs, self.spends);
			popOutputs(t.outputs, self.historys);
			block.transactions[i] = t;

			txdb:remove(hash);
		else
			Utility.log("[Database]pop: failed to find transaction with hash %s in block(hash %s)", 
						Utility.HashBytesToString(hash),Utility.HashBytesToString(block.header:hash()));
		end

	end

	blocks:unlink(h);


	return block;
end

function Database:report()
	echo("Database report:")
	self.blocks:report()
	self.spends:report()
	self.transactions:report()
end