--[[
	NPL.load("(gl)script/PCoin/Wallet/Wallet.lua");
	local Wallet = commonlib.gettable("Mod.PCoin.Wallet.Wallet");
]]


NPL.load("(gl)script/PCoin/math/sha256.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Output.lua");
NPL.load("(gl)script/PCoin/Input.lua");
NPL.load("(gl)script/PCoin/Point.lua");
NPL.load("(gl)script/PCoin/Script.lua");
NPL.load("(gl)script/PCoin/Protocol.lua");
NPL.load("(gl)script/PCoin/Buffer.lua");

local Buffer = commonlib.gettable("Mod.PCoin.Buffer");
local Protocol = commonlib.gettable("Mod.PCoin.Protocol");
local Script = commonlib.gettable("Mod.PCoin.Script");
local Point = commonlib.gettable("Mod.PCoin.Point");
local Input = commonlib.gettable("Mod.PCoin.Input");
local Output = commonlib.gettable("Mod.PCoin.Output");
local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Encoding = commonlib.gettable("System.Encoding");
local makePublicKey = Encoding.sha224;
local makePrivateKey = Encoding.sha224
local Wallet = commonlib.gettable("Mod.PCoin.Wallet.Wallet");

local blockchain
local transactionPool;
local wallet;
local nextKey;
local seed;

local function makeKey()
    -- make key chain
    nextKey = Encoding.sha256(nextKey,"string");
    
    local private = makePrivateKey(nextKey, "string");
    local public = makePublicKey(private,"string")
    return public, private
end

function Wallet.init(chain, pool, start, lastKey)
    start = tostring(start)
    seed = start
    nextKey = start;
    blockchain = chain;
    transactionPool = pool
    wallet = {}

	local timer = commonlib.Timer:new({callbackFunc = function ()
		wallet.coins , wallet.useable, wallet.total = Wallet.collectCoins(seed, lastKey);
	end})
	timer:Change(0, 5000);
    Wallet.report();
end

function Wallet.getCoins()
    return wallet.coins;
end

function Wallet.getUseableNumber()
	return wallet.useable;
end

function Wallet.getTotalNumber()
    return wallet.total;
end

function Wallet.pay(value, hashes)
    local inputs, useable, coins = Wallet.getInputs(value);
    if not inputs then 
        echo({"not enough money", value, wallet.useable})
        return;-- not enough money;
    end
    local tx = Transaction:new()
    tx.inputs = inputs;
    
    local osize = #hashes;
    local each = value / osize; 
    
    for k,v in pairs(hashes) do
        local o = Output:new()
        o.value = each;
        o.script = Script.create(v);
        tx.outputs[#tx.outputs + 1] = o; 
    end

    local cash = useable - value;
    if cash > 0 then
        local o = Output:new();
        o.value = cash;
        o.script = Script.create(makeKey());
        tx.outputs[#tx.outputs + 1] = o;
    end


    if  transactionPool:store(tx) then
        for k,v in pairs(coins) do 
            wallet.useable = wallet.useable - wallet.coins[v].value;
			wallet.total= wallet.total- wallet.coins[v].value;
            wallet.coins[v] = nil;
        end
        
        Protocol.notifyNewTransaction(tx:hash())
		return true;
    end

end



function Wallet.generateKeys(num)
    local pool= {}
    for i = 1, num do 
        pool[#pool + 1] = makeKey();
    end
    return pool;
end

function Wallet.getInputs(value)
    if value > wallet.useable then
        return 
    end
    local useable = 0;
    local inputs = {}
    local hashes = {}
    for k,v in pairs(wallet.coins) do 
        useable = useable + v.value;
        local input = Input:new()
        input.preOutput = Point.create(v.point);
        input.script = Script.create(k);
        inputs[#inputs + 1] = input;
        hashes[#hashes + 1] = k;
        if (useable >= value) then
            return inputs, useable, hashes
        end
    end
    return 
end

function Wallet.collectCoins(start, lastKey)
    seed = start
    nextKey = seed;
    local collector = {}
    local key = nextKey
    local reserveCount ;
    local useable = 0;
	local total = 0;
    if not lastKey then
        reserveCount = 0;
    end

	local inputs = {};
	local outputs = {};
	for k,t in ipairs(transactionPool:getByCount()) do
		for _, i in ipairs(t.inputs) do
			inputs[i.script.operations] = true;
		end
		for _, o in ipairs(t.outputs) do 
			outputs[o.script.operations] = o.value;
		end
	end

    while true do  
        key = Encoding.sha256(key,"string");
        local private = makePrivateKey(key, "string");
        local public = makePublicKey(private,"string");
        local historydata = blockchain:fetchHistoryData(public);
        if not historydata then
			if outputs[public] then
				total = total + outputs[public];
                nextKey = key;
            elseif reserveCount then 
                reserveCount = reserveCount + 1;
            end
        else
            local spenddata = blockchain:fetchSpendData(historydata.point);
            if not spenddata and not inputs[private] then
                collector[private] = historydata;
                useable = useable + historydata.value;
				total = total + historydata.value;
            end
            nextKey = key;
        end

        if lastKey and lastKey == key then
            reserveCount = 0;
        end

        if reserveCount >= 100 then
            break;
        end
    end
    return collector, useable, total;
end

function Wallet.report()
    echo("Wallet report:")
    wallet.coins , wallet.useable, wallet.total = Wallet.collectCoins(seed);
    echo(format("useable: %d",wallet.useable) )
    for k,v in pairs(wallet.coins) do
        echo(v);
    end    


end


function Wallet.test()
	echo("Wallet Test")
	
    NPL.load("(gl)script/PCoin/Settings.lua");
	local Settings = commonlib.gettable("Mod.PCoin.Settings");
    NPL.load("(gl)script/PCoin/BlockChain.lua");
	local BlockChain = commonlib.gettable("Mod.PCoin.BlockChain");
	NPL.load("(gl)script/PCoin/TransactionPool.lua");
	local TransactionPool = commonlib.gettable("Mod.PCoin.TransactionPool");

    echo("	create block chain")

	local bc = BlockChain.create(Settings.BlockChain);
    local tp = TransactionPool.create(bc, Settings.TransactionPool);

    Wallet.init(bc, tp , "Treasure");
    echo("useable value: " .. wallet.useable)

    Wallet.pay(10, Wallet.generateKeys(2));

    echo("Wallet Test done")
end

