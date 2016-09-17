--[[
	NPL.load("(gl)script/PCoin/Settings.lua");
	local Settings = commonlib.gettable("Mod.PCoin.Settings");
]]

local Settings = commonlib.gettable("Mod.PCoin.Settings");


Settings.BlockChain = 
{
    database = 
    {
        root = "database/pcoin/", -- database path
        sync = true, 
    },

}

Settings.TransactionPool = 
{
    capacity = 1000,


}

