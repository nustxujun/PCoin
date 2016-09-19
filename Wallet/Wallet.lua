--[[
	NPL.load("(gl)script/PCoin/Wallet/Wallet.lua");
	local Wallet = commonlib.gettable("Mod.PCoin.Wallet.Wallet");
]]


NPL.load("(gl)script/Pcoin/sha256.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Output.lua");
NPL.load("(gl)script/PCoin/Input.lua");
NPL.load("(gl)script/PCoin/Point.lua");
NPL.load("(gl)script/PCoin/Script.lua");

local Script = commonlib.gettable("Mod.PCoin.Script");
local Point = commonlib.gettable("Mod.PCoin.Point");
local Input = commonlib.gettable("Mod.PCoin.Input");
local Output = commonlib.gettable("Mod.PCoin.Output");
local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local Encoding = commonlib.gettable("System.Encoding");
local makePrivateKey = Encoding.sha224;
local makePublicKey = Encoding.sha256
local Wallet = commonlib.gettable("Mod.PCoin.Wallet.Wallet");

local blockchain
local transactionPool;
local package;
local wallet;
local unconfirmed;
local nextKey;
local seed;

local function makeKey()
    nextKey = makePrivateKey(nextKey, "string")
    return makePublicKey(nextKey,"string"), nextKey;
end

function Wallet.init(chain, pool, start, lastKey)
    seed = start
    nextKey = start;
    blockchain = chain;
    transactionPool = pool
    unconfirmed = {};
    wallet = {}
    wallet.coins , wallet.total = Wallet.collectCoins(seed, lastKey);

    Wallet.report();
end

function Wallet.getCoins()
    return wallet.coins;
end

function Wallet.getTotalNumber()
    return wallet.total;
end

function Wallet.pay(value, hashes)
    local inputs, total, coins = Wallet.getInputs(value);
    if not inputs then 
        echo({"not enough money", value, wallet.total})
        return;-- not enough money;
    end
    local tx = Transaction:new()
    tx.inputs = inputs;
    
    local osize = #hashes;
    local each = value / osize; 
        echo("output")
    
    for k,v in pairs(hashes) do
        local o = Output:new()
        o.value = each;
        o.script = Script.create(v);
        tx.outputs[#tx.outputs + 1] = o; 
        echo(o)
    end

    local cash = total - value;
    if cash > 0 then
        local o = Output:new();
        o.value = cash;
        o.script = Script.create(makeKey());
        tx.outputs[#tx.outputs + 1] = o;
        echo("cash")
        echo(o)
    end


    if  transactionPool:store(tx) then
        for k,v in pairs(coins) do 
            wallet.total = wallet.total - wallet.coins[v].value;
            wallet.coins[v] = nil;
        end
        
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
    if value > wallet.total then
        return 
    end
    local total = 0;
    local inputs = {}
    local hashes = {}
    echo("input")
    for k,v in pairs(wallet.coins) do 
        total = total + v.value;
        local input = Input:new()
        input.preOutput = Point.create(v.point);
        input.script = Script.create(k);
        echo(v)
        inputs[#inputs + 1] = input;
        hashes[#hashes + 1] = k;

        if (total >= value) then
            return inputs, total, hashes
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
    local total = 0;
    if not lastKey then
        reserveCount = 0;
    end

    while true do  
        key = makePrivateKey(key, "string");
        local publickey = makePublicKey(key,"string");
        local historydata = blockchain:fetchHistoryData(publickey);
        if not historydata then
            if reserveCount then 
                reserveCount = reserveCount + 1;
            end
        else
            local spenddata = blockchain:fetchSpendData(historydata.point);
            if not spenddata then
                collector[key] = historydata;
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
    return collector, total;
end

function Wallet.report()
    echo("Wallet report:")
    echo("coins")
    wallet.coins , wallet.total = Wallet.collectCoins(seed);
    for k,v in pairs(wallet.coins) do
        echo(v);
    end    
    echo(wallet.total)

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
    echo("total value: " .. wallet.total)

    Wallet.pay(10, Wallet.generateKeys(2));

    echo("Wallet Test done")
end

