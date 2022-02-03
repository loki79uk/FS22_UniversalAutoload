-- ============================================================= --
-- Universal Autoload MOD
-- ============================================================= --

UniversalAutoloadREGISTER = {}

g_specializationManager:addSpecialization('universalAutoload', 'UniversalAutoload', Utils.getFilename('UniversalAutoload.lua', g_currentModDirectory), true)

for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
	if vehicleName == 'trailer' or vehicleName == 'dynamicMountAttacherTrailer' then
		if SpecializationUtil.hasSpecialization(FillUnit, vehicleType.specializations) and
		   SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) then
			g_vehicleTypeManager:addSpecialization(vehicleName, 'universalAutoload')
		end
	end
end

--TODO:
-- bales
-- test unload area for collisions
-- custom pallets
-- custom trailers

-- tension straps key conflict
-- bridges and kerbs



-- Welger DK 115
-- Brantner DD 24073/2 XXL
-- Fliegl DTS 5.9
-- Demco Steel Drop Deck
-- LODE KING Renown Drop Deck
-- KRONE Trailer Profi Liner
-- Farmtech DPW 1800
-- Kröger PWO 24
-- Bremer Transportwagen TP 500 S
-- BÖCKMANN MH-AL 4320/35

--data/objects/buyableBales/buyableBale.i3d (0.18 ms)
--baseDirectory :: 
--height :: 0.9
--width :: 1.2
--xmlFilename :: data/objects/squarebales/squarebale240.xml
--centerOffsetY :: 0
--centerOffsetX :: 0
--isClient :: true
--obstacleNodeId :: 176084
--fermentingDirtyFlag :: 64
--wrapColorDirtyFlag :: 32
--wrapStateDirtyFlag :: 16
--texturesDirtyFlag :: 8
--fillLevelDirtyFlag :: 4
--fillTypeDirtyFlag :: 2
--id :: 319
--isMissionBale :: false
--allowPickup :: true
--fermentingPercentage :: 0
--isFermenting :: false
--baleValueScale :: 1
--wrappingColor :: table: 0x025ff316a798
--    1 :: 1
--    2 :: 1
--    3 :: 1
--    4 :: 1
--wrappingState :: 0
--supportsWrapping :: false
--tensionBeltMeshes :: table: 0x025f8a6be980
--    1 :: 176086
--meshes :: table: 0x025feb8bfce8
--    1 :: table: 0x025f8a172010
--    2 :: table: 0x025f8d1ddac0
--uvId :: DEFAULT
--nextDirtyFlag :: 128
--synchronizedConnections :: table: 0x025feb765d88
--recieveUpdates :: true
--isServer :: true
--isRegistered :: true
--canBeSold :: true
--fillType :: 35
--sharedLoadRequestId :: 1733
--physicsObjectDirtyFlag :: 1
--i3dFilename :: data/objects/squarebales/squarebale240/squarebale240.i3d
--sendRotZ :: 3.1415903568268
--sendRotY :: 3.7317242913559e-06
--sendRotX :: 3.1415920257568
--sendPosZ :: 54
--sendPosY :: 86.342208862305
--sendPosX :: 800
--fillTypes :: table: 0x025f8a636fb8
--    1 :: table: 0x025f8b98ac10
--    2 :: table: 0x025f8d2d2168
--    3 :: table: 0x025fe798dfe0
--    4 :: table: 0x025ff31b6078
--networkTimeInterpolator :: table: 0x025ff3709570
--    interpolationAlpha :: 1.2
--    interpolationDuration :: 80
--    isDirty :: false
--    maxInterpolationAlpha :: 1.2
--lastMoveTime :: 28394.787099838
--defaultMass :: 0.465
--diameter :: 0
--nodeId :: 176084
--dynamicMountTriggerId :: 176085
--isRoundbale :: false
--activatable :: table: 0x025fe7c120a8
--    bale :: table: 0x025fe7e97200
--    activateText :: Cut open bale
--dynamicMountForceLimitScale :: 1
--dynamicMountJointNodeDynamic :: 176088
--dynamicMountTriggerForceAcceleration :: 10
--ownerFarmId :: 1
--length :: 2.4
--lastServerId :: 319
--forcedClipDistance :: 300
--deleteListeners :: table: 0x025ff4335a30
--dirtyMask :: 0
--centerOffsetZ :: 0
--dynamicMountSingleAxisFreeY :: false
--dynamicMountType :: 1
--dynamicMountSingleAxisFreeX :: false
--fillLevel :: 8000