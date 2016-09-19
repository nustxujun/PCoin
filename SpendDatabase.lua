--[[
	NPL.load("(gl)script/PCoin/SpendDatabase.lua");
	local SpendDatabase = commonlib.gettable("Mod.PCoin.SpendDatabase");
]]

NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local SpendDatabase = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.SpendDatabase"));

local Collection = "Spends";


function SpendDatabase:ctor()
    self.db = nil;
end

function SpendDatabase:init(db)
    self.db = db;

    
    return self;
end

local function convertKey(outpoint)
    return (outpoint.hash or "") .. (outpoint.index or "");
end

-- spendpointData {transaction_hash, inputs_index}
function SpendDatabase:store(outpoint, spendpointData)
    self.db[Collection]:insertOne({outpoint = convertKey(outpoint)}, 
                                  {outpoint = convertKey(outpoint), index = outpoint.index, spend = spendpointData});
end

function SpendDatabase:get(outpoint)
   return self.db[Collection]:findOne({outpoint = convertKey(outpoint)});
end

function SpendDatabase:remove(outpoint)
    self.db[Collection]:deleteOne({outpoint = convertKey(outpoint)});
end

function SpendDatabase:report()
    echo("SpendDatabase report")
    local err, data = self.db[Collection]:find({})
    for k,v in pairs(data) do
        echo({k, v})
    end
    echo("------------------------")
end
