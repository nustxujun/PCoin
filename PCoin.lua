--[[
    NPL.load("(gl)script/PCoin/PCoin.lua");
	local PCoin = commonlib.gettable("Mod.PCoin");
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
local curState; 
local states = 
{
    selectPath = {verifyNewPeer = true, selectPath = true},
    verifyNewPeer = {updateNodeAddress = true},
    updateNodeAddress = {updateBlocks = true},
    updateBlocks = {selectPath = true},
}

local function fullnode(seed)
	local bc = BlockChain.create(Settings.BlockChain);
    local tp = TransactionPool.create(bc, Settings.TransactionPool);

    Miner.init(bc, tp);
    Wallet.init(bc, tp , seed);

    Network.init(Settings.Network);
    Protocol.init(bc, tp);
end
 

function PCoin.init(key)
    fullnode(key)
end

function PCoin.start()
    curState = states.selectPath;
    PCoin.selectPath();
end

function PCoin.stop()
end

function PCoin.mine()
    Miner.generateBlock();
end

function PCoin.generateKeys(num)
    return Wallet.generateKeys(num);
end

function PCoin.pay(value, keys)
    Wallet.pay(value, keys);
end

function PCoin.connect(ip, port)
    Network.addNewPeer(ip or "127.0.0.1", port or "8099")
end

----------------------------------------------------------
function PCoin.step(input, ...)
    if not curState[input] then    
        return 
    end

    echo("step to " .. input)
    PCoin[input](...)
    curState = states[input];
end

function PCoin.selectPath()
    local nid =  Network.getNewPeer() 
    if nid then
        PCoin.step("verifyNewPeer", nid);
    else
    end

    local sleep = commonlib.Timer:new({callbaclFunc = 
        function () PCoin.step("selectPath"); end})

    sleep:Change(10000);
end

function PCoin.verifyNewPeer(nid)
    Protocol.version(nid, Constants.curVersion,
        function (msg)
            if msg.version == Constants.curVersion then
                PCoin.step("updateNodeAddress", nid)
            else
                PCoin.step("selectPath")
            end
        end)
end

function PCoin.updateNodeAddress(nid)
    Protocol.node_address(nid, 
        function (msg)
            PCoin.step("updateBlocks", nid)
        end
    )
end

function PCoin.updateBlocks(nid)
    Protocol.block_header(nid, 
        function ()
            PCoin.step("selectPath");
        end);
end
