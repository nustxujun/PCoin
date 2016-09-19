--[[
	NPL.load("(gl)script/PCoin/Network.lua");
	local Network = commonlib.gettable("Mod.PCoin.Network");
]]

local Network =  commonlib.gettable("Mod.PCoin.Network");

local connections = {};
local callback ;

local function makeAddress(nid)
	return "(gl)" .. nid .. ":script/PCoin/Network.lua";
end

function Network.init(port)
	NPL.StartNetServer("0,0,0,0", port or "8099");

	NPL.AddPublicFile("script/PCoin/Network.lua", 2001);
end



function Network.receive(msg)
	msg.nid = msg.nid or msg.tid;
	local conn = connections[msg.nid];
	if not conn then
		connections[msg.nid] = true;
	end

	if callback then
		callback(msg);
	end
end

function Network.send(nid, msg)
	msg.nid = nid;
	msg.service = "PCoin";
	if NPL.activate(makeAddress(nid), msg) ~= 0 then
		echo({"warning: cannot send msg to ",nid})
		Network.collect(nid);
	end
end

local send = Network.send;
function Network.broadcast(msg)
	for k,v in pairs(connections) do
		send(k, msg);
	end
end

function Network.register(cb)
	callback = cb
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

local rec = {};
function Network.collect(nid)
	rec[nid] = true;
end

function Network.recycle()
	if #rec then
		return 
	end

	for k,v in pairs(rec) do 
		connections[nid] = nil;
		NPL.reject(k)
	end

	rec = {};
end

NPL.load("(gl)script/ide/timer.lua");
local timer = commonlib.Timer:new({callbackFunc = Network.recycle})
timer:Change(5000,5000);


local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;
	if msg.service == "PCoin" then
		connections[id] = true;
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