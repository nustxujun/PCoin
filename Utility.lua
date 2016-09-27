--[[
	NPL.load("(gl)script/PCoin/Utility.lua");
	local Utility = commonlib.gettable("Mod.PCoin.Utility");
]]

NPL.load("(gl)script/PCoin/math/sha256.lua");
NPL.load("(gl)script/PCoin/math/uint256.lua");
NPL.load("(gl)script/PCoin/Constants.lua");

local Constants = commonlib.gettable("Mod.PCoin.Constants");	
local BlockHeader = commonlib.gettable("Mod.PCoin.BlockHeader");
local uint256 = commonlib.gettable("Mod.PCoin.math.uint256");
local Encoding = commonlib.gettable("System.Encoding");
local sha256 = Encoding.sha256;

local Utility = commonlib.gettable("Mod.PCoin.Utility");

function Utility.log(desc, ...)

    LOG.std(nil, "info", "PCoin", desc, ...);
end

function Utility.bitcoinHash(data)
	return sha256(sha256(NPL.SerializeToSCode("",data)));
end

function Utility.HashBytesToString(hash)
	return uint256:new():setHash(hash):tostring();
end

function Utility.blockWork(bits)
	local target, negative, overflow = uint256:new():setCompact(bits);

	if negative or overflow or not target then
		return 0
	end

	--[[ 
			2^256 / (target +1) ===>  
			((2^256 - (1 + target)) / (target + 1)) + 1 ===>
			(~target / (target + 1)) + 1
		someone's explanation:
			http://bitcoin.stackexchange.com/questions/34111/bitcoin-getblockwork-function

	]]	
	local bnottarget = target:clone();
	return (bnottarget:bnot() / (target + 1)) + 1; 

	-- get from https://en.bitcoin.it/wiki/Difficulty
	-- return (uint256:new(0):bnot / target) -- pdiff
	-- return (Constants.maxTarget / target)  -- bdiff
end

local targetSpacingSeconds = 10 * 60; -- 10 min
local targetTimeSpanSeconds = 2* 7 * 24 * 60 * 60 -- 2 week
--The target number of blocks for 2 weeks of work (2016 blocks).
local retargetingInterval = targetTimeSpanSeconds / targetSpacingSeconds
-- Value used to define retargeting range constraint.
local retargetingFactor = 4;

-- previous, preInterval : BlockHeader
function Utility.workRequired(height, fetchBlockHeader)
	local previous = fetchBlockHeader(height - 1);

	if ( (height - 1) % retargetingInterval) == 0 then
		local preInterval = fetchBlockHeader(height - retargetingInterval);
		local actual = previous.timestamp - preInterval.timestamp;
		local upper = targetTimeSpanSeconds * retargetingFactor;
		local lower = targetTimeSpanSeconds / retargetingFactor;

		local constrained = math.min(math.max(lower, actual), upper);

		local retarget = uint256:new():setCompact(previous.bits);
		retarget = retarget * constrained;
		retarget = retarget / targetTimeSpanSeconds;
		
		if retarget > Constants.maxTarget then
			retarget = Constants.maxTarget;
		end
		
		return retarget:getCompact();
	else
		return previous.bits;
	end
	
end



function Utility.test()
	local hash = uint256:new():setHash(Utility.bitcoinHash(""));
	echo(tostring(hash))

	echo(tostring(Utility.blockWork(0x1d00ffff)))

end