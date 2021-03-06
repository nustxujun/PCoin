--[[
	NPL.load("(gl)script/PCoin/Protocol.lua");
	local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
]]

NPL.load("(gl)script/PCoin/Network.lua");
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");

local Constants = commonlib.gettable("Mod.PCoin.Constants");
local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockHeader = commonlib.gettable("Mod.PCoin.BlockHeader")
local BlockDetail = commonlib.gettable("Mod.PCoin.BlockDetail");
local Network = commonlib.gettable("Mod.PCoin.Network");

local Protocol = commonlib.gettable("Mod.PCoin.Protocol");

local blockchain ;
local transactionpool;
--protocol
local REQUEST_T = 1;
local RESPONSE_T = 2;
local NOTIFY_T = 3;

local protocols = 
{
	"ping",
	"version",
	"node_address",
	"block",
	"block_header",
	"transaction_notify",
	"transaction",

	--ext
	"mining_service",
}

local protocolmap = {}
for i,p in ipairs(protocols) do
	protocolmap[p] = i; 
end

local function getProtocolName(i)
	return protocols[i];
end

local function getProtocolID(name)
	return protocolmap[name];
end

local callbacks = {};
local seqNum = 1;
local function getSeq()
	seqNum = seqNum + 1;
	return seqNum
end

local function send(nid, msg)
	msg.module = "internal"
	return Network.send(nid, msg);
end

local function broadcast(msg, exclude)
	msg.module = "internal"
	Network.broadcast(msg, exclude);
end

local function fetch(type, v)
	if type == "hash" then 
		return blockchain:fetchBlockDataByHash(v);
	elseif type == "height" then
		return blockchain:fetchBlockDataByHeight(v);
	end
end


--function------------------------------------------------------------------------------


function Protocol.init(chain, pool)
	blockchain = chain;
	transactionpool = pool;


	Network.register(Protocol.receive);
	
end


--request-------------------------------------------------------------------------------
local function request(nid, name, msg, callback)
	msg.id = getProtocolID(name);
	msg.seq = getSeq();
	msg.type = REQUEST_T;
	msg[1] = name
	callbacks[msg.seq] = callback

	return send(nid, msg)
end

--{timestamp = 0, }
function Protocol.ping(nid, callback)
	request(nid, "ping", {timestamp = os.time()}, callback)
end

--{version = 0, }
function Protocol.version(nid, version,callback)
	request(nid, "version", {version = version},callback);
end

--{nodes = {{ip, port}}, }
function Protocol.node_address(nid, callback)
	request(nid, "node_address", {},callback);
end


--get block
function Protocol.block(nid, desired, callback)
	request(nid, "block", {desired = desired}, callback or 
		function (msg)
			for k,v in ipairs(msg.desired) do 
				local bd = BlockDetail.create(Block.create(v));
				local txdatas = bd.block.transactions;
				local txs = {};
				for _, td in ipairs(txdatas) do
					txs[#txs + 1] = Transaction.create(td);
				end
				bd.block.transactions = txs;
				blockchain:store(bd);
			end
			local newblocks = blockchain:organize();
			if #newblocks ~= 0 then
				local hashes = {};
				for k,v in ipairs(newblocks) do
					hashes[#hashes + 1] = v:getHash(); 
				end
				Protocol.notifyNewBlock(hashes, nid);
			end
		end)
end

--{locator = {hash,hash, ... ,hash}}
function Protocol.block_header(nid,cb)
	local function getLocator(height)
		local locator = {}
		local step = 1
		local i = height;
		while (i > 1) do 
			local data = blockchain:fetchBlockDataByHeight(i);
			if data then 
				locator[#locator + 1] = data.hash;
			else
				break;
			end
			if #locator >= 10 then
				step = step * 2;
			end
			i = i - step;
		end
		-- genesis block
		locator[#locator + 1] = blockchain:fetchBlockDataByHeight(1).hash;
		
		return locator;
	end
	local locator = getLocator(blockchain:getHeight());

	local function callback(msg)
		if #msg.headers ~= 0 then --#1
			local desired = {}
			for k,v in pairs(msg.headers) do 
				local data = blockchain:exist(v);
				if not data then 
					desired[#desired + 1] = v;
				end
			end
			
			if #desired ~= 0 then
				Protocol.block(nid,  desired,
					function (msg)
						local lastHash ;
						for k,v in ipairs(msg.desired) do 
							local bd = BlockDetail.create(Block.create(v));
							local txdatas = bd.block.transactions;
							local txs = {};
							for _, td in ipairs(txdatas) do
								txs[#txs + 1] = Transaction.create(td);
							end
							bd.block.transactions = txs;
							blockchain:store(bd);
							lastHash = bd:getHash();
						end
						local newblocks = blockchain:organize();
						if #newblocks ~= 0 then
							local hashes = {};
							for k,v in ipairs(newblocks) do
								hashes[#hashes + 1] = v:getHash(); 
							end
							Protocol.notifyNewBlock(hashes, nid);
						end
						if lastHash then
							request(nid, "block_header", {locator = {lastHash}}, callback);
						else
							-- repeat from top
							Protocol.block_header(nid,cb)
						end
					end);
			else
				request(nid, "block_header", {locator = {msg.headers[#msg.headers]}}, callback);
			end
		else
			--echo("warning: another MAIN CHAIN is existed which has different genesis block!")
			cb();
		end --#1
	end
	request(nid, "block_header", {locator = locator}, callback);
end

function Protocol.transaction(nid, desired, cb)
	request(nid, "transaction", {desired = desired}, 
		function (msg)
			for k,v in pairs(msg.desired) do 
				local tx = Transaction.create(v);
				transactionpool:store(tx);
			end

			if cb then
				cb()
			end;
		end);
end

function Protocol.mining_service(nid, header, callback)
	return request(nid, "mining_service", {header = header}, callback);
end

--response------------------------------------------------------------------------------
local function response(nid, seq, msg)
	msg.seq = seq
	msg.type = RESPONSE_T;
	send(nid, msg);
end

function Protocol.receive(msg)
	local receiver = nil;
	local name = getProtocolName(msg.id);
	if msg.type == REQUEST_T then
		receiver = protocols[name];
	elseif msg.type == RESPONSE_T then
		receiver = callbacks[msg.seq];
		callbacks[msg.seq] = nil;
		
	elseif msg.type == NOTIFY_T then 
		receiver = protocols[name];
	else
		return
	end

	if receiver then
		receiver(msg);
	else
		echo("receiver not found")
		echo(msg)
	end
end

protocols.ping = 
function (msg)
	response(msg.nid, msg.seq, {timestamp = msg.timestamp})
end

protocols.version = 
function (msg)
	response(msg.nid, msg.seq,{version = Constants.curVersion});
end

protocols.node_address = 
function (msg)
	response(msg.nid, msg.seq,{});
end

protocols.block = 
function (msg)
	local desired = {}
	for k,v in ipairs(msg.desired) do 
		local data = blockchain:fetchBlockDataByHash(v);
		if data then 
			local txs = {}
			for k,v in ipairs(data.block.transactions) do
				local txdata = blockchain:fetchTransactionData(v);
				if not txdata then 
					return
				end
				txs[#txs + 1] = txdata.transaction;
			end
			data.block.transactions = txs;
			desired[#desired + 1] = data.block;  
		end
	end
	response(msg.nid, msg.seq, {top = blockchain:getHeight(),desired = desired})
	
end

protocols.block_header = 
function (msg)
	if msg.type == REQUEST_T then
		local headers = {};
		local top = blockchain:getHeight();
		for k,v in pairs(msg.locator) do
			local height = blockchain:getHeight(v);
			if height then
				local max_num = math.min(height + 10, top);
				for i = height + 1, max_num do 
					local data = blockchain:fetchBlockDataByHeight(i);
					headers[#headers + 1] = data.hash;
				end
				break;
			else
			end
		end
		response(msg.nid, msg.seq, {headers = headers});

	elseif msg.type == NOTIFY_T then
		-- request blocks if not existed;
		local desired = {}
		for k,v in ipairs(msg.headers) do 
			if not blockchain:exist(v) then
				desired[#desired + 1] = v; 
			end
		end
		Protocol.block(msg.nid, desired);
	end
	
end

protocols.transaction = 
function (msg)
	local desired = {};
	if msg.type == REQUEST_T then 
		if not msg.desired then
			local txs ;
			txs = transactionpool:getByCount();
			for k,v in ipairs(txs) do
				desired[#desired + 1] = v:toData();
			end
		else
			for k,v in ipairs(msg.desired) do 
				local tx =transactionpool:get(v);
				local txData;
				if tx then 
					txData = tx:toData();
				else 
					txData = blockchain:fetchTransactionData(v)
				end
				desired[#desired + 1] = txData
			end
		end

		response(msg.nid, msg.seq, {desired = desired})
	end
end

protocols.transaction_notify = 
function (msg)
	if (not transactionpool:get(msg.hash)) and 
		(not blockchain:fetchTransactionData(v)) then 
		Protocol.transaction(msg.nid, {msg.hash});
		Protocol.notifyNewTransaction(msg.hash,msg.nid)
	end
end

protocols.mining_service = 
function (msg)
	local Miner = commonlib.gettable("Mod.PCoin.Miner");
	Miner.mine(BlockHeader.create(msg.header), 
		function (nonce)
			response(msg.nid, msg.seq, {nonce = nonce});
		end)
end


--broadcast-------------------------------------------------------------------------------------
local function notify(name,msg, exclude)
	msg.id = getProtocolID(name);
	msg.seq = getSeq();
	msg.type = NOTIFY_T;
	msg[1] = name;
	broadcast( msg, exclude);
end

function Protocol.notifyNewBlock(hashes, excludeSender)
	notify("block_header", {headers = hashes}, excludeSender)
end

function Protocol.notifyNewTransaction(hash, excludeSender)
	notify("transaction_notify", {hash = hash}, excludeSender)
end







--test---------------------------------------------------------------------------------------------

function Protocol.test()
	NPL.load("(gl)script/PCoin/BlockChain.lua");
	local BlockChain = commonlib.gettable("Mod.PCoin.BlockChain");
	NPL.load("(gl)script/PCoin/TransactionPool.lua");
	local TransactionPool = commonlib.gettable("Mod.PCoin.TransactionPool");
	NPL.load("(gl)script/PCoin/Settings.lua");
	local Settings = commonlib.gettable("Mod.PCoin.Settings");


	local bc = BlockChain.create(Settings.BlockChain);
    local tp = TransactionPool.create(bc, Settings.TransactionPool);

	Protocol.init(bc, tp);
	echo("send ping")
	Protocol.ping(1, function (msg) echo("receive ping")end);
	echo("send version")
	Protocol.version(1, 1000,function (msg) echo("receive version")end);

	local top = bc:getHeight();
	echo(top)
	local b = bc:fetchBlockDataByHeight(top);

	echo("send header")
	Protocol.block_header(1, {2, ["type"] = "height"}, 
	function (msg)
		echo(msg)
	end);

	echo("send newBlock")

	local header = BlockHeader.create(b.block.header);
	Protocol.notifyNewBlock({header:hash()})
end
