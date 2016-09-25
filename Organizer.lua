--[[
	NPL.load("(gl)script/PCoin/Organizer.lua");
	local Organizer = commonlib.gettable("Mod.PCoin.Organizer");
]]
	
NPL.load("(gl)script/PCoin/OrphanPool.lua");
NPL.load("(gl)script/PCoin/Utility.lua");
NPL.load("(gl)script/PCoin/ValidateBlock.lua");
NPL.load("(gl)script/PCoin/math/uint256.lua");

local uint256 = commonlib.gettable("Mod.PCoin.math.uint256");
local ValidateBlock = commonlib.gettable("Mod.PCoin.ValidateBlock");
local validater = ValidateBlock.validate;
local Utility = commonlib.gettable("Mod.PCoin.Utility");
local blockwork = Utility.blockWork;
local log = Utility.log;

local OrphanPool = commonlib.gettable("Mod.PCoin.OrphanPool");
local Organizer = commonlib.inherit(nil, commonlib.gettable("Mod.PCoin.Organizer"));

function Organizer:ctor()
	self.chain = nil;
	self.orphans = nil;
end

function Organizer.create(blockchain)
	local o = Organizer:new();
	o:init(blockchain);
	return o
end

function Organizer:init(chain)
	self.chain = chain;
	self.orphans = OrphanPool:new();

end

function Organizer:add(blockdetail)
	return self.orphans:add(blockdetail)
end

function Organizer:organize()
	local blocks = {}
	while true do
		local b = self.orphans:unprocessed();
		if b then
			for k,v in pairs(self:process(b)) do
				blocks[#blocks + 1] = v;
			end
		else
			break;
		end
	end
	return blocks;
end

function Organizer:process(blockdetail)
	local orphanchain = self.orphans:trace(blockdetail);
	local hash = orphanchain:front():getPreHash();
	local height = self.chain:getHeight(hash);
	local blocks;
	if height then
		blocks = self:replaceChain(height , orphanchain)
	else
		log("[Organizer]process: cannot find previous block in chain(hash: %s)", Utility.HashBytesToString(hash));
	end
	blockdetail:setProcessed()
	return blocks or {}
end

function Organizer:replaceChain(fork, orphanchain)

	local orphans = self.orphans
	local orphanwork = uint256:new();
	-- check orphanchain and get block work;
	for k,v in orphanchain:iterator() do
		local ret = self:verify(v.block, fork, k,orphanchain);
		if ret then -- fail
			self:clipOrphans(orphanchain, k);
			break;	
		end
		
		orphanwork = orphanwork + blockwork(v.block.header.bits);
	end
	if orphanchain:size() == 0 then	
		log("no block store in chain")
		return
	end

	local begin = fork + 1;
	local mainwork = self.chain:getDifficulty(begin);
	if orphanwork <= mainwork then
		log("Insufficient work to reorganize, orphans work: %s, need: %s",orphanwork:tostring(), mainwork:tostring() );
		return;
	end

	local mainchain = self.chain;
	--remove the old blocks from main chain first
	local releasedblocks = mainchain:pop(begin);

	--then add the valid orphans to main chain
	local arrivalindex = fork + 1;
	local orpahns = self.orpahns;
	local newBlocks = {}
	for k,v in orphanchain:iterator() do
		orphans:remove(v);

		v:setHeight(arrivalindex);
		arrivalindex = arrivalindex + 1;

		mainchain:push(v);
		newBlocks[#newBlocks + 1] = v:getHash();
	end

	--add the old blocks back to the orphan pool
	for k,v in ipairs(releasedblocks) do
		v:setProcessed();
		orphans:add(v);
	end

	return newBlocks
end

function Organizer:verify(block, fork, index, orphanchain)
	local ret = validater(block, index , fork, self.chain, orphanchain);
	if ret then
		log("failed to verify Block(fork:%d, height:%d), reason: %s", fork, fork + index, ret)
	end
	return ret;
end

--remove all blocks above the invalid one(included)
function Organizer:clipOrphans(chain, index)
	local orplans = self.orphans;
	local count = chain:size();
	for i = index, count do
		local b = chain:get(i);
		b:setInvalid()
		b:setProcessed();
	
		orplans:remove(b);
	end 
	chain:erase(index, count);
	log("[Organizer] clipOrphans: cliped count: %d, remain: %d", count - index + 1, chain:size())
end

function Organizer:exist(hash)
	return self.orphans:exist(hash) or self.chain:fetchBlockDataByHash(hash) ~= nil;
end

function Organizer:report()
	self.orphans:report()
end