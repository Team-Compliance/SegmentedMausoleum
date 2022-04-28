maus=RegisterMod("Maus",1)					--someone please write better floorgen!!!!! :sob:
maus.savedrooms={}
maus.permittedtypes={[1]=true,[25]=true,[26]=true}
function maus:Find1x1TreasureRoom()
	while true do
		local rooms=Game():GetLevel():GetRooms()
		for i=0,#rooms-1 do
			local r=rooms:Get(i)
			if r.Data and r.Data.Type==4 and r.Data.Shape==1 then
				return r.Data
			end
		end
		Isaac.ExecuteCommand("reseed")
	end
end
function maus:CreateRooms(id,rng)
	local lastroom=nil
	local neighbors={-1,-13,1,13}
	for i=1,4 do
		local out=rng:RandomFloat()
		if out<0.2 then
			Game():GetLevel():MakeRedRoomDoor(id,i-1)
			
			Game():GetLevel():GetRoomByIdx(id+neighbors[i],0).Flags=0
			if Game():GetLevel():GetRoomByIdx(id+neighbors[i],0).Data then
				if not maus.permittedtypes[Game():GetLevel():GetRoomByIdx(id+neighbors[i],0).Data.Type] then
					Game():GetLevel():GetRoomByIdx(id+neighbors[i],0).Data=Game():GetLevel():GetRoomByIdx(84,0).Data
				end
				lastroom=Game():GetLevel():GetRoomByIdx(id+neighbors[i])
			end
		end
	end
	return lastroom
end
function maus:GenerateBackroomSpace()
	local chosenroomslot=nil
	for i=2+26,168-2-26 do
		local skip=false
		for x=-2,2 do
			for y=-2,2 do
				if not skip then
					local offroom=Game():GetLevel():GetRoomByIdx(i+x+13*y,0)
					if (i+x+13*y)>168 or offroom.Data then
						skip=true
					end
				end
			end
		end
		if not skip then
			chosenroomslot=i
			print(chosenroomslot)
			break
		end
	end
	if not chosenroomslot then
		return
	end
	local oldchallenge=Game().Challenge
	Game().Challenge=44
	Game():GetLevel():MakeRedRoomDoor(chosenroomslot-13,DoorSlot.DOWN0)
	if maus.savedrooms["teleporterexit"] then
		local r=Game():GetLevel():GetRoomByIdx(chosenroomslot,0)
		r.Data=maus.savedrooms["teleporterexit"]
		r.Flags=1<<1
	end
	Game().Challenge=oldchallenge
	local neighbors={-1,-13,1,13}
	local saveneighbors={}
	local rng=RNG()
	rng:SetSeed(Game():GetSeeds():GetStageSeed(Game():GetLevel():GetStage()),0)
	local generatedrooms=0
	local lastroom=nil
	for i=1,4 do
		local out=rng:RandomFloat()
		if out<0.9 or (generatedrooms==0 and i==4) then
			Game():GetLevel():MakeRedRoomDoor(chosenroomslot,i-1)
			Game():GetLevel():GetRoomByIdx(chosenroomslot+neighbors[i],0).Flags=0
			generatedrooms=generatedrooms+1
			if Game():GetLevel():GetRoomByIdx(chosenroomslot+neighbors[i],0).Data then
				if not maus.permittedtypes[Game():GetLevel():GetRoomByIdx(chosenroomslot+neighbors[i],0).Data.Type] then
					Game():GetLevel():GetRoomByIdx(chosenroomslot+neighbors[i],0).Data=Game():GetLevel():GetRoomByIdx(84,0).Data
				end
				lastroom=mausroom
			end
			mausroom=maus:CreateRooms(chosenroomslot+neighbors[i],rng)
			if mausroom and mausroom.Data then
				lastroom=mausroom
			end
		end
	end
	if lastroom then
		if maus.savedrooms["treasure"] then
			lastroom.Data=maus.savedrooms["treasure"]
		end
	end
	return chosenroomslot
end
function maus:Init()
	for i=0,168 do
		local r=Game():GetLevel():GetRoomByIdx(i,0)
		if r.Data and r.Data.Type==5 then
			if not maus.savedrooms["mausboss"] or maus.savedrooms["mausboss"].Subtype~=89 then
				maus.savedrooms["mausboss"]=r.Data
			end
		end
	end
	Isaac.ExecuteCommand("goto s.teleporter.0")
	local gotor=Game():GetLevel():GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporter"]=gotor.Data
	end
	Isaac.ExecuteCommand("goto s.teleporterexit.0")
	local gotor=Game():GetLevel():GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporterexit"]=gotor.Data
	end
	Isaac.ExecuteCommand("goto 6 6 0")
	maus.savedrooms["treasure"]=maus:Find1x1TreasureRoom()
	Game():GetLevel():SetStage(4,27)
	Game():GetSeeds():ForgetStageSeed(4)
	Isaac.ExecuteCommand("reseed")
	for i=0,168 do
		local r=Game():GetLevel():GetRoomByIdx(i,0)
		if r.Data and r.Data.Type==5 then
			local neighborcount=0
			local neighbors={-13,-1,1,13}
			for ncount=1,4 do
				local n=Game():GetLevel():GetRoomByIdx(neighbors[ncount],0)
				if n.Data then
					neighborcount=neighborcount+1
				end
			end
			if neighborcount<=1 then
				if maus.savedrooms["mausboss"] then
					r.Data=maus.savedrooms["mausboss"]
				end
			end
		elseif r.Data and r.Data.Type==4 then
--			maus.savedrooms["treasure"]=r.Data
			if maus.savedrooms["teleporter"] then
				r.Data=maus.savedrooms["teleporter"]
			end
		end
	end
	maus:GenerateBackroomSpace()
	Game():GetLevel():SetStage(6,4)
end

function maus:Level()
	if Game():GetLevel():GetStage()==6 and Game():GetLevel():GetStageType()==4 then
		maus:Init()
	end
end

maus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,maus.Level)