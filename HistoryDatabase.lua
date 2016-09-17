--[[
	NPL.load("(gl)script/PCoin/HistoryDatabase.lua");
	local HistoryDatabase = commonlib.gettable("Mod.PCoin.HistoryDatabase");
]]

NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");

local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local HistoryDatabase = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.HistoryDatabase"));

local Collection = "Historys";


function HistoryDatabase:ctor()
    self.db = nil;
end

function HistoryDatabase:init(db)
    self.db = db;
    return self;
end

-- spendpointData {transaction_hash, inputs_index}
function HistoryDatabase:store(hash, pointdata, value, height)
    self.db[Collection]:insertOne({hash = hash}, 
                                  {hash = hash, point = pointdata, value = value, height = height});
end

function HistoryDatabase:get(hash)
    return self.db[Collection]:findOne({hash = hash});
end

function HistoryDatabase:remove(hash)
    self.db[Collection]:deleteOne({hash = hash});
end
