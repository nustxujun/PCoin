
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/BlockChain.lua");

local BlockHeader = commonlib.gettable("Mod.PCoin.BlockHeader");
local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockDetail = commonlib.gettable("Mod.PCoin.BlockDetail");
local BlockChain = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockChain"));

function testBlockChain()
	local paras = {header = {}, }
	local block = Block.create(paras);
	local bd = BlockDetail.create(block);
	
	local config = 
	{
		database = 
		{
			root = nil,
			sync = true,
		},
	}
	local chain = BlockChain.create(config)
	chain:store(bd);
end

testBlockChain();

