maus=RegisterMod("Maus",1)					--someone please write better floorgen!!!!! :sob:
maus.savedrooms={}
maus.permittedtypes={[1]=true,[25]=true,[26]=true}

local DoorSlotFlag = { -- for reference
  LEFT0 = 1 << DoorSlot.LEFT0,
  UP0 = 1 << DoorSlot.UP0,
  RIGHT0 = 1 << DoorSlot.RIGHT0,
  DOWN0 = 1 << DoorSlot.DOWN0,
  LEFT1 = 1 << DoorSlot.LEFT1,
  UP1 = 1 << DoorSlot.UP1,
  RIGHT1 = 1 << DoorSlot.RIGHT1,
  DOWN1 = 1 << DoorSlot.DOWN1,
}

function maus:FindTreasureRoom()
	local rooms = Game():GetLevel():GetRooms()
	for i = 0, rooms.Size - 1 do
		local room = rooms:Get(i)
		if room.Data and room.Data.Type == RoomType.ROOM_TREASURE then
			return room.Data
		end
	end
end

function maus:FindBossRoom()
	local rooms = Game():GetLevel():GetRooms()
	for i = 0, rooms.Size - 1 do
		local room = rooms:Get(i)
		if room.Data and room.Data.Type == RoomType.ROOM_BOSS then
			if not maus.savedrooms["mausboss"] or maus.savedrooms["mausboss"].Subtype ~= 89 then
				return room.Data
			end
		end
	end
end

function maus:CreateRooms(id,rng)
	local oldroom = Game():GetLevel():GetRoomByIdx(id)
	local lastroom=nil
	local neighbors={-1,-13,1,13}
	for i=1,4 do
		if oldroom.Data.Doors & (1 << i-1) > 0 then
			print(i-1)
			local out=rng:RandomFloat()
			if out<0.2 then
				Game():GetLevel():MakeRedRoomDoor(id,i-1)
				
				local newRoom = Game():GetLevel():GetRoomByIdx(id+neighbors[i],0)
				newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
				if newRoom.Data then
					if not maus.permittedtypes[newRoom.Data.Type] then
						newRoom.Data = Game():GetLevel():GetRoomByIdx(84,0).Data
					end
					lastroom = newRoom
				end
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
	
	local oldchallenge = Game().Challenge
	Game().Challenge = Challenge.CHALLENGE_RED_REDEMPTION
	Game():GetLevel():MakeRedRoomDoor(chosenroomslot - 13, DoorSlot.DOWN0)
	local exitroom = Game():GetLevel():GetRoomByIdx(chosenroomslot, 0)
	if maus.savedrooms["teleporterexit"] then
		exitroom.Data = maus.savedrooms["teleporterexit"]
		exitroom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
	end
	Game().Challenge = oldchallenge
	
	local neighbors = {-1,-13,1,13}
	local saveneighbors = {}
	local rng = RNG()
	rng:SetSeed(Game():GetSeeds():GetStageSeed(Game():GetLevel():GetStage()),0)
	local generatedrooms = 0
	local lastroom = nil
	for i = 1, 4 do
		if exitroom.Data.Doors & (1 << i-1) > 0 then
			local out = rng:RandomFloat()
			if out < 0.9 or (generatedrooms == 0 and i == 4) then
				Game():GetLevel():MakeRedRoomDoor(chosenroomslot, i-1)
				
				local newRoom = Game():GetLevel():GetRoomByIdx(chosenroomslot+neighbors[i],0)
				newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
				generatedrooms = generatedrooms + 1
				if newRoom.Data then
					if not maus.permittedtypes[newRoom.Data.Type] then
						newRoom.Data = Game():GetLevel():GetRoomByIdx(84,0).Data
					end
					lastroom = mausroom
				end
				mausroom = maus:CreateRooms(chosenroomslot+neighbors[i],rng)
				if mausroom and mausroom.Data then
					lastroom = mausroom
				end
			end
		end
	end
	if lastroom then
		if maus.savedrooms["treasure"] then
			lastroom.Data = maus.savedrooms["treasure"]
		end
	end
	return chosenroomslot
end

function maus:Init()
	maus.savedrooms = {}
	
	Isaac.ExecuteCommand("goto s.teleporter.0")
	local gotor = Game():GetLevel():GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporter"] = gotor.Data
	end
	Isaac.ExecuteCommand("goto s.teleporterexit.0")
	local gotor = Game():GetLevel():GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporterexit"] = gotor.Data
	end
	Isaac.ExecuteCommand("goto 6 6 0")
	
	maus.savedrooms["mausboss"] = maus:FindBossRoom()
	maus.savedrooms["treasure"] = maus:FindTreasureRoom()
	
	local caves = Game():GetLevel():GetStage() - 2
	Game():GetLevel():SetStage(caves,27)
	Game():GetSeeds():ForgetStageSeed(caves)
	Isaac.ExecuteCommand("reseed")
	
	for i = 0, 168 do
		local room = Game():GetLevel():GetRoomByIdx(i, 0)
		if room.Data then 
			if room.Data.Type == RoomType.ROOM_BOSS then
				local neighborcount=0
				local neighbors = {-13,-1,1,13}
				for n = 1, 4 do
					local neighbor = Game():GetLevel():GetRoomByIdx(neighbors[n], 0)
					if neighbor.Data then
						neighborcount = neighborcount + 1
					end
				end
				
				if neighborcount <= 1 then
					if maus.savedrooms["mausboss"] then
						room.Data = maus.savedrooms["mausboss"]
					end
				end
			elseif room.Data.Type == RoomType.ROOM_TREASURE then
				if maus.savedrooms["teleporter"] then
					room.Data = maus.savedrooms["teleporter"]
				end
			end
		end
	end
	
	maus:GenerateBackroomSpace()
	Game():GetLevel():SetStage(caves + 2, StageType.STAGETYPE_REPENTANCE)
end

function maus:Room()
	local level = Game():GetLevel()
	local room = level:GetRoomByIdx(level:GetCurrentRoomIndex())
	
	if room.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0 then
		Game():ShowHallucination(0, BackdropType.MAUSOLEUM3)
		SFXManager():Stop(SoundEffect.SOUND_DEATH_CARD)
	end
end
maus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, maus.Room)

function maus:Level()
	if Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE then
		if Game():GetLevel():GetStage() == LevelStage.STAGE3_1 or Game():GetLevel():GetStage() == LevelStage.STAGE3_2 then
			maus:Init()
		end
	end
end
maus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, maus.Level)