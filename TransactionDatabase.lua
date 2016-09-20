--[[
	NPL.load("(gl)script/PCoin/TransactionDatabase.lua");
	local TransactionDatabase = commonlib.gettable("Mod.PCoin.TransactionDatabase");
]]
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Utility.lua");

local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local TransactionDatabase = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.TransactionDatabase"));

local Collection = "Transactions";

function TransactionDatabase:ctor()
    self.db = nil;
end

function TransactionDatabase:init(db)
    self.db = db;

    return self;    
end

function TransactionDatabase:get(hashvalue, callback)
    return self.db[Collection]:findOne({hash = hashvalue}, callback);
end

function TransactionDatabase:store(hash, height, index, transactionData)
    local hash = hash;
    self.db[Collection]:insertOne({hash = hash}, 
                                  {hash = hash, index = index, height = height, transaction = transactionData})

end

function TransactionDatabase:remove(hash)
    self.db[Collection]:deleteOne({hash = hash});
end


function TransactionDatabase:report()
    echo("TransactionDatabase report")
    local err, data = self.db[Collection]:find({})
    for k,v in pairs(data) do
        echo({k, Utility.HashBytesToString(v.hash)})
		echo(v)
    end
    echo("------------------------")
end