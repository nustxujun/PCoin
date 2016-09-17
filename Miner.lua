--[[
	NPL.load("(gl)script/PCoin/Miner.lua");
	local Miner = commonlib.gettable("Mod.PCoin.Miner");
]]
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/uint256.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Encoding = commonlib.gettable("System.Encoding");
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



function Miner.init(chain, pool)
	blockchain = chain
	transactionpool = pool;
end



function Miner.generateBlock()
	Miner.stop();

	local top = blockchain:getHeight();
	local topblock = blockchain:fetchBlockDataByHeight(top);
	local preheader = BlockHeader.create(topblock.block.header);

	local curTarget = Utility.workRequired(top + 1, blockchain);


	local header = BlockHeader:new();
	header.version = Constants.curVersion;
	header.preBlockHash = preheader:hash();
	header.timestamp = os.time();
	header.bits = curTarget 
	header.merkle = ""
	header.nonce = "default";

	local block = Block:new();
	block.header = header;
	block.transactions = transactionpool:getAll();
	header.merkle = block:generateMerkleRoot();

	Miner.mine(block, curTarget,true)
end


function Miner.stop()
	if timer then
		timer:Change()
		timer = nil;
	end

end

function Miner.proofofwork(block)
	local nonce = NPL.getValidPOW();
	if nonce ~= 0 then
		Miner.stop();
		block.header.nonce = nonce;
		Miner.store(block);
	end
end

function Miner.store(block)
	Utility.log("stop mining, nonce: %d", block.header.nonce)
	
	local blockdetail = BlockDetail.create(block);
	blockchain:store(blockdetail);
end

function Miner.mine(block, bits,  CPPsupported)
	Utility.log("begin mining, target: %x", bits)

	if CPPsupported and NPL.ProofOfWork then
		NPL.ProofOfWork(NPL.SerializeToSCode("",block.header:toData()) , bits);
		timer = commonlib.Timer:new({callbackFunc = 
		function ()
			Miner.proofofwork(block);
		end});
		timer:Change(1000, 1000);
	else
		local target = uint256:new():setCompact(bits);
		local header = block.header;
		nonce = 1;
		local hash = uint256:new();
		while true do 
			header.nonce = nonce;
			hash:setHash(header:hash(true));

			if (hash <= target ) then
				break;
			end
			nonce = nonce + 1;
		end
		Miner.store(block);
	end
end