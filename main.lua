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

NPL.load("(gl)script/PCoin/Settings.lua");
local Settings = commonlib.gettable("Mod.PCoin.Settings");

local blockchain = nil
local transactionpool = nil


local function fullnode()
    blockchain = BlockChain.create(Settings.BlockChain);
    transactionpool = TransactionPool.create();

    Network.init();
    Protocol.init(blockchain, transactionpool);    

    -- Network.connect("127.0.0.1","8099",
    -- function (nid,ret)
    --     if not ret then
    --         echo("failed to connect 127")
    --         return 
    --     end
    --     Protocol.version(nid, function (msg)
    --         Protocol.block_header(msg.nid);
    --     end);
    -- end);

    Miner.init(blockchain, transactionpool);
    

end



