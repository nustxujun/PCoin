--[[
	NPL.load("(gl)script/PCoin/Constants.lua");
	local Constants = commonlib.gettable("Mod.PCoin.Constants");
]]

NPL.load("(gl)script/PCoin/uint256.lua");

local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");

Constants.maxTransactionsCount = 1000;
Constants.maxTransactionsSize = 1000; -- inputs + outputs size;
Constants.maxMoney = 0xffffffff; 
Constants.maxBlockScriptSignatureOperations = 1000
Constants.maxWorkBit = 0x1d00ffff;
Constants.maxTarget = uint256:new():setCompact(Constants.maxWorkBit)

Constants.minVersion = 1000;