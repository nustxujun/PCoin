--[[
	NPL.load("(gl)script/PCoin/Organizer.lua");
	local Organizer = commonlib.gettable("Mod.PCoin.Organizer");
]]
	
NPL.load("(gl)script/PCoin/OrphanPool.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/ValidateBlock.lua");

local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");
local validater = ValidateBlock.validate;
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local blockwork = Utility.blockWork;
local log = Utility.log;

local OrphanPool = commonlib.gettable("Mod.PCoin.OrphanPool");
local Organizer = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Organizer"));

Organizer.chain = nil;
Organizer.orphans = nil;

function Organizer.create(blockchain)
	local o = Organizer:new();
	o:init(blockchain);
	return o
end

function Organizer:ctor()
end

function Organizer:init(chain)
	self.chain = chain;
	self.orphans = OrphanPool:new();

end

function Organizer:add(blockdetail)
	return self.orphans:add(blockdetail)
end

function Organizer:organize()
	local process = self.orphans:unprocessed();
	for k,v in ipairs(process) do
		if v:isValid() then
			self:process(v);
		end
	end
end

function Organizer:process(blockdetail)
	local orphanchain = self.orphans:trace(blockdetail);
	local hash = orphanchain[1]:getPreHash();

	local height = self.chain:getHeight(hash);
	if height then
		self:replaceChain(height , chain)
	end
	blockdetail:setProcessed()
end

function Organizer:replaceChain(fork, chain)
	local verify = self.verify;
	local orphanwork = 0
	-- check orphanchain and get block work;
	for k,v in ipairs(chain) do
		local ret = verify(v.block, fork, k);
		if ret then -- fail
			self:clipOrphans(chain, k);
			break;	
		end
		
		orphanwork = orphanwork + blockwork(v.block.header.bits);
	end

	local begin = fork + 1;
	local mainwork = self.chain:getDifficulty(begin);

	if orphanwork <= mainwork then
		log("Insufficient work to reorganize at ["..begin.."]");
		return 
	end

	local mainchain = self.chain;
	--remove the old blocks from main chain first
	local releasedblocks = mainchain:pop(begin);

	--then add the valid orphans to main chain
	local arrivalindex = fork + 1;
	local orpahns = self.orpahns;
	for k,v in ipairs(chain) do
		orphans.remove(v);

		v:setHeight(arrivalindex);
		arrivalindex = arrivalindex + 1;

		mainchain:push(v);
	end

	--add the old blocks back to the orphan pool
	for k,v in ipairs(releasedblocks) do
		v:setProcessed();
		orphans.add(v);
	end


end

function Organizer:verify(block, fork, index)
	return validater(block, fork + index , self.chain);
end

--remove all blocks above the invalid one(included)
function Organizer:clipOrphans(chain, index)
	local orplans = self.orphans;
	local count = #chain;
	for i = index, count do
		local b = chain[i];
		b:setInvalid()
		b:setProcessed();
	
		orplans:remove(b);
		chain[index] = nil;
	end 
end