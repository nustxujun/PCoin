--[[
	NPL.load("(gl)script/PCoin/Constants.lua");
	local Constants = commonlib.gettable("Mod.PCoin.Constants");
]]

NPL.load("(gl)script/PCoin/math/uint256.lua");

local uint256 = commonlib.gettable("Mod.PCoin.math.uint256");
local Constants = commonlib.gettable("Mod.PCoin.Constants");

Constants.curVersion = 1000;

Constants.maxTransactionsCount = 1000;
Constants.maxTransactionsSize = 1000; -- inputs + outputs size;
Constants.maxMoney = 100; 
Constants.maxBlockScriptSignatureOperations = 1000
Constants.maxWorkBit = 0x1f00ffff;
Constants.maxTarget = uint256:new():setCompact(Constants.maxWorkBit)

Constants.minVersion = 1000;