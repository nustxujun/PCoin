--[[
	NPL.load("(gl)script/PCoin/ValidateBlock.lua");
	local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");
]]

NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");
NPL.load("(gl)script/PCoin/uint256.lua");

local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");

local maxBlockScriptSigOps = Constants.maxBlockScriptSignatureOperations;

local function legacySigOpsCount(trans)
	
end

local function scriptHashSignatureOperationsCount(outputScript, inputScript)

end



local twoHour = 2 * 60 * 60;
local function isValidTimestamp(timestamp) 
	local cur = os.time();
	return timestamp <= (cur + twoHour) 
end

local function isValidVersion(version)
	return version >= Constants.minVersion;
end

local function isDistinctTransactionSet(trans)
	local hashs = {}
	for k,v in pairs(trans) do
		hashs[#hashs + 1] = v:hash();
	end
	hashs:sort(
		function (a, b) 
			return a < b;
		end);
		
	local count = #hash - 1;
	for i = 1 , count do
		if hashs[i] == hashs[i + 1] then
			return false
		end
	end
	return true;
end

local function isValidProofOfWork(hash, bits)
	local target = uint256:new():setCompact(bits);
	if not target or  target > Constants.maxTarget then
		return false;
	end

	local ourValue = uint256:new():setHash(hash);
	return ourValue <= target;
end

local function checkBlock(block)
	local trans = block.transactions;

	if #trans == 0 or #trans > Constants.maxTransactionsCount then
		return "Error:TransactionsLimits";
	end

	local header = block.header;

	if not isValidProofOfWork(header:hash(), header.bits) then
		return "Error:ProofOfWork";
	end

	if not isValidTimestamp(header.timestamp) then
		return "Error:TimstampLimits"
	end

	for k,v in pairs(trans) do
		local ret = ValidateTransaction.checkTransaction(v)
		if ret then
			return ret
		end
	end

	if not isDistinctTransactionSet(trans) then
		return "Error:Duplicate";
	end

	local sigops = legacySigOpsCount(trans)
	if sigops > maxBlockScriptSigOps then
		return "Error:TooManySigs";
	end

	if header.merkle ~= block:generateMerkleRoot() then
		return "Error:MerkleMismatch"
	end

	return;
end


local function acceptBlock(block, height,chain)
	local header = block.header;
	if header.bits ~= Utility.workRequired(height, chain) then
		return "Error:IncorrectProofofWork";
	end

	if not isValidVersion(header.version) then
		return "Error:OldVersionBlock"
	end

	return
end

local function transactionExists(hash, fork, chain)
	local data = chain:fetchTransactionData(hash);
	if not data then
		return false;
	end

	return data.height <= fork;
end

local function isOutputSpent(outpoint, fork, chain)
	local data = chain:fetchSpendData(outpoint);
	if not data then 
		return false;
	end

	return transactionExists(data.hash, fork, chain);
end

local function isSpentDuplicate(tx, fork, chain)
	local hash = tx:hash();

	if not transactionExists(hash, fork, chain)
		return false;
	end

	for index,output in pairs(tx.outputs) do
		if not isOutputSpent({hash, index}) then 
			return false;
		end
	end

	return true;
end

local function fetchOrphanTransaction(hash, fork, orphanchain, orphanIndex)
	for index , orphan in pairs(orphanchain) do
		for _, tx in pairs(orphan.block.transactions) do
			if tx:hash() == hash then
				return tx, fork + index;
			end
		end

		if index >= orphanIndex then
			return
		end
	end
end

local function fetchTransaction(hash, fork, chain, orphanchain, orphanIndex)
	local data = chain:fetchTransactionData(hash);

	if (not data) or (data.height > fork ) then
		return fetchOrphanTransaction(hash, fork, orphanchain, orphanIndex );
	elseif data then
		return Transaction.create(data.transaction), data.height;
	end
end

local function orphanIsSpent(outpoint, skipTx, skipInput, orphanchain, orphanIndex)
	for index, orphan in pairs(orphanchain) do
		for indextx, tx in pairs(orphan.block.transactions) do
			for indexin, input in pairs(tx.inputs) do
				-- skip if is self
				if not (index == orphanIndex and indextx == skipTx and indexin == skipInput) then
					if input.preOutput == outpoint then
						return true
					end
				end
			end
		end
	end
	return false;
end

local function isOutputSpentIncludeOrphans(outpoint,indexTx, indexInput, fork, chain, orphanchain)
	if isOutputSpent(outpoint, fork, chain) then
		return true;
	end

	return orphanIsSpent(outpoint, indexTx, indexInput,orphanchain, orphanIndex) 
end

local function validateInputs(tx, fork, chain, orphanchain, orphanIndex, totalSigops, valueIn)
	for index, input in pairs(tx.inputs) do
		local preOutputPt = input.preOutput;

		local preOuputTx , preHeight = fetchTransaction(preOutputPt.hash, fork, chain, orphanchain, orphanIndex);
		if not preOutputTx then
			return {error="Error:FetchingOutputTransactionFailed"};
		end

		local preOutput = preOuputTx.outputs[preOutputPt.index];
		local count = scriptHashSignatureOperationsCount(preOutput.script, input.script);
		if not count then
			return {error="Error:InvalidEvalScript"};
		end

		totalSigops = totalSigops + count;
		if totalSigops > maxBlockScriptSigOps then
			return {error="Error:TooManySigs"};
		end

		local outputValue = preOuput.value;
		if outputValue > Constants.maxMoney then 
			return {error="Error:OutputValueOverflow"};
		end

		if not ValidateTransaction.checkConsensus(preOutput.script, input, index, tx, --[[, FLAG]]) then
			return {error="Error:InputScriptInvalidConsensus"};
		end
		
		if isOutputSpentIncludeOrphans(preOutputPt, fork, chain,orphanchain, orphanIndex) then
			return {error="Error:DoubleSpend(IncludeInOrphanChain)"}
		end

		valueIn = valueIn + outputValue;

		if valueIn > Constants.maxMoney then
			return {error="Error:InputValueOverflow"};
		end
	end
	return {valueIn = valueIn, totalSigops = totalSigops};
end

local function connectBlock(block, fork, chain, orphanchain, orphanIndex)
	local fees = 0;
	local totalSigops = 0;
	
	for index,tx in pairs(block.transactions) do
		if isSpentDuplicate(tx, fork, chain) then 
			return "Error:DuplicateOrSpent";
		end

		totalSigops = totalSigops + legacySigOpsCount(tx);
		if totalSigops > maxBlockScriptSigOps then 
			return "Error:TooManySigs"
		end

		local ret = validateInputs(tx, fork, chain, orphanchain, orphanIndex, totalSigops, valueIn );
		if ret.error then
			return ret.error;
		else
			totalSigops = ret.totalSigops;
		end

		local valueOut = tx:totalOutputValue();
		if ret.valueIn < valueOut then
			return "Error:FeesOutOfRange";
		end
		fees = fees + valueIn - valueOut;
		if fees > Constants.maxMoney then
			return "Error:FeesOutOfRange";
		end
	end
end

function ValidateBlock.validate(block, index, fork, blockchain, orphanchain)
	local height = fork + index;
	local ret = checkBlock(block);
	if ret then return ret end;

	ret = acceptBlock(block, height, blockchain)
	if ret then return ret end;

	ret = connectBlock(block, fork, blockchain, orphanchain, index)
	if ret then return ret end;
	

	return ;
end