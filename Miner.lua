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
local miningServiceNid = nil;
local thread = "miner01"
local runtime = nil;

function Miner.init(chain, pool)
	blockchain = chain
	transactionpool = pool;

	blockchain:setHandler( function () Miner.stop(); end);


	runtime = NPL.CreateRuntimeState(thread, 0);
	runtime:Start();
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
		function (nonce, ret)
			block.header.nonce = nonce;
			if ret then
				Miner.store(block);
			end
			if callback then
				callback(ret);
			end
		end)
end


function Miner.stop()
	if Miner.isAsyncModeSupported() then
		NPL.activate(format("(%s)%s", thread, "script/PCoin/Miner.lua"), {cmd = "stop"})
		if Miner.callback then
			local callback = Miner.callback;
			Miner.callback = nil
			callback(nil, false)
		end
	end
end

function Miner.store(block)
	local blockdetail = BlockDetail.create(block);
	blockchain:store(blockdetail);
	local newblocks = blockchain:organize();
	if #newblocks ~= 0 then
		Protocol.notifyNewBlock(newblocks);
	end
end

function Miner.isMiningServiceSupported()
	return miningServiceNid ~= nil;
end

function Miner.isAsyncModeSupported()
	return true
end

function Miner.setMiningServiceNid(nid)
	miningServiceNid = nid;
end

function Miner.mine(header, callback)
	Utility.log("begin mining, target: %x", header.bits)

	if Miner.isMiningServiceSupported() then
		Protocol.mining_service(miningServiceNid, header, 
			function (msg)
				callback(msg.nonce,true);
			end)
	elseif Miner.isAsyncModeSupported() then
		Miner.callback = callback;
		NPL.activate(format("(%s)%s", thread, "script/PCoin/Miner.lua"), {cmd = "mine", header = header:toData()})
	else
		function mine(header)
			local target = uint256:new():setCompact(header.bits);
			local nonce = 1;
			local hash = uint256:new();
			while not stop do 
				header.nonce = nonce;
				hash:setHash(BlockHeader.hash(header, true));

				if (hash <= target ) then
					break;
				end
				nonce = nonce + 1;
			end
			return nonce;
		end

		local nonce = mine(header);
		Utility.log("stop mining, nonce: %d", nonce)
		callback(nonce,true);
	end
end

local timer = nil;
NPL.this(function ()
	local msg = msg;
	local cmd = msg.cmd
	if cmd == "mine" then --  mining thread
		local header = BlockHeader.create(msg.header);
		local target = uint256:new():setCompact(header.bits);
		local hash = uint256:new();
		local nonce = 0;

		timer = commonlib.Timer:new({callbackFunc = function ()
			for i = 1, 0xffff do
				nonce = nonce + 1;
				header.nonce = nonce;
				hash:setHash(header:hash(true));
				if (hash <= target ) then
					timer:Change();
					timer = nil;
					NPL.activate("(main)script/PCoin/Miner.lua", {cmd = "result", nonce = nonce});
					break;
				end
			end
		end})
		timer:Change(0,1);

	elseif cmd == "result" then --  main thread
		local callback = Miner.callback ;
		Miner.callback= nil
		callback(msg.nonce, true);
	elseif cmd == "stop" then
		if timer then
			timer:Change()
			timer = nil;
		end
	end
end)