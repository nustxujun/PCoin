NPL.load("(gl)script/PCoin/BlockChain.lua");
local BlockChain = commonlib.gettable("Mod.PCoin.BlockChain");

NPL.load("(gl)script/PCoin/Network.lua");
local Network = commonlib.gettable("Mod.PCoin.Network");

NPL.load("(gl)script/PCoin/TransactionPool.lua");
local TransactionPool = commonlib.gettable("Mod.PCoin.TransactionPool");

NPL.load("(gl)script/PCoin/Protocol.lua");
local Protocol = commonlib.gettable("Mod.PCoin.Protocol");

NPL.load("(gl)script/PCoin/Miner.lua");
local Miner = commonlib.gettable("Mod.PCoin.Miner");

local blockchain = nil
local transactionpool = nil

local settings = 
{
    database = 
    {
        root = nil,
        sync = true,
    },
}

local function fullnode()
    blockchain = BlockChain.create(settings);
    transactionpool = TransactionPool.create();


    Protocol.init();    
    Network.init();
    Miner.init(blockchain, transactionpool);
end



