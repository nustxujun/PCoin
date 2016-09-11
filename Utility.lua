--[[
	NPL.load("(gl)script/PCoin/Utility.lua");
	local Utility = commonlib.gettable("Mod.PCoin.Utility");
]]

NPL.load("(gl)script/Pcoin/sha256.lua");
NPL.load("(gl)script/PCoin/Difficulty.lua");

local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");
local Encoding = commonlib.gettable("System.Encoding");
local sha256 = Encoding.sha256;

local Utility = commonlib.gettable("Mod.PCoin.Utility");

function Utility.log(desc, ...)
    LOG.std(nil, "debug", "PCoin", desc, ...);
end

function Utility.bitcoinHash(data)
	return sha256(sha256(data));
end

function Utility.blockWork = Difficulty.calDifficulty;

function Utility.validateProofOfWork(hash, bits)
	local diff = Utility.blockWork(bits);
	if diff > Constants.maxDifficulty then
		return false;
	end

	
end