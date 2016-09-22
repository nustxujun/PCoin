--[[
	NPL.load("(gl)script/PCoin/ValidateBlock.lua");
	local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");
]]

NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");
NPL.load("(gl)script/PCoin/uint256.lua");
NPL.load("(gl)script/PCoin/Transaction.lua");
NPL.load("(gl)script/PCoin/Block.lua");

local BlockHeader = commonlib.gettable("Mod.PCoin.BlockHeader");
local Transaction = commonlib.gettable("Mod.PCoin.Transaction");
local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");

local maxBlockScriptSigOps = Constants.maxBlockScriptSignatureOperations;

local function legacySigOpsCount(trans)
	

	return 0;
end

local function scriptHashSignatureOperationsCount(outputScript, inputScript)
	return 0;
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
	
	table.sort(hashs,
		function (a, b) 
			return a < b;
		end);
		
	local count = #hashs - 1;
	for i = 1 , count do
		if hashs[i] == hashs[i + 1] then
			return false
		end
	end
	return true;
end

local function isValidProofOfWork(hash, bits)
	local target = uint256:new():setCompact(bits);
	if target > Constants.maxTarget then
		return false;
	end

	local ourValue = uint256:new():setHash(hash);
	return ourValue <= target;
end

local function checkBlock(block)
	local trans = block.transactions;

	if --[[#trans == 0 or]] #trans > Constants.maxTransactionsCount then
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



local function workRequired(index, fork, chain, orphanchain)
	return Utility.workRequired(fork + index,
			function (height)
				if height > fork then
					return orphanchain:get(height - fork).block.header;
				end
				return BlockHeader.create(chain:fetchBlockDataByHeight(height).block.header);
			end)
end

local function acceptBlock(block, index, fork,chain,orphanchain)
	local header = block.header;
	if header.bits ~= workRequired(index, fork, chain, orphanchain) then
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

	if not transactionExists(hash, fork, chain) then
		return false;
	end

	for index,output in pairs(tx.outputs) do
		if not isOutputSpent({hash, index},fork, chain) then 
			return false;
		end
	end

	return true;
end

local function fetchOrphanTransaction(hash, fork, orphanchain, orphanIndex)
	for index , orphan in orphanchain:iterator() do
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
	for index, orphan in orphanchain:iterator() do
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

local function isOutputSpentIncludeOrphans(outpoint,indexTx, indexInput, fork, chain, orphanchain,orphanIndex)
	if isOutputSpent(outpoint, fork, chain) then
		return true;
	end

	return orphanIsSpent(outpoint, indexTx, indexInput,orphanchain, orphanIndex) 
end

local function validateInputs(tx, indextx, fork, chain, orphanchain, orphanIndex, totalSigops, valueIn)
	for index, input in pairs(tx.inputs) do
		local preOutputPt = input.preOutput;

		local preOutputTx , preHeight = fetchTransaction(preOutputPt.hash, fork, chain, orphanchain, orphanIndex);
		if not preOutputTx then
			return {error="Error:FetchingOutputTransactionFailed"};
		end

		local preOutput = preOutputTx.outputs[preOutputPt.index];
		local count = scriptHashSignatureOperationsCount(preOutput.script, input.script);
		if not count then
			return {error="Error:InvalidEvalScript"};
		end

		totalSigops = totalSigops + count;
		if totalSigops > maxBlockScriptSigOps then
			return {error="Error:TooManySigs"};
		end

		local outputValue = preOutput.value;
		if outputValue > Constants.maxMoney then 
			return {error="Error:OutputValueOverflow"};
		end

		if not ValidateTransaction.checkConsensus(preOutput.script, input.script, index, tx --[[, FLAG]]) then
			return {error="Error:InputScriptInvalidConsensus"};
		end
		
		if isOutputSpentIncludeOrphans(preOutputPt,indextx,index, fork, chain,orphanchain, orphanIndex) then
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

		local valueIn = 0
		local ret = validateInputs(tx,index, fork, chain, orphanchain, orphanIndex, totalSigops, valueIn );
		if ret.error then
			return ret.error;
		else
			totalSigops = ret.totalSigops;
			valueIn = ret.valueIn;
		end

		local valueOut = tx:totalOutputValue();
		echo({valueOut, valueIn})
		if ret.valueIn < valueOut then
			return "Error:FeesOutOfRange";
		end
		echo(fees)
		fees = fees + valueIn - valueOut;
		if fees > Constants.maxMoney then
			return "Error:FeesOutOfRange";
		end
	end
end

function ValidateBlock.validate(block, index, fork, blockchain, orphanchain)
	local ret = checkBlock(block);
	if ret then return ret end;

	ret = acceptBlock(block, index, fork, blockchain, orphanchain)
	if ret then return ret end;

	ret = connectBlock(block, fork, blockchain, orphanchain, index)
	if ret then return ret end;

	return ;
end