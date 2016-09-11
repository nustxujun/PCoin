--[[
	NPL.load("(gl)script/PCoin/TransactionDatabase.lua");
	local TransactionDatabase = commonlib.gettable("Mod.PCoin.TransactionDatabase");
]]
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");

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
    local hash = transaction:hash();

    self.db[Collection]:insertOne({hash = hash}, 
                                  {hash = hash, index = index, height = height, transaction = transactionData})

end

function TransactionDatabase:remove(hash)
    self.db[Collection]:deleteOne({hash = hash});
end


