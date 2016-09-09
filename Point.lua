--[[
	NPL.load("(gl)script/PCoin/Point.lua");
	local Point = commonlib.gettable("Mod.PCoin.Point");
]]

local Point = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Point"));

Point.hash = nil;
Point.index = nil;

function Point.create(data)
	local p = Point:new();
	p:fromData(data)
	return p;
end

function Point:fromData(data)
	self.hash = data.hash;
	self.index = index;
end

function Point:toData()
	return {hash = self.hash, index = self.index};
end

function Point:isNull()
	return self.hash == nil or self.index == nil;
end

function Point:equal(p)
	return self.hash == p.hash and self.index == p.index
end
