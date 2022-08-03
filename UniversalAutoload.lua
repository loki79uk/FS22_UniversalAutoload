-- ============================================================= --
-- Universal Autoload MOD - SPECIALISATION
-- ============================================================= --
UniversalAutoload = {}

UniversalAutoload.name = g_currentModName
UniversalAutoload.path = g_currentModDirectory
UniversalAutoload.specName = ("spec_%s.universalAutoload"):format(g_currentModName)

UniversalAutoload.showDebug = true
UniversalAutoload.showLoading = false

UniversalAutoload.delayTime = 200

local debugKeys = false
local debugConsole = false

-- EVENTS
source(g_currentModDirectory.."events/CycleContainerEvent.lua")
source(g_currentModDirectory.."events/CycleMaterialEvent.lua")
source(g_currentModDirectory.."events/PlayerTriggerEvent.lua")
source(g_currentModDirectory.."events/RaiseActiveEvent.lua")
source(g_currentModDirectory.."events/ResetLoadingEvent.lua")
source(g_currentModDirectory.."events/SetBaleCollectionModeEvent.lua")
source(g_currentModDirectory.."events/SetContainerTypeEvent.lua")
source(g_currentModDirectory.."events/SetFilterEvent.lua")
source(g_currentModDirectory.."events/SetLoadsideEvent.lua")
source(g_currentModDirectory.."events/SetMaterialTypeEvent.lua")
source(g_currentModDirectory.."events/SetTipsideEvent.lua")
source(g_currentModDirectory.."events/StartLoadingEvent.lua")
source(g_currentModDirectory.."events/StopLoadingEvent.lua")
source(g_currentModDirectory.."events/UnloadingEvent.lua")
source(g_currentModDirectory.."events/UpdateActionEvents.lua")
source(g_currentModDirectory.."events/WarningMessageEvent.lua")


-- REQUIRED SPECIALISATION FUNCTIONS
function UniversalAutoload.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TensionBelts, specializations)
end
--
function UniversalAutoload.initSpecialization()
	g_configurationManager:addConfigurationType("universalAutoload", g_i18n:getText("configuration_universalAutoload"), "universalAutoload", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	
	UniversalAutoload.xmlSchema = XMLSchema.new("universalAutoload")

	local globalKey = "universalAutoload"
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, globalKey.."#showDebug", "Show the full graphical debugging display for all vehicles in game", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, globalKey.."#manualLoadingOnly", "Prevent autoloading (automatic unloading is allowed)", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, globalKey.."#disableAutoStrap", "Disable the automatic application of tension belts", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, globalKey.."#pricePerPallet", "The price charged for each auto-loaded pallet (default is zero)", 0)
	
	local allVehiclesKey = "universalAutoload.vehicleConfigurations"
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, allVehiclesKey.."#showDebug", "Show the full graphical debugging display for all vehicles in config", false)
	
	local vehicleKey = "universalAutoload.vehicleConfigurations.vehicleConfiguration(?)"
	local vehicleSchemas = {
		[1] = { ["schema"] = UniversalAutoload.xmlSchema, ["key"] = vehicleKey },
		[2] = { ["schema"] = Vehicle.xmlSchema, ["key"] = "vehicle."..vehicleKey }
	}
	for _, s in ipairs(vehicleSchemas) do
		s.schema:register(XMLValueType.STRING, s.key.."#configFileName", "Vehicle config file xml full path - used to identify supported vechicles", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#selectedConfigs", "Selected Configuration Names", nil)
		s.schema:register(XMLValueType.VECTOR_TRANS, s.key..".loadingArea(?)#offset", "Offset to the centre of the loading area", "0 0 0")
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea(?)#width", "Width of the loading area", 0)
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea(?)#length", "Length of the loading area", 0)
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea(?)#height", "Height of the loading area", 0)
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea(?)#baleHeight", "Height of the loading area for BALES only", nil)
		s.schema:register(XMLValueType.BOOL, s.key..".loadingArea(?)#noLoadingIfFolded", "Prevent loading when folded (for this area only)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".loadingArea(?)#noLoadingIfUnfolded", "Prevent loading when unfolded (for this area only)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".loadingArea(?)#noLoadingIfCovered", "Prevent loading when covered (for this area only)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".loadingArea(?)#noLoadingIfUncovered", "Prevent loading when uncovered (for this area only)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#isBoxTrailer", "If trailer is enclosed with a rear door", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#isBaleTrailer", "If trailer should use an automatic bale collection mode", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#isCurtainTrailer", "Automatically detect the available load side (if the trailer has curtain sides)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#enableRearLoading", "Use the automatic rear loading trigger", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#enableSideLoading", "Use the automatic side loading triggers", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfFolded", "Prevent loading when folded", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfUnfolded", "Prevent loading when unfolded", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfCovered", "Prevent loading when covered", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfUncovered", "Prevent loading when uncovered", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#rearUnloadingOnly", "Use rear unloading zone only (not side zones)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#frontUnloadingOnly", "Use front unloading zone only (not side zones)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#disableAutoStrap", "Disable the automatic application of tension belts", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#zonesOverlap", "Flag to identify when the loading areas overlap each other", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#showDebug", "Show the full graphical debugging display for this vehicle", false)
	end

	local containerKey = "universalAutoload.containerConfigurations.containerConfiguration(?)"
	local legacyContainerKey = "universalAutoload.containerTypeConfigurations.containerConfiguration(?)"
	local containerSchemas = {
		[1] = { ["schema"] = UniversalAutoload.xmlSchema, ["key"] = containerKey },
		[2] = { ["schema"] = UniversalAutoload.xmlSchema, ["key"] = legacyContainerKey }
	}
	for _, s in ipairs(containerSchemas) do
		s.schema:register(XMLValueType.STRING, s.key.."#containerType", "The loading type category to group under in the menu)", "ANY")
		s.schema:register(XMLValueType.STRING, s.key.."#name", "Simplified Pallet Configuration Filename", "UNKNOWN")
		s.schema:register(XMLValueType.FLOAT, s.key.."#sizeX", "Width of the pallet", 1.5)
		s.schema:register(XMLValueType.FLOAT, s.key.."#sizeY", "Height of the pallet", 2.0)
		s.schema:register(XMLValueType.FLOAT, s.key.."#sizeZ", "Length of the pallet", 1.5)
		s.schema:register(XMLValueType.BOOL, s.key.."#isBale", "If the object is either a round bale or square bale", false)
		s.schema:register(XMLValueType.BOOL, s.key.."#flipYZ", "Should always rotate 90 degrees to stack on end - e.g. for round bales", false)
		s.schema:register(XMLValueType.BOOL, s.key.."#neverStack", "Should never load another pallet on top of this one when loading", false)
		s.schema:register(XMLValueType.BOOL, s.key.."#neverRotate", "Should never rotate object when loading", false)
		s.schema:register(XMLValueType.BOOL, s.key.."#alwaysRotate", "Should always rotate to face outwards for manual unloading", false)
	end

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local specKey = "vehicles.vehicle(?).universalAutoload"
    schemaSavegame:register(XMLValueType.STRING, specKey.."#tipside", "Last used tip side", "none")
    schemaSavegame:register(XMLValueType.STRING, specKey.."#loadside", "Last used load side", "both")
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadWidth", "Last used load width", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadLength", "Last used load length", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadHeight", "Last used load height", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#actualWidth", "Last used expected load width", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#actualLength", "Last used complete load length", 0)
	schemaSavegame:register(XMLValueType.INT, specKey.."#loadAreaIndex", "Last used load area", 1)
    schemaSavegame:register(XMLValueType.INT, specKey.."#materialIndex", "Last used material type", 1)
    schemaSavegame:register(XMLValueType.INT, specKey.."#containerIndex", "Last used container type", 1)
    schemaSavegame:register(XMLValueType.BOOL, specKey.."#loadingFilter", "TRUE=Load full pallets only; FALSE=Load any pallets", false)

end
--
function UniversalAutoload.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsMoving", UniversalAutoload.getIsMoving)
    SpecializationUtil.registerFunction(vehicleType, "getIsFilled", UniversalAutoload.getIsFilled)
    SpecializationUtil.registerFunction(vehicleType, "getIsCovered", UniversalAutoload.getIsCovered)
    SpecializationUtil.registerFunction(vehicleType, "getIsFolding", UniversalAutoload.getIsFolding)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteLoadedObject_Callback", UniversalAutoload.onDeleteLoadedObject_Callback)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteAvailableObject_Callback", UniversalAutoload.onDeleteAvailableObject_Callback)
    SpecializationUtil.registerFunction(vehicleType, "onDeleteAutoLoadingObject_Callback", UniversalAutoload.onDeleteAutoLoadingObject_Callback)
    SpecializationUtil.registerFunction(vehicleType, "testUnloadLocation_Callback", UniversalAutoload.testUnloadLocation_Callback)
    SpecializationUtil.registerFunction(vehicleType, "testLocationOverlap_Callback", UniversalAutoload.testLocationOverlap_Callback)
    SpecializationUtil.registerFunction(vehicleType, "playerTrigger_Callback", UniversalAutoload.playerTrigger_Callback)
    SpecializationUtil.registerFunction(vehicleType, "loadingTrigger_Callback", UniversalAutoload.loadingTrigger_Callback)
    SpecializationUtil.registerFunction(vehicleType, "unloadingTrigger_Callback", UniversalAutoload.unloadingTrigger_Callback)
    SpecializationUtil.registerFunction(vehicleType, "autoLoadingTrigger_Callback", UniversalAutoload.autoLoadingTrigger_Callback)
end
--
function UniversalAutoload.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartFieldWork", UniversalAutoload.getCanStartFieldWork)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanImplementBeUsedForAI", UniversalAutoload.getCanImplementBeUsedForAI)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", UniversalAutoload.getDynamicMountTimeToMount)
end

function UniversalAutoload:getCanStartFieldWork(superFunc)
	local spec = self.spec_universalAutoload
	if spec~=nil and spec.isAutoloadEnabled and spec.baleCollectionMode then
		--if UniversalAutoload.showDebug then print("getCanStartFieldWork...") end
		--return true
	end
	return superFunc(self)
end
function UniversalAutoload:getCanImplementBeUsedForAI(superFunc)
	local spec = self.spec_universalAutoload
	if spec~=nil and spec.isAutoloadEnabled then
		--if UniversalAutoload.showDebug then print("*** getCanImplementBeUsedForAI ***") end
		--DebugUtil.printTableRecursively(self.spec_aiImplement, "--", 0, 1)
		--return true
	end
	return superFunc(self)
end
--
function UniversalAutoload.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", UniversalAutoload)
end
--
function UniversalAutoload.removeEventListeners(vehicleType)
	-- print("REMOVE EVENT LISTENERS")
	-- *** full credit to GtX for this function ***
	local function removeUnusedEventListener(vehicle, name, specClass)
		local eventListeners = vehicle.eventListeners[name]

		if eventListeners ~= nil then
			for i = #eventListeners, 1, -1 do
				if specClass.className ~= nil and specClass.className == eventListeners[i].className then
					table.remove(eventListeners, i)
				end
			end
		end
	end
	
	-- (called during 'onLoad' so do not unregister that)
    removeUnusedEventListener(vehicleType, "onRegisterActionEvents", UniversalAutoload)
    removeUnusedEventListener(vehicleType, "onDelete", UniversalAutoload)
    removeUnusedEventListener(vehicleType, "onPreDelete", UniversalAutoload)
	
	removeUnusedEventListener(vehicleType, "onUpdate", UniversalAutoload)
	removeUnusedEventListener(vehicleType, "onActivate", UniversalAutoload)
	removeUnusedEventListener(vehicleType, "onDeactivate", UniversalAutoload)
	removeUnusedEventListener(vehicleType, "onFoldStateChanged", UniversalAutoload)
end

-- HOOK PLAYER ON FOOT UPDATE OBJECTS/TRIGGERS
UniversalAutoload.lastClosestVehicle = nil
function UniversalAutoload:OverwrittenUpdateObjects(superFunc)

	superFunc(self)
		
	if self.mission.player.isControlled and not g_gui:getIsGuiVisible() then
		-- print("Player Is Controlled")
		local player = self.mission.player
		local playerId = player.userId
	
		local closestVehicle = nil
		local closestVehicleDistance = 25 --math.huge
		for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
			if vehicle ~= nil then
				local SPEC = vehicle.spec_universalAutoload
				if SPEC.playerInTrigger[playerId] == true and
				g_currentMission.nodeToObject[vehicle.rootNode]~=nil then
					local distance = calcDistanceFrom(player.rootNode, vehicle.rootNode)
					if distance < closestVehicleDistance then
						closestVehicle = vehicle
						closestVehicleDistance = distance
					end
				end
			end
		end
		
		if UniversalAutoload.lastClosestVehicle~=closestVehicle then
			local lastVehicle = UniversalAutoload.lastClosestVehicle
			if lastVehicle ~= nil then
				UniversalAutoload.clearActionEvents(lastVehicle)
				UniversalAutoload.forceRaiseActive(lastVehicle)
			end
			
			UniversalAutoload.lastClosestVehicle = closestVehicle
			if closestVehicle ~= nil then
				closestVehicle.spec_universalAutoload.updateKeys = true
			end
		end
		if closestVehicle ~= nil then
			UniversalAutoload.forceRaiseActive(closestVehicle)
			g_currentMission:addExtraPrintText(closestVehicle:getFullName())
		end
	end
end
ActivatableObjectsSystem.updateObjects = Utils.overwrittenFunction(ActivatableObjectsSystem.updateObjects, UniversalAutoload.OverwrittenUpdateObjects)


-- ACTION EVENT FUNCTIONS
function UniversalAutoload:clearActionEvents()
	local spec = self.spec_universalAutoload
	if spec~=nil and spec.isAutoloadEnabled and spec.actionEvents~=nil then
		self:clearActionEventsTable(spec.actionEvents)
	end
end
--
function UniversalAutoload:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_universalAutoload
		UniversalAutoload.clearActionEvents(self)

		if isActiveForInput then
			-- print("onRegisterActionEvents: "..self:getFullName())
			UniversalAutoload.updateActionEventKeys(self)
		end
	end
end
--
function UniversalAutoload:updateActionEventKeys()
	if self.isClient then
		local spec = self.spec_universalAutoload
		
		if spec.isAutoloadEnabled and spec.actionEvents ~= nil and next(spec.actionEvents) == nil then
			if debugKeys then print("updateActionEventKeys: "..self:getFullName()) end
			local actions = UniversalAutoload.ACTIONS
			local ignoreCollisions = true

			if not UniversalAutoload.manualLoadingOnly then
				
				if spec.isBaleTrailer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_BALE_COLLECTION, self, UniversalAutoload.actionEventToggleBaleCollectionMode, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
					spec.toggleBaleCollectionModeEventId = actionEventId
					if debugKeys then print("  TOGGLE_BALE_COLLECTION: "..tostring(valid)) end
				end
				
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_LOADING, self, UniversalAutoload.actionEventToggleLoading, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
				spec.toggleLoadingActionEventId = actionEventId
				if debugKeys then print("  TOGGLE_LOADING: "..tostring(valid)) end

				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_FILTER, self, UniversalAutoload.actionEventToggleFilter, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				spec.toggleLoadingFilterActionEventId = actionEventId
				if debugKeys then print("  TOGGLE_FILTER: "..tostring(valid)) end
			end
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.UNLOAD_ALL, self, UniversalAutoload.actionEventUnloadAll, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			spec.unloadAllActionEventId = actionEventId
			if debugKeys then print("  UNLOAD_ALL: "..tostring(valid)) end
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_FW, self, UniversalAutoload.actionEventCycleMaterial_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.cycleMaterialActionEventId = actionEventId
			if debugKeys then print("  CYCLE_MATERIAL_FW: "..tostring(valid)) end

			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_BW, self, UniversalAutoload.actionEventCycleMaterial_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			if debugKeys then print("  CYCLE_MATERIAL_BW: "..tostring(valid)) end
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_MATERIALS, self, UniversalAutoload.actionEventSelectAllMaterials, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			if debugKeys then print("  SELECT_ALL_MATERIALS: "..tostring(valid)) end
			
			if UniversalAutoload.chatKeyConflict ~= true then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_FW, self, UniversalAutoload.actionEventCycleContainer_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				spec.cycleContainerActionEventId = actionEventId
				if debugKeys then print("  CYCLE_CONTAINER_FW: "..tostring(valid)) end

				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_BW, self, UniversalAutoload.actionEventCycleContainer_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				if debugKeys then print("  CYCLE_CONTAINER_BW: "..tostring(valid)) end

				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_CONTAINERS, self, UniversalAutoload.actionEventSelectAllContainers, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				if debugKeys then print("  SELECT_ALL_CONTAINERS: "..tostring(valid)) end
			end
			
			if not spec.isCurtainTrailer and not spec.rearUnloadingOnly and not spec.frontUnloadingOnly then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_TIPSIDE, self, UniversalAutoload.actionEventToggleTipside, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				spec.toggleTipsideActionEventId = actionEventId
				if debugKeys then print("  TOGGLE_TIPSIDE: "..tostring(valid)) end
			end
			
			if g_currentMission.player.isControlled then
			
				if not g_currentMission.missionDynamicInfo.isMultiplayer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_BELTS, self, UniversalAutoload.actionEventToggleBelts, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleBeltsActionEventId = actionEventId
					if debugKeys then print("  TOGGLE_BELTS: "..tostring(valid)) end
				end
				
				if spec.isCurtainTrailer or spec.isBoxTrailer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_DOOR, self, UniversalAutoload.actionEventToggleDoor, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleDoorActionEventId = actionEventId
					if debugKeys then print("  TOGGLE_DOOR: "..tostring(valid)) end
				end
					
				if spec.isCurtainTrailer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_CURTAIN, self, UniversalAutoload.actionEventToggleCurtain, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleCurtainActionEventId = actionEventId
					if debugKeys then print("  TOGGLE_CURTAIN: "..tostring(valid)) end
				end
				
			end
			
			if self.isServer then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_SHOW_DEBUG, self, UniversalAutoload.actionEventToggleShowDebug, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				-- spec.ToggleShowLoadingActionEventId = actionEventId
				if debugKeys then print("  TOGGLE_DEBUG: "..tostring(valid)) end
				
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_SHOW_LOADING, self, UniversalAutoload.actionEventToggleShowLoading, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				-- spec.ToggleShowLoadingActionEventId = actionEventId
				if debugKeys then print("  TOGGLE_DEBUG: "..tostring(valid)) end
			end

			spec.updateCycleMaterial = true
			spec.updateCycleContainer = true
			spec.updateToggleDoor = true
			spec.updateToggleCurtain = true
			spec.updateToggleTipside = true
			spec.updateToggleBelts = true
			spec.updateToggleFilter = true
			spec.updateToggleLoading = true
		end
	end
end
--
function UniversalAutoload:updateToggleBeltsActionEvent()
	--if debugKeys then print("updateToggleBeltsActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.toggleBeltsActionEventId ~= nil then

		g_inputBinding:setActionEventActive(spec.toggleBeltsActionEventId, true)
		
		local tensionBeltsText
		if self.spec_tensionBelts.areBeltsFasten then
			tensionBeltsText = g_i18n:getText("action_unfastenTensionBelts")
		else
			tensionBeltsText = g_i18n:getText("action_fastenTensionBelts")
		end
		g_inputBinding:setActionEventText(spec.toggleBeltsActionEventId, tensionBeltsText)
		g_inputBinding:setActionEventTextVisibility(spec.toggleBeltsActionEventId, true)

	end
end
--
function UniversalAutoload:updateToggleDoorActionEvent()
	--if debugKeys then print("updateToggleDoorActionEvent") end
	local spec = self.spec_universalAutoload
	local foldable = self.spec_foldable

	if g_currentMission.player.isControlled then
		if spec.isAutoloadEnabled and self.spec_foldable and (spec.isCurtainTrailer or spec.isBoxTrailer) then
			local direction = self:getToggledFoldDirection()

			local toggleDoorText = ""
			if direction == foldable.turnOnFoldDirection then
				toggleDoorText = foldable.negDirectionText
			else
				toggleDoorText = foldable.posDirectionText
			end

			g_inputBinding:setActionEventText(spec.toggleDoorActionEventId, toggleDoorText)
			g_inputBinding:setActionEventTextVisibility(spec.toggleDoorActionEventId, true)
		end
	else
		if spec.isAutoloadEnabled and self.spec_foldable and self.isClient then
			Foldable.updateActionEventFold(self)
		end
	end
end
--
function UniversalAutoload:updateToggleCurtainActionEvent()
	--if debugKeys then print("updateToggleCurtainActionEvent") end
	local spec = self.spec_universalAutoload
	
	if self.spec_trailer and spec.isCurtainTrailer and g_currentMission.player.isControlled then
		local trailer = self.spec_trailer
		local tipSide = trailer.tipSides[trailer.preferedTipSideIndex]
		
		if spec.isAutoloadEnabled and tipSide ~= nil then
			local toggleCurtainText = nil
			local tipState = self:getTipState()
			if tipState == Trailer.TIPSTATE_CLOSED or tipState == Trailer.TIPSTATE_CLOSING then
				toggleCurtainText = tipSide.manualTipToggleActionTextPos
			else
				toggleCurtainText = tipSide.manualTipToggleActionTextNeg
			end
			g_inputBinding:setActionEventText(spec.toggleCurtainActionEventId, toggleCurtainText)
			g_inputBinding:setActionEventTextVisibility(spec.toggleCurtainActionEventId, true)
		end
	end
end

--
function UniversalAutoload:updateCycleMaterialActionEvent()
	--if debugKeys then print("updateCycleMaterialActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.cycleMaterialActionEventId ~= nil then
		-- Material Type: ALL / <MATERIAL>
		if not spec.isLoading then
			local materialTypeText = g_i18n:getText("universalAutoload_materialType")..": "..UniversalAutoload.getSelectedMaterialText(self)
			g_inputBinding:setActionEventText(spec.cycleMaterialActionEventId, materialTypeText)
			g_inputBinding:setActionEventTextVisibility(spec.cycleMaterialActionEventId, true)
		end

	end
end
--
function UniversalAutoload:updateCycleContainerActionEvent()
	--if debugKeys then print("updateCycleContainerActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.cycleContainerActionEventId ~= nil then
		-- Container Type: ALL / <PALLET_TYPE>
		if not spec.isLoading then
			local containerTypeText = g_i18n:getText("universalAutoload_containerType")..": "..UniversalAutoload.getSelectedContainerText(self)
			g_inputBinding:setActionEventText(spec.cycleContainerActionEventId, containerTypeText)
			g_inputBinding:setActionEventTextVisibility(spec.cycleContainerActionEventId, true)
		end
	end
end
--
function UniversalAutoload:updateToggleFilterActionEvent()
	--if debugKeys then print("updateToggleFilterActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.toggleLoadingFilterActionEventId ~= nil then
		-- Loading Filter: ANY / FULL ONLY
		local loadingFilterText
		if spec.currentLoadingFilter then
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_fullOnly")
		else
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_loadAny")
		end
		g_inputBinding:setActionEventText(spec.toggleLoadingFilterActionEventId, loadingFilterText)
		g_inputBinding:setActionEventTextVisibility(spec.toggleLoadingFilterActionEventId, true)
	end
end
--
function UniversalAutoload:updateToggleTipsideActionEvent()
	--if debugKeys then print("updateToggleTipsideActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.toggleTipsideActionEventId ~= nil then
		-- Tipside: NONE/BOTH/LEFT/RIGHT/
		if spec.currentTipside == "none" then
			g_inputBinding:setActionEventActive(spec.toggleTipsideActionEventId, false)
		else
			local tipsideText = g_i18n:getText("universalAutoload_tipside")..": "..g_i18n:getText("universalAutoload_"..(spec.currentTipside or "none"))
			g_inputBinding:setActionEventText(spec.toggleTipsideActionEventId, tipsideText)
			g_inputBinding:setActionEventTextVisibility(spec.toggleTipsideActionEventId, true)
		end
	end
end
--
function UniversalAutoload:updateToggleLoadingActionEvent()
	--if debugKeys then print("updateToggleLoadingActionEvent") end
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.toggleBaleCollectionModeEventId ~= nil then
		-- Activate/Deactivate the AUTO-BALE key binding
		if spec.baleCollectionMode==true or spec.validUnloadCount==0 then
			local baleCollectionModeText
			if spec.baleCollectionMode then
				baleCollectionModeText = g_i18n:getText("universalAutoload_baleMode")..": "..g_i18n:getText("universalAutoload_enabled")
			else
				baleCollectionModeText = g_i18n:getText("universalAutoload_baleMode")..": "..g_i18n:getText("universalAutoload_disabled")
			end
			g_inputBinding:setActionEventText(spec.toggleBaleCollectionModeEventId, baleCollectionModeText)
			g_inputBinding:setActionEventTextVisibility(spec.toggleBaleCollectionModeEventId, true)
			if debugKeys then print("   >> " .. baleCollectionModeText) end
		else
			g_inputBinding:setActionEventActive(spec.toggleBaleCollectionModeEventId, false)
		end
	end
	
	if spec.isAutoloadEnabled and spec.toggleLoadingActionEventId ~= nil then
		-- Activate/Deactivate the LOAD key binding
		if spec.isLoading and not self.baleCollectionMode==true then
			local stopLoadingText = g_i18n:getText("universalAutoload_stopLoading")
			g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, stopLoadingText)
			if debugKeys then print("   >> " .. stopLoadingText) end
		else
			if UniversalAutoload.getIsLoadingKeyAllowed(self) then
				local startLoadingText = g_i18n:getText("universalAutoload_startLoading")
				if UniversalAutoload.showLoading then startLoadingText = startLoadingText.." ("..tostring(spec.validLoadCount)..")" end
				g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, startLoadingText)
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, true)
				g_inputBinding:setActionEventTextVisibility(spec.toggleLoadingActionEventId, true)
				if debugKeys then print("   >> " .. startLoadingText) end
			else
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, false)
			end
		end
	end

	if spec.isAutoloadEnabled and spec.unloadAllActionEventId ~= nil then
		-- Activate/Deactivate the UNLOAD key binding
		if UniversalAutoload.getIsUnloadingKeyAllowed(self) then
			local unloadText = g_i18n:getText("universalAutoload_unloadAll")
			if UniversalAutoload.showLoading then unloadText = unloadText.." ("..tostring(spec.validUnloadCount)..")" end
			g_inputBinding:setActionEventText(spec.unloadAllActionEventId, unloadText)
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, true)
			g_inputBinding:setActionEventTextVisibility(spec.unloadAllActionEventId, true)
			if debugKeys then print("   >> " .. unloadText) end
		else
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, false)
		end
		
	end
	
end

-- ACTION EVENTS
function UniversalAutoload.actionEventToggleBelts(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleBelts: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if self.spec_tensionBelts.areBeltsFasten then
		self:setAllTensionBeltsActive(false)
	else
		self:setAllTensionBeltsActive(true)
	end
	spec.updateToggleBelts = true
end
--
function UniversalAutoload.actionEventToggleDoor(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleDoor: "..self:getFullName())
	local spec = self.spec_universalAutoload
	local foldable = self.spec_foldable
	if #foldable.foldingParts > 0 then
		local toggleDirection = self:getToggledFoldDirection()
		if toggleDirection == foldable.turnOnFoldDirection then
			self:setFoldState(toggleDirection, true)
		else
			self:setFoldState(toggleDirection, false)
		end
	end
	spec.updateToggleDoor = true
end
--
function UniversalAutoload.actionEventToggleCurtain(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleCurtain: "..self:getFullName())
	local spec = self.spec_universalAutoload
	local tipState = self:getTipState()
	if tipState == Trailer.TIPSTATE_CLOSED or tipState == Trailer.TIPSTATE_CLOSING then
		self:startTipping(nil, false)
		TrailerToggleManualTipEvent.sendEvent(self, true)
	else
		self:stopTipping()
		TrailerToggleManualTipEvent.sendEvent(self, false)
	end
	spec.updateToggleCurtain = true
end
--
function UniversalAutoload.actionEventToggleShowDebug(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleShowDebug: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if self.isServer then
		UniversalAutoload.showDebug = not UniversalAutoload.showDebug
	end
end
--
function UniversalAutoload.actionEventToggleShowLoading(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleShowLoading: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if self.isServer then
		UniversalAutoload.showLoading = not UniversalAutoload.showLoading
	end
end
--
function UniversalAutoload.actionEventToggleBaleCollectionMode(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleBaleCollectionMode: "..self:getFullName())
	local spec = self.spec_universalAutoload
	UniversalAutoload.setBaleCollectionMode(self, not spec.baleCollectionMode)
end
--
function UniversalAutoload.actionEventCycleMaterial_FW(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventCycleMaterial_FW: "..self:getFullName())
	UniversalAutoload.cycleMaterialTypeIndex(self, 1)
end
--
function UniversalAutoload.actionEventCycleMaterial_BW(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventCycleMaterial_BW: "..self:getFullName())
	UniversalAutoload.cycleMaterialTypeIndex(self, -1)
end
--
function UniversalAutoload.actionEventSelectAllMaterials(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventSelectAllMaterials: "..self:getFullName())
	UniversalAutoload.setMaterialTypeIndex(self, 1)
end
--
function UniversalAutoload.actionEventCycleContainer_FW(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventCycleContainer_FW: "..self:getFullName())
	UniversalAutoload.cycleContainerTypeIndex(self, 1)
end
--
function UniversalAutoload.actionEventCycleContainer_BW(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventCycleContainer_BW: "..self:getFullName())
	UniversalAutoload.cycleContainerTypeIndex(self, -1)
end
--
function UniversalAutoload.actionEventSelectAllContainers(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventSelectAllContainers: "..self:getFullName())
	UniversalAutoload.setContainerTypeIndex(self, 1)
end
--
function UniversalAutoload.actionEventToggleFilter(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleFilter: "..self:getFullName())
	local spec = self.spec_universalAutoload
	local state = not spec.currentLoadingFilter
	UniversalAutoload.setLoadingFilter(self, state)
end
--
function UniversalAutoload.actionEventToggleTipside(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleTipside: "..self:getFullName())
	local spec = self.spec_universalAutoload
	local tipside
	if spec.currentTipside == "left" then
		tipside = "right"
	else
		tipside = "left"
	end
	UniversalAutoload.setCurrentTipside(self, tipside)
end
--
function UniversalAutoload.actionEventToggleLoading(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleLoading: "..self:getFullName())
    local spec = self.spec_universalAutoload
	if not spec.isLoading then
		UniversalAutoload.startLoading(self)
	else
		UniversalAutoload.stopLoading(self)
	end
end
--
function UniversalAutoload.actionEventUnloadAll(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventUnloadAll: "..self:getFullName())
	UniversalAutoload.startUnloading(self)
end

-- EVENT FUNCTIONS
function UniversalAutoload:cycleMaterialTypeIndex(direction, noEventSend)
	local spec = self.spec_universalAutoload
	
	if self.isServer then
		local materialIndex
		if direction == 1 then
			materialIndex = 999
			for _, object in pairs(spec.availableObjects) do
				local objectMaterialName = UniversalAutoload.getMaterialTypeName(object)
				local objectMaterialIndex = UniversalAutoload.MATERIALS_INDEX[objectMaterialName] or 1
				if objectMaterialIndex > spec.currentMaterialIndex and objectMaterialIndex < materialIndex then
					materialIndex = objectMaterialIndex
				end
			end
			for _, object in pairs(spec.loadedObjects) do
				local objectMaterialName = UniversalAutoload.getMaterialTypeName(object)
				local objectMaterialIndex = UniversalAutoload.MATERIALS_INDEX[objectMaterialName] or 1
				if objectMaterialIndex > spec.currentMaterialIndex and objectMaterialIndex < materialIndex then
					materialIndex = objectMaterialIndex
				end
			end
		else
			materialIndex = 0
			local startingValue = (spec.currentMaterialIndex==1) and #UniversalAutoload.MATERIALS+1 or spec.currentMaterialIndex
			for _, object in pairs(spec.availableObjects) do
				local objectMaterialName = UniversalAutoload.getMaterialTypeName(object)	
				local objectMaterialIndex = UniversalAutoload.MATERIALS_INDEX[objectMaterialName] or 1
				if objectMaterialIndex < startingValue and objectMaterialIndex > materialIndex then
					materialIndex = objectMaterialIndex
				end
			end
			for _, object in pairs(spec.loadedObjects) do
				local objectMaterialName = UniversalAutoload.getMaterialTypeName(object)	
				local objectMaterialIndex = UniversalAutoload.MATERIALS_INDEX[objectMaterialName] or 1
				if objectMaterialIndex < startingValue and objectMaterialIndex > materialIndex then
					materialIndex = objectMaterialIndex
				end
			end
		end
		if materialIndex == nil or materialIndex == 0 or materialIndex == 999 then
			materialIndex = 1
		end
		
		UniversalAutoload.setMaterialTypeIndex(self, materialIndex)
		if materialIndex==1 and spec.totalAvailableCount==0 and spec.totalUnloadCount==0 then
			-- NO_OBJECTS_FOUND
			UniversalAutoload.showWarningMessage(self, 2)
		end
	end
	
	UniversalAutoloadCycleMaterialEvent.sendEvent(self, direction, noEventSend)
end
--
function UniversalAutoload:setMaterialTypeIndex(typeIndex, noEventSend)
	-- print("setMaterialTypeIndex: "..self:getFullName().." "..tostring(typeIndex))
	local spec = self.spec_universalAutoload

	spec.currentMaterialIndex = math.min(math.max(typeIndex, 1), table.getn(UniversalAutoload.MATERIALS))

	UniversalAutoloadSetMaterialTypeEvent.sendEvent(self, typeIndex, noEventSend)
	
	spec.updateCycleMaterial = true
	
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
	end
end
--
function UniversalAutoload:cycleContainerTypeIndex(direction, noEventSend)
	local spec = self.spec_universalAutoload
	if self.isServer then
		local containerIndex
		if direction == 1 then
			containerIndex = 999
			for _, object in pairs(spec.availableObjects) do
				local objectContainerName = UniversalAutoload.getContainerTypeName(object)
				local objectContainerIndex = UniversalAutoload.CONTAINERS_INDEX[objectContainerName] or 1
				if objectContainerIndex > spec.currentContainerIndex and objectContainerIndex < containerIndex then
					containerIndex = objectContainerIndex
				end
			end
			for _, object in pairs(spec.loadedObjects) do
				local objectContainerName = UniversalAutoload.getContainerTypeName(object)
				local objectContainerIndex = UniversalAutoload.CONTAINERS_INDEX[objectContainerName] or 1
				if objectContainerIndex > spec.currentContainerIndex and objectContainerIndex < containerIndex then
					containerIndex = objectContainerIndex
				end
			end
		else
			containerIndex = 0
			local startingValue = (spec.currentContainerIndex==1) and #UniversalAutoload.CONTAINERS+1 or spec.currentContainerIndex
			for _, object in pairs(spec.availableObjects) do
				local objectContainerName = UniversalAutoload.getContainerTypeName(object)
				local objectContainerIndex = UniversalAutoload.CONTAINERS_INDEX[objectContainerName] or 1
				if objectContainerIndex < startingValue and objectContainerIndex > containerIndex then
					containerIndex = objectContainerIndex
				end
			end
			for _, object in pairs(spec.loadedObjects) do
				local objectContainerName = UniversalAutoload.getContainerTypeName(object)
				local objectContainerIndex = UniversalAutoload.CONTAINERS_INDEX[objectContainerName] or 1
				if objectContainerIndex < startingValue and objectContainerIndex > containerIndex then
					containerIndex = objectContainerIndex
				end
			end
		end
		if containerIndex == nil or containerIndex == 0 or containerIndex == 999 then
			containerIndex = 1
		end
		
		UniversalAutoload.setContainerTypeIndex(self, containerIndex)
		if containerIndex==1 and spec.totalAvailableCount==0 and spec.totalUnloadCount==0 then
			-- NO_OBJECTS_FOUND
			UniversalAutoload.showWarningMessage(self, 2)
		end
	end
	
	UniversalAutoloadCycleContainerEvent.sendEvent(self, direction, noEventSend)
end
--
function UniversalAutoload:setContainerTypeIndex(typeIndex, noEventSend)
	-- print("setContainerTypeIndex: "..self:getFullName().." "..tostring(typeIndex))
	local spec = self.spec_universalAutoload

	spec.currentContainerIndex = math.min(math.max(typeIndex, 1), table.getn(UniversalAutoload.CONTAINERS))

	UniversalAutoloadSetContainerTypeEvent.sendEvent(self, typeIndex, noEventSend)
	spec.updateCycleContainer = true
	
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
	end
end
--
function UniversalAutoload:setLoadingFilter(state, noEventSend)
	-- print("setLoadingFilter: "..self:getFullName().." "..tostring(state))
	local spec = self.spec_universalAutoload
	
	spec.currentLoadingFilter = state
	
	UniversalAutoloadSetFilterEvent.sendEvent(self, state, noEventSend)
	
	spec.updateToggleFilter = true
	
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
	end
end
--
function UniversalAutoload:setCurrentTipside(tipside, noEventSend)
	-- print("setTipside: "..self:getFullName().." - "..tostring(tipside))
	local spec = self.spec_universalAutoload
	
	spec.currentTipside = tipside
	
	UniversalAutoloadSetTipsideEvent.sendEvent(self, tipside, noEventSend)
	spec.updateToggleTipside = true
end
--
function UniversalAutoload:setCurrentLoadside(loadside, noEventSend)
	-- print("setLoadside: "..self:getFullName().." - "..tostring(loadside))
	local spec = self.spec_universalAutoload
	
	spec.currentLoadside = loadside
	
	UniversalAutoloadSetLoadsideEvent.sendEvent(self, loadside, noEventSend)
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
		UniversalAutoload.updateActionEventText(self)
	end
end
--

function UniversalAutoload:setBaleCollectionMode(baleCollectionMode, noEventSend)
	-- print("setBaleCollectionMode: "..self:getFullName().." - "..tostring(baleCollectionMode))
	local spec = self.spec_universalAutoload
		
	if self.isServer then
		if baleCollectionMode then
			if spec.availableBaleCount > 0 and not spec.trailerIsFull then
				if UniversalAutoload.showDebug then print("baleCollectionMode: startLoading") end
				UniversalAutoload.startLoading(self)
			end
		else
			if UniversalAutoload.showDebug then print("baleCollectionMode: stopLoading") end
			UniversalAutoload.stopLoading(self)
			spec.baleCollectionModeDeactivated = true
		end
	end
	
	spec.baleCollectionMode = baleCollectionMode
	
	UniversalAutoloadSetBaleCollectionModeEvent.sendEvent(self, baleCollectionMode, noEventSend)
	spec.updateToggleLoading = true
end
--
function UniversalAutoload:startLoading(noEventSend)
	local spec = self.spec_universalAutoload

	if not spec.isLoading and UniversalAutoload.getIsLoadingVehicleAllowed(self) then
		-- print("Start Loading: "..self:getFullName() )

		spec.isLoading = true
		spec.firstAttemptToLoad = true
		
		if self.isServer then
		
			spec.loadDelayTime = math.huge
			if not spec.baleCollectionMode and UniversalAutoload.testLoadAreaIsEmpty(self) then
				spec.resetLoadingPattern = true
			end
		
			spec.sortedObjectsToLoad = UniversalAutoload.createSortedObjectsToLoad(self, spec.availableObjects)
		end
		
		UniversalAutoloadStartLoadingEvent.sendEvent(self, noEventSend)
		spec.updateToggleLoading = true
	end
end
--
function UniversalAutoload:createSortedObjectsToLoad(availableObjects)
	local spec = self.spec_universalAutoload

	sortedObjectsToLoad = {}
	for _, object in pairs(availableObjects) do
	
		local node = UniversalAutoload.getObjectNode(object)
		if UniversalAutoload.isValidForLoading(self, object) and node~=nil then
		
			local containerType = UniversalAutoload.getContainerType(object)
			local x, y, z = localToLocal(node, spec.loadArea[1].startNode, 0, 0, 0)
			object.sort = {}
			object.sort.height = y
			object.sort.distance = math.abs(x) + math.abs(z)
			object.sort.area = (containerType.sizeX * containerType.sizeZ) or 1
			object.sort.material = UniversalAutoload.getMaterialType(object) or 1
			
			table.insert(sortedObjectsToLoad, object)
		end
	end
	if #sortedObjectsToLoad > 1 then
		table.sort(sortedObjectsToLoad, UniversalAutoload.sortPalletsForLoading)
	end
	for _, object in pairs(sortedObjectsToLoad) do
		object.sort = nil
	end
	
	return sortedObjectsToLoad
end
--
function UniversalAutoload.sortPalletsForLoading(w1,w2)
	-- SORT BY:  AREA > MATERIAL > HEIGHT > DISTANCE
	if w1.sort.area == w2.sort.area and w1.sort.material == w2.sort.material and w1.sort.height == w2.sort.height and w1.sort.distance < w2.sort.distance then
		return true
	elseif w1.sort.area == w2.sort.area and w1.sort.material == w2.sort.material and w1.sort.height > w2.sort.height then
		return true
	elseif w1.sort.area == w2.sort.area and w1.sort.material < w2.sort.material then
		return true
	elseif w1.sort.area > w2.sort.area then
		return true
	end
end
--
function UniversalAutoload:stopLoading(noEventSend)
	local spec = self.spec_universalAutoload
	
	if spec.isLoading then
		-- print("Stop Loading: "..self:getFullName() )
		spec.isLoading = false
		spec.doPostLoadDelay = true
		
		if self.isServer then
			spec.loadDelayTime = 0

			if not self.spec_tensionBelts.areBeltsFasten then
				spec.doSetTensionBelts = true
			end
		end
		
		UniversalAutoloadStopLoadingEvent.sendEvent(self, noEventSend)
		spec.updateToggleLoading = true
	end
end
--
function UniversalAutoload:startUnloading(noEventSend)
	local spec = self.spec_universalAutoload

	if not spec.isUnloading then
		-- print("Start Unloading: "..self:getFullName() )
		spec.isUnloading = true

		if self.isServer then
			if spec.loadedObjects ~= nil then
				UniversalAutoload.buildObjectsToUnloadTable(self)
			end

			if spec.objectsToUnload ~= nil and spec.unloadingAreaClear then
				self:setAllTensionBeltsActive(false)
				for object, unloadPlace in pairs(spec.objectsToUnload) do
					if not UniversalAutoload.unloadObject(self, object, unloadPlace) then
						-- print("THERE WAS A PROBLEM UNLOADING...")
					end
				end
				spec.objectsToUnload = {}
				if spec.totalUnloadCount == 0 then
					spec.trailerIsFull = false
					spec.partiallyUnloaded = false
					spec.resetLoadingPattern = true
					spec.currentLoadAreaIndex = 1
					spec.currentLoadingPlace = nil
				else
					spec.partiallyUnloaded = true
				end
			else
				-- CLEAR_UNLOADING_AREA
				UniversalAutoload.showWarningMessage(self, 1)
			end
		end
		
		spec.isUnloading = false
		spec.doPostLoadDelay = true

		UniversalAutoloadStartUnloadingEvent.sendEvent(self, noEventSend)
		
		spec.updateToggleLoading = true
	end
end
--
function UniversalAutoload:showWarningMessage(messageId, noEventSend)
	-- print("Show Warning Message: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isClient then
		-- print("CLIENT: "..g_i18n:getText(UniversalAutoload.WARNINGS[messageId]))
		g_currentMission:showBlinkingWarning(g_i18n:getText(UniversalAutoload.WARNINGS[messageId]), 2000);
	end
	
	if self.isServer then
		-- print("SERVER: "..g_i18n:getText(UniversalAutoload.WARNINGS[messageId]))
		UniversalAutoloadWarningMessageEvent.sendEvent(self, messageId, noEventSend)
	end
end
--
function UniversalAutoload:resetLoadingState(noEventSend)
	-- print("RESET Loading State: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isServer then
		if spec.doSetTensionBelts and not spec.disableAutoStrap and not UniversalAutoload.disableAutoStrap then
			self:setAllTensionBeltsActive(true)
		end
		spec.postLoadDelayTime = 0
	end
	
	spec.doPostLoadDelay = false
	spec.doSetTensionBelts = false
	
	UniversalAutoloadResetLoadingEvent.sendEvent(self, noEventSend)
	
	spec.updateToggleLoading = true
end
--
function UniversalAutoload:updateActionEventText(loadCount, unloadCount, noEventSend)
	-- print("updateActionEventText: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isClient then
		if loadCount ~= nil then
			spec.validLoadCount = loadCount
		end
		if unloadCount ~= nil then
			spec.validUnloadCount = unloadCount
		end
		-- print("Valid Load Count = " .. tostring(spec.validLoadCount) .. " / " .. tostring(spec.validUnloadCount) )
	end
	
	if self.isServer then
		-- print("updateActionEventText - SEND EVENT")
		UniversalAutoloadUpdateActionEvents.sendEvent(self, spec.validLoadCount, spec.validUnloadCount, noEventSend)
	end
	
	spec.updateToggleLoading = true
end
--
function UniversalAutoload:forceRaiseActive(state, noEventSend)
	-- print("forceRaiseActive: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if spec.updateKeys then
		--print("UPDATE KEYS: "..self:getFullName())
		spec.updateKeys = false
		spec.updateToggleLoading = true
	end
	
	if self.isServer then
		-- print("SERVER RAISE ACTIVE: "..self:getFullName().." ("..tostring(state)..")")
		self:raiseActive()
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
		
		UniversalAutoload.determineTipside(self)
		UniversalAutoload.countActivePallets(self)
	end
	
	if state ~= nil then
		-- print("Activated = "..tostring(state))
		spec.isActivated = state
	end
	
	UniversalAutoloadRaiseActiveEvent.sendEvent(self, state, noEventSend)
end
--
function UniversalAutoload:updatePlayerTriggerState(playerId, inTrigger, noEventSend)
	-- print("updatePlayerTriggerState: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if playerId ~= nil then
		spec.playerInTrigger[playerId] = inTrigger
	end
	
	UniversalAutoloadPlayerTriggerEvent.sendEvent(self, playerId, inTrigger, noEventSend)
end
--
function UniversalAutoload:getIsValidConfiguration(selectedConfigs, xmlFile, key)

	local validConfig = nil
	
	if selectedConfigs == nil or selectedConfigs == "ALL" then
		validConfig = "ALL CONFIGURATIONS"
	else
		local selectedConfigs = selectedConfigs:split(",")
		
		local item = {}
		item.configurations, _ = UniversalAutoload.getConfigurationsFromXML(xmlFile, "vehicle", self.customEnvironment, item)
		item.configurationSets = UniversalAutoload.getConfigurationSetsFromXML(item, xmlFile, "vehicle", self.customEnvironment)

		if item.configurationSets ~= nil and #item.configurationSets > 0  then
			local closestSet, _ = UniversalAutoload.getClosestConfigurationSet(self.configurations, item.configurationSets)
			
			for k, v in pairs(item.configurationSets) do
				if v == closestSet then
					for _, n in ipairs(selectedConfigs) do
						if tonumber(n) == tonumber(k) then
							if UniversalAutoload.showDebug then print("UNIVERSAL AUTOLOAD VALID CONFIG: "..n) end
							validConfig = closestSet.name
						end
					end
				end
			end
		end
	end
	return validConfig

end
--
function UniversalAutoload.getConfigurationsFromXML(xmlFile, key, customEnvironment, storeItem)
	local configurations = {}
	local numConfigs = 0
	local configurationTypes = g_configurationManager:getConfigurationTypes()

	for _, name in pairs(configurationTypes) do
		local configuration = g_configurationManager:getConfigurationDescByName(name)
		local configurationItems = {}
		local i = 0
		local xmlKey = configuration.xmlKey

		if xmlKey ~= nil then
			xmlKey = "." .. xmlKey
		else
			xmlKey = ""
		end

		local baseKey = key .. xmlKey .. "." .. name .. "Configurations"

		local overwrittenTitle = xmlFile:getValue(baseKey .. "#title", nil, customEnvironment, false)
		local loadedSaveIds = {}

		while true do
			local configKey = string.format(baseKey .. "." .. name .. "Configuration(%d)", i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local configName = ConfigurationUtil.loadConfigurationNameFromXML(xmlFile, configKey, customEnvironment)
			local desc = xmlFile:getValue(configKey .. "#desc", nil, customEnvironment, false)
			local price = xmlFile:getValue(configKey .. "#price", 0)
			local dailyUpkeep = xmlFile:getValue(configKey .. "#dailyUpkeep", 0)
			local isDefault = xmlFile:getValue(configKey .. "#isDefault", false)
			local isSelectable = xmlFile:getValue(configKey .. "#isSelectable", true)
			local saveId = xmlFile:getValue(configKey .. "#saveId")
			local vehicleBrandName = xmlFile:getValue(configKey .. "#vehicleBrand")
			local vehicleBrand = g_brandManager:getBrandIndexByName(vehicleBrandName)
			local vehicleName = xmlFile:getValue(configKey .. "#vehicleName")
			local vehicleIcon = xmlFile:getValue(configKey .. "#vehicleIcon")


			local brandName = xmlFile:getValue(configKey .. "#displayBrand")
			local brandIndex = g_brandManager:getBrandIndexByName(brandName)
			local configItem = StoreItemUtil.addConfigurationItem(configurationItems, configName, desc, price, dailyUpkeep, isDefault, overwrittenTitle, saveId, brandIndex, isSelectable, vehicleBrand, vehicleName, vehicleIcon)
			
			StoreItemUtil.renameDuplicatedConfigurationNames(configurationItems, configItem)

			i = i + 1
		end
		
		if #configurationItems > 0 then
			configurations[name] = configurationItems
			numConfigs = numConfigs + 1
		end
	end

	if numConfigs == 0 then
		configurations = nil
	end

	return configurations
end
--
function UniversalAutoload.getConfigurationSetsFromXML(storeItem, xmlFile, key, customEnvironment)
	local configurationSetsKey = string.format("%s.configurationSets", key)
	local overwrittenTitle = xmlFile:getValue(configurationSetsKey .. "#title", nil, customEnvironment, false)
	local configurationsSets = {}
	local i = 0

	while true do
		local key = string.format("%s.configurationSet(%d)", configurationSetsKey, i)
		if not xmlFile:hasProperty(key) then
			break
		end
		local configSet = {
			name = xmlFile:getValue(key .. "#name", nil, customEnvironment, false)
		}
		
		local params = xmlFile:getValue(key .. "#params")
		if params ~= nil then
			params = params:split("|")
			configSet.name = string.format(configSet.name, unpack(params))
		end

		configSet.isDefault = xmlFile:getValue(key .. "#isDefault", false)
		configSet.overwrittenTitle = overwrittenTitle
		configSet.configurations = {}
		local j = 0

		while true do
			local configKey = string.format("%s.configuration(%d)", key, j)
			if not xmlFile:hasProperty(configKey) then
				break
			end
			local name = xmlFile:getValue(configKey .. "#name")
			if name ~= nil then
				if storeItem.configurations[name] ~= nil then
					local index = xmlFile:getValue(configKey .. "#index")

					if index ~= nil then
						if storeItem.configurations[name][index] ~= nil then
							configSet.configurations[name] = index
						end
					end
				end
			end
			j = j + 1
		end

		table.insert(configurationsSets, configSet)
		i = i + 1
	end

	return configurationsSets
end
--
function UniversalAutoload.getClosestConfigurationSet(configurations, configSets)
	local closestSet = nil
	local closestSetMatches = 0

	for _, configSet in pairs(configSets) do
		local numMatches = 0

		for configName, index in pairs(configSet.configurations) do
			if configurations[configName] == index then
				numMatches = numMatches + 1
			end
		end

		if closestSetMatches < numMatches then
			closestSet = configSet
			closestSetMatches = numMatches
		end
	end

	return closestSet, closestSetMatches
end

-- MAIN "ON LOAD" INITIALISATION FUNCTION
function UniversalAutoload:onLoad(savegame)

	self.spec_universalAutoload = self[UniversalAutoload.specName]
	local spec = self.spec_universalAutoload
	spec.isAutoloadEnabled = false
	
	if self.isServer then

		local configFileName = self.configFileName
		local xmlFile = XMLFile.load("configXml", configFileName, Vehicle.xmlSchema)

		if self.customEnvironment ~= nil then
			configFileName = Utils.removeModDirectory(configFileName)
			if UniversalAutoload.showDebug then print("configFileName:  " .. configFileName) end
		end
		
		if xmlFile ~= 0 then
			if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] ~= nil then
				local configGroup = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
				for selectedConfigs, config in pairs(configGroup) do
					local validConfig = UniversalAutoload.getIsValidConfiguration(self, selectedConfigs, xmlFile, key)
					if validConfig ~= nil then
						print("UniversalAutoload - supported vehicle: "..self:getFullName().." - "..validConfig)
						-- define the loading area parameters from supported vehicles settings file
						spec.boughtConfig = selectedConfigs
						spec.loadArea = {}
						for i, loadArea in pairs(config.loadingArea) do
							spec.loadArea[i] = {}
							spec.loadArea[i].width      = loadArea.width
							spec.loadArea[i].length     = loadArea.length
							spec.loadArea[i].height     = loadArea.height
							spec.loadArea[i].baleHeight = loadArea.baleHeight
							spec.loadArea[i].offset     = loadArea.offset
							spec.loadArea[i].noLoadingIfFolded   = loadArea.noLoadingIfFolded
							spec.loadArea[i].noLoadingIfUnfolded = loadArea.noLoadingIfUnfolded
							spec.loadArea[i].noLoadingIfCovered  = loadArea.noLoadingIfCovered
							spec.loadArea[i].noLoadingIfUncovered  = loadArea.noLoadingIfUncovered
						end
						spec.isBoxTrailer = config.isBoxTrailer
						spec.isBaleTrailer = config.isBaleTrailer
						spec.isCurtainTrailer = config.isCurtainTrailer
						spec.enableRearLoading = config.enableRearLoading
						spec.enableSideLoading = config.enableSideLoading
						spec.noLoadingIfFolded = config.noLoadingIfFolded
						spec.noLoadingIfUnfolded = config.noLoadingIfUnfolded
						spec.noLoadingIfCovered = config.noLoadingIfCovered
						spec.noLoadingIfUncovered = config.noLoadingIfUncovered
						spec.rearUnloadingOnly = config.rearUnloadingOnly
						spec.frontUnloadingOnly = config.frontUnloadingOnly
						spec.disableAutoStrap = config.disableAutoStrap
						spec.zonesOverlap = config.zonesOverlap
						spec.showDebug = config.showDebug
						break
					end
				end
				
			else
				-- print("LOOK IN XML: " .. configFileName)
				local i = 0
				while true do
					local key = string.format("vehicle.universalAutoload.vehicleConfigurations.vehicleConfiguration(%d)", i)

					if not xmlFile:hasProperty(key) then
						break
					end
					local selectedConfigs = xmlFile:getValue(key.."#selectedConfigs")
					local validConfig = UniversalAutoload.getIsValidConfiguration(self, selectedConfigs, xmlFile, key)
					if validConfig ~= nil then
						validVehicleName = self:getFullName().." - "..validConfig
						print("UniversalAutoload - vaild vehicle: "..validVehicleName)
						-- define the loading area parameters from vechicle.xml file
						spec.loadArea = {}
						local j = 0
						while true do
							local loadAreaKey = string.format("%s.loadingArea(%d)", key, j)
							if not xmlFile:hasProperty(loadAreaKey) then
								break
							end
							spec.loadArea[j+1] = {}
							spec.loadArea[j+1].width      = xmlFile:getValue(loadAreaKey.."#width")
							spec.loadArea[j+1].length     = xmlFile:getValue(loadAreaKey.."#length")
							spec.loadArea[j+1].height     = xmlFile:getValue(loadAreaKey.."#height")
							spec.loadArea[j+1].baleHeight = xmlFile:getValue(loadAreaKey.."#baleHeight", nil)
							spec.loadArea[j+1].offset     = xmlFile:getValue(loadAreaKey.."#offset", "0 0 0", true)
							spec.loadArea[j+1].noLoadingIfFolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfFolded", false)
							spec.loadArea[j+1].noLoadingIfUnfolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfUnfolded", false)
							spec.loadArea[j+1].noLoadingIfCovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfCovered", false)
							spec.loadArea[j+1].noLoadingIfUncovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfUncovered", false)
							j = j + 1
						end
						spec.isBoxTrailer = xmlFile:getValue(key..".options#isBoxTrailer", false)
						spec.isBaleTrailer = xmlFile:getValue(key..".options#isBaleTrailer", false)
						spec.isCurtainTrailer = xmlFile:getValue(key..".options#isCurtainTrailer", false)
						spec.enableRearLoading = xmlFile:getValue(key..".options#enableRearLoading", false)
						spec.enableSideLoading = xmlFile:getValue(key..".options#enableSideLoading", false)
						spec.noLoadingIfFolded = xmlFile:getValue(key..".options#noLoadingIfFolded", false)
						spec.noLoadingIfUnfolded = xmlFile:getValue(key..".options#noLoadingIfUnfolded", false)
						spec.noLoadingIfCovered = xmlFile:getValue(key..".options#noLoadingIfCovered", false)
						spec.noLoadingIfUncovered = xmlFile:getValue(key..".options#noLoadingIfUncovered", false)
						spec.rearUnloadingOnly = xmlFile:getValue(key..".options#rearUnloadingOnly", false)
						spec.frontUnloadingOnly = xmlFile:getValue(key..".options#frontUnloadingOnly", false)
						spec.disableAutoStrap = xmlFile:getValue(key..".options#disableAutoStrap", false)
						spec.zonesOverlap = xmlFile:getValue(key..".options#zonesOverlap", false)
						spec.showDebug = xmlFile:getValue(key..".options#showDebug", UniversalAutoload.showDebug)
						break
					end

					i = i + 1
				end
			end
			xmlFile:delete()
		end
		
		if spec.loadArea ~= nil and spec.loadArea[1] ~= nil and spec.loadArea[1].offset ~= nil
		and spec.loadArea[1].width ~= nil and spec.loadArea[1].length ~= nil and spec.loadArea[1].height ~= nil then
			if UniversalAutoload.showDebug then print("Universal Autoload Enabled: " .. self:getFullName()) end
			spec.isAutoloadEnabled = true
			if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
				UniversalAutoload.VEHICLES[self] = self
			end
		else
			if UniversalAutoload.showDebug then print("Universal Autoload DISABLED: " .. self:getFullName()) end
			spec.isAutoloadEnabled = false
			UniversalAutoload.removeEventListeners(self)
			return
		end
	end

    if self.isServer and self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then

		--initialise server only arrays
		spec.triggers = {}
		spec.loadedObjects = {}
		spec.availableObjects = {}
		spec.autoLoadingObjects = {}
		spec.objectToLoadingAreaIndex = {}
		
		local x0, y0, z0 = math.huge, math.huge, math.huge
		local x1, y1, z1 = -math.huge, -math.huge, -math.huge
		
		for i, loadArea in pairs(spec.loadArea) do
			-- create bounding box for loading area
			local offsetX, offsetY, offsetZ = unpack(spec.loadArea[i].offset)
			loadArea.rootNode = createTransformGroup("LoadAreaCentre")
			link(self.rootNode, loadArea.rootNode)
			setTranslation(loadArea.rootNode, offsetX, offsetY, offsetZ)

			loadArea.startNode = createTransformGroup("LoadAreaStart")
			link(self.rootNode, loadArea.startNode)
			setTranslation(loadArea.startNode, offsetX, offsetY, offsetZ+(loadArea.length/2))
			
			loadArea.endNode = createTransformGroup("LoadAreaEnd")
			link(self.rootNode, loadArea.endNode)
			setTranslation(loadArea.endNode, offsetX, offsetY, offsetZ-(loadArea.length/2))
			
			-- measure bounding box for all loading areas
			if x0 > offsetX-(loadArea.width/2) then x0 = offsetX-(loadArea.width/2) end
			if x1 < offsetX+(loadArea.width/2) then x1 = offsetX+(loadArea.width/2) end
			if y0 > offsetY then y0 = offsetY end
			if y1 < offsetY+(loadArea.height) then y1 = offsetY+(loadArea.height) end
			if z0 > offsetZ-(loadArea.length/2) then z0 = offsetZ-(loadArea.length/2) end
			if z1 < offsetZ+(loadArea.length/2) then z1 = offsetZ+(loadArea.length/2) end
		end
	
		-- create bounding box for all loading areas
		spec.loadVolume = {}
		spec.loadVolume.width = x1-x0
		spec.loadVolume.height = y1-y0
		spec.loadVolume.length = z1-z0
		
		local offsetX, offsetY, offsetZ = (x0+x1)/2, y0, (z0+z1)/2
		
		spec.loadVolume.rootNode = createTransformGroup("loadVolumeCentre")
		link(self.rootNode, spec.loadVolume.rootNode)
		setTranslation(spec.loadVolume.rootNode, offsetX, offsetY, offsetZ)

		spec.loadVolume.startNode = createTransformGroup("loadVolumeStart")
		link(self.rootNode, spec.loadVolume.startNode)
		setTranslation(spec.loadVolume.startNode, offsetX, offsetY, offsetZ+(spec.loadVolume.length/2))
		
		spec.loadVolume.endNode = createTransformGroup("loadVolumeEnd")
		link(self.rootNode, spec.loadVolume.endNode)
		setTranslation(spec.loadVolume.endNode, offsetX, offsetY, offsetZ-(spec.loadVolume.length/2))

		-- load trigger i3d file
		local i3dFilename = UniversalAutoload.path .. "triggers/UniversalAutoloadTriggers.i3d"
		local triggersRootNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)

		-- create triggers
		local unloadingTrigger = {}
		unloadingTrigger.node = I3DUtil.getChildByName(triggersRootNode, "unloadingTrigger")
		if unloadingTrigger.node ~= nil then
			unloadingTrigger.name = "unloadingTrigger"
			link(spec.loadVolume.rootNode, unloadingTrigger.node)
			setRotation(unloadingTrigger.node, 0, 0, 0)
			setTranslation(unloadingTrigger.node, 0, spec.loadVolume.height/2, 0)
			local boundary = spec.loadVolume.width/4
			setScale(unloadingTrigger.node, spec.loadVolume.width-boundary, spec.loadVolume.height, spec.loadVolume.length-boundary)
			
			table.insert(spec.triggers, unloadingTrigger)
            addTrigger(unloadingTrigger.node, "unloadingTrigger_Callback", self)
		end
		
		local playerTrigger = {}
		playerTrigger.node = I3DUtil.getChildByName(triggersRootNode, "playerTrigger")
		if playerTrigger.node ~= nil then
			playerTrigger.name = "playerTrigger"
			link(spec.loadVolume.rootNode, playerTrigger.node)
			setRotation(playerTrigger.node, 0, 0, 0)
			setTranslation(playerTrigger.node, 0, spec.loadVolume.height/2, 0)
			setScale(playerTrigger.node, 5*spec.loadVolume.width, 2*spec.loadVolume.height, spec.loadVolume.length+2*spec.loadVolume.width)
			
			table.insert(spec.triggers, playerTrigger)
            addTrigger(playerTrigger.node, "playerTrigger_Callback", self)
		end

		if not UniversalAutoload.manualLoadingOnly then

			if not spec.rearUnloadingOnly and not spec.frontUnloadingOnly then
				local leftPickupTrigger = {}
				leftPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "leftPickupTrigger")
				if leftPickupTrigger.node ~= nil then
					leftPickupTrigger.name = "leftPickupTrigger"
					link(spec.loadVolume.rootNode, leftPickupTrigger.node)
					
					local width, height, length = 1.66*spec.loadVolume.width, 2*spec.loadVolume.height, spec.loadVolume.length+spec.loadVolume.width/2

					setRotation(leftPickupTrigger.node, 0, 0, 0)
					setTranslation(leftPickupTrigger.node, 1.1*(width+spec.loadVolume.width)/2, 0, 0)
					setScale(leftPickupTrigger.node, width, height, length)

					table.insert(spec.triggers, leftPickupTrigger)
					addTrigger(leftPickupTrigger.node, "loadingTrigger_Callback", self)
				end
				
				local rightPickupTrigger = {}
				rightPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "rightPickupTrigger")
				if rightPickupTrigger.node ~= nil then
					rightPickupTrigger.name = "rightPickupTrigger"
					link(spec.loadVolume.rootNode, rightPickupTrigger.node)
					
					local width, height, length = 1.66*spec.loadVolume.width, 2*spec.loadVolume.height, spec.loadVolume.length+spec.loadVolume.width/2

					setRotation(rightPickupTrigger.node, 0, 0, 0)
					setTranslation(rightPickupTrigger.node, -1.1*(width+spec.loadVolume.width)/2, 0, 0)
					setScale(rightPickupTrigger.node, width, height, length)

					table.insert(spec.triggers, rightPickupTrigger)
					addTrigger(rightPickupTrigger.node, "loadingTrigger_Callback", self)
				end
			end
			
			if spec.rearUnloadingOnly then
				local rearPickupTrigger = {}
				rearPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "rearPickupTrigger")
				if rearPickupTrigger.node ~= nil then
					rearPickupTrigger.name = "rearPickupTrigger"
					link(spec.loadVolume.rootNode, rearPickupTrigger.node)
					
					local squareSide = spec.loadVolume.length+spec.loadVolume.width
					local width, height, length = squareSide, 2*spec.loadVolume.height, 0.8*squareSide

					setRotation(rearPickupTrigger.node, 0, 0, 0)
					setTranslation(rearPickupTrigger.node, 0, 0, -1.1*(length+spec.loadVolume.length)/2)
					setScale(rearPickupTrigger.node, width, height, length)

					table.insert(spec.triggers, rearPickupTrigger)
					addTrigger(rearPickupTrigger.node, "loadingTrigger_Callback", self)
				end
			end
			
			if spec.frontUnloadingOnly then
				local frontPickupTrigger = {}
				frontPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "frontPickupTrigger")
				if frontPickupTrigger.node ~= nil then
					frontPickupTrigger.name = "frontPickupTrigger"
					link(spec.loadVolume.rootNode, frontPickupTrigger.node)
					
					local squareSide = spec.loadVolume.length+spec.loadVolume.width
					local width, height, length = squareSide, 2*spec.loadVolume.height, 0.8*squareSide

					setRotation(frontPickupTrigger.node, 0, 0, 0)
					setTranslation(frontPickupTrigger.node, 0, 0, 1.1*(length+spec.loadVolume.length)/2)
					setScale(frontPickupTrigger.node, width, height, length)

					table.insert(spec.triggers, frontPickupTrigger)
					addTrigger(frontPickupTrigger.node, "loadingTrigger_Callback", self)
				end
			end
		end
		
		if UniversalAutoload.manualLoadingOnly or spec.enableRearLoading or spec.rearUnloadingOnly then
			local rearAutoTrigger = {}
			rearAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "rearAutoTrigger")
			if rearAutoTrigger.node ~= nil then
				rearAutoTrigger.name = "rearAutoTrigger"
				link(spec.loadVolume.rootNode, rearAutoTrigger.node)
				
				local depth = 0.05
				local recess = spec.loadVolume.width/4
				local boundary = spec.loadVolume.width/4
				local width, height, length = spec.loadVolume.width-boundary, spec.loadVolume.height, depth

				setRotation(rearAutoTrigger.node, 0, 0, 0)
				setTranslation(rearAutoTrigger.node, 0, spec.loadVolume.height/2, recess-(spec.loadVolume.length/2)-depth )
				setScale(rearAutoTrigger.node, width, height, length)

				table.insert(spec.triggers, rearAutoTrigger)
				addTrigger(rearAutoTrigger.node, "autoLoadingTrigger_Callback", self)
				spec.rearTriggerId = rearAutoTrigger.node
			end
		end
		
		if UniversalAutoload.manualLoadingOnly or spec.enableSideLoading then
			local depth = 0.05
			local recess = spec.loadVolume.width/7
			local boundary = 2*spec.loadVolume.width/3
			local width, height, length = depth, spec.loadVolume.height, spec.loadVolume.length-boundary
				
			local leftAutoTrigger = {}
			leftAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "leftAutoTrigger")
			if leftAutoTrigger.node ~= nil then
				leftAutoTrigger.name = "leftAutoTrigger"
				link(spec.loadVolume.rootNode, leftAutoTrigger.node)

				setRotation(leftAutoTrigger.node, 0, 0, 0)
				setTranslation(leftAutoTrigger.node, 2*depth+(spec.loadVolume.width/2)-recess, spec.loadVolume.height/2, 0)
				setScale(leftAutoTrigger.node, width, height, length)

				table.insert(spec.triggers, leftAutoTrigger)
				addTrigger(leftAutoTrigger.node, "autoLoadingTrigger_Callback", self)
			end
			local rightAutoTrigger = {}
			rightAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "rightAutoTrigger")
			if rightAutoTrigger.node ~= nil then
				rightAutoTrigger.name = "rightAutoTrigger"
				link(spec.loadVolume.rootNode, rightAutoTrigger.node)
	
				setRotation(rightAutoTrigger.node, 0, 0, 0)
				setTranslation(rightAutoTrigger.node, -(2*depth+(spec.loadVolume.width/2)-recess), spec.loadVolume.height/2, 0)
				setScale(rightAutoTrigger.node, width, height, length)

				table.insert(spec.triggers, rightAutoTrigger)
				addTrigger(rightAutoTrigger.node, "autoLoadingTrigger_Callback", self)
			end
		end
		
		delete(triggersRootNode)

		--server only
		spec.isLoading = false
		spec.isUnloading = false
		spec.doPostLoadDelay = false
		spec.doSetTensionBelts = false
		spec.totalAvailableCount = 0
		spec.availableBaleCount = 0
		spec.totalUnloadCount = 0
		spec.validLoadCount = 0
		spec.validUnloadCount = 0

	end

	--client+server
	spec.actionEvents = {}
	spec.playerInTrigger = {}
	spec.currentTipside = "left"
	spec.currentLoadside = "both"
	spec.currentMaterialIndex = 1
	spec.currentContainerIndex = 1
	spec.currentLoadingFilter = true

end

-- "ON POST LOAD" CALLED AFTER VEHICLE IS LOADED
function UniversalAutoload:onPostLoad(savegame)
    if self.isServer and savegame ~= nil and self.spec_universalAutoload ~= nil then
		local spec = self.spec_universalAutoload
		
		if spec.isAutoloadEnabled then
			if savegame.resetVehicles then
				--client+server
				spec.currentTipside = "left"
				spec.currentLoadside = "both"
				spec.currentMaterialIndex = 1
				spec.currentContainerIndex = 1
				spec.currentLoadingFilter = true
			else
				--client+server
				spec.currentTipside = savegame.xmlFile:getValue(savegame.key..".universalAutoload#tipside", "left")
				spec.currentLoadside = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadside", "both")
				spec.currentMaterialIndex = savegame.xmlFile:getValue(savegame.key..".universalAutoload#materialIndex", 1)
				spec.currentContainerIndex = savegame.xmlFile:getValue(savegame.key..".universalAutoload#containerIndex", 1)
				spec.currentLoadingFilter = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadingFilter", true)
				--server only
				spec.currentLoadWidth = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadWidth", 0)
				spec.currentLoadLength = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadLength", 0)
				spec.currentLoadHeight = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadHeight", 0)
				spec.currentActualWidth = savegame.xmlFile:getValue(savegame.key..".universalAutoload#actualWidth", 0)
				spec.currentActualLength = savegame.xmlFile:getValue(savegame.key..".universalAutoload#actualLength", 0)
				spec.currentLoadAreaIndex = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadAreaIndex", 1)
				spec.resetLoadingPattern = false
			end
		end
	
	end
end

-- "SAVE TO XML FILE" CALLED DURING GAME SAVE
function UniversalAutoload:saveToXMLFile(xmlFile, key, usedModNames)
	if self.spec_universalAutoload ~= nil then
		local spec = self.spec_universalAutoload
		if spec.isAutoloadEnabled then
			-- print("UniversalAutoload - saveToXMLFile: "..self:getFullName())
			if spec.resetLoadingPattern ~= false then
				UniversalAutoload.resetLoadingPattern(self)
			end
		
			-- HACK (FOR NOW) - need to find out if this can be avoided..
			local correctedKey = key:gsub(UniversalAutoload.name..".", "")
			--client+server
			xmlFile:setValue(correctedKey.."#tipside", spec.currentTipside or "left")
			xmlFile:setValue(correctedKey.."#loadside", spec.currentLoadside or "both")
			xmlFile:setValue(correctedKey.."#materialIndex", spec.currentMaterialIndex or 1)
			xmlFile:setValue(correctedKey.."#containerIndex", spec.currentContainerIndex or 1)
			xmlFile:setValue(correctedKey.."#loadingFilter", spec.currentLoadingFilter or true)
			--server only
			xmlFile:setValue(correctedKey.."#loadWidth", spec.currentLoadWidth or 0)
			xmlFile:setValue(correctedKey.."#loadHeight", spec.currentLoadHeight or 0)
			xmlFile:setValue(correctedKey.."#loadLength", spec.currentLoadLength or 0)
			xmlFile:setValue(correctedKey.."#actualWidth", spec.currentActualWidth or 0)
			xmlFile:setValue(correctedKey.."#actualLength", spec.currentActualLength or 0)
			xmlFile:setValue(correctedKey.."#loadAreaIndex", spec.currentLoadAreaIndex or 1)
		end
	end
end

-- "ON DELETE" CLEANUP TRIGGER NODES
function UniversalAutoload:onPreDelete()
	-- print("UniversalAutoload - onPreDelete")
	local spec = self.spec_universalAutoload
	if UniversalAutoload.VEHICLES[self] ~= nil then
		-- print("PRE DELETE: " .. self:getFullName() )
		UniversalAutoload.VEHICLES[self] = nil
	end
    if self.isServer then
        if spec.triggers ~= nil then
			for _, trigger in pairs(spec.triggers) do
				removeTrigger(trigger.node)
			end            
        end
    end
end
--
function UniversalAutoload:onDelete()
	-- print("UniversalAutoload - onDelete")
    local spec = self.spec_universalAutoload
	if UniversalAutoload.VEHICLES[self] ~= nil then
		-- print("DELETE: " .. self:getFullName() )
		UniversalAutoload.VEHICLES[self] = nil
	end
    if spec.isAutoloadEnabled and self.isServer then
        if spec.triggers ~= nil then
			for _, trigger in pairs(spec.triggers) do
				removeTrigger(trigger.node)
			end            
        end
    end
end


-- SET FOLDING STATE FLAG ON FOLDING STATE CHANGE
function UniversalAutoload:onFoldStateChanged(direction, moveToMiddle)
	--if self.isClient and g_dedicatedServer==nil then
	local spec = self.spec_universalAutoload
	if spec.isAutoloadEnabled and self.isServer then
		-- print("onFoldStateChanged: "..self:getFullName())
		spec.foldAnimationStarted = true
		UniversalAutoload.updateActionEventText(self)
	end
end
--
function UniversalAutoload:getIsFolding()

	for _, foldingPart in pairs(self.spec_foldable.foldingParts) do
		if self:getIsAnimationPlaying(foldingPart.animationName) then
			return true
		end
	end
	
	return false
end
--
function UniversalAutoload:getIsCovered()

	if self.spec_cover ~= nil and self.spec_cover.hasCovers then
		return self.spec_cover.state == 0
	else
		return false
	end
end
--
function UniversalAutoload:getIsFilled()

	local isFilled = false
	if self.spec_fillVolume ~= nil then
		for _, fillVolume in ipairs(self.spec_fillVolume.volumes) do
			local capacity = self:getFillUnitCapacity(fillVolume.fillUnitIndex)
			local fillLevel = self:getFillUnitFillLevel(fillVolume.fillUnitIndex)
			if fillLevel > 0 then
				isFilled = true
			end
		end
	end
	return isFilled
end
--
function UniversalAutoload:getIsMoving()
	return self.lastSpeedReal > 0.0005
end


-- NETWORKING FUNCTIONS
function UniversalAutoload:onReadStream(streamId, connection)
	-- print("onReadStream")
    local spec = self.spec_universalAutoload
	
	if streamReadBool(streamId) then
		print("Universal Autoload Enabled: " .. self:getFullName())
		spec.isAutoloadEnabled = true
		spec.currentTipside = streamReadString(streamId)
		spec.currentLoadside = streamReadString(streamId)
		spec.currentMaterialIndex = streamReadInt32(streamId)
		spec.currentContainerIndex = streamReadInt32(streamId)
		spec.currentLoadingFilter = streamReadBool(streamId)
		spec.isLoading = streamReadBool(streamId)
		spec.isUnloading = streamReadBool(streamId)
		spec.validLoadCount = streamReadInt32(streamId)
		spec.validUnloadCount = streamReadInt32(streamId)
		
		UniversalAutoload.disableAutoStrap = streamReadBool(streamId)
		UniversalAutoload.manualLoadingOnly = streamReadBool(streamId)
		
		if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
			UniversalAutoload.VEHICLES[self] = self
		end
	else
		print("Universal Autoload Disabled: " .. self:getFullName())
		spec.isAutoloadEnabled = false
		UniversalAutoload.removeEventListeners(self)
	end
end
--
function UniversalAutoload:onWriteStream(streamId, connection)
	-- print("onWriteStream")
    local spec = self.spec_universalAutoload
	
	streamWriteBool(streamId, spec.isAutoloadEnabled)
	if spec.isAutoloadEnabled then
		spec.currentTipside = spec.currentTipside or "left"
		spec.currentLoadside = spec.currentLoadside or "both"
		spec.currentMaterialIndex = spec.currentMaterialIndex or 1
		spec.currentContainerIndex = spec.currentContainerIndex or 1
		spec.currentLoadingFilter = spec.currentLoadingFilter or true
		spec.isLoading = spec.isLoading or false
		spec.isUnloading = spec.isUnloading or false
		spec.validLoadCount = spec.validLoadCount or 0
		spec.validUnloadCount = spec.validUnloadCount or 0
		UniversalAutoload.disableAutoStrap = UniversalAutoload.disableAutoStrap or false
		UniversalAutoload.manualLoadingOnly = UniversalAutoload.manualLoadingOnly or false
		
		streamWriteString(streamId, spec.currentTipside)
		streamWriteString(streamId, spec.currentLoadside)
		streamWriteInt32(streamId, spec.currentMaterialIndex)
		streamWriteInt32(streamId, spec.currentContainerIndex)
		streamWriteBool(streamId, spec.currentLoadingFilter)
		streamWriteBool(streamId, spec.isLoading)
		streamWriteBool(streamId, spec.isUnloading)
		streamWriteInt32(streamId, spec.validLoadCount)
		streamWriteInt32(streamId, spec.validUnloadCount)
		
		streamWriteBool(streamId, UniversalAutoload.disableAutoStrap)
		streamWriteBool(streamId, UniversalAutoload.manualLoadingOnly)
	end
end

-- MAIN AUTOLOAD ONUPDATE LOOP
function UniversalAutoload:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	-- print("UniversalAutoload - onUpdate")
	local spec = self.spec_universalAutoload
	
	if not spec.isAutoloadEnabled then
		return
	end

	local playerActive = spec.playerInTrigger[g_currentMission.player.userId] == true
	if self.isClient and isActiveForInputIgnoreSelection or playerActive then
		spec.menuDelayTime = spec.menuDelayTime or 0
		if spec.menuDelayTime > UniversalAutoload.delayTime/2 then
			spec.menuDelayTime = 0

			if spec.updateToggleLoading then
				if debugKeys then print("*** clearActionEvents ***") end
				UniversalAutoload.clearActionEvents(self)
				UniversalAutoload.updateActionEventKeys(self)
				if debugKeys then print("  UPDATE Toggle Loading") end
				spec.updateToggleLoading=false
				UniversalAutoload.updateToggleLoadingActionEvent(self)
			end
			if spec.updateCycleMaterial then
				if debugKeys then print("  UPDATE Cycle Material") end
				spec.updateCycleMaterial = false
				UniversalAutoload.updateCycleMaterialActionEvent(self)
			end
			if spec.updateCycleContainer then
				if debugKeys then print("  UPDATE Cycle Container") end
				spec.updateCycleContainer = false
				UniversalAutoload.updateCycleContainerActionEvent(self)
			end
			if spec.updateToggleDoor then
				if debugKeys then print("  UPDATE Toggle Door") end
				spec.updateToggleDoor=false
				UniversalAutoload.updateToggleDoorActionEvent(self)
			end
			if spec.updateToggleCurtain then
				if debugKeys then print("  UPDATE Toggle Curtain") end
				spec.updateToggleCurtain=false
				UniversalAutoload.updateToggleCurtainActionEvent(self)
			end
			if spec.updateToggleTipside then
				if debugKeys then print("  UPDATE Toggle Tipside") end
				spec.updateToggleTipside=false
				UniversalAutoload.updateToggleTipsideActionEvent(self)
			end
			if spec.updateToggleBelts then
				if debugKeys then print("  UPDATE Toggle Belts") end
				spec.updateToggleBelts=false
				UniversalAutoload.updateToggleBeltsActionEvent(self)
			end
			if spec.updateToggleFilter then
				if debugKeys then print("  UPDATE Toggle Filter") end
				spec.updateToggleFilter=false
				UniversalAutoload.updateToggleFilterActionEvent(self)
			end
		else
			spec.menuDelayTime = spec.menuDelayTime + dt
		end
	end
	
	if spec.isAutoloadEnabled and self.isServer then
	
		-- DETECT WHEN FOLDING STOPS IF IT WAS STARTED
		if spec.foldAnimationStarted then
			if not self:getIsFolding() then
				-- print("*** FOLDING COMPLETE ***")
				spec.foldAnimationStarted = false
				UniversalAutoload.updateActionEventText(self)
			end
		end
		
		-- DETECT WHEN COVER STATE CHANGES
		if self.spec_cover ~= nil and self.spec_cover.hasCovers then
			if spec.lastCoverState ~= self.spec_cover.state then
				-- print("*** COVERS CHANGED STATE ***")
				spec.lastCoverState = self.spec_cover.state
				UniversalAutoload.updateActionEventText(self)
			end
		end


		-- ALWAYS LOAD THE AUTO LOADING PALLETS
		if spec.autoLoadingObjects ~= nil then
			for _, object in pairs(spec.autoLoadingObjects) do
				-- print("LOADING PALLET FROM AUTO TRIGGER")
				if not UniversalAutoload.getPalletIsSelectedMaterial(self, object) then
					UniversalAutoload.setMaterialTypeIndex(self, 1)
				end
				if not UniversalAutoload.getPalletIsSelectedContainer(self, object) then
					UniversalAutoload.setContainerTypeIndex(self, 1)
				end
				self:setAllTensionBeltsActive(false)
				-- *** Don't set belts as they can grab the pallet forks ***
				-- spec.doSetTensionBelts = true -- spec.doPostLoadDelay = true
				if UniversalAutoload.loadObject(self, object) then
					-- print("LOADED PALLET FROM AUTO TRIGGER")
					spec.autoLoadingObjects[object] = nil
				else
					--UNABLE_TO_LOAD_OBJECT
					UniversalAutoload.showWarningMessage(self, 3)
				end
			end
		end
		
		-- CREATE AND LOAD BALES (IF REQUESTED)
		if spec.spawnBales then
			spec.spawnBalesDelayTime = spec.spawnBalesDelayTime or 0
			if spec.spawnBalesDelayTime > UniversalAutoload.delayTime/4 then
				spec.spawnBalesDelayTime = 0
				bale = spec.baleToSpawn
				local baleObject = UniversalAutoload.createBale(self, bale.xmlFile, bale.fillTypeIndex, bale.wrapState)
				if not UniversalAutoload.loadObject(self, baleObject) then
					baleObject:delete()
				end
				if spec.currentLoadingPlace == nil then
					spec.spawnBales = false
					self:setAllTensionBeltsActive(true)
					if debugConsole then print("..adding bales complete!") end
				end
			else
				spec.spawnBalesDelayTime = spec.spawnBalesDelayTime + dt
			end
		end
		
		-- CREATE AND LOAD PALLETS (IF REQUESTED)
		if spec.spawnPallets and not spec.spawningPallet then
			spec.spawnPalletsDelayTime = spec.spawnPalletsDelayTime or 0
			if spec.spawnPalletsDelayTime > UniversalAutoload.delayTime/4 then
				spec.spawnPalletsDelayTime = 0

				local i = math.random(1, #spec.palletsToSpawn)
				pallet = spec.palletsToSpawn[i]
				if spec.lastSpawnedPallet then
					if math.random(1, 100) > 50 then
						pallet = spec.lastSpawnedPallet
					end
				end
				UniversalAutoload.createPallet(self, pallet)
				spec.lastSpawnedPallet = pallet
			else
				spec.spawnPalletsDelayTime = spec.spawnPalletsDelayTime + dt
			end
		end
		
		-- CHECK IF ANY PLAYERS ARE ACTIVE ON FOOT
		local playerTriggerActive = false
		if not isActiveForInputIgnoreSelection then
			for k, v in pairs (spec.playerInTrigger) do
				playerTriggerActive = true
			end
		end

		local isActiveForLoading = spec.isLoading or spec.isUnloading or spec.doPostLoadDelay
		if isActiveForInputIgnoreSelection or isActiveForLoading or playerTriggerActive or spec.baleCollectionModeDeactivated then
		
			if spec.baleCollectionMode and not isActiveForLoading then
				if spec.availableBaleCount > 0 and not spec.trailerIsFull then
					UniversalAutoload.startLoading(self)
				end
			end
			
			-- RETURN BALES TO PHYSICS WHEN NOT MOVING
			if spec.baleCollectionModeDeactivated and not self:getIsMoving() then
				-- print("ADDING BALES BACK TO PHYSICS")
				spec.baleCollectionModeDeactivated = false
				for object,_ in pairs(spec.loadedObjects) do
					if object ~= nil and object.isRoundbale~=nil then
						UniversalAutoload.unlinkObject(object)
						UniversalAutoload.addToPhysics(self, object)
					end
				end
				if not UniversalAutoload.disableAutoStrap then
					self:setAllTensionBeltsActive(false)
					spec.doSetTensionBelts = true
					spec.doPostLoadDelay = true
				end
				UniversalAutoload.updateActionEventText(self)
			end

			-- LOAD ALL ANIMATION SEQUENCE
			if spec.isLoading then
				spec.loadDelayTime = spec.loadDelayTime or 0
				if spec.loadDelayTime > UniversalAutoload.delayTime then
					local lastObjectType = nil
					local loadedObject = false
					for index, object in ipairs(spec.sortedObjectsToLoad) do
						lastObjectType = UniversalAutoload.getContainerType(object)
						if UniversalAutoload.loadObject(self, object) then
							loadedObject = true
							if spec.firstAttemptToLoad then
								spec.firstAttemptToLoad = false
								self:setAllTensionBeltsActive(false)
							end
							spec.loadDelayTime = 0
						end
						table.remove(spec.sortedObjectsToLoad, index)
						break
					end
					if not loadedObject then
						if #spec.sortedObjectsToLoad > 0 and lastObjectType ~= nil then
							local i = 1
							for _ = 1, #spec.sortedObjectsToLoad do
								local nextObject = spec.sortedObjectsToLoad[i]
								if lastObjectType == UniversalAutoload.getContainerType(nextObject) then
									-- print("DELETE SAME OBJECT TYPE: "..lastObjectType.name)
									table.remove(spec.sortedObjectsToLoad, i)
								else
									i = i + 1
								end
							end
						end
						if #spec.sortedObjectsToLoad > 0 then
							if spec.trailerIsFull or (UniversalAutoload.testLoadAreaIsEmpty(self) and not spec.baleCollectionMode) then
								if UniversalAutoload.showDebug then print("RESET PATTERN to fill in any gaps") end
								spec.partiallyUnloaded = true
								spec.resetLoadingPattern = true
							end
						else
							if spec.firstAttemptToLoad and not spec.baleCollectionMode and not self:getIsMoving() then
								--UNABLE_TO_LOAD_OBJECT
								UniversalAutoload.showWarningMessage(self, 3)
								spec.partiallyUnloaded = true
								spec.resetLoadingPattern = true
							end
							if UniversalAutoload.showDebug then print("STOP LOADING") end
							UniversalAutoload.stopLoading(self)
						end
					end
				else
					spec.loadDelayTime = spec.loadDelayTime + dt
				end
			end
			
			-- DELAY AFTER LOAD/UNLOAD FOR MP POSITION SYNC
			if spec.doPostLoadDelay then
				spec.postLoadDelayTime = spec.postLoadDelayTime or 0
				local mpDelay = g_currentMission.missionDynamicInfo.isMultiplayer and 1000 or 0
				if spec.postLoadDelayTime > UniversalAutoload.delayTime + mpDelay then
					UniversalAutoload.resetLoadingState(self)
				else
					spec.postLoadDelayTime = spec.postLoadDelayTime + dt
				end
			end
			
			UniversalAutoload.determineTipside(self)
			UniversalAutoload.countActivePallets(self)
			UniversalAutoload.drawDebugDisplay(self, isActiveForInput)

		end
	end
end
--
function UniversalAutoload:onActivate(isControlling)
	-- print("onActivate: "..self:getFullName())
	if UniversalAutoload.showDebug then print("*** "..self:getFullName().." ***") end
	local spec = self.spec_universalAutoload
	if spec.isAutoloadEnabled and self.isServer then
		UniversalAutoload.forceRaiseActive(self, true)
	end
end
--
function UniversalAutoload:onDeactivate()
	-- print("onDeactivate: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if spec.isAutoloadEnabled and self.isServer then
		UniversalAutoload.forceRaiseActive(self, false)
	end
	UniversalAutoload:clearActionEvents(self)
end
--
function UniversalAutoload:determineTipside()
	-- currently only used for the KRONE Profi Liner Curtain Trailer
	local spec = self.spec_universalAutoload

	--<trailer tipSideIndex="1" doorState="false" tipAnimationTime="1.000000" tipState="2"/>
	if spec.isAutoloadEnabled and spec.isCurtainTrailer and self.spec_trailer ~= nil then
		if self.spec_trailer.tipState == 2 then
			local tipSide = self.spec_trailer.tipSides[self.spec_trailer.currentTipSideIndex]
			
			if spec.currentTipside ~= "left" and string.find(tipSide.animation.name, "Left") then
				-- print("SET SIDE = LEFT")
				UniversalAutoload.setCurrentTipside(self, "left")
				UniversalAutoload.setCurrentLoadside(self, "left")	
			end
			if spec.currentTipside ~= "right" and string.find(tipSide.animation.name, "Right") then
				-- print("SET SIDE = RIGHT")
				UniversalAutoload.setCurrentTipside(self, "right")
				UniversalAutoload.setCurrentLoadside(self, "right")	
			end
		else
			if spec.currentTipside ~= "none" then
				-- print("SET SIDE = NONE")
				UniversalAutoload.setCurrentTipside(self, "none")
				UniversalAutoload.setCurrentLoadside(self, "none")
			end
		end
	end
end
--
function UniversalAutoload:isValidForLoading(object)
	local spec = self.spec_universalAutoload
	
	if spec.baleCollectionMode and object.isRoundbale==nil then
		return false
	end
	if object.isRoundbale ~= nil and object.mountObject then
		return false
	end

	return UniversalAutoload.getPalletIsSelectedMaterial(self, object) and UniversalAutoload.getPalletIsSelectedContainer(self, object) and 
	(spec.autoLoadingObjects[object] ~= nil or ( spec.loadedObjects[object] == nil and UniversalAutoload.getPalletIsSelectedLoadside(self, object) )) and
	(not spec.currentLoadingFilter or (spec.currentLoadingFilter and UniversalAutoload.getPalletIsFull(object)) )
end
--
function UniversalAutoload:isValidForUnloading(object)
	local spec = self.spec_universalAutoload

	return UniversalAutoload.getPalletIsSelectedMaterial(self, object) and UniversalAutoload.getPalletIsSelectedContainer(self, object) and spec.autoLoadingObjects[object] == nil
end
--
function UniversalAutoload.isValidForManualLoading(object)
	if object.dynamicMountObject ~= nil then
		return true
	end
	if g_currentMission.player ~= nil then
		local rootNode = UniversalAutoload.getObjectNode(object)
		if g_currentMission.player.pickedUpObject == rootNode then
			return true
		end
	end
end
--
function UniversalAutoload:countActivePallets()
	-- print("COUNT ACTIVE PALLETS")
	local spec = self.spec_universalAutoload
	local isActiveForLoading = spec.isLoading or spec.isUnloading or spec.doPostLoadDelay
	
	local totalAvailableCount = 0
	local validLoadCount = 0
	if spec.availableObjects ~= nil then
		for _, object in pairs(spec.availableObjects) do
			if object ~= nil then
				totalAvailableCount = totalAvailableCount + 1
				if UniversalAutoload.isValidForLoading(self, object) then
					validLoadCount = validLoadCount + 1
				end
				if isActiveForLoading then
					UniversalAutoload.raiseObjectDirtyFlags(object)
				end
			end
		end
	end
	
	local totalUnloadCount = 0
	local validUnloadCount = 0
	if spec.loadedObjects ~= nil then
		for object,_ in pairs(spec.loadedObjects) do
			if object ~= nil then
				totalUnloadCount = totalUnloadCount + 1
				if UniversalAutoload.isValidForUnloading(self, object) then
					validUnloadCount = validUnloadCount + 1
				end
				if isActiveForLoading then
					UniversalAutoload.raiseObjectDirtyFlags(object)
				end
			end
		end
	end

	if (spec.validLoadCount ~= validLoadCount) or (spec.validUnloadCount ~= validUnloadCount) then
		if spec.validLoadCount ~= validLoadCount then
			spec.validLoadCount = validLoadCount
		end
		if spec.validUnloadCount ~= validUnloadCount then
			spec.validUnloadCount = validUnloadCount
		end
		UniversalAutoload.updateActionEventText(self)
	end

	if UniversalAutoload.showDebug then
		if spec.totalAvailableCount ~= totalAvailableCount then
			print("TOTAL AVAILABLE COUNT ERROR: "..tostring(spec.totalAvailableCount).." vs "..tostring(totalAvailableCount))
			spec.totalAvailableCount = totalAvailableCount
		end
		if spec.totalUnloadCount ~= totalUnloadCount then
			print("TOTAL UNLOAD COUNT ERROR: "..tostring(spec.totalUnloadCount).." vs "..tostring(totalUnloadCount))
			spec.totalUnloadCount = totalUnloadCount
		end
	end
end
--
function UniversalAutoload:createBoundingBox()
	local spec = self.spec_universalAutoload

	if next(spec.loadedObjects) then
		spec.boundingBox = {}
		
		local x0, y0, z0 = math.huge, math.huge, math.huge
		local x1, y1, z1 = -math.huge, -math.huge, -math.huge
		for _, object in pairs(spec.loadedObjects) do
			-- print("  loaded object: " .. tostring(object.id).." ("..tostring(object.currentSavegameId or "BALE")..")")
			
			local node = UniversalAutoload.getObjectNode(object)
			if node ~= nil then
			
				local containerType = UniversalAutoload.getContainerType(object)
				local w, h, l = containerType.sizeX, containerType.sizeY, containerType.sizeZ
				local xx,xy,xz = localDirectionToLocal(node, spec.loadVolume.rootNode, w,0,0)
				local yx,yy,yz = localDirectionToLocal(node, spec.loadVolume.rootNode, 0,h,0)
				local zx,zy,zz = localDirectionToLocal(node, spec.loadVolume.rootNode, 0,0,l)
				
				local W, H, L = math.abs(xx+yx+zx), math.abs(xy+yy+zy), math.abs(xz+yz+zz)
				if containerType.flipYZ then
					L, H = math.abs(xy+yy+zy), math.abs(xz+yz+zz)
				end
				
				local X, Y, Z = localToLocal(node, spec.loadVolume.rootNode, 0, 0, 0)
				if containerType.isBale then Y = Y-(H/2) end
				
				-- include object in bounding box
				if x0 > X-(W/2) then x0 = X-(W/2) end
				if x1 < X+(W/2) then x1 = X+(W/2) end
				if y0 > Y then y0 = Y end
				if y1 < Y+(H) then y1 = Y+(H) end
				if z0 > Z-(L/2) then z0 = Z-(L/2) end
				if z1 < Z+(L/2) then z1 = Z+(L/2) end
				
			end
		end
		
		-- create bounding box for all objects
		local width = x1-x0
		local height = y1-y0
		local length = z1-z0
		
		local offsetX, offsetY, offsetZ = (x0+x1)/2, y0, (z0+z1)/2
		
		if UniversalAutoload.showDebug then
			print(string.format("(W,H,L) = (%f, %f, %f)", width, height, length))
			print(string.format("(X,Y,Z) = (%f, %f, %f)", offsetX, offsetY, offsetZ))
			print(string.format("(X0,Y0,Z0) = (%f, %f, %f)", localToWorld(spec.loadVolume.rootNode, 0, 0, 0)))
		end

		spec.boundingBox.rootNode = createTransformGroup("loadVolumeCentre")
		link(spec.loadVolume.rootNode, spec.boundingBox.rootNode)
		setTranslation(spec.boundingBox.rootNode, offsetX, offsetY, offsetZ)
		
		spec.boundingBox.width = x1-x0
		spec.boundingBox.height = y1-y0
		spec.boundingBox.length = z1-z0
	else
		spec.boundingBox = nil
	end
end

-- LOADING AND UNLOADING FUNCTIONS
function UniversalAutoload:loadObject(object)
	-- print("UniversalAutoload - loadObject")
	if object ~= nil and UniversalAutoload.getIsLoadingVehicleAllowed(self) and UniversalAutoload.isValidForLoading(self, object) then

		local spec = self.spec_universalAutoload
		local containerType = UniversalAutoload.getContainerType(object)
		local loadPlace = UniversalAutoload.getLoadPlace(self, containerType, object)
		if loadPlace ~= nil then

			if UniversalAutoload.moveObjectNodes(self, object, loadPlace, spec.baleCollectionMode) then
				UniversalAutoload.clearPalletFromAllVehicles(self, object)
				UniversalAutoload.addLoadedObject(self, object)
				
				if UniversalAutoload.pricePerPallet > 0 then
					g_currentMission:addMoney(-UniversalAutoload.pricePerPallet, self:getOwnerFarmId(), MoneyType.AI)
				end
			
				if UniversalAutoload.showDebug then print(string.format("LOADED OBJECT: %s [%.3f, %.3f, %.3f]",
					containerType.name, containerType.sizeX, containerType.sizeY, containerType.sizeZ)) end
				return true
			end
		end

	end

	return false
end
--
function UniversalAutoload:unloadObject(object, unloadPlace)
	-- print("UniversalAutoload - unloadObject")
	if object ~= nil and UniversalAutoload.isValidForUnloading(self, object) then
	
		if UniversalAutoload.moveObjectNodes(self, object, unloadPlace) then
			UniversalAutoload.clearPalletFromAllVehicles(self, object)
			UniversalAutoload.addAvailableObject(self, object)
			return true
		end
	end
end
--
function UniversalAutoload.buildObjectsToUnloadTable(vehicle)
	local spec = vehicle.spec_universalAutoload
	
	spec.objectsToUnload = {}
	spec.unloadingAreaClear = true
	
	
	local _, HEIGHT, _ = getTranslation(spec.loadVolume.rootNode)
	for _, object in pairs(spec.loadedObjects) do
		if UniversalAutoload.isValidForUnloading(vehicle, object) then
		
			local node = UniversalAutoload.getObjectNode(object)
			if node ~= nil then
				x, y, z = localToLocal(node, spec.loadVolume.rootNode, 0, 0, 0)
				rx, ry, rz = localRotationToLocal(node, spec.loadVolume.rootNode, 0, 0, 0)
				
				local unloadPlace = {}
				local containerType = UniversalAutoload.getContainerType(object)
				unloadPlace.sizeX = containerType.sizeX
				unloadPlace.sizeY = containerType.sizeY
				unloadPlace.sizeZ = containerType.sizeZ
				if containerType.flipYZ then
					unloadPlace.sizeY = containerType.sizeZ
					unloadPlace.sizeZ = containerType.sizeY
					unloadPlace.wasFlippedYZ = true
				end
				
				local offsetX = 0
				local offsetZ = 0
				
				if spec.frontUnloadingOnly then
					offsetZ = spec.loadVolume.length + spec.loadVolume.width/2
				elseif spec.rearUnloadingOnly then
					offsetZ = -spec.loadVolume.length - spec.loadVolume.width/2
				else
					offsetX = 1.5*spec.loadVolume.width
					if spec.currentTipside == "right" then offsetX = -offsetX end
				end

				unloadPlace.node = createTransformGroup("unloadPlace")
				link(spec.loadVolume.rootNode, unloadPlace.node)
				setTranslation(unloadPlace.node, x+offsetX, y, z+offsetZ)
				setRotation(unloadPlace.node, rx, ry, rz)

				local X, Y, Z = getWorldTranslation(unloadPlace.node)
				local heightAboveGround = DensityMapHeightUtil.getCollisionHeightAtWorldPos(X, Y, Z) + 0.1
				unloadPlace.heightAbovePlace = math.max(0, y)
				unloadPlace.heightAboveGround = math.max(-(HEIGHT+y), heightAboveGround-Y)
				spec.objectsToUnload[object] = unloadPlace
			end
		end
	end
	
	for object, unloadPlace in pairs(spec.objectsToUnload) do
		local thisAreaClear = false
		local x, y, z = getTranslation(unloadPlace.node)
		
		if #spec.loadArea > 1 then
			local i = spec.objectToLoadingAreaIndex[object] or 1
			local _, offsetY, _ = localToLocal(spec.loadArea[i].rootNode, spec.loadVolume.rootNode, 0, 0, 0)
			y = y - offsetY
		end
		
		for height = unloadPlace.heightAboveGround, 0, 0.1 do
			setTranslation(unloadPlace.node, x, y+height, z)
			if UniversalAutoload.testUnloadLocationIsEmpty(vehicle, unloadPlace) then
				local offset = unloadPlace.heightAbovePlace
				setTranslation(unloadPlace.node, x, y+offset+height, z)
				thisAreaClear = true
				break
			end
		end
		if not thisAreaClear then
			spec.unloadingAreaClear = false
		end
	end
end
--
function UniversalAutoload.clearPalletFromAllVehicles(self, object)
	for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		if vehicle ~= nil then
			local loadedObjectRemoved = UniversalAutoload.removeLoadedObject(vehicle, object)
			local availableObjectRemoved = UniversalAutoload.removeAvailableObject(vehicle, object)
			local autoLoadingObjectRemoved = UniversalAutoload.removeAutoLoadingObject(vehicle, object)
			if loadedObjectRemoved or availableObjectRemoved then
				if self ~= vehicle then
					local SPEC = vehicle.spec_universalAutoload
					if SPEC.totalUnloadCount == 0 then
						SPEC.resetLoadingPattern = true
						vehicle:setAllTensionBeltsActive(false)
					elseif loadedObjectRemoved then
						if self.spec_tensionBelts.areBeltsFasten then
							vehicle:setAllTensionBeltsActive(false)
							vehicle:setAllTensionBeltsActive(true)
						end
					end
				end
				UniversalAutoload.forceRaiseActive(vehicle)
			end
		end
	end
end
--
function UniversalAutoload.unmountDynamicMount(object)
	if object.dynamicMountObject ~= nil then
		local vehicle = object.dynamicMountObject
		-- print("Remove Dynamic Mount from: "..vehicle:getFullName())
		vehicle:removeDynamicMountedObject(object, false)
		object:unmountDynamic()
		if object.additionalDynamicMountJointNode ~= nil then
			delete(object.additionalDynamicMountJointNode)
			object.additionalDynamicMountJointNode = nil
		end
	end
end

function UniversalAutoload:createLoadingPlace(containerType)
    local spec = self.spec_universalAutoload
	
	spec.currentLoadWidth = spec.currentLoadWidth or 0
	spec.currentLoadLength = spec.currentLoadLength or 0
	
	spec.currentActualWidth = spec.currentActualWidth or 0
	spec.currentActualLength = spec.currentActualLength or 0
	
	local i = spec.currentLoadAreaIndex or 1
	
	--CALCUATE POSSIBLE ARRAY SIZES
	local width = spec.loadArea[i].width
	local length = spec.loadArea[i].length
	local N1 = math.floor(width / containerType.sizeX)
	local M1 = math.floor(length / containerType.sizeZ)
	local N2 = math.floor(width / containerType.sizeZ)
	local M2 = math.floor(length / containerType.sizeX)
	
	--CHOOSE BEST PACKING ORIENTATION
	local N, M, sizeX, sizeY, sizeZ, rotation
	local shouldRotate = ((N2*M2) > (N1*M1)) or ((N1>N2) and (N2*M2)>0)

	if UniversalAutoload.showDebug then
		print("-------------------------------")
		print("width: " .. tostring(width) )
		print("length: " .. tostring(length) )
		print(" N1: "..N1.. " ,  M1: "..M1)
		print(" N2: "..N2.. " ,  M2: "..M2)
		print("shouldRotate: " .. tostring(shouldRotate) )
	end
	
	local doRotate = (containerType.alwaysRotate or shouldRotate) and not containerType.neverRotate
	if doRotate then
		N, M = N2, M2
		rotation = math.pi/2
		sizeZ = containerType.sizeX
		sizeY = containerType.sizeY
		sizeX = containerType.sizeZ
	else
		N, M = N1, M1
		rotation = 0
		sizeX = containerType.sizeX
		sizeY = containerType.sizeY
		sizeZ = containerType.sizeZ
	end
	
	--TEST FOR ROUNDBALE PACKING
	local r = 0.70710678
	local R = ((3/4)+(r/4))
	local roundbaleOffset = 0
	local useRoundbalePacking = false
	if containerType.isBale and sizeX==sizeZ then
		-- print("IS ROUNDBALE")
		isRoundbale = true
		NR = math.floor(width / (R*containerType.sizeX))
		MR = math.floor(length / (R*containerType.sizeX))
		if NR > N and width >= (2*R)*containerType.sizeX then
			-- print("ROUNDBALE PACKING")
			useRoundbalePacking = true
			N, M = NR, MR
			sizeX = R*containerType.sizeX
		end
	end
	
	--UPDATE NEW PACKING DIMENSIONS
	spec.currentLoadHeight = 0
	if spec.currentLoadWidth == 0 or spec.currentLoadWidth + sizeX > spec.loadArea[i].width then
		spec.currentLoadWidth = sizeX
		spec.currentActualWidth = N * sizeX
		spec.currentActualLength = spec.currentLoadLength
		spec.currentLoadLength = spec.currentLoadLength + sizeZ
	else
		spec.currentLoadWidth = spec.currentLoadWidth + sizeX
	end

	if spec.currentLoadLength == 0 then
		-- print("LOAD LENGTH WAS ZERO")
		spec.currentLoadLength = sizeZ
	end
	
	if useRoundbalePacking then
		if (spec.currentLoadWidth/sizeX) % 2 == 0 then
			roundbaleOffset = containerType.sizeZ/2
		end
	end
	
	if UniversalAutoload.showDebug then
		print("LoadingAreaIndex: " .. tostring(spec.currentLoadAreaIndex) )
		print("currentLoadWidth: " .. tostring(spec.currentLoadWidth) )
		print("currentLoadLength: " .. tostring(spec.currentLoadLength) )
		print("currentActualWidth: " .. tostring(spec.currentActualWidth) )
		print("currentActualLength: " .. tostring(spec.currentActualLength) )
		print("-------------------------------")
	end
	
	if spec.currentLoadLength<spec.loadArea[i].length and spec.currentLoadWidth<=spec.currentActualWidth then
		-- print("CREATE NEW LOADING PLACE")
		loadPlace = {}
		loadPlace.node = createTransformGroup("loadPlace")
		loadPlace.sizeX = containerType.sizeX
		loadPlace.sizeY = containerType.sizeY
		loadPlace.sizeZ = containerType.sizeZ
		loadPlace.flipYZ = containerType.flipYZ
		loadPlace.isRoundbale = isRoundbale
		loadPlace.roundbaleOffset = roundbaleOffset
		loadPlace.useRoundbalePacking = useRoundbalePacking
		loadPlace.containerType = containerType
		loadPlace.rotation = rotation
		if useRoundbalePacking then
			loadPlace.sizeX = r*containerType.sizeX
			loadPlace.sizeZ = r*containerType.sizeZ
		end
		if containerType.isBale then
			loadPlace.baleOffset = containerType.sizeY/2
		end
		
		--LOAD FROM THE CORRECT SIDE
		local posX = -( spec.currentLoadWidth - (spec.currentActualWidth/2) - (sizeX/2) )
		local posZ = -( spec.currentLoadLength - (sizeZ/2) ) - roundbaleOffset
		if spec.currentLoadside == "left" then posX = -posX end

		--SET POSITION AND ORIENTATION
		link(spec.loadArea[i].startNode, loadPlace.node)
		setTranslation(loadPlace.node, posX, 0, posZ)
		setRotation(loadPlace.node, 0, rotation, 0)
		
		--STORE AS CURRENT LOADING PLACE
		spec.currentLoadingPlace = loadPlace
	end
end
--
function UniversalAutoload:resetLoadingPattern()
    local spec = self.spec_universalAutoload
	if UniversalAutoload.showDebug then print("RESET LOADING PATTERN") end
	spec.currentLoadWidth = 0
	spec.currentLoadHeight = 0
	spec.currentLoadLength = 0
	spec.currentActualWidth = 0
	spec.currentActualLength = 0
	spec.currentLoadingPlace = nil
	spec.resetLoadingPattern = false
end
--
function UniversalAutoload:getLoadPlace(containerType, object)
    local spec = self.spec_universalAutoload
	
	if containerType ~= nil then
		if UniversalAutoload.showDebug then
			print("===============================")
			-- print("FIND LOADING PLACE FOR "..containerType.name)
		end

		local i = spec.currentLoadAreaIndex or 1
		while i <= #spec.loadArea do
			if spec.resetLoadingPattern ~= false then
				UniversalAutoload.resetLoadingPattern(self)
			end
		
			if UniversalAutoload.getIsLoadingAreaAllowed(self, i) then
			
				while spec.currentLoadLength < spec.loadArea[i].length do
				
					spec.currentLoadHeight = spec.currentLoadHeight or 0
					
					local maxLoadAreaHeight = spec.loadArea[i].height
					if containerType.isBale and spec.loadArea[i].baleHeight ~= nil then
						maxLoadAreaHeight = spec.loadArea[i].baleHeight
					end
					
					if spec.currentLoadHeight > 0 and maxLoadAreaHeight > containerType.sizeY then
						local mass = UniversalAutoload.getContainerMass(object)
						local volume = containerType.sizeX * containerType.sizeY * containerType.sizeZ
						local density = mass/volume
						if density > 0.5 then
							maxLoadAreaHeight = maxLoadAreaHeight * (7-(2*density))/6
						end
						if maxLoadAreaHeight > 5*containerType.sizeY then
							maxLoadAreaHeight = 5*containerType.sizeY
						end
					end

					if spec.currentLoadHeight + containerType.sizeY > maxLoadAreaHeight then
						if (containerType.isBale and not spec.zonesOverlap) or (spec.currentLoadingPlace
						and UniversalAutoload.testLocationIsFull(self, spec.currentLoadingPlace)) then
							if UniversalAutoload.showDebug then print("LOADING PLACE IS FULL - SET TO NIL") end
							spec.currentLoadingPlace = nil
						else
							if UniversalAutoload.showDebug then print("PALLET IS MISSING FROM PREVIOUS PLACE - TRY AGAIN") end
						end
					end
				
					if not spec.currentLoadingPlace then
						if UniversalAutoload.showDebug then print(string.format("ADDING NEW PLACE FOR: %s [%.3f, %.3f, %.3f]",
						containerType.name, containerType.sizeX, containerType.sizeY, containerType.sizeZ)) end
						UniversalAutoload.createLoadingPlace(self, containerType)
					end

					local thisLoadHeight = spec.currentLoadHeight
					local thisLoadPlace = spec.currentLoadingPlace
					if thisLoadPlace ~= nil then
					
						local containerFitsInLoadSpace = containerType.flipYZ == thisLoadPlace.flipYZ and
							((containerType.sizeX <= thisLoadPlace.sizeX and containerType.sizeZ <= thisLoadPlace.sizeZ)
							or (loadPlace.useRoundbalePacking and containerType.sizeX==containerType.sizeZ))

						local x0,y0,z0 = getTranslation(thisLoadPlace.node)
						setTranslation(thisLoadPlace.node, x0, thisLoadHeight, z0)
						
						if containerFitsInLoadSpace then
							local useThisLoadSpace = false
							if not self:getIsMoving() and not spec.baleCollectionMode then
								local increment = 0.1
								while thisLoadHeight >= -increment do
								
									setTranslation(thisLoadPlace.node, x0, thisLoadHeight, z0)
								
									if UniversalAutoload.testLocationIsEmpty(self, thisLoadPlace, object)
									and (thisLoadHeight<=0 or UniversalAutoload.testLocationIsFull(self, thisLoadPlace, -containerType.sizeY))
									then
										spec.currentLoadHeight = math.max(0, thisLoadHeight)
										useThisLoadSpace = true
										break
									end
									-- print("Not empty OR no pallet found below position")
									thisLoadHeight = thisLoadHeight - increment
								end
							else
								if containerType.isBale and not spec.zonesOverlap
								and not spec.partiallyUnloaded and not spec.trailerIsFull then
									useThisLoadSpace = true
								else
									if not spec.trailerIsFull then
										--NO_LOADING_UNLESS_STATIONARY
										UniversalAutoload.showWarningMessage(self, 4)
									end
									return
								end
							end
							
							if useThisLoadSpace then
								if containerType.neverStack then
									spec.currentLoadingPlace = nil
								end
								spec.currentLoadHeight = spec.currentLoadHeight + containerType.sizeY
								if UniversalAutoload.showDebug then print("USING LOAD PLACE - height: " .. tostring(spec.currentLoadHeight)) end
								return thisLoadPlace
							end
						end
					end

					if UniversalAutoload.showDebug then print("DID NOT FIT HERE...") end
					spec.currentLoadingPlace = nil
				end
			end
			i = i + 1
			spec.resetLoadingPattern = true
			if #spec.loadArea > 1 and i <= #spec.loadArea then
				if UniversalAutoload.showDebug then print("TRY NEXT LOADING AREA ("..tostring(i)..")...") end
				spec.currentLoadAreaIndex = i
			end
		end
		spec.currentLoadAreaIndex = 1
		spec.trailerIsFull = true
		if spec.baleCollectionMode == true then
			if UniversalAutoload.showDebug then print("baleCollectionMode: trailerIsFull") end
			UniversalAutoload.setBaleCollectionMode(self, false)
		end
		if UniversalAutoload.showDebug then print("FULL - NO MORE ROOM") end
		if UniversalAutoload.showDebug then print("===============================") end
	end
end

-- OBJECT PICKUP LOGIC FUNCTIONS
function UniversalAutoload:getIsValidObject(object)
    local spec = self.spec_universalAutoload
	
	if object.i3dFilename ~= nil and (
		object.typeName=="pallet" or
		object.typeName=="bigBag" or
		object.typeName=="treeSaplingPallet" or
		object.isRoundbale~=nil
	) then
		if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) then
			return UniversalAutoload.getContainerType(object) ~= nil
		end
	end
	
    return false
end
--
function UniversalAutoload:getIsLoadingKeyAllowed()
	local spec = self.spec_universalAutoload

	if spec.doPostLoadDelay or spec.validLoadCount == 0 or spec.currentLoadside == "none" then
		return false
	end
	if spec.baleCollectionMode then
		return false
	end
	return UniversalAutoload.getIsLoadingVehicleAllowed(self)
end
--
function UniversalAutoload:getIsUnloadingKeyAllowed()
	local spec = self.spec_universalAutoload

	if spec.doPostLoadDelay or spec.isLoading or spec.isUnloading
	or spec.validUnloadCount == 0 or spec.currentTipside == "none" then
		return false
	end
	if spec.isBoxTrailer and spec.noLoadingIfFolded and (self:getIsFolding() or not self:getIsUnfolded()) then
		return false
	end
	if spec.isBoxTrailer and spec.noLoadingIfUnfolded and (self:getIsFolding() or self:getIsUnfolded()) then
		return false
	end
	if spec.noLoadingIfCovered and self:getIsCovered() then
		return false
	end
	if spec.noLoadingIfUncovered and not self:getIsCovered() then
		return false
	end
	if spec.baleCollectionMode then
		return false
	end
    return true
end
--
function UniversalAutoload:getIsLoadingVehicleAllowed(triggerId)
	local spec = self.spec_universalAutoload
	
	if self:getIsFilled() then
		return false
	end
	if spec.noLoadingIfFolded and (self:getIsFolding() or not self:getIsUnfolded()) then
		return false
	end
	if spec.noLoadingIfUnfolded and (self:getIsFolding() or self:getIsUnfolded()) then
		return false
	end
	if spec.noLoadingIfCovered and self:getIsCovered() then
		return false
	end
	if spec.noLoadingIfUncovered and not self:getIsCovered() then
		return false
	end
	
	-- check that curtain trailers have an open curtain
	if spec.isCurtainTrailer and triggerId then
		-- print("CURTAIN TRAILER")
		local tipState = self:getTipState()
		local doorOpen = self:getIsUnfolded()
		local rearTrigger = triggerId == spec.rearTriggerId
		local curtainsOpen = not (tipState == Trailer.TIPSTATE_CLOSED or tipState == Trailer.TIPSTATE_CLOSING)

		if spec.enableRearLoading and rearTrigger then
			if not doorOpen then
				-- print("NO LOADING IF DOOR CLOSED")
				return false
			end
		end
		
		if spec.enableSideLoading and not rearTrigger then
			if not curtainsOpen then
				-- print("NO LOADING IF CURTAIN CLOSED")
				return false
			end
		end
	end

	local node = UniversalAutoload.getObjectNode( self )
	if node == nil then
		return false
	end
	
	if node then
		-- check that the vehicle has not fallen on its side
		local _, y1, _ = getWorldTranslation(node)
		local _, y2, _ = localToWorld(node, 0, 1, 0)
		if y2 - y1 < 0.5 then
			-- print("NO LOADING IF FALLEN OVER")
			return false
		end
	end
	
	return true
end
--
function UniversalAutoload:getIsLoadingAreaAllowed(i)
	local spec = self.spec_universalAutoload
	
	if spec.loadArea[i].noLoadingIfFolded and (self:getIsFolding() or not self:getIsUnfolded()) then
		return false
	end
	if spec.loadArea[i].noLoadingIfUnfolded and (self:getIsFolding() or self:getIsUnfolded()) then
		return false
	end
	if spec.loadArea[i].noLoadingIfCovered and self:getIsCovered() then
		return false
	end
	if spec.loadArea[i].noLoadingIfUncovered and not self:getIsCovered() then
		return false
	end
	return true
end
--
function UniversalAutoload:getIsUnloadingAreaAllowed(i)
	local spec = self.spec_universalAutoload
	
    return true
end
--
function UniversalAutoload:getDynamicMountTimeToMount(superFunc)
	return UniversalAutoload.getIsLoadingVehicleAllowed(self) and -1 or math.huge
end
--
function UniversalAutoload:testLocationIsFull(loadPlace, offset)
	local spec = self.spec_universalAutoload
	local r = 0.025
	local sizeX, sizeY, sizeZ = (loadPlace.sizeX/2)-r, (loadPlace.sizeY/2)-r, (loadPlace.sizeZ/2)-r
	local x, y, z = localToWorld(loadPlace.node, 0, offset or 0, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
		
	spec.foundObject = false
	spec.currentObject = self
	
	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)

	return spec.foundObject
end
--
function UniversalAutoload:testLocationIsEmpty(loadPlace, object, offset)
	local spec = self.spec_universalAutoload
	local r = 0.025
	local sizeX, sizeY, sizeZ = (loadPlace.sizeX/2)-r, (loadPlace.sizeY/2)-r, (loadPlace.sizeZ/2)-r
	local x, y, z = localToWorld(loadPlace.node, 0, offset or 0, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.currentObject = object

	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)

	if UniversalAutoload.showDebug then
		if spec.testLocation == nil then
			spec.testLocation = {}
		end
		spec.testLocation.node = loadPlace.node
		spec.testLocation.sizeX = 2*sizeX
		spec.testLocation.sizeY = 2*sizeY
		spec.testLocation.sizeZ = 2*sizeZ
	end

	return not spec.foundObject
end
--
function UniversalAutoload:testLocationOverlap_Callback(hitObjectId, x, y, z, distance)
	
    if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.SHAPE) then
        local spec = self.spec_universalAutoload
        local object = g_currentMission:getNodeObject(hitObjectId)

        if object ~= nil and object ~= self and object ~= spec.currentObject then
			-- print(object.i3dFilename)
            spec.foundObject = true
        end
    end
end
--
function UniversalAutoload:testLoadAreaIsEmpty()
	local spec = self.spec_universalAutoload
	local i = spec.currentLoadAreaIndex or 1
	--print(self:getFullName() .. " IS EMPTY: " .. tostring(next(spec.loadedObjects) == nil))
	
	local sizeX, sizeY, sizeZ = spec.loadArea[i].width/2, spec.loadArea[i].height/2, spec.loadArea[i].length/2
	local x, y, z = localToWorld(spec.loadArea[i].rootNode, 0, 0, 0)
	local rx, ry, rz = getWorldRotation(spec.loadArea[i].rootNode)
	local dx, dy, dz = localDirectionToWorld(spec.loadArea[i].rootNode, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.currentObject = nil

	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)

	--print(self:getFullName() .. " IS EMPTY: " .. tostring(not spec.foundObject))
	return not spec.foundObject
end
--
function UniversalAutoload:testUnloadLocationIsEmpty(unloadPlace)

	local spec = self.spec_universalAutoload
	local sizeX, sizeY, sizeZ = unloadPlace.sizeX/2, unloadPlace.sizeY/2, unloadPlace.sizeZ/2
	local x, y, z = localToWorld(unloadPlace.node, 0, 0, 0)
	local rx, ry, rz = getWorldRotation(unloadPlace.node)
	local dx, dy, dz
	if unloadPlace.wasFlippedYZ then
		dx, dy, dz = localDirectionToWorld(unloadPlace.node, 0, 0, -sizeY)
	else
		dx, dy, dz = localDirectionToWorld(unloadPlace.node, 0, sizeY, 0)
	end
	
	spec.hasOverlap = false

	-- local collisionMask = CollisionMask.ALL - CollisionMask.TRIGGERS - CollisionFlag.FILLABLE
	local collisionMask = CollisionFlag.STATIC_WORLD + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testUnloadLocation_Callback", self, collisionMask, true, true, true)

	return not spec.hasOverlap
end
--
function UniversalAutoload:testUnloadLocation_Callback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= 0 and hitObjectId ~= g_currentMission.terrainRootNode then
		local spec = self.spec_universalAutoload
		spec.hasOverlap = true
		return false
	end
	return true
end

-- OBJECT MOVEMENT FUNCTIONS
function UniversalAutoload.getObjectNode( object )
	local node = nil
	if object.components ~= nil then
		node = object.components[1].node
	else
		node = object.nodeId
	end
	if node ~= nil and node ~= 0 and g_currentMission.nodeToObject[node]~=nil then
		return node
	end
end
--
function UniversalAutoload.unlinkObject( object )
	local node = UniversalAutoload.getObjectNode(object)
	local x, y, z = localToWorld(node, 0, 0, 0)
	local rx, ry, rz = getWorldRotation(node, 0, 0, 0)
	link(getRootNode(), node)
	setWorldTranslation(node, x, y, z)
	setWorldRotation(node, rx, ry, rz)
end
--
function UniversalAutoload.moveObjectNode( node, p )
	if p.x ~= nil then
		setWorldTranslation(node, p.x, p.y, p.z)
	end
	if p.rx ~= nil then
		setWorldRotation(node, p.rx, p.ry, p.rz)
	end
end
--
function UniversalAutoload.getNodes( object )
	local nodes = {}
	if object.components ~= nil then
		for i = 1, #object.components do
			table.insert(nodes, object.components[i].node)
		end
	else
		table.insert(nodes, object.nodeId)
	end
	return nodes
end
--
function UniversalAutoload.getTransformation( position, nodes )
	local n = {}
	for i = 1, #nodes do
		n[i] = {}
		n[i].x, n[i].y, n[i].z = localToWorld(position.node, 0, position.baleOffset or 0, 0)
		n[i].rx, n[i].ry, n[i].rz = getWorldRotation(position.node)
		if position.flipYZ then
			n[i].rx = n[i].rx + math.pi/2
		end
		if i > 1 then
			local dx, dy, dz = localToLocal(nodes[i], nodes[1], 0, 0, 0)
			n[i].x = n[i].x + dx
			n[i].y = n[i].y + dy
			n[i].z = n[i].z + dz
		end
		n[i].x = n[i].x
		n[i].y = n[i].y
		n[i].z = n[i].z
	end
	return n
end
--
function UniversalAutoload.removeFromPhysics(object)
	if object.isRoundbale~=nil then
		local node = UniversalAutoload.getObjectNode(object)
		removeFromPhysics(node)
	elseif object.isAddedToPhysics then
		object:removeFromPhysics()
	end
end
--
function UniversalAutoload:addToPhysics(object)
	if object.isRoundbale~=nil then
		local node = UniversalAutoload.getObjectNode(object)
		addToPhysics(node)
	else
		object:addToPhysics()
	end
	
	local nodes = UniversalAutoload.getNodes(object)
	local rootNode = self:getParentComponent(self.rootNode)
	local vx, vy, vz = getLinearVelocity(rootNode)
	for i = 1, #nodes do
		setLinearVelocity(nodes[i], vx or 0, vy or 0, vz or 0)
	end
	object:raiseActive()
	object.networkTimeInterpolator:reset()
	UniversalAutoload.raiseObjectDirtyFlags(object)
end
--
function UniversalAutoload:addBaleModeBale(node)
	local rootNode = self.spec_universalAutoload.loadVolume.rootNode
	local x, y, z = localToLocal(node, rootNode, 0, 0, 0)
	local rx, ry, rz = localRotationToLocal(node, rootNode, 0, 0, 0)
	
	link(rootNode, node)
	setTranslation(node, x, y, z)
	setRotation(node, rx, ry, rz)
end
--
function UniversalAutoload:moveObjectNodes( object, position, baleMode )

	local nodes = UniversalAutoload.getNodes(object)
	local node = nodes[1]
	if node ~= nil and node ~= 0 and g_currentMission.nodeToObject[node]~=nil then
	
		UniversalAutoload.unmountDynamicMount(object)
		UniversalAutoload.removeFromPhysics(object)

		local n = UniversalAutoload.getTransformation( position, nodes )
		for i = 1, #nodes do
			UniversalAutoload.moveObjectNode(nodes[i], n[i])
		end

		if baleMode==true and object.isRoundbale~=nil then
			UniversalAutoload.addBaleModeBale(self, node)
		else
			UniversalAutoload.addToPhysics(self, object)
		end
		
		return true
	end
end

-- TRIGGER CALLBACK FUNCTIONS
function UniversalAutoload:playerTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self ~= nil and otherActorId ~= 0 then
		for _, player in pairs(g_currentMission.players) do
			if otherActorId == player.rootNode then
				
				if g_currentMission.accessHandler:canFarmAccess(player.farmId, self) then
				
					local spec = self.spec_universalAutoload
					local playerId = player.userId
					
					if onEnter then
						UniversalAutoload.updatePlayerTriggerState(self, playerId, true)
						UniversalAutoload.forceRaiseActive(self, true)
					else
						UniversalAutoload.updatePlayerTriggerState(self, playerId, false)
						UniversalAutoload.forceRaiseActive(self, true)
					end

				end
	
			end
		end
	end
end
--
function UniversalAutoload:loadingTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self ~= nil and otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsValidObject(self, object) then
				if onEnter then
					UniversalAutoload.addAvailableObject(self, object)
				elseif onLeave then
					UniversalAutoload.removeAvailableObject(self, object)
				end
			end
		else
			local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(otherActorId))
			if splitType ~= nil then
				if onEnter then
					-- print("WOOD")
				elseif onLeave then
					-- print("NO WOOD")
				end
			end
		end
    end
end
--
function UniversalAutoload:unloadingTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self ~= nil and otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsValidObject(self, object) then
				if onEnter then
					UniversalAutoload.addLoadedObject(self, object)
				elseif onLeave then
					UniversalAutoload.removeLoadedObject(self, object)
				end
			end
		end
	end
end
--
function UniversalAutoload:autoLoadingTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self ~= nil and otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsValidObject(self, object) then
				if onEnter then
					UniversalAutoload.addAutoLoadingObject(self, object)
				elseif onLeave then
					UniversalAutoload.removeAutoLoadingObject(self, object)
				end
			end
		end
	end
end
--
function UniversalAutoload:addLoadedObject(object)
	local spec = self.spec_universalAutoload
	
	if spec.loadedObjects[object] == nil and not UniversalAutoload.isValidForManualLoading(object) then
		spec.loadedObjects[object] = object
		spec.objectToLoadingAreaIndex[object] = spec.currentLoadAreaIndex
		spec.totalUnloadCount = spec.totalUnloadCount + 1
		if object.addDeleteListener ~= nil then
			object:addDeleteListener(self, "onDeleteLoadedObject_Callback")
		end
		return true
	end
end
--
function UniversalAutoload:removeLoadedObject(object)
	local spec = self.spec_universalAutoload
	if spec.loadedObjects[object] ~= nil then
		spec.loadedObjects[object] = nil
		spec.objectToLoadingAreaIndex[object] = nil
		spec.totalUnloadCount = spec.totalUnloadCount - 1
		if object.removeDeleteListener ~= nil then
			object:removeDeleteListener(self, "onDeleteLoadedObject_Callback")
		end
		if next(spec.loadedObjects) == nil then
			spec.resetLoadingPattern = true
			spec.currentLoadAreaIndex = 1
		end
		return true
	end
end
--
function UniversalAutoload:onDeleteLoadedObject_Callback(object)
	UniversalAutoload.removeLoadedObject(self, object)
end
--
function UniversalAutoload:addAvailableObject(object)
	local spec = self.spec_universalAutoload
	
	if spec.availableObjects[object] == nil and spec.loadedObjects[object] == nil then
		spec.availableObjects[object] = object
		spec.totalAvailableCount = spec.totalAvailableCount + 1
		if object.isRoundbale~=nil then
			spec.availableBaleCount = spec.availableBaleCount + 1
		end
		if object.addDeleteListener ~= nil then
			object:addDeleteListener(self, "onDeleteAvailableObject_Callback")
		end
		
		if spec.isLoading and UniversalAutoload.isValidForLoading(self, object) then
			-- print("ADDING OBJECT")
			table.insert(spec.sortedObjectsToLoad, object)
		end
		
		return true
	end
end
--
function UniversalAutoload:removeAvailableObject(object)
	local spec = self.spec_universalAutoload
	local isActiveForLoading = spec.isLoading or spec.isUnloading or spec.doPostLoadDelay
	
	if spec.availableObjects[object] ~= nil then
		spec.availableObjects[object] = nil
		spec.totalAvailableCount = spec.totalAvailableCount - 1
		if object.isRoundbale~=nil then
			spec.availableBaleCount = spec.availableBaleCount - 1
		end
		if object.removeDeleteListener ~= nil then
			object:removeDeleteListener(self, "onDeleteAvailableObject_Callback")
		end
		
		if spec.totalAvailableCount == 0 and not isActiveForLoading then
			-- print("RESETTING MATERIAL AND CONTAINER SELECTIONS")
			if spec.currentMaterialIndex ~= 1 then
				UniversalAutoload.setMaterialTypeIndex(self, 1)
			end
			if spec.currentContainerIndex ~= 1 then
				UniversalAutoload.setContainerTypeIndex(self, 1)
			end
		end
		return true
	end
end
--
function UniversalAutoload:removeFromSortedObjectsToLoad(object)
	local spec = self.spec_universalAutoload
	
	if spec.sortedObjectsToLoad ~= nil then
		for index, sortedobject in ipairs(spec.sortedObjectsToLoad) do
			if object == sortedobject then
				table.remove(spec.sortedObjectsToLoad, index)
				return true
			end
		end
	end
end
--
function UniversalAutoload:onDeleteAvailableObject_Callback(object)
	UniversalAutoload.removeAvailableObject(self, object)
	UniversalAutoload.removeFromSortedObjectsToLoad(self, object)
end
--
function UniversalAutoload:addAutoLoadingObject(object)
	local spec = self.spec_universalAutoload

	if UniversalAutoload.isValidForManualLoading(object) then
		if spec.autoLoadingObjects[object] == nil and spec.loadedObjects[object] == nil then
			spec.autoLoadingObjects[object] = object
			if object.addDeleteListener ~= nil then
				object:addDeleteListener(self, "onDeleteAutoLoadingObject_Callback")
			end
			local rootNode = UniversalAutoload.getObjectNode(object)
			if g_currentMission.player ~= nil and g_currentMission.player.pickedUpObject == rootNode then	
				g_currentMission.player:pickUpObject(false)
			end
			return true
		end
	end
end
--
function UniversalAutoload:removeAutoLoadingObject(object)
	local spec = self.spec_universalAutoload
	
	if spec.autoLoadingObjects[object] ~= nil then
		spec.autoLoadingObjects[object] = nil
		if object.removeDeleteListener ~= nil then
			object:removeDeleteListener(self, "onDeleteAutoLoadingObject_Callback")
		end
		return true
	end
end
--
function UniversalAutoload:onDeleteAutoLoadingObject_Callback(object)
	UniversalAutoload.removeAutoLoadingObject(self, object)
end
--
function UniversalAutoload:createPallet(xmlFilename)
	local spec = self.spec_universalAutoload
	spec.spawningPallet = xmlFilename

	local x, y, z = getWorldTranslation(spec.loadVolume.rootNode)
	local location = { x=x, y=y+10, z=z }

	local function asyncCallbackFunction(vehicle, pallet, palletLoadState, arguments)
		if palletLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
			local fillTypeIndex = pallet:getFillUnitFirstSupportedFillType(1)
			pallet:addFillUnitFillLevel(1, 1, math.huge, fillTypeIndex, ToolType.UNDEFINED, nil)
			
			if not UniversalAutoload.loadObject(vehicle, pallet) then
				g_currentMission:removeVehicle(pallet, true)
				
				if spec.palletsToSpawn and #spec.palletsToSpawn>1 then
					for i, name in pairs(spec.palletsToSpawn) do
						if spec.spawningPallet == name then
							if debugConsole then print("removing: " .. spec.spawningPallet) end
							table.remove(spec.palletsToSpawn, i)
							vehicle.spec_universalAutoload.trailerIsFull = false
							break
						end
					end
				end
			end
			
			vehicle.spec_universalAutoload.spawningPallet = nil
			if vehicle.spec_universalAutoload.trailerIsFull == true then
				vehicle.spec_universalAutoload.spawnPallets = false
				vehicle:setAllTensionBeltsActive(true)
				print(vehicle:getFullName() .. " ..adding pallets complete!")
			end
			return
		end
	end

	local farmId = g_currentMission:getFarmId()
	farmId = farmId ~= FarmManager.SPECTATOR_FARM_ID and farmId or 1
	VehicleLoadingUtil.loadVehicle(xmlFilename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, farmId, nil, nil, asyncCallbackFunction, self)
end
--
function UniversalAutoload:createPallets(pallets)
	local spec = self.spec_universalAutoload
	
	if spec ~= nil then
		if debugConsole then print("ADD PALLETS: " .. self:getFullName()) end
		self:setAllTensionBeltsActive(false)
		spec.spawnPallets = true
		spec.palletsToSpawn = {}

		for _, pallet in pairs(pallets) do
			table.insert(spec.palletsToSpawn, pallet)
		end
	end
end
--
function UniversalAutoload:createBale(xmlFilename, fillTypeIndex, wrapState)
	local spec = self.spec_universalAutoload

	local x, y, z = getWorldTranslation(spec.loadVolume.rootNode)
	y = y + 10

	local farmId = g_currentMission:getFarmId()
	farmId = farmId ~= FarmManager.SPECTATOR_FARM_ID and farmId or 1
	local baleObject = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
	
	if baleObject:loadFromConfigXML(xmlFilename, x, y, z, 0, 0, 0) then
		baleObject:setFillType(fillTypeIndex, true)
		baleObject:setWrappingState(wrapState)
		baleObject:setOwnerFarmId(farmId, true)
		baleObject:register()
	end
	
	return baleObject
end
--
function UniversalAutoload:createBales(bale)
	local spec = self.spec_universalAutoload
	
	if spec ~= nil then
		if debugConsole then print("ADD BALES: " .. self:getFullName()) end
		self:setAllTensionBeltsActive(false)
		spec.spawnBales = true
		spec.baleToSpawn = bale
	end
end
--
function UniversalAutoload:clearLoadedObjects()
	local spec = self.spec_universalAutoload
	local palletCount, balesCount = 0, 0
	
	if spec ~= nil and spec.loadedObjects ~= nil then
		if debugConsole then print("CLEAR OBJECTS: " .. self:getFullName()) end
		self:setAllTensionBeltsActive(false)
		for _, object in pairs(spec.loadedObjects) do
			if object.isRoundbale == nil then
				g_currentMission:removeVehicle(object, true)
				palletCount = palletCount + 1
			else
				object:delete()
				balesCount = balesCount + 1
			end
		end
		spec.loadedObjects = {}
		spec.totalUnloadCount = 0
		UniversalAutoload.resetLoadingPattern(self)
		spec.trailerIsFull = false
		spec.partiallyUnloaded = false
	end
	return palletCount, balesCount
end
--

-- PALLET IDENTIFICATION AND SELECTION FUNCTIONS
function UniversalAutoload.getObjectNameFromI3d(i3d_path)
	local i3d_name = i3d_path:match("[^/]*.i3d$")
	return i3d_name:sub(0, #i3d_name - 4)
end
--
function UniversalAutoload.getObjectNameFromXml(xml_path)
	local xml_name = xml_path:match("[^/]*.xml$")
	return xml_name:sub(0, #xml_name - 4)
end
--
function UniversalAutoload.getEnvironmentNameFromPath(i3d_path)
	local customEnvironment = nil
	if i3d_path:find(g_modsDirectory) then
		local temp = i3d_path:gsub(g_modsDirectory, "")
		customEnvironment, _ = temp:match( "^(.-)/(.+)$" )
	end
	return customEnvironment
end
--
function UniversalAutoload.getContainerTypeName(object)
	local containerType = UniversalAutoload.getContainerType(object)
	return containerType.type
end
--
function UniversalAutoload.getContainerType(object)
	local name = UniversalAutoload.getObjectNameFromI3d(object.i3dFilename)
	if object.customEnvironment ~= nil then
		name = object.customEnvironment..":"..name
	end
	
	local objectType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
	if objectType == nil then
		if UniversalAutoload.UNKNOWN_TYPES[name] == nil then
			UniversalAutoload.UNKNOWN_TYPES[name] = true
			print("*** UNIVERSAL AUTOLOAD - UNKNOWN OBJECT TYPE: ".. name.." ***")
		end
	end
	
	return objectType
end
--
function UniversalAutoload.getContainerMass(object)
	local mass = 1
	if object ~= nil then
		if object.getTotalMass == nil then
			if object.getMass ~= nil then
				-- print("GET BALE MASS")
				mass = object:getMass()
			end
		else
			-- print("GET OBJECT MASS")
			mass = object:getTotalMass()
		end
	end
	return mass
end
--
function UniversalAutoload.getMaterialType(object)
	if object ~= nil then
		if object.fillType ~= nil then
			return object.fillType
		elseif object.spec_fillUnit ~= nil then
			local fillUnitIndex = object.spec_fillUnit.fillUnits[1].fillType
			return fillUnitIndex
		end
	end
end
--
function UniversalAutoload.getMaterialTypeName(object)
	local fillUnitIndex = UniversalAutoload.getMaterialType(object)
	local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillUnitIndex)
	return fillTypeName
end
--
function UniversalAutoload:getSelectedContainerType()
	local spec = self.spec_universalAutoload
	return UniversalAutoload.CONTAINERS[spec.currentContainerIndex]
end
--
function UniversalAutoload:getSelectedContainerText()
   return g_i18n:getText("universalAutoload_"..UniversalAutoload.getSelectedContainerType(self))
end
--
function UniversalAutoload:getSelectedMaterialType()
	local spec = self.spec_universalAutoload
	return UniversalAutoload.MATERIALS[spec.currentMaterialIndex]
end
--
function UniversalAutoload:getSelectedMaterialText()
	local materialType = UniversalAutoload.getSelectedMaterialType(self)
	local materialIndex = UniversalAutoload.MATERIALS_INDEX[materialType]
	local fillType = UniversalAutoload.MATERIALS_FILLTYPE[materialIndex]
	return fillType.title
end
--
function UniversalAutoload:getPalletIsSelectedLoadside(object)
	local spec = self.spec_universalAutoload
	
	if spec.currentLoadside == "both" then
		return true
	end
	
	if spec.availableObjects[object] == nil then
		return true
	end

	local node = UniversalAutoload.getObjectNode(object)
	if node == nil then
		return false
	end
	
	if g_currentMission.nodeToObject[self.rootNode]==nil then
		return false
	end
	
	local x, y, z = localToLocal(node, spec.loadVolume.rootNode, 0, 0, 0)
	if ( x > 0 and spec.currentLoadside == "left") or 
	   ( x < 0 and spec.currentLoadside == "right") then
		return true
	else
		return false
	end
end
--
function UniversalAutoload:getPalletIsSelectedMaterial(object)

	local objectMaterialType = UniversalAutoload.getMaterialTypeName(object)
	local selectedMaterialType = UniversalAutoload.getSelectedMaterialType(self)

	if objectMaterialType~=nil and selectedMaterialType~=nil then
		if selectedMaterialType == "ALL" then
			return true
		else
			return objectMaterialType == selectedMaterialType
		end
	else
		return false
	end
end
--
function UniversalAutoload:getPalletIsSelectedContainer(object)

	local objectContainerType = UniversalAutoload.getContainerTypeName(object)
	local selectedContainerType = UniversalAutoload.getSelectedContainerType(self)

	if objectContainerType~=nil and selectedContainerType~=nil then
		if selectedContainerType == "ALL" then
			return true
		else
			return objectContainerType == selectedContainerType
		end
	else
		return false
	end
end
--
function UniversalAutoload.getPalletIsFull(object)
	if object.getFillUnits ~= nil then
		for k, _ in ipairs(object:getFillUnits()) do
			if object:getFillUnitFillLevelPercentage(k) < 1 then
				return false
			end
		end
	end
	return true
end
--
function UniversalAutoload.raiseObjectDirtyFlags(object)
	if object.isRoundbale ~= nil then
		object:raiseDirtyFlags(object.physicsObjectDirtyFlag)
	else
		object:raiseDirtyFlags(object.vehicleDirtyFlag)
	end
end

-- DRAW DEBUG PALLET FUNCTIONS
function UniversalAutoload:drawDebugDisplay(isActiveForInput)
	local spec = self.spec_universalAutoload

	if (UniversalAutoload.showLoading or UniversalAutoload.showDebug or spec.showDebug) and not g_gui:getIsGuiVisible() then
	
		local RED     = { 1.0, 0.1, 0.1 }
		local GREEN   = { 0.1, 1.0, 0.1 }
		local YELLOW  = { 1.0, 1.0, 0.1 }
		local CYAN    = { 0.1, 1.0, 1.0 }
		local MAGENTA = { 1.0, 0.1, 1.0 }
		local GREY    = { 0.2, 0.2, 0.2 }
		local WHITE   = { 1.0, 1.0, 1.0 }
		
		if not (isActiveForInput or self==UniversalAutoload.lastClosestVehicle) then
			RED = GREY
			GREEN = GREY
			YELLOW = GREY
			CYAN = GREY
			MAGENTA = GREY
			WHITE = GREY
		end
		
		if spec.currentLoadingPlace ~= nil then
			local place = spec.currentLoadingPlace
			UniversalAutoload.DrawDebugPallet( place.node, place.sizeX, place.sizeY, place.sizeZ, true, false, GREY)
		end
		if UniversalAutoload.showDebug and spec.testLocation ~= nil then
			UniversalAutoload.DrawDebugPallet( spec.testLocation.node, spec.testLocation.sizeX, spec.testLocation.sizeY, spec.testLocation.sizeZ, true, false, WHITE)
		end

		if UniversalAutoload.showDebug or spec.showDebug then
			for _, trigger in pairs(spec.triggers) do
				if trigger.name == "rearAutoTrigger" or trigger.name == "leftAutoTrigger" or trigger.name == "rightAutoTrigger" then
					DebugUtil.drawDebugCube(trigger.node, 1,1,1, unpack(YELLOW))
				elseif trigger.name == "leftPickupTrigger" or trigger.name == "rightPickupTrigger"
				    or trigger.name == "rearPickupTrigger" or trigger.name == "frontPickupTrigger"  then
					DebugUtil.drawDebugCube(trigger.node, 1,1,1, unpack(MAGENTA))
				end
			end
		end
	
		for _,object in pairs(spec.availableObjects) do
			if object ~= nil then
				local node = UniversalAutoload.getObjectNode(object)
				if node ~= nil then
					local containerType = UniversalAutoload.getContainerType(object)
					local w, h, l = containerType.sizeX, containerType.sizeY, containerType.sizeZ
					if containerType.flipYZ then
						l, h = containerType.sizeY, containerType.sizeZ
					end
					local offset = 0 if containerType.isBale then offset = h/2 end
					if UniversalAutoload.isValidForLoading(self, object) then
						UniversalAutoload.DrawDebugPallet( node, w, h, l, true, false, GREEN, offset )
					else
						UniversalAutoload.DrawDebugPallet( node, w, h, l, true, false, GREY, offset )
					end
				end
			end
		end
		
		for _,object in pairs(spec.loadedObjects) do
			if object ~= nil then
				local node = UniversalAutoload.getObjectNode(object)
				if node ~= nil then
					local containerType = UniversalAutoload.getContainerType(object)
					local w, h, l = containerType.sizeX, containerType.sizeY, containerType.sizeZ
					if containerType.flipYZ then
						l, h = containerType.sizeY, containerType.sizeZ
					end
					local offset = 0 if containerType.isBale then offset = h/2 end
					if UniversalAutoload.isValidForUnloading(self, object) then 
						UniversalAutoload.DrawDebugPallet( node, w, h, l, true, false, GREEN, offset )
					else
						UniversalAutoload.DrawDebugPallet( node, w, h, l, true, false, GREY, offset )
					end
				end
			end
		end
		
		UniversalAutoload.buildObjectsToUnloadTable(self)
		for object, unloadPlace in pairs(spec.objectsToUnload) do
			local containerType = UniversalAutoload.getContainerType(object)
			local w, h, l = containerType.sizeX, containerType.sizeY, containerType.sizeZ
			if containerType.flipYZ then
				l, h = containerType.sizeY, containerType.sizeZ
			end
			local offset = 0 if containerType.isBale then offset = h/2 end
			if spec.unloadingAreaClear then
				UniversalAutoload.DrawDebugPallet( unloadPlace.node, w, h, l, true, false, CYAN, offset )
			else
				UniversalAutoload.DrawDebugPallet( unloadPlace.node, w, h, l, true, false, RED, offset )
			end
		end
		
		if UniversalAutoload.showDebug or spec.showDebug then
			local W, H, L = spec.loadVolume.width, spec.loadVolume.height, spec.loadVolume.length
			UniversalAutoload.DrawDebugPallet( spec.loadVolume.rootNode, W, H, L, true, false, MAGENTA )
			
			if spec.boundingBox then
				local W, H, L = spec.boundingBox.width, spec.boundingBox.height, spec.boundingBox.length
				UniversalAutoload.DrawDebugPallet( spec.boundingBox.rootNode, W, H, L, true, false, MAGENTA )
			end
		end
		
		for i, loadArea in pairs(spec.loadArea) do
			local W, H, L = loadArea.width, loadArea.height, loadArea.length
			if not (UniversalAutoload.showDebug or spec.showDebug) then H = 0 end
			
			if UniversalAutoload.getIsLoadingAreaAllowed(self, i) then
				UniversalAutoload.DrawDebugPallet( loadArea.rootNode,  W, H, L, true, false, WHITE )
				UniversalAutoload.DrawDebugPallet( loadArea.startNode, W, 0, 0, true, false, GREEN )
				UniversalAutoload.DrawDebugPallet( loadArea.endNode,   W, 0, 0, true, false, RED )
				
				if (UniversalAutoload.showDebug or spec.showDebug) and loadArea.baleHeight ~= nil then
					H = loadArea.baleHeight
					UniversalAutoload.DrawDebugPallet( loadArea.rootNode, W, H, L, true, false, YELLOW )
				end
			else
				UniversalAutoload.DrawDebugPallet( loadArea.rootNode,  W, H, L, true, false, GREY )
				if (UniversalAutoload.showDebug or spec.showDebug) and loadArea.baleHeight ~= nil then
					H = loadArea.baleHeight
					UniversalAutoload.DrawDebugPallet( loadArea.rootNode, W, H, L, true, false, GREY )
				end
			end
		end

	end
end
--
function UniversalAutoload.DrawDebugPallet( node, w, h, l, showCube, showAxis, colour, offset )

	if node ~= nil and node ~= 0 then
		-- colour for square
		colour = colour or WHITE
		local r, g, b = unpack(colour)
		local w, h, l = (w or 1), (h or 1), (l or 1)
		local offset = offset or 0

		local xx,xy,xz = localDirectionToWorld(node, w,0,0)
		local yx,yy,yz = localDirectionToWorld(node, 0,h,0)
		local zx,zy,zz = localDirectionToWorld(node, 0,0,l)
		
		local x0,y0,z0 = localToWorld(node, -w/2, -offset, -l/2)
		drawDebugLine(x0,y0,z0,r,g,b,x0+xx,y0+xy,z0+xz,r,g,b)
		drawDebugLine(x0,y0,z0,r,g,b,x0+zx,y0+zy,z0+zz,r,g,b)
		drawDebugLine(x0+xx,y0+xy,z0+xz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)
		drawDebugLine(x0+zx,y0+zy,z0+zz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)

		if showCube then			
			local x1,y1,z1 = localToWorld(node, -w/2, h-offset, -l/2)
			drawDebugLine(x1,y1,z1,r,g,b,x1+xx,y1+xy,z1+xz,r,g,b)
			drawDebugLine(x1,y1,z1,r,g,b,x1+zx,y1+zy,z1+zz,r,g,b)
			drawDebugLine(x1+xx,y1+xy,z1+xz,r,g,b,x1+xx+zx,y1+xy+zy,z1+xz+zz,r,g,b)
			drawDebugLine(x1+zx,y1+zy,z1+zz,r,g,b,x1+xx+zx,y1+xy+zy,z1+xz+zz,r,g,b)
			
			drawDebugLine(x0,y0,z0,r,g,b,x1,y1,z1,r,g,b)
			drawDebugLine(x0+zx,y0+zy,z0+zz,r,g,b,x1+zx,y1+zy,z1+zz,r,g,b)
			drawDebugLine(x0+xx,y0+xy,z0+xz,r,g,b,x1+xx,y1+xy,z1+xz,r,g,b)
			drawDebugLine(x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b,x1+xx+zx,y1+xy+zy,z1+xz+zz,r,g,b)
		end
		
		if showAxis then
			local x,y,z = localToWorld(node, 0, (h/2)-offset, 0)
			Utils.renderTextAtWorldPosition(x-xx/2,y-xy/2,z-xz/2, "-x", getCorrectTextSize(0.012), 0)
			Utils.renderTextAtWorldPosition(x+xx/2,y+xy/2,z+xz/2, "+x", getCorrectTextSize(0.012), 0)
			Utils.renderTextAtWorldPosition(x-yx/2,y-yy/2,z-yz/2, "-y", getCorrectTextSize(0.012), 0)
			Utils.renderTextAtWorldPosition(x+yx/2,y+yy/2,z+yz/2, "+y", getCorrectTextSize(0.012), 0)
			Utils.renderTextAtWorldPosition(x-zx/2,y-zy/2,z-zz/2, "-z", getCorrectTextSize(0.012), 0)
			Utils.renderTextAtWorldPosition(x+zx/2,y+zy/2,z+zz/2, "+z", getCorrectTextSize(0.012), 0)
			drawDebugLine(x-xx/2,y-xy/2,z-xz/2,1,1,1,x+xx/2,y+xy/2,z+xz/2,1,1,1)
			drawDebugLine(x-yx/2,y-yy/2,z-yz/2,1,1,1,x+yx/2,y+yy/2,z+yz/2,1,1,1)
			drawDebugLine(x-zx/2,y-zy/2,z-zz/2,1,1,1,x+zx/2,y+zy/2,z+zz/2,1,1,1)
		end
	
	end

end

-- ADD CUSTOM STRINGS FROM ModDesc.xml TO GLOBAL g_i18n
function UniversalAutoload.AddCustomStrings()
	-- print("  ADD custom strings from ModDesc.xml to g_i18n")
	local i = 0
	local xmlFile = loadXMLFile("modDesc", g_currentModDirectory.."modDesc.xml")
	while true do
		local key = string.format("modDesc.l10n.text(%d)", i)
		
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		
		local name = getXMLString(xmlFile, key.."#name")
		local text = getXMLString(xmlFile, key.."."..g_languageShort)
		
		if name ~= nil then
			g_i18n:setText(name, text)
			-- print("  "..tostring(name)..": "..tostring(text))
		end
		
		i = i + 1
	end
end
UniversalAutoload.AddCustomStrings()
