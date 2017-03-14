--[[
	NPL.load("(gl)script/PCoin/Buffer.lua");
	local Buffer = commonlib.gettable("Mod.PCoin.Buffer");
]]

local Buffer = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Buffer"));

function Buffer:ctor()
	self:clear();
end

function Buffer:clear()
	self.data = {};
	self.first = 1;
	self.last = 0;
end

function Buffer:push_back(elem)
	self.last = self.last + 1;
	self.data[self.last] = elem;
end

function Buffer:pop_front()
	if self:size() == 0 then
		return
	end
	local e = self.data[self.first];
	self.data[self.first] = nil;
	self.first = self.first + 1 ;
	return e;
end

function Buffer:front()
	return self.data[self.first];
end

function Buffer:back()
	return self.data[self.last];
end

function Buffer:find(match)
	local data = self.data;
	for i = self.first, self.last do 
		if match(data[i]) then
			return data[i], i
		end
	end
end

function Buffer:get(index)
	return self.data[self.first + index - 1];
end

function Buffer:erase(index, last)
	last = last or index;
	local size = last - index + 1
	if last > self:size() then
		return
	end

	local data = self.data;
	for i = self.first + index - 1, self.last - 1 do
		data[i] = data[i + size];
	end
	self.last = self.last - size;
end

function Buffer:size()
	return self.last - self.first + 1;
end

function Buffer:iterator()
	local index = self.first - 1;
	return function ()
		index = index + 1;
		if (index <= self.last) then
			return index, self.data[index];
		end
	end
end
