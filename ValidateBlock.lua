--[[
	NPL.load("(gl)script/PCoin/ValidateBlock.lua");
	local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");
]]

NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/ValidateTransaction.lua");
NPL.load("(gl)script/PCoin/Constants.lua");

local Constants = commonlib.gettable("Mod.PCoin.Constants");
local ValidateTransaction = commonlib.gettable("Mod.PCoin.ValidateTransaction");
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local isValidProofOfWork = Utility.validateProofOfWork;
local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");

local function isValidTimestamp(timestamp) 
	

	return true
end

local function isValidVersion(version)
	return true
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

local function legacySigOpsCount(trans)
	
end

local function checkBlock(block)
	local trans = block.transactions;

	if #trans == 0 or #trans > Constants.maxTransactionsCount then
		return "TransactionsLimits";
	end

	local header = block.header;

	if not isValidProofOfWork(header:hash(), header.bits) then
		return "ProofOfWork";
	end

	if not isValidTimestamp(header.timestamp) then
		return "TimstampLimits"
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
	if sigops > maxBlockScriptSignatureOperations then
		return "Error:TooManySigs";
	end

	if header.merkle ~= block:generateMerkleRoot() then
		return "Error:MerkleMismatch"
	end

	return;
end

local function workRequired(height)


end

local function acceptBlock(block, height)
	local header = block.header;
	if header.bits ~= workRequired(height) then
		return "Error:IncorrectProofofWork";
	end

	if not isValidVersion(header.version) then
		return "Error:OldVersionBlock"
	end

	return
end

function connectBlock(block)

end

function ValidateBlock.validate(block, height, blockchain)
	local ret = checkBlock(block);
	if ret then return ret end;

	ret = acceptBlock(block, height)
	if ret then return ret end;

	ret = connectBlock(block)
	if ret then return ret end;
	
	return ;
end