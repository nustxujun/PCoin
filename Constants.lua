--[[
	NPL.load("(gl)script/PCoin/Constants.lua");
	local Constants = commonlib.gettable("Mod.PCoin.Constants");
]]

NPL.load("(gl)script/PCoin/Difficulty.lua");

local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");
local Constants = commonlib.gettable("Mod.PCoin.Constants");

Constants.maxTransactionsCount = 1000;
Constants.maxTransactionsSize = 1000; -- inputs + outputs size;
Constants.maxMoney = 0xffffffff; 
Constants.maxBlockScriptSignatureOperations = 1000
Constants.maxWorkBit = 0x1d00ffff;
Constants.maxDifficulty = Difficulty.calDifficulty(Constants.maxWorkBit);
