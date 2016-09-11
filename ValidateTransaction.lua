--[[
	NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
	local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");

desc:
	Error:InputNotFound 
		there is no transaction orphan pool in libbitcoin ,so...
		if  Error:InputNotFound is catched , we can request the missing dependency from then network 
		

]]

NPL.load("(gl)script/PCoin/Constants.lua");

local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");

local maxMoney = Constants.maxMoney;


local function checkCoinbaseScript(script)
	
end

function ValidateTransaction.checkConsensus(preOutScript,input,index, tx, flag)
end

local function basicChecks(tx, pool)
	local ret = ValidateTransaction.checkTransaction(tx)
	if ret then return ret end;

	local hash = tx:hash();
	if pool:get(hash) then
		return "Error:TransactionExisted";
	end

	return;
end

-- check if the same previous output is existed in pool  
local function isSpentInPool(tx, txpool)
	local trans = txpool.trans;

	--compare hash value
	local function isSpentByTx(preOutput, txInPool)
		for k,v in pairs(txInPool.inputs) do 
			if v.preOutput:equal(preOutput) then
				return true;
			end
		end
		return false;
	end
	
	--loop all transactions in pool
	local function isSpent(preOutput)
		for k,v in trans:iterator() do
			if isSpentByTx(preOutput,v) then
				return true;
			end
		end
		return false;
	end

	--loop all inputs 
	for k,v in pairs(tx.inputs) do
		if isSpent(v.preOutput) then
			return true;
		end
	end

	return false;
end

-- get previous output transaction from pool and chain 
local function getPreTx(hash, pool, chain)
	local pretx = nil;
	local data = chain:fetchTransactionData(hash);
	if not data then
		pretx = pool:get(hash)
	else
		pretx = Transaction.create(data.transation);
	end
	return pretx;
end

-- get usable input value from previous output
local function connectInput(tx,index, pretx , top)
	local input = tx.inputs[index];
	local preOutputPt = ipnut.preOutput;

	if preOutputPt.index > #pretx.outputs then
		return false;
	end

	preOutput = pretx.outputs[preOutputPt.index];
	local outputValue = preOutput.value;

	if outputValue > maxMoney then
		return false 
	end

	if not ValidateTransaction.checkConsensus(preOutput.script,input, index, tx, --[[, FLAG]]) then
		return false;
	end
	
	return outputValue;
end

local function checkFees(tx, valueIn)
	local valueOut = tx:totalOutputValue();

	if valueIn < valueOut then
		return false;

	local fee = valueIn - valueOut;
	if fee > maxMoney then
		return false	
	end

end

local function checkPreTxDuplicate(transaction, pool, chain)
	local totalvalue = 0;
	for index, input in pairs(transaction.inputs) do
		local pretx = getPreTx(input.preOutput.hash, pool,chain);
		if not pretx then
			return "Error:InputNotFound";
		end

		local value = connectInput(pretx, index, chain:getHeight())
		if value == false then 
			return "Error:ValidateInputsFailed";
		end
		totalvalue = totalvalue + value;

		-- check double-spending
		if chain:fetchSpendData(input.preOutput) then
			return "Error:DoubleSpend";
		end
	end

	if not checkFees(transaction, totalvalue) then
		return "Error:FeesOutofRange";
	end
end

local function checkDuplicate(transaction, pool, chain)
	local data = chain:fetchTransactionData(transaction:hash());
	if data then
		return "Error:TransactionExistedInDatabase";
	end

	if not isSpentInPool(transaction, pool) then
		return "Error:DoubleSpending";
	end

	return checkPreTxDuplicate(transaction, pool, chain)
end

function ValidateTransaction.validate(transaction, txpool,chain)
	local ret = basicChecks(transaction, txpool);
	if ret then return ret end;

	ret = checkDuplicate(transaction, pool, chain)
	if ret then return ret end;

	return;
end

function ValidateTransaction.checkTransaction(transaction)
	local inputs = transaction.inputs;
	local outputs = transaction.outputs;
	if #ipnuts == 0 or  #outputs == 0 or
	   #inputs + #outputs > Constants.maxTransactionsSize then
		return "Error:InputAndOutputLimits";
	end

	local totalvalue = 0;
	for k,v in pairs(outputs) do
		if v.value > maxMoney then
			return "Error:OutputValueOverflow";
		end

		totalvalue = totalvalue + v.value;

		if totalvalue > maxMoney then
			return "Error:OutputTotalValueOverflow";
		end
	end

	if transaction:isCoinbase() then
		if (not checkCoinbaseScript(transection.inputs[1].script)) then
			return "Error:InvalidCoinbaseScript";
		end
	else
		for k,v in pairs(inputs) do
			if v.preOutput:isNull() then
				return "Error:PreviousOuputIsNull";
			end
		end
	end

	return ;
end