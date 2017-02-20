--[[
	NPL.load("(gl)script/PCoin/Network.lua");
	local Network = commonlib.gettable("Mod.PCoin.Network");
]]

NPL.load("(gl)script/PCoin/Buffer.lua");
local Buffer = commonlib.gettable("Mod.PCoin.Buffer");


local Network =  commonlib.gettable("Mod.PCoin.Network");

local connections = {};
local newConnPool = {};
local callback ;
local proxy;


local function makeAddress(nid)
	return "(gl)" .. (nid or "nid(nil)") .. ":2001";
end

local function loadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", false);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(5000);
end

local function loadPeer(filename)
	local file = ParaIO.open(filename, "r")
	if file:IsValid() then
		local line = file:readline();
		while line do
			local ip, port = line:match("(%d+.%d+.%d+.%d+) (%d+)")
			Network.connect(ip, port, function (nid, ret)
				if ret then
					Network.addNewPeer(nid);
				end
			end)
			line = file:readline();
		end
	end
end

function Network.init(settings)
	loadNetworkSettings();

	NPL.AddPublicFile("script/PCoin/Network.lua", 2001);

    port = tostring(settings.port or 8099);
	NPL.StartNetServer("0.0.0.0", port);


	loadPeer(settings.peers)


	NPL.load("(gl)script/ide/timer.lua");
	local timer = commonlib.Timer:new({callbackFunc = Network.recycle})
	timer:Change(5000,5000);
end

local ping_msg = {service="PCoin"};
local lastnid = 1000;
local addressTonid = {};
function Network.connect(ip, port, cb)
	local key = ip .. port;
	local nid = addressTonid[key];
	if not nid then
		nid = tostring(lastnid);
		addressTonid[key] = nid;
		lastnid = lastnid + 1;

		local paras = {host = tostring(ip), port = tostring(port), nid = nid};
		NPL.AddNPLRuntimeAddress(paras);
		connections[nid] = true
	end


	local intervals = {100, 300,500, 1000, 1000, 1000, 1000}; -- intervals to try
	local try_count = 0;
	local address = makeAddress(nid);
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		try_count = try_count + 1;
		if(NPL.activate(address, ping_msg) ~=0) then
			if(intervals[try_count]) then
				timer:Change(intervals[try_count], nil);
			else
				echo("PCoin ConnectionNotEstablished");
				if cb then
					cb(nid, false);
				end
			end	
		else
			if cb then
				cb(nid,true);
			end
		end
	end})
	mytimer:Change(10, nil);
	return 0;
end


function Network.addNewPeer(nid)
	if connections[nid] then
		return;
	end

	newConnPool[nid] = true;
end

function Network.getNewPeer()
	if next(newConnPool) then
		local con = next(newConnPool);
		newConnPool[con] = nil;
		return con;
	else
		return;
	end
end

function Network.receive(msg)
	msg.nid = msg.nid or msg.tid;
	local conn = connections[msg.nid];
	if not conn then
		connections[msg.nid] = true;
	end

	echo({"receive",msg})

	if callback then
		callback(msg);
	end
end

function Network.send(nid, msg)
	msg.nid = nid;
	msg.service = "PCoin";
	echo({"send",msg})

	if proxy then
		return proxy:send(nid, msg);
	end

	if NPL.activate(makeAddress(nid), msg) ~= 0 then
		echo({"warning: cannot send msg to ",nid})
		Network.collect(nid);
		return false;
	end

	return true
end

local send = Network.send;
function Network.broadcast(msg, exclude)
	for k,v in pairs(connections) do
		if k ~= exclude then
			send(k, msg);
		end
	end
end

function Network.register(cb)
	callback = cb
end

function Network.setProxy(p)
	proxy = p;
end


local rec = {};
function Network.collect(nid)
	rec[nid] = true;
end

function Network.recycle()
	if not next(rec) then
		return 
	end

	for k,v in pairs(rec) do 
		connections[k] = nil;
		newConnPool[k] = nil;
		
		NPL.reject(k)
		echo("close connection ".. k)
	end

	rec = {};
end




local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;

	if msg.service == "PCoin" then
		if not connections[id] then  
			newConnPool[id] = true;
			connections[id] = true
		end
		Network.receive(msg)
	end
end
NPL.this(activate);


function Network.test()
	NPL.load("(gl)script/PCoin/Protocol.lua");
	local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
	Network.init()
	Network.register(Protocol.receive);
	Network.connect("127.0.0.1","8099", 
		function (...)
			Protocol.ping("1000", 
				function(msg) 
					echo("lag: " .. (os.time() - msg.timestamp))
				end) 
		end)
end