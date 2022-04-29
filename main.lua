maus=RegisterMod("Maus",1)					--someone please write better floorgen!!!!! :sob:
maus.savedrooms={}
maus.permittedtypes={[1]=true,[25]=true,[26]=true}
local rng = RNG()

function maus:CountNeighbors(index)
	local count = 0
	local neighbors={-1,-13,1,13}
	for i = 1, 4 do
		local room = Game():GetLevel():GetRoomByIdx(index+neighbors[i], 0)
		if room then
			if room.GridIndex > -1 then
				count = count + 1
			end
		end
	end
	
	return count
end

function maus:SetVisibility()
	local level = Game():GetLevel()
	if level:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then
		level:ApplyCompassEffect(true)
	end
	if level:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then
		level:ApplyMapEffect()
	end
	if level:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then
		level:ApplyBlueMapEffect()
	end
	if level:GetStateFlag(LevelStateFlag.STATE_FULL_MAP_EFFECT) then
		level:ShowMap()
	end
end

function maus:CanCreateRoom(id, doorSlot)
	local level = Game():GetLevel()
	
	if doorSlot == DoorSlot.LEFT0 then
		if level:GetRoomByIdx(id-1,0).GridIndex > -1 or level:GetRoomByIdx(id-2,0).GridIndex > -1 or level:GetRoomByIdx(id-14,0).GridIndex > -1 or level:GetRoomByIdx(id+12,0).GridIndex > -1 then
			return false
		end
	elseif doorSlot == DoorSlot.UP0 then
		if level:GetRoomByIdx(id-13,0).GridIndex > -1 or level:GetRoomByIdx(id-26,0).GridIndex > -1 or level:GetRoomByIdx(id-14,0).GridIndex > -1 or level:GetRoomByIdx(id-12,0).GridIndex > -1 then
			return false
		end
	elseif doorSlot == DoorSlot.RIGHT0 then
		if level:GetRoomByIdx(id+1,0).GridIndex > -1 or level:GetRoomByIdx(id+2,0).GridIndex > -1 or level:GetRoomByIdx(id+14,0).GridIndex > -1 or level:GetRoomByIdx(id-12,0).GridIndex > -1 then
			return false
		end
	elseif doorSlot == DoorSlot.DOWN0 then
		if level:GetRoomByIdx(id+13,0).GridIndex > -1 or level:GetRoomByIdx(id+26,0).GridIndex > -1 or level:GetRoomByIdx(id+14,0).GridIndex > -1 or level:GetRoomByIdx(id+12,0).GridIndex > -1 then
			return false
		end
	end
	
	return true
end

local numRooms = 0
local loops = 0
function maus:CreateRooms(id,rng)
	local oldroom = Game():GetLevel():GetRoomByIdx(id)
	if oldroom.GridIndex < 0 then return end
	local neighbors={-1,-13,1,13}
	while numRooms < 12 do
		for i = 1, 4 do
			local door = rng:RandomInt(4) + 1
			if oldroom.Data.Doors & (1 << door-1) > 0 then
				if maus:CanCreateRoom(id, door-1) then
					local out = rng:RandomFloat()
					if out < 0.7 then
						Game():GetLevel():MakeRedRoomDoor(id,door-1)
						
						local newRoom = Game():GetLevel():GetRoomByIdx(id+neighbors[door],0)
						if newRoom.GridIndex > -1 then
							newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
							if newRoom.Data then
								if not maus.permittedtypes[newRoom.Data.Type] then
									newRoom.Data = Game():GetLevel():GetRoomByIdx(84,0).Data
								end
							end
							numRooms = numRooms + 1
							maus:CreateRooms(id+neighbors[door], rng)
						end
					end
				end
			end
		end
		
		loops = loops + 1
		if loops > 1000 then
			break
		end
	end
end

function maus:GenerateBackroomSpace()
	local chosenroomslot=nil
	local level = Game():GetLevel()
	for i=2+26,168-2-26 do
		local skip=false
		for x=-2,2 do
			for y=-2,2 do
				if not skip then
					local offroom=level:GetRoomByIdx(i+x+13*y,0)
					if (i+x+13*y)>168 or offroom.GridIndex > -1 then
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
	level:MakeRedRoomDoor(chosenroomslot - 13, DoorSlot.DOWN0)
	local exitroom = level:GetRoomByIdx(chosenroomslot, 0)
	if maus.savedrooms["teleporterexit"] then
		exitroom.Data = maus.savedrooms["teleporterexit"]
		exitroom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
	end
	Game().Challenge = oldchallenge
	
	local neighbors = {-1,-13,1,13}
	local lastroom = nil
	
	local randomdoorslot = nil
	repeat randomdoorslot = rng:RandomInt(4)
	until exitroom.Data.Doors & (1 << randomdoorslot) > 0
	
	if maus:CanCreateRoom(chosenroomslot, randomdoorslot) then
		level:MakeRedRoomDoor(chosenroomslot, randomdoorslot)
		
		local newRoom = level:GetRoomByIdx(chosenroomslot+neighbors[randomdoorslot+1],0)
		newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
		if newRoom.Data then
			if not maus.permittedtypes[newRoom.Data.Type] then
				newRoom.Data = level:GetRoomByIdx(84,0).Data
			end
		end
		maus:CreateRooms(chosenroomslot+neighbors[randomdoorslot+1], rng)
		local room = nil
		repeat room = level:GetRoomByIdx(rng:RandomInt(169))
		until room.Data and room.Data.Type ~= RoomType.ROOM_TELEPORTER_EXIT and (room.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0) and (maus:CountNeighbors(room.GridIndex) == 1)
		if maus.savedrooms["special"] then
			room.Data = maus.savedrooms["special"]
		end
		maus:SetVisibility()
		numRooms = 0
		loops = 0
		return chosenroomslot
	end
end

function maus:Init()
	local level = Game():GetLevel()
	maus.savedrooms = {}
	rng:SetSeed(Game():GetSeeds():GetStageSeed(level:GetStage()),0)

	Isaac.ExecuteCommand("goto s.teleporter.0")
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporter"] = gotor.Data
	end
	Isaac.ExecuteCommand("goto s.teleporterexit.0")
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		maus.savedrooms["teleporterexit"] = gotor.Data
	end
	local ran = rng:RandomInt(32)+1
	Isaac.ExecuteCommand("goto s.supersecret."..ran)
	local gotor = level:GetRoomByIdx(level:GetCurrentRoomIndex())
	if gotor.Data then
		maus.savedrooms["supersecret"] = gotor.Data
	end

	Isaac.ExecuteCommand("goto 6 6 0")
	
	local room = nil
	repeat room = level:GetRoomByIdx(rng:RandomInt(169))
	until room.Data and room.Data.Type ~= RoomType.ROOM_DEFAULT and room.Data.Type ~= RoomType.ROOM_BOSS and room.Data.Type ~= RoomType.ROOM_SECRET and room.Data.Type ~= RoomType.ROOM_SUPERSECRET and room.Data.Type ~= RoomType.ROOM_ULTRASECRET and room.Data.Shape == RoomShape.ROOMSHAPE_1x1 and room.Data.StageID == 0
	if maus.savedrooms["teleporter"] then
		maus.savedrooms["special"] = room.Data
		room.Data = maus.savedrooms["teleporter"]
	end
	
	maus:GenerateBackroomSpace()
end

function maus:Room()
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	local roomDesc = level:GetRoomByIdx(level:GetCurrentRoomIndex())
	print(maus:CountNeighbors(level:GetCurrentRoomIndex()))
	
	for i=0, DoorSlot.NUM_DOOR_SLOTS do
		local door = room:GetDoor(i)
		if door then
			if door.TargetRoomType == RoomType.ROOM_ERROR then
				door:Remove()
			end
		end
	end
	
	if roomDesc.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0 then
		Game():ShowHallucination(-1, BackdropType.MAUSOLEUM3)
		SFXManager():Stop(SoundEffect.SOUND_DEATH_CARD)
	end
end
maus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, maus.Room)

function maus:Level()
	local level = Game():GetLevel()
	if level:GetStageType() == StageType.STAGETYPE_REPENTANCE then
		if level:GetStage() == LevelStage.STAGE3_1 or level:GetStage() == LevelStage.STAGE3_2 then
			if level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH == 0 then
				maus:Init()
			end
		end
	end
end
maus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, maus.Level)