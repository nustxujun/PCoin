--[[
	NPL.load("(gl)script/PCoin/Protocol.lua");
	local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
]]

NPL.load("(gl)script/PCoin/Network.lua");
NPL.load("(gl)script/PCoin/Block.lua");

local Block = commonlib.gettable("Mod.PCoin.Block");
local BlockHeader = commonlib.gettable("Mod.PCoin.BlockHeader")
local Network = commonlib.gettable("Mod.PCoin.Network");

local Protocol = commonlib.gettable("Mod.PCoin.Protocol");

--type
REQUEST_T = 1,
RESPONSE_T = 2,
NOTIFY_T = 3,

local protocols = 
{
	"ping",
	"version",
	"node_address",
	"block",
	"block_header",
	"transaction",
	"",
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

local blockchain ;
local transactionpool;
function Protocol.init(chain, pool)
	blockchain = chain;
	transactionpool = pool;
end


--request-------------------------------------------------------------------------------
local function request(nid, name, msg, callback)
	msg.id = getProtocolID(name);
	msg.seq = getSeq();
	msg.type = REQUEST_T;
	callbacks[msg.seq] = callback

	Network.send(nid, msg);
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
			for k,v in pairs(msg.desired) do 
				local bd = BlockDetail.create(Block.create(v));
				blockchain:store(bd);
			end
		end)
end

--{top=0, desired = {{header},{header}, ... ,type = "hash" or "height"}}
function Protocol.block_header(nid,desired)
	request(nid, "block_header", {desired = desired}, 
		function (msg)
			local type = msg.desired.type
			local fetch = nil;
			if type == "hash" then
				fetch = blockchain.fetchBlockDataByHash;
			elseif type == "height" then
				fetch = blockchain.fetchBlockDataByHeight;
			end

			local desired = {type = type}
			for k,v in pairs(msg.desired) do 
				local data = fetch(blockchain, v);
				if not data then
					desired[#desired + 1] = v; 
				end
			end
			Protocol.block(msg.nid);

		end)
end

--response------------------------------------------------------------------------------
local function response(nid, seq, msg)
	msg.seq = seq
	msg.type = RESPONSE_T;
	Network.send(nid, msg);
end

function Protocol.receive(msg)
	local receiver = nil;
	if msg.type == REQUEST_T then
		receiver = protocols[msg.id];
	elseif msg.type == RESPONSE_T then
		receiver = callbacks[msg.seq];
		callbacks[msg.seq] = nil;
	elseif msg.type == NOTIFY_T then 
		receiver = protocols[msg.id];
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
		local type = msg.desired.type
		local fetch = nil;
		if type == "hash" then
			fetch = blockchain.fetchBlockDataByHash;
		elseif type == "height" then
			fetch = blockchain.fetchBlockDataByHeight;
		end
		if msg.type == REQUEST_T then
			local desired = {type = type}
			for k,v in pairs(msg.desired) do 
				local data = fetch(blockchain, v);
				if data then
					desired[#desired + 1] = data.block; 
				end
			end
			response(msg.nid, msg.seq, {top = blockchain:getHeight(),desired = desired})
	
	elseif msg.type == NOTIFY_T then
		for k,v in pairs(msg.desired) do 
			local bd = BlockDetail.create(Block.create(v));
			blockchain:store(bd);
		end
	end
end

protocols.block_header = 
function (msg)
	if not msg.desired then
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
		local fetch = nil;
		if type == "hash" then
			fetch = blockchain.fetchBlockDataByHash;
		elseif type == "height" then
			fetch = blockchain.fetchBlockDataByHeight;
		end
		if msg.type == REQUEST_T then
			local desired = {type = type}
			for k,v in pairs(msg.desired) do 
				local data = fetch(blockchain, v);
				if data then
					desired[#desired + 1] = data.block.header; 
				end
			end
			response(msg.nid, msg.seq, {top = blockchain:getHeight(),desired = desired})

		elseif msg.type == NOTIFY_T then
			-- request blocks if not existed;
			local desired = {type = type}
			for k,v in pairs(msg.desired) do 
				local data = fetch(blockchain, v);
				if not data then
					desired[#desired + 1] = v; 
				end
			end
			Protocol.block(msg.nid);

		end
	end
end


Network.register(Protocol.receive);

