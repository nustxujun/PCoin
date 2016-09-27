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
local curState; 
local states = 
{
    selectPath = {verifyNewPeer = true, mine = true,selectPath = true},
    verifyNewPeer = {updateNodeAddress = true},
    updateNodeAddress = {updateBlocks = true},
    updateBlocks = {selectPath = true},
    mine = {selectPath = true}
}

local function fullnode(seed)
	local bc = BlockChain.create(Settings.BlockChain);
    local tp = TransactionPool.create(bc, Settings.TransactionPool);
    Miner.init(bc, tp);
    Wallet.init(bc, tp , seed);

    Network.init(Settings.Network);
    Protocol.init(bc, tp);

end

local function miningprocess()
    Network.init(Settings.Network);
    Protocol.init();
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

    local paras = {...}
    local nextFrame = commonlib.Timer:new({callbackFunc = 
        function ()
            echo("step to " .. input)
            curState = states[input];
            PCoin[input](paras[1], paras[2], paras[3], paras[4],paras[5])
        end});
    nextFrame:Change(1);
end

function PCoin.selectPath()
    local nid =  Network.getNewPeer() 
    if nid then
        PCoin.step("verifyNewPeer", nid);
    elseif Miner.isCPPSupported() or Miner.isMiningServiceSurpported() then
        PCoin.step("mine");
    else
        local sleep = commonlib.Timer:new({callbackFunc = 
        function (t)  PCoin.selectPath(); end})

        sleep:Change(5000);
    end


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


function PCoin.mine()
    Miner.generateBlock(
        function ()
            PCoin.step("selectPath");
        end) 
end


--------------------------------------------------------------

function PCoin.test()
    PCoin.init("wallet password")

    PCoin.start();

    PCoin.connect("127.0.0.1", "8099")
end