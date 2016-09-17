--[[
	NPL.load("(gl)script/PCoin/Wallet/PaymentAddress.lua");
	local PaymentAddress = commonlib.gettable("Mod.PCoin.Wallet.PaymentAddress");
]]


local PaymentAddress = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Wallet.PaymentAddress"));

function PaymentAddress:ctor()
    self.hashvalue = nil;
end

function PaymentAddress.create(script)
    local p = PaymentAddress:new();

    p:extract(script);
    return p;
end

function PaymentAddress:extract(script)
    self.hashvalue = script.operations;
end


function PaymentAddress:hash()
    return self.hashvalue;
end