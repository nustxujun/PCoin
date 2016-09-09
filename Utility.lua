--[[
	NPL.load("(gl)script/PCoin/Utility.lua");
	local Utility = commonlib.gettable("Mod.PCoin.Utility");
]]

local Utility = commonlib.gettable("Mod.PCoin.Utility");

function Utility.log(desc, ...)
    LOG.std(nil, "debug", "PCoin", desc, ...);
end

function Utility.bitcoinHash()
end

function Utility.blockWork(bits)
end

function Utility.validateProofOfWork(hash, bits)

end