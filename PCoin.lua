--[[
    NPL.load("(gl)script/PCoin/PCoin.lua");
	local PCoin = commonlib.gettable("Mod.PCoin");
    PCoin.init("test");
    PCoin.start()
]]

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

NPL.load("(gl)script/PCoin/Constants.lua");
local Constants = commonlib.gettable("Mod.PCoin.Constants");

local PCoin = commonlib.gettable("Mod.PCoin");
local mode = nil;
local curState; 
local states = 
{
    selectPath = {verifyNewPeer = true, selectPath = true},
    verifyNewPeer = {updateNodeAddress = true},
    updateNodeAddress = {updateBlocks = true},
    updateBlocks = {updateTransactions = true},
    updateTransactions = {selectPath = true},
}


local blockchain;
local transactionpool;
local function fullnode(seed)
	blockchain = BlockChain.create(Settings.BlockChain);
    transactionpool = TransactionPool.create(blockchain, Settings.TransactionPool);
    local bc = blockchain
    local tp = transactionpool
    Miner.init(bc, tp);

    Wallet.init(bc, tp , seed);

    Network.init(Settings.Network);
    Protocol.init(bc, tp);

end

local function wallet(seed)
    blockchain = BlockChain.create(Settings.BlockChain);
    transactionpool = TransactionPool.create(blockchain, Settings.TransactionPool);
    local bc = blockchain
    local tp = transactionpool
    Wallet.init(bc, tp , seed);

    Network.init(Settings.Network);
    Protocol.init(bc, tp);
end

local function miningprocess()
    Network.init(Settings.Network);
    Protocol.init();
end

function PCoin.isInited()
	return curState ~= nil
end

function PCoin.start(key, m)
	if PCoin.isInited() then 
		return 
	end
	mode = m;
	if mode == "wallet" then
		wallet(key)
	else
		mode = "fullnode"
		fullnode(key)
	end
    curState = states.selectPath;
    PCoin.selectPath();
    
	if mode == "fullnode" then
		PCoin.mine();
	end
end

function PCoin.stop()
end

function PCoin.generateKeys(num)
    return Wallet.generateKeys(num);
end

function PCoin.pay(value, keys)
   return Wallet.pay(value, keys);
end

function PCoin.connect(ip, port)
	ip = ip or "127.0.0.1";
	port = port or  "8099"
	Network.connect(ip ,port , function (nid, ret)
		if ret then
			Network.addNewPeer( nid)
		end
	end)
end

function PCoin.addNewPeer( nid)
	Network.addNewPeer( nid)
end

----------------------------------------------------------
function PCoin.step(input, delay, ...)
    if not curState[input] then    
        return 
    end

	delay = delay or 1;
    local paras = {...}
    local nextFrame = commonlib.Timer:new({callbackFunc = 
        function ()
            curState = states[input];
            PCoin[input](paras[1], paras[2], paras[3], paras[4],paras[5])
        end});
    nextFrame:Change(delay);
end

function PCoin.selectPath()
    local nid =  Network.getNewPeer() 
    if nid then
        PCoin.step("verifyNewPeer",nil, nid);
	else
        PCoin.step("selectPath", 5000)
    end
end

function PCoin.verifyNewPeer(nid)
    Protocol.version(nid, Constants.curVersion,
        function (msg)
            if msg.version == Constants.curVersion then
                PCoin.step("updateNodeAddress",nil, nid)
            else
                PCoin.step("selectPath")
            end
        end)
end

function PCoin.updateNodeAddress(nid)
    Protocol.node_address(nid, 
        function (msg)
            PCoin.step("updateBlocks",nil, nid)
        end
    )
end

function PCoin.updateBlocks(nid)
    Protocol.block_header(nid, 
        function ()
            PCoin.step("updateTransactions", nil, nid);
        end);
end

function PCoin.updateTransactions(nid)
    Protocol.transaction(nid, nil, 
        function ()
            PCoin.step("selectPath");
        end )
end


function PCoin.mine()
    Miner.generateBlock(
        function ()
            PCoin.mine();
        end) 
end

function PCoin.getCount()
	return Wallet.getUseableNumber(), Wallet.getTotalNumber();
end

function PCoin.report()
    echo("PCoin report:")
    blockchain:report();
    transactionpool:report();

end
--------------------------------------------------------------

function PCoin.test()

    PCoin.start("Treasure", "fullnode");

    PCoin.connect("127.0.0.1", "8099")
end