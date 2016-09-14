--[[
	NPL.load("(gl)script/PCoin/Network.lua");
	local Network = commonlib.gettable("Mod.PCoin.Network");
]]

local Network =  commonlib.gettable("Mod.PCoin.Network");

local connections = {};
local callback = {};
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
	if NPL.activate(nid, msg) ~= 0 then
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
local lastnid = 1;
local addressTonid = {};
function Network.connect(ip, port, callback)
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
	
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		try_count = try_count + 1;
		if(NPL.activate(nid, ping_msg) ~=0) then
			if(intervals[try_count]) then
				timer:Change(intervals[try_count], nil);
			else
				echo("PCoin ConnectionNotEstablished");
				callback(nid, false);
				
			end	
		else
			callback(nid,true);
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
