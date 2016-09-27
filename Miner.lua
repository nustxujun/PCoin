--[[
	NPL.load("(gl)script/PCoin/Miner.lua");
	local Miner = commonlib.gettable("Mod.PCoin.Miner");
]]
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/math/uint256.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Encoding = commonlib.gettable("System.Encoding");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local uint256 = commonlib.gettable("Mod.PCoin.math.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local Block = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Block"));
local BlockDetail = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockDetail"));
local BlockHeader = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.BlockHeader"));
local Miner = commonlib.gettable("Mod.PCoin.Miner");
local Protocol = commonlib.gettable("Mod.PCoin.Protocol");

local blockchain = nil
local transactionpool = nil;
local timer = nil;
local miningServiceNid = nil;


function Miner.init(chain, pool)
	blockchain = chain
	transactionpool = pool;
end



function Miner.generateBlock(callback)
	Miner.stop();

	local top = blockchain:getHeight();
	local topblock = blockchain:fetchBlockDataByHeight(top);
	local preheader = BlockHeader.create(topblock.block.header);

	local function fetchHeader(height)
		return BlockHeader.create(blockchain:fetchBlockDataByHeight(height).block.header)
	end
	local curTarget = Utility.workRequired(topblock.height + 1, fetchHeader);


	local header = BlockHeader:new();
	header.version = Constants.curVersion;
	header.preBlockHash = preheader:hash();
	header.timestamp = os.time();
	header.bits = curTarget 
	header.merkle = "calculate after creating block"
	header.nonce = "default";

	local block = Block:new();
	block.header = header;
	block.transactions = transactionpool:getByCount();
	header.merkle = block:generateMerkleRoot();


	Miner.mine(block.header,
		function (nonce)
			block.header.nonce = nonce;

			Miner.store(block);
			if callback then
				callback();
			end
		end)
end


function Miner.stop()
	if timer then
		timer:Change()
		timer = nil;
	end

end

function Miner.store(block)
	local blockdetail = BlockDetail.create(block);
	blockchain:store(blockdetail);
	local newblocks = blockchain:organize();
	echo(newblocks)
	if #newblocks ~= 0 then
		Protocol.notifyNewBlock(newblocks);
	end
end

function Miner.isCPPSupported()
	return NPL.ProofOfWork ~= nil;
end

function Miner.isMiningServiceSurpported()
	return miningServiceNid ~= nil;
end

function Miner.setMiningServiceNid(nid)
	miningServiceNid = nid;
end

function Miner.mine(header, callback)
	Utility.log("begin mining, target: %x", header.bits)

	if Miner.isCPPSupported() then
		NPL.ProofOfWork(NPL.SerializeToSCode("",header:toData()) , header.bits);
		timer = commonlib.Timer:new({callbackFunc = 
		function ()
			local nonce = NPL.getValidPOW();
			if nonce ~= 0 then
				Miner.stop();
				header.nonce = nonce;
				Utility.log("stop mining, nonce: %d", nonce)
				
				callback(nonce);
			end
		end});
		timer:Change(1000, 1000);
	elseif Miner.isMiningServiceSurpported() then
		Protocol.mining_service(miningServiceNid, header, 
			function (msg)
				callback(msg.nonce);
			end)
	else
		local target = uint256:new():setCompact(header.bits);
		local nonce = 1;
		local hash = uint256:new();
		while true do 
			header.nonce = nonce;
			hash:setHash(header:hash(true));

			if (hash <= target ) then
				break;
			end
			nonce = nonce + 1;
		end
		Utility.log("stop mining, nonce: %d", nonce)
		callback(nonce);
	end
end