--[[
	NPL.load("(gl)script/PCoin/uint256.lua");
	local uint256 = commonlib.gettable("Mod.PCoin.uint256");

compact:
    0x1b0404cb ----> 0x0404cb * 2^(8*( 0x1b - 3)) = 0x00000000000404CB000000000000000000000000000000000000000000000000   

use: 
    local a = uint256:new(0xff);                        --> 0x00000000000000000000000000000000000000000000000000000000000000FF
    local b = uint256:new():setCompact(0x1b0404cb);     --> 0x00000000000404CB000000000000000000000000000000000000000000000000
    local c = b - 123321                                --> 0x00000000000404CAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE1E47

]]

NPL.load("(gl)script/ide/math/bit.lua");


local modf = math.modf;
local bor = mathlib.bit.bor
local band = mathlib.bit.band;
local bxor = mathlib.bit.bxor;
local bnot = mathlib.bit.bnot
-- bug: if B > 32 ,it will return A with no changing;
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;

local uint256 = commonlib.gettable("Mod.PCoin.uint256");

local WIDTH = 32;

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
    -- unsigned char pn[32] 
    self.pn = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
end

function uint256:new(bits)
    if bits and type(bits) == "table" then
         return bits:clone();
    else
        local o = {}
        setmetatable(o, self)
        self.__index = self

         o:reset();

        if bits then
            for i = 1, 4 do
                o.pn[i] = band(rshift(bits, (i - 1) * 8),0xff);
            end
        end
        return o;
    end
end

function uint256:clone()
    local n = uint256:new()
    for i = 1, WIDTH do
        n.pn[i] = self.pn[i];
    end
    return n;
end

-- compact int32 to uint256
function uint256:setCompact(bits)
    self:reset();
    local pn = self.pn;
    
    local size = rshift(bits, 24);
    local word = band(bits, 0x007fffff);
    if size <= 3 then
        word = rshift(word, 8 * (3 - size));
        for i = 1, 3 do
            pn[i] = band(rshift(word, (i - 1) * 8), 0xff);
        end
    else
        size = size - 3;
        local shift = size * 8;
        for i = 1, 3 do
            pn[size + i] = band(rshift(word, (i - 1) * 8), 0xff);
        end
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
        pn[index] = pn[index] + num;
        index = index + 1;
    end
    return self;
end

function uint256:compare(b)
    if type(b) == "table" then
        for i = WIDTH, 1, -1 do 
            if self.pn[i] < b.pn[i] then
                return -1;
            end
            if self.pn[i] > b.pn[i] then
                return 1;
            end
        end
        return 0;
    else
        return self:compare(uint256:new(b))
    end
end

function uint256:bits()
    local pn = self.pn;
    for pos = WIDTH, 1, -1 do
        if pn[pos] ~= 0 then
            for bits = 7, 1 ,-1 do 
                if band(pn[pos], lshift(1, bits)) ~=0 then
                    return 8 * (pos - 1) + bits + 1 ;
                end
            end
            return 8 * (pos-1) + 1
        end
    end
    return 0;
end

function uint256:tostring()
    return self:__tostring();
end

function uint256:__tostring()
    local ret = "0x"
    for i = WIDTH, 1 , -1 do 
        ret = ret .. string.format("%02X",self.pn[i]);
    end
    return ret;
end

function uint256.__lshift(u, shift)
    local ret = uint256:new()
    local pn = ret.pn;

    local k = modf(shift / 8);
    shift = shift % 8;
    for i = 1, WIDTH do
        if (i + k + 1 <= WIDTH) and (shift ~=0) then
            pn[i + k + 1] = bor(pn[i + k + 1], rshift(u.pn[i], 8 - shift)) 
        end
        if i + k <= WIDTH then
            pn[i + k] = band(bor(pn[i + k], lshift(u.pn[i], shift)), 0xff)
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

    local k = modf(shift / 8);
    shift = shift % 8;
    for i = 1, WIDTH do
        if (i - k - 1 > 0) and (shift ~=0) then
            pn[i - k - 1] = band(bor(pn[i - k - 1], lshift(u.pn[i], 8 - shift)), 0xff) 
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

function uint256.__add(u,b)
    if type(b) == "table" then
        local ret = uint256:new();
        local carry = 0;
        local pn = u.pn;
        for i = 1, WIDTH do 
            local n = carry + pn[i] + b.pn[i];
            ret.pn[i] = band(n, 0xff);
            carry = rshift(n, 8); 
        end
        return ret;
    else
        return u + uint256:new(b);
    end
end

function uint256:add(b)
    self.pn = (self + b).pn
    return self;
end

function uint256.__unm(a)
    local b = uint256:new(a)
    local pn = b.pn;
    for i = 1, WIDTH do 
        pn[i] = band(bnot(pn[i]),0xff)
    end

    for i = 1, WIDTH do 
        pn[i] = band(pn[i] + 1, 0xff);
        if pn[i] ~= 0 then
            break;
        end
    end
    return b;
end

function uint256.__sub(a,b)
    if type(b) == "table" then
        local c = uint256:new();
        c = a + (-b);
        return c;
    else
        return a - uint256:new(b);
    end
end

function uint256:sub(b)
    self.pn = (self - b).pn
    return self
end

function uint256.__mul(a,b)
    if type(b) == "table" then
        local c = uint256:new();
        local pn = c.pn;

        for j = 1, WIDTH do
            local carry = 0;
            for i = 1, WIDTH do 
                if i + j > WIDTH then
                    break;
                end
                local n = carry + pn[i + j - 1] + a.pn[j] * b.pn[i];
                pn[i + j - 1] = band(n, 0xff);
                carry = rshift(n, 8); 
            end
        end
        return c;
    else
        return a * uint256:new(b);
    end
end

function uint256:mul(b)
    self.pn = (self * b).pn;
    return self;
end

function uint256.__div(a,b)
    if type(b) == "table" then
        local div = b;
        local num = a;
        local c = uint256:new()
        local pn = c.pn;

        local num_bits = num:bits();
        local div_bits = div:bits();

        if div_bits == 0 then
            return {pn="Error: Division by ZERO"};
        end

        if div_bits > num_bits then
            return c;
        end

        local shift = num_bits - div_bits;

        div:lshift(shift);

        while shift >= 0 do
            if num >= div then
                num:sub(div)
                pn[modf(shift / 8) + 1] = band( bor(pn[modf(shift / 8) + 1], lshift(1, band(shift, 7))) , 0xff);             
            end
            div:rshift(1);
            shift = shift - 1;
        end
        return c;
    else
        return a / uint256:new(b);
    end
end

function uint256:mul(b)
    self.pn = (self / b).pn;
    return self;
end

function uint256.__eq(a,b)
    return a:compare(b) == 0;
end

function uint256.__lt(a,b)
    return a:compare(b) < 0;
end

function uint256.__le(a,b)
    return a:compare(b) <= 0;
end

function uint256.test()
    local num = uint256:new(1);
    echo(uint256:new(2) >= uint256:new(1))
    
end