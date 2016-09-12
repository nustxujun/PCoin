--[[
	NPL.load("(gl)script/PCoin/Utility.lua");
	local Utility = commonlib.gettable("Mod.PCoin.Utility");
]]

NPL.load("(gl)script/Pcoin/sha256.lua");
NPL.load("(gl)script/PCoin/uint256.lua");

local uint256 = commonlib.gettable("Mod.PCoin.uint256");
local Encoding = commonlib.gettable("System.Encoding");
local sha256 = Encoding.sha256;

local Utility = commonlib.gettable("Mod.PCoin.Utility");

function Utility.log(desc, ...)
    LOG.std(nil, "debug", "PCoin", desc, ...);
end

function Utility.bitcoinHash(data)
	return sha256(sha256(data));
end

function Utility.blockWork(bits)
	local target, negative, overflow = uint256:new():setCompact(bits);

	if negative or overflow or not target then
		return 0
	end

	local bntarget = uint256:new(target);
	bntarget:bnot();
	return  (bntarget / (target + 1)) + 1;
end



function Utility.test()
	echo(sha256(sha256("","string"),"string"))
	local hash = uint256:new():setHash(Utility.bitcoinHash(""));
	echo(tostring(hash))

	echo(tostring(Utility.blockWork(0x1d00ffff)))


end