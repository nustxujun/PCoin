--[[
	NPL.load("(gl)script/PCoin/Miner.lua");
	local Miner = commonlib.gettable("Mod.PCoin.Miner");
]]
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/uint256.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local Block = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Block"));
local BlockDetail = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDetail"));
local BlockHeader = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockHeader"));
local Miner = commonlib.gettable("Mod.PCoin.Miner");

local blockchain = nil
local transactionpool = nil;
local timer = nil;
local curHeader = nil;

function Miner.proofofwork()
	local nonce = NPL.getValidPOW();
	if nonce ~= 0 then
		Miner.stop();

		local block = Block:new();
		block.header = curHeader;

		local blockdetail = BlockDetail.create(block);

		blockchain:store(blockdetail);
	end
end



function Miner.init(chain, pool)
	blockchain = chain
	transactionpool = pool
end


function Miner.generateBlock()
	Miner.stop();


	local top = blockchain:getHeight();
	local topblock = blockchain:fetchBlockData(top);
	local header = BlockHeader.create(topblock.block.header);

	local curTarget = Utility.workRequired(top + 1, blockchain);

	curHeader = BlockHeader:new();
	curHeader.version = Constants.curVersion;
	curHeader.preBlockHash = header:hash();
	curHeader.timestamp = os.time();
	curHeader.bits = curTarget 
	curHeader.nonce = "default";

	NPL.ProofOfWork(NPL.SerializeToSCode("",curHeader:toData()) , curTarget,"proofofwork();");


	timer = commonlib.Timer:new({callbackFunc = Miner.proofofwork});
	timer:Change(1000, 1000);
	
end

function Miner.stop()
	if timer then()
		timer:Change()
		timer = nil;
	end

	curHeader = nil;
end