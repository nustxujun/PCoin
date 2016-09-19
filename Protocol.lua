--[[
	NPL.load("(gl)script/PCoin/Protocol.lua");
	local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
]]

NPL.load("(gl)script/PCoin/Network.lua");
NPL.load("(gl)script/PCoin/Block.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");

local Constants = commonlib.gettable("Mod.PCoin.Constants");
local TransactionPool = commonlib.gettable("Mod.PCoin.Transaction");
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
	"transaction"

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
	Network.send(nid, msg);
end

local function broadcast(msg)
	msg.module = "internal"
	Network.broadcast(msg);
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

	chain:setHandler(
		function (event,blockdetail)
			if (event == "PushBlock") then
				Protocol.notifyNewBlock(blockdetail.block.header);
			end
		end
	) 

	Network.register(Protocol.receive);
	
end


--request-------------------------------------------------------------------------------
local function request(nid, name, msg, callback)
	msg.id = getProtocolID(name);
	msg.seq = getSeq();
	msg.type = REQUEST_T;
	callbacks[msg.seq] = callback

	send(nid, msg)
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

--{ desired = {{header},{header}, ... ,type = "hash" or "height"}}
function Protocol.block(nid, desired)
	request(nid, "block", {desired = desired}, 
		function (msg)
			for k,v in ipairs(msg.desired) do 
				local bd = BlockDetail.create(Block.create(v));
				blockchain:store(bd);
			end
		end)
end

--{top=0, desired = {{header},{header}, ... ,type = "hash" or "height"}}
function Protocol.block_header(nid,desired, callback)
	request(nid, "block_header", {desired = desired}, callback)
end

function Protocol.transaction(nid, desired)
	request(nid, "transaction", {desired = desired});
end


--response------------------------------------------------------------------------------
local function response(nid, seq, msg)
	msg.seq = seq
	msg.type = RESPONSE_T;
	send(nid, msg);
end

function Protocol.receive(msg)
	echo(msg)
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
	if msg.type == REQUEST_T then
		local type = msg.desired.type;

		local desired = {type = type}
		for k,v in ipairs(msg.desired) do 
			local data = fetch(type, v);
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
	
end

protocols.block_header = 
function (msg)
	if not msg.desired or not msg.desired.type then
		if  msg.type == REQUEST_T then
			local desired = {type = "height"}
			local top = blockchain:getHeight();
			local step = 1
			local i = top;
			while (i >= 1) do 
				local data = blockchain:fetchBlockDataByHeight(i);
				if data then 
					desired[#desired + 1] = data.block.header;
				else
					break;
				end
				if #desired >= 10 then
					step = step * 2;
				end
				i = i + step;
			end
			response(msg.nid, msg.seq, {top = blockchain:getHeight(),desired = desired})
		end
	else
		local type = msg.desired.type
		if msg.type == REQUEST_T then
			local desired = {type = type}
			for k,v in ipairs(msg.desired) do 
				local data = fetch(v, type)
				if data then 
					desired[#desired + 1] = data;
				end
			end
			response(msg.nid, msg.seq, {top = blockchain:getHeight(),desired = desired})

		elseif msg.type == NOTIFY_T and type == "hash"then
			-- request blocks if not existed;
			local desired = {type = type}
			for k,v in ipairs(msg.desired) do 
				if not blockchain:fetchBlockDataByHash(v) then
					desired[#desired + 1] = v; 
				end
			end
			Protocol.block(msg.nid, desired);
		end
	end
end

protocols.transaction = 
function (msg)
	for k,data in ipairs(msg.desired) do 
		local tx = Transaction.create(data);
		transactionpool:store(tx);
	end
end

protocols.transaction_notify = 
function (msg)
	local desired = {};
	for k,v in ipairs(msg.desired) do
		 transactionpool:get(v);
		if (not transactionpool:get(v)) and 
			(not blockchain:fetchTransactionData(v)) then 
			desired[#desired + 1] = v;
		end
	end
	Protocol.transaction(msg.nid, desired);
end



--broadcast-------------------------------------------------------------------------------------
local function notify(name,msg)
	msg.id = getProtocolID(name);
	msg.seq = getSeq();
	msg.type = NOTIFY_T;

	broadcast( msg);
end

function Protocol.notifyNewBlock(hash)
	notify("block_header", {desired = {hash, type="hash"}})
end

function Protocol.notifyNewTransaction(transaction)
	notify("transaction_notify", {transaction:hash()})
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
	Protocol.notifyNewBlock(header:hash())
end
