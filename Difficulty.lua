--[[
	NPL.load("(gl)script/PCoin/Difficulty.lua");
	local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");

ref: 
    https://en.bitcoin.it/wiki/Difficulty
]]

NPL.load("(gl)script/PCoin/uint256.lua");
local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");

local log = math.log;
local max_body = log(0x00ffff)
local scaland = log(256)
function Difficulty.caldifficulty(bits)
    return math.exp(max_body - log(band(bits, 0x00ffffff)) + scaland * (0x1d - rshift(band(bits, 0xff000000),24)))
end

function Difficulty.createTarget(bits)
    return uint256.create(bits);
end


