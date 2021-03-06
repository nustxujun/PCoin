-- NPL.load("(gl)script/PCoin/main.lua");


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

NPL.load("(gl)script/PCoin/Wallet/Wallet.lua");
local Wallet = commonlib.gettable("Mod.PCoin.Wallet.Wallet");

local PCoin = commonlib.gettable("Mod.PCoin");



local function fullnode(seed)
	local bc = BlockChain.create(Settings.BlockChain);
    local tp = TransactionPool.create(bc, Settings.TransactionPool);
    --bc:report()
    Miner.init(bc, tp);
    Wallet.init(bc, tp , seed);

    Network.init();
    Protocol.init(bc, tp);

    --Wallet.pay(10, {"02c44a58839b261a6a14e5de674415eefc2cc5f2d1c5481ea654b02330030141"});
    --Miner.generateBlock();
    --Miner.generateBlock();
    --Wallet.report();
    --bc:report()
end


local function node1()
    fullnode("Treasure");
end

local function node2()
    fullnode("test")

    Network.connect("127.0.0.1","8099",
        function (nid)
            Protocol.block_header(nid);
        end);
end

function PCoin.node(num)
    local nodes = {node1, node2}
    nodes[num]();
end



function PCoin.report()
    Wallet.report();
end