--[[
	NPL.load("(gl)script/PCoin/SpendDatabase.lua");
	local SpendDatabase = commonlib.gettable("Mod.PCoin.SpendDatabase");
]]

NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");

local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
local SpendDatabase = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.SpendDatabase"));

local Connection = "Spends";


function SpendDatabase:ctor()
    self.db = nil;
end

function SpendDatabase:init(db)
    self.db = db;



    return self;
end

-- spendpointData {transaction_hash, inputs_index}
function SpendDatabase:store(outpoint, spendpointData)
    self.db[Collection]:insertOne({hash = outpoint.hash, index = outpoint.index}, 
                                  {hash = outpoint.hash, index = outpoint.index, spend = spendpointData});
end

function SpendDatabase:get(outpoint)
    return self.db[Collection]:findOne({hash = outpoint.hash, index = outpoint.index});
end

function SpendDatabase:remove(outpoint)
    self.db[Collection]:deleteOne({hash = outpoint.hash, index = outpoint.index});
end
