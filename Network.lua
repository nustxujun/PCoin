--[[
	NPL.load("(gl)script/PCoin/Network.lua");
	local Network = commonlib.gettable("Mod.PCoin.Network");
]]

local Network =  commonlib.gettable("Mod.PCoin.Network");

local connections = {};
local callbacks = {};

function Network.receive(msg)
	local nid = msg.nid or msg.tid;

	local conn = connections[nid];
	if not conn then
		connections[nid] = true;
	end

	local cb = callbacks[msg.name];
	if cb then
		cb(nid, msg);
	end
end

function Network.send(nid, msg)
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

function Network.register(name, cb)
	callbacks[name] = cb;
end

local ping_msg = {service="PCoin",name="ping"};
function Network.connect(ip, port, msg)
		local intervals = {100, 300,500, 1000, 1000, 1000, 1000}; -- intervals to try
		local try_count = 0;
		
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			try_count = try_count + 1;
			if(NPL.activate(address, ping_msg) ~=0) then
				if(intervals[try_count]) then
					timer:Change(intervals[try_count], nil);
				else
					echo("PCoin ConnectionNotEstablished");
				end	
			else
				
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
