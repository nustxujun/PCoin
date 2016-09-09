--[[
	NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
	local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
]]

NPL.load("(gl)script/PCoin/Constants.lua");

local Constants = commonlib.gettable("Mod.PCoin.Constants");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");

local function checkCoinbaseScript(script)
	
end

local function basicChecks(tx, trans)
	local ret = ValidateTransaction.checkTransaction(tx)
	if ret then return ret end;

	local hash = tx:hash();
	if trans:find(function (t) return t:hash() == hash end) then
		return "Error:TransactionExisted";
	end

	return;
end

local function isDoubleSpending(tx, txpool)
	local trans = txpool.trans;

	local function isSpentByTx(preOutput, txInPool)
		for k,v in pairs(txInPool.inputs) do 
			if v.preOutput:equal(preOutput) then
				return true;
			end
		end
		return false;
	end
	
	local function isSpentInPool(preOutput)
		for k,v in trans:iterator() do
			if isSpentByTx(preOutput,v) then
				return true;
			end
		end
		return false;
	end

	for k,v in pairs(tx.inputs) do
		if isSpentInPool(v.preOutput) then
			return true;
		end
	end

	return false;
end

function ValidateTransaction.validate(transaction, txpool,chain)
	local trans = txpool.trans;

	local ret = basicChecks;
	if ret then return ret end;

	local data = chain:fetchTransaction(transaction:hash());
	if data then
		return "Error:TransactionExistedInDatabase";
	end

	if not isDoubleSpending(transaction, txpool) then
		return "Error:DoubleSpending";
	end

	return;
end

local maxMoney = Constants.maxMoney;
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
			return "Error:outputValueOverflow";
		end

		totalvalue = totalvalue + v.value;

		if totalvalue > maxMoney then
			return "Error:outputTotalValueOverflow";
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