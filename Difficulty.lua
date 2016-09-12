--[[
	NPL.load("(gl)script/PCoin/Difficulty.lua");
	local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");

ref:
    based on: https://en.bitcoin.it/wiki/Difficulty
    need c++ supported
]]

NPL.load("(gl)script/ide/math/bit.lua");

local Difficulty = commonlib.gettable("Mod.PCoin.Difficulty");
local uint256 = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.uint256"));

local modf = math.modf;
local bor = mathlib.bit.bor
local band = mathlib.bit.band;
local bxor = mathlib.bit.bxor;
local bnot = mathlib.bit.bnot

-- bug: if B > 32 ,it will return A with no changing;
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;

local log = math.log;

local max_body = log(0x00ffff)
local scaland = log(256)

function Difficulty.caldifficulty(bits)
    return math.exp(max_body - log(band(bits, 0x00ffffff)) + scaland * (0x1d - rshift(band(bits, 0xff000000),24)))
end

function Difficulty.createTarget(bits)
    return uint256.create(bits);
end

local WIDTH = 8; 
function uint256.create(bits)
    if (type(bits) == "table" ) then
        return bits:clone();
    elseif type(bits) == "string" then
        local u = uint256:new()
        u:setHash(bits);
        return u
    else
        local u = uint256:new()
        u:setCompact(bits);
        return u;
    end
end

function uint256:reset()
    self.pn = {0,0,0,0,0,0,0,0}
end

function uint256:ctor()
    self:reset();
end

function uint256:clone()
    local n = uint256:new()
    for i = 1, WIDTH do
        n.pn[i] = self.pn[i];
    end
    return n;
end

function uint256:setCompact(bits)
    local size = rshift(bits, 24);
    local word = band(bits, 0x007fffff);
    if size <= 3 then
        word = rshift(word, 8 * (3 - size));
        self.pn[1] = word;
    else
        size = size - 3;
        local chunk = modf(size / 4);
        local shift = (size % 4) * 8;
        self:reset();
        local pn = self.pn;
        pn[chunk + 1] = lshift(word, shift);
    end

    local negative = word ~= 0 and band(bits, 0x00800000) ~= 0;
    local overflow =(word ~= 0 and size > 34) or 
                    (word > 0xff and size > 33) or 
                    (word > 0xffff and size > 32)
    return self, negative, overflow;
end

function uint256:setHash(hashbytes)
    local index = 0;
    self:reset();
    local pn = self.pn;
    for c in hashbytes:gmatch(".") do
        local num = string.byte(c);
        local chunk = modf(index / 4) + 1
        local pos = index % 4;
        pn[chunk] = pn[chunk] + lshift(num, pos * 8);
        index = index + 1;
    end

    echo({pn})
    return self;
end

function uint256:compare(b)
    for i = WIDTH, 1, -1 do 
        if self.pn[i] < b.pn[i] then
            return -1;
        end
        if self.pn[i] > b.pn[i] then
            return 1;
        end
    end
    return 0;
end


function uint256.__lshift(u, shift)
    local ret = uint256:new()
    local pn = ret.pn;

    local k = modf(shift / 32);
    shift = shift % 32;
    for i = 1, WIDTH do
        if (i + k + 1 <= WIDTH) and (shift ~=0) then
            pn[i + k + 1] = bor(pn[i + k + 1], rshift(u.pn[i], 32 - shift)) 
        end
        if i + k <= WIDTH then
            pn[i + k] = bor(pn[i + k], lshift(u.pn[i], shift))
        end
    end
    return ret;
end

function uint256:lshift(shift)
    self.pn = uint256.__lshift(self, shift).pn
    return self;
end

function uint256.__rshift(u, shift)
    local ret = uint256:new()
    local pn = ret.pn;

    local k = modf(shift / 32);
    shift = shift % 32;
    for i = 1, WIDTH do
        if (i - k - 1 > 0) and (shift ~=0) then
            pn[i - k - 1] = bor(pn[i - k - 1], lshift(u.pn[i], 32 - shift)) 
        end
        if i - k > 0 then
            pn[i - k] = bor(pn[i - k], rshift(u.pn[i], shift))
        end
    end
    return ret;
end

function uint256:rshift(shift)
    self.pn = uint256.__rshift(self, shift).pn
    return self;
end




---------------------------------------------------------------------
-- This algorithm need int64
---------------------------------------------------------------------
-- local uint256 = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.uint256"));

-- local WIDTH = 256 / 32;

-- local modf = math.modf;

-- uint256.pn = nil;

-- function uint256.create(bits)
--     local u = uint256:new()
--     if type(bits) == "table" then
--         u:fromUint256(bits);
--     else
--         u:fromInt(bits);
--     end
--     return u;
-- end

-- function uint256:ctor()
--     self.pn = {}
--     for i= 1, WIDTH do
--         self.pn[i] = 0;
--     end

-- end

-- function uint256:fromUint256(b)
--     for i = 1, WIDTH do
--         self.pn[i] = b.pn[i]
--     end
--     return self;
-- end

-- function uint256:fromInt(b)
--     local pn = self.pn;
--     pn[1] = b;
--     pn[2] = rshift(b,32);
    
--     for i = 3 , WIDTH do 
--         pn[i] = 0
--     end
--     return self;
-- end

-- function uint256.__lshift(u, shift)
--     local ret = uint256:new()
--     local pn = ret.pn;

--     local k = modf(shift / 32);
--     shift = shift % 32;
--     for i = 1, WIDTH do
--         if (i + k + 1 <= WIDTH) and (shift ~=0) then
--             pn[i + k + 1] = bor(pn[i + k + 1], rshift(u.pn[i], 32 - shift)) 
--         end
--         if i + k <= WIDTH then
--             pn[i + k] = bor(pn[i + k], lshift(u.pn[i], shift))
--         end
--     end
--     return ret;
-- end

-- function uint256:lshift(shift)
--     self.pn = uint256.__lshift(self, shift).pn
--     return self;
-- end

-- function uint256.__rshift(u, shift)
--     local ret = uint256:new()
--     local pn = ret.pn;

--     local k = modf(shift / 32);
--     shift = shift % 32;
--     for i = 1, WIDTH do
--         if (i - k - 1 > 0) and (shift ~=0) then
--             pn[i - k - 1] = bor(pn[i - k - 1], lshift(u.pn[i], 32 - shift)) 
--         end
--         if i - k > 0 then
--             pn[i - k] = bor(pn[i - k], rshift(u.pn[i], shift))
--         end
--     end
--     return ret;
-- end

-- function uint256:rshift(shift)
--     self.pn = uint256.__rshift(self, shift).pn
--     return self;
-- end

-- function uint256:setCompact(bits)
--     local size = rshift(bits, 24);
--     local word = band(bits, 0x007fffff);
--     if size <= 3 then
--         word = rshift(word, 8 * (3 - size));
--         self:fromInt(word);
--     else
--         self:fromInt(word)
--         self = self:lshift(8 * (size - 3))
--     end

--     local negative = word ~= 0 and band(bits, 0x00800000) ~= 0;
--     local overflow =(word ~= 0 and size > 34) or 
--                     (word > 0xff and size > 33) or 
--                     (word > 0xffff and size > 32)
--     return self, negative, overflow;
-- end

-- function uint256:equal(b)
--     local pn = self.pn;
    
--     for i = WIDTH, 3, -1 do
--         if pn[i] ~= 0 then
--             return false;
--         end
--     end

--     if pn[2] ~= 0 rshift(b, 32) then
--         return false;
--     end

--     if pn[1] ~= band(b, 0xffffffff) then
--         return false
--     end

--     return true;
-- end

-- function uint256.__bnot(u)
--     local ret = uint256:new()
--     for i = 1, WIDTH do
--         ret.pn[i] = bnot(u.pn[i]);
--     end
--     return ret;
-- end

-- function uint256:bnot()
--     self.pn = uint256.__bnot(self).pn
--     return self;
-- end

-- function uint256.__add(u,b)
--     local ret = uint256:new();
--     if type(b) == "table" then
--         local carry = 0;
--         local pn = u.pn;
--         for i = 1, WIDTH do 
--             local n = carry + pn[i] + b.pn[i];
--             ret.pn[i] = n;
--             carry = rshift(n, 32); 
--         end
--         return ret;
--     else
--         ret:fromInt(b);
--         return uint256.__add(u,ret)
--     end
-- end

-- function uint256:add(b)
--     self.pn = uint256.__add(self, b).pn
--     return self;
-- end

-- function uint256:bits()
--     local pn = self.pn
--     for pos = WIDTH, 1, -1 do
--         if pn[pos] ~= 0 then
--             for b = 31, 1, -1 do
--                 if band(pn[pos], lshift(1, b)) ~= 0 then
--                     return 32 * pos + b + 1;
--                 end
--             end
--             return 32 * pos + 1;
--         end
--     end
--     return 0;
-- end

-- function uint256:CompareTo(b)
--     for i = WIDTH, 1, -1 do 
--         if self.pn[i] < b.pn[i] then
--             return -1;
--         end
--         if self.pn[i] > b.pn[i] then
--             return 1;
--         end
--     end
        
--     return 0;
-- end

-- function uint256.__greaterequal(a, b)
--     return a:CompareTo(b) >= 0;
-- end

-- function uint256:sub(b)
--     local num = uint256.create(b);
--     num:bnot();
--     local i = 1;
--     local pn = num.pn;
--     while i <= WIDTH do
--         pn[i] = pn[i] + 1;
--         if pn[i] ~= 0 then
--             break;
--         end
--         i = i + 1;    
--     end
--     self:add(num);
--     return self;
-- end

-- function uint256.__div(u,b)
--     local ret = uint256:new()
--     local pn = ret.pn;
--     if type(b) == "table" then
--         local div = uint256.create(b);
--         local num = uint256.create(u);
--         local num_bits = num:bits();
--         local div_bits = div:bits();

--         if div_bits == 0 then
--             return "Error:Division by ZERO"
--         end
--         local shift = num_bits - div_bits;
--         div:lshift(shift)
--         while shift >= 0 do
--             echo({shift, num.pn, div.pn})
--             if uint256.__greaterequal(num, div) then
--                 num:sub(div)
--                 pn[modf(shift / 32) + 1] = bor(pn[modf(shift / 32) + 1], lshift(1, band(shift,31)));
--             end
            
--             div:rshift(1);
--             shift = shift - 1;
--         end
        
--         return ret;
--     else
--         return uint256.__div(ret:fromInt(b))
--     end
-- end

-- function uint256:div(b)
--     self.pn = uint256.__div(self, b).pn;
--     return self;
-- end

-- local ubnot = uint256.__bnot;
-- local udiv = uint256.__div;
-- local uadd = uint256.__add;

-- local function blockWork(bits)
--     local number = uint256:new()
--     local _, negative, overflow = number:setCompact(bits);
--     if  negative or overflow then  
--         return 0
--     end

--     if number:equal(0) then
--         return 0
--     end

--     return  uadd(udiv(ubnot(number), uadd(number,1)),1);
-- end
