-- ============================================================= --
-- Universal Autoload MOD - SPECIALISATION
-- ============================================================= --
UniversalAutoload = {}

UniversalAutoload.name = g_currentModName
UniversalAutoload.path = g_currentModDirectory
UniversalAutoload.specName = ("spec_%s.universalAutoload"):format(g_currentModName)
UniversalAutoload.debugEnabled = false
UniversalAutoload.delayTime = 200

-- EVENTS
source(g_currentModDirectory.."events/CycleContainerEvent.lua")
source(g_currentModDirectory.."events/CycleMaterialEvent.lua")
source(g_currentModDirectory.."events/PlayerTriggerEvent.lua")
source(g_currentModDirectory.."events/RaiseActiveEvent.lua")
source(g_currentModDirectory.."events/ResetLoadingEvent.lua")
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
	UniversalAutoload.vehicleKey = "universalAutoload.vehicleConfigurations.vehicleConfiguration(?)"
	local schemas = {
		[1] = { ["schema"] = UniversalAutoload.xmlSchema, ["key"] = UniversalAutoload.vehicleKey },
		[2] = { ["schema"] = Vehicle.xmlSchema, ["key"] = "vehicle."..UniversalAutoload.vehicleKey }
	}
	for _, s in ipairs(schemas) do
		s.schema:register(XMLValueType.STRING, s.key.."#configFileName", "Vehicle config file xml full path - used to identify supported vechicles", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#selectedConfigs", "Selected Configuration Names", nil)
		s.schema:register(XMLValueType.VECTOR_TRANS, s.key..".loadingArea#offset", "Offset to the centre of the loading area", "0 0 0")
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea#height", "Height of the loading area", 0)
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea#length", "Length of the loading area", 0)
		s.schema:register(XMLValueType.FLOAT, s.key..".loadingArea#width", "Width of the loading area", 0)
		s.schema:register(XMLValueType.BOOL, s.key..".options#isBoxTrailer", "If trailer is enclosed with a rear door", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#isCurtainTrailer", "Automatically detect the available load side (if the trailer has curtain sides)", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#enableRearLoading", "Use the automatic rear loading trigger", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#enableSideLoading", "Use the automatic side loading triggers", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfFolded", "Prevent loading when folded", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#noLoadingIfUnfolded", "Prevent loading when unfolded", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#disableAutoStrap", "Disable the automatic application of tension belts", false)
		s.schema:register(XMLValueType.BOOL, s.key..".options#showDebug", "Show the grahpical debugging display for this vehicle", false)
	end

	local containerTypeKey = "universalAutoload.containerTypeConfigurations.containerTypeConfiguration(?)"
	local objectTypeKey = "universalAutoload.containerTypeConfigurations.containerTypeConfiguration(?).objectType(?)"
	UniversalAutoload.xmlSchema:register(XMLValueType.STRING, containerTypeKey.."#containerType", "The loading type category to group under in the menu)", "ANY")
	UniversalAutoload.xmlSchema:register(XMLValueType.STRING, objectTypeKey.."#name", "Simplified Pallet Configuration Filename", "UNKNOWN")
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeX", "Width of the pallet", 1.5)
	UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeY", "Height of the pallet", 2.0)
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeZ", "Length of the pallet", 1.5)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#isBale", "If the object is either a round bale or square bale", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#flipYZ", "Should always rotate 90 degrees to stack on end - e.g. for round bales", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#neverStack", "Should never load another pallet on top of this one when loading", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#neverRotate", "Should never rotate object when loading", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#alwaysRotate", "Should always rotate to face outwards for manual unloading", false)

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	--local specKey = "vehicles.vehicle(?)." .. UniversalAutoload.specName
	local specKey = "vehicles.vehicle(?).universalAutoload"
    schemaSavegame:register(XMLValueType.STRING, specKey.."#tipside", "Last used tip side", "none")
    schemaSavegame:register(XMLValueType.STRING, specKey.."#loadside", "Last used load side", "both")
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadWidth", "Last used load width", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadLength", "Last used load length", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#loadHeight", "Last used load height", 0)
    schemaSavegame:register(XMLValueType.FLOAT, specKey.."#actualWidth", "Last used total load width", 0)
    schemaSavegame:register(XMLValueType.INT, specKey.."#materialIndex", "Last used material type", 1)
    schemaSavegame:register(XMLValueType.INT, specKey.."#containerIndex", "Last used container type", 1)
    schemaSavegame:register(XMLValueType.BOOL, specKey.."#loadingFilter", "TRUE=Load full pallets only; FALSE=Load any pallets", false)

end
--
function UniversalAutoload.registerFunctions(vehicleType)
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
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", UniversalAutoload.getDynamicMountTimeToMount)
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

    -- SpecializationUtil.removeEventListener(vehicleType, "onLoad", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onPostLoad", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onRegisterActionEvents", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onReadStream", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onWriteStream", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onDelete", UniversalAutoload)
    -- SpecializationUtil.removeEventListener(vehicleType, "onPreDelete", UniversalAutoload)
	
	-- SpecializationUtil.removeEventListener(vehicleType, "onUpdate", UniversalAutoload)
	-- SpecializationUtil.removeEventListener(vehicleType, "onActivate", UniversalAutoload)
	-- SpecializationUtil.removeEventListener(vehicleType, "onDeactivate", UniversalAutoload)
	-- SpecializationUtil.removeEventListener(vehicleType, "onFoldStateChanged", UniversalAutoload)
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
			-- print("updateActionEventKeys: "..self:getFullName())
			local actions = UniversalAutoload.ACTIONS
			local ignoreCollisions = true

			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_LOADING, self, UniversalAutoload.actionEventToggleLoading, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			spec.toggleLoadingActionEventId = actionEventId
			-- print("TOGGLE_LOADING: "..tostring(valid))

			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.UNLOAD_ALL, self, UniversalAutoload.actionEventUnloadAll, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			spec.unloadAllActionEventId = actionEventId
			-- print("UNLOAD_ALL: "..tostring(valid))

			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_FILTER, self, UniversalAutoload.actionEventToggleFilter, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.toggleLoadingFilterActionEventId = actionEventId
			-- print("TOGGLE_FILTER: "..tostring(valid))
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_FW, self, UniversalAutoload.actionEventCycleMaterial_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.cycleMaterialActionEventId = actionEventId
			-- print("CYCLE_MATERIAL_FW: "..tostring(valid))

			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_BW, self, UniversalAutoload.actionEventCycleMaterial_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			-- print("CYCLE_MATERIAL_BW: "..tostring(valid))
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_MATERIALS, self, UniversalAutoload.actionEventSelectAllMaterials, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			-- print("SELECT_ALL_MATERIALS: "..tostring(valid))
			
			if UniversalAutoload.chatKeyConflict ~= true then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_FW, self, UniversalAutoload.actionEventCycleContainer_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				spec.cycleContainerActionEventId = actionEventId
				-- print("CYCLE_CONTAINER_FW: "..tostring(valid))

				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_BW, self, UniversalAutoload.actionEventCycleContainer_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				-- print("CYCLE_CONTAINER_BW: "..tostring(valid))

				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_CONTAINERS, self, UniversalAutoload.actionEventSelectAllContainers, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				-- print("SELECT_ALL_CONTAINERS: "..tostring(valid))
			end
			
			if not spec.isCurtainTrailer then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_TIPSIDE, self, UniversalAutoload.actionEventToggleTipside, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				spec.toggleTipsideActionEventId = actionEventId
				-- print("TOGGLE_TIPSIDE: "..tostring(valid))
			end
			
			if g_currentMission.player.isControlled then
			
				if not g_currentMission.missionDynamicInfo.isMultiplayer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_BELTS, self, UniversalAutoload.actionEventToggleBelts, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleBeltsActionEventId = actionEventId
					-- print("TOGGLE_BELTS: "..tostring(valid))
				end
				
				if spec.isCurtainTrailer or spec.isBoxTrailer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_DOOR, self, UniversalAutoload.actionEventToggleDoor, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleDoorActionEventId = actionEventId
					-- print("TOGGLE_DOOR: "..tostring(valid))
				end
					
				if spec.isCurtainTrailer then
					local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_CURTAIN, self, UniversalAutoload.actionEventToggleCurtain, false, true, false, true, nil, nil, ignoreCollisions, true)
					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					spec.toggleCurtainActionEventId = actionEventId
					-- print("TOGGLE_CURTAIN: "..tostring(valid))
				end
				
			end
			
			if self.isServer then
				local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_DEBUG, self, UniversalAutoload.actionEventToggleDebug, false, true, false, true, nil, nil, ignoreCollisions, true)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				-- spec.toggleDebugActionEventId = actionEventId
				-- print("TOGGLE_DEBUG: "..tostring(valid))
			end

			UniversalAutoload.updateToggleLoadingActionEvent(self)
			UniversalAutoload.updateToggleFilterActionEvent(self)
			UniversalAutoload.updateToggleTipsideActionEvent(self)
			UniversalAutoload.updateToggleBeltsActionEvent(self)
			UniversalAutoload.updateCycleMaterialActionEvent(self)
			UniversalAutoload.updateCycleContainerActionEvent(self)
			UniversalAutoload.updateToggleDoorActionEvent(self)
			UniversalAutoload.updateToggleCurtainActionEvent(self)
		end
	end
end
--
function UniversalAutoload:updateToggleBeltsActionEvent()
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
	local spec = self.spec_universalAutoload

	if spec.isAutoloadEnabled and self.spec_foldable and g_currentMission.player.isControlled
	and (spec.isCurtainTrailer or spec.isBoxTrailer) then
		local foldable = self.spec_foldable
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
end
--
function UniversalAutoload:updateToggleCurtainActionEvent()
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
	local spec = self.spec_universalAutoload
	if spec.isAutoloadEnabled and spec.toggleLoadingFilterActionEventId ~= nil then
		-- Loading Filter: ANY / FULL ONLY
		local loadingFilterText
		if spec.currentLoadingFilter then
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_enabled")
		else
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_disabled")
		end
		g_inputBinding:setActionEventText(spec.toggleLoadingFilterActionEventId, loadingFilterText)
		g_inputBinding:setActionEventTextVisibility(spec.toggleLoadingFilterActionEventId, true)
	end
end
--
function UniversalAutoload:updateToggleTipsideActionEvent()
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
	local spec = self.spec_universalAutoload
	
	if spec.isAutoloadEnabled and spec.toggleLoadingActionEventId ~= nil then
		-- Activate/Deactivate the LOAD key binding
		-- print("UPDATE LOADING ACTION EVENT")
		if spec.isLoading then
			local stopLoadingText = g_i18n:getText("universalAutoload_stopLoading")
			g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, stopLoadingText)
		else
			if spec.doPostLoadDelay or spec.validLoadCount == 0 or spec.currentLoadside == "none" or
			  (spec.noLoadingIfFolded and (self:getIsFolding() or not self:getIsUnfolded())) or
			  (spec.noLoadingIfUnfolded and (self:getIsFolding() or self:getIsUnfolded()))
			then
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, false)
			else
				local startLoadingText = g_i18n:getText("universalAutoload_startLoading")
				if UniversalAutoload.debugEnabled then startLoadingText = startLoadingText.." ("..tostring(spec.validLoadCount)..")" end
				g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, startLoadingText)
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, true)
				g_inputBinding:setActionEventTextVisibility(spec.toggleLoadingActionEventId, true)
			end
		end
	end

	if spec.isAutoloadEnabled and spec.unloadAllActionEventId ~= nil then
		-- Activate/Deactivate the UNLOAD key binding
		if spec.doPostLoadDelay or spec.isLoading or spec.isUnloading or
		   spec.validUnloadCount == 0 or spec.currentTipside == "none"
		then
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, false)
		else
			local unloadText = g_i18n:getText("universalAutoload_unloadAll")
			if UniversalAutoload.debugEnabled then unloadText = unloadText.." ("..tostring(spec.validUnloadCount)..")" end
			-- print("unloadText: "..unloadText)
			g_inputBinding:setActionEventText(spec.unloadAllActionEventId, unloadText)
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, true)
			g_inputBinding:setActionEventTextVisibility(spec.unloadAllActionEventId, true)
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
	UniversalAutoload.updateToggleBeltsActionEvent(self)
end
--
function UniversalAutoload.actionEventToggleDoor(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleDoor: "..self:getFullName())
	local spec = self.spec_foldable
	if #spec.foldingParts > 0 then
		local toggleDirection = self:getToggledFoldDirection()
		if toggleDirection == spec.turnOnFoldDirection then
			self:setFoldState(toggleDirection, true)
		else
			self:setFoldState(toggleDirection, false)
		end
	end
	UniversalAutoload.updateToggleDoorActionEvent(self)
end
function UniversalAutoload.actionEventToggleCurtain(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleCurtain: "..self:getFullName())
	local tipState = self:getTipState()
	if tipState == Trailer.TIPSTATE_CLOSED or tipState == Trailer.TIPSTATE_CLOSING then
		self:startTipping(nil, false)
		TrailerToggleManualTipEvent.sendEvent(self, true)
	else
		self:stopTipping()
		TrailerToggleManualTipEvent.sendEvent(self, false)
	end
	UniversalAutoload.updateToggleCurtainActionEvent(self)
end
--
function UniversalAutoload.actionEventToggleDebug(self, actionName, inputValue, callbackState, isAnalog)
	-- print("actionEventToggleDebug: "..self:getFullName())
	if self.isServer then
		UniversalAutoload.debugEnabled = not UniversalAutoload.debugEnabled
	end
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
	UniversalAutoload.updateCycleMaterialActionEvent(self)
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
	UniversalAutoload.updateCycleContainerActionEvent(self)
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
	UniversalAutoload.updateToggleFilterActionEvent(self)
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
	UniversalAutoload.updateToggleTipsideActionEvent(self)
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
function UniversalAutoload:startLoading(noEventSend)
	local spec = self.spec_universalAutoload

	if not spec.isLoading and UniversalAutoload.getIsAutoloadingAllowed(self) then
		-- print("Start Loading: "..self:getFullName() )

		spec.isLoading = true
		spec.firstAttemptToLoad = true
		
		if self.isServer then
		
			spec.loadDelayTime = math.huge
			if UniversalAutoload.testLoadAreaIsEmpty(self) then
				spec.resetLoadingPattern = true
			end
		
			spec.sortedObjectsToLoad = {}
			for _, object in pairs(spec.availableObjects) do
			
				local node = UniversalAutoload.getObjectNode(object)
				if UniversalAutoload.isValidForLoading(self, object) and node~=nil then
				
					local containerType = UniversalAutoload.getContainerType(object)
					local x, y, z = localToLocal(node, spec.loadArea.startNode, 0, 0, 0)
					object.sort = {}
					object.sort.height = y
					object.sort.distance = math.abs(x) + math.abs(z)
					object.sort.area = (containerType.sizeX * containerType.sizeZ) or 1
					object.sort.material = UniversalAutoload.getMaterialType(object) or 1
					
					table.insert(spec.sortedObjectsToLoad, object)
				end
			end
			if #spec.sortedObjectsToLoad > 1 then
				table.sort(spec.sortedObjectsToLoad, UniversalAutoload.sortPalletsForLoading)
			end
			for _, object in pairs(spec.sortedObjectsToLoad) do
				object.sort = nil
			end
		end
		
		UniversalAutoloadStartLoadingEvent.sendEvent(self, noEventSend)
		UniversalAutoload.updateToggleLoadingActionEvent(self)
	end
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

			if not (spec.trailerIsFull and self.spec_tensionBelts.areBeltsFasten) then
				spec.doSetTensionBelts = true
			end
		end
		
		UniversalAutoloadStopLoadingEvent.sendEvent(self, noEventSend)
		UniversalAutoload.updateToggleLoadingActionEvent(self)
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
					spec.currentLoadingPattern = {}
					spec.test = {}
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
		UniversalAutoload.updateToggleLoadingActionEvent(self)
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
		if spec.doSetTensionBelts then
			self:setAllTensionBeltsActive(true)
		end
		spec.postLoadDelayTime = 0
	end
	
	spec.doPostLoadDelay = false
	spec.doSetTensionBelts = false
	
	UniversalAutoloadResetLoadingEvent.sendEvent(self, noEventSend)
	UniversalAutoload.updateToggleLoadingActionEvent(self)
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
	
	UniversalAutoload.updateToggleLoadingActionEvent(self)
	UniversalAutoload.updateToggleDoorActionEvent(self)
	UniversalAutoload.updateToggleCurtainActionEvent(self)
end
function UniversalAutoload:forceRaiseActive(state, noEventSend)
	-- print("forceRaiseActive: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if spec.updateKeys then
		--print("UPDATE KEYS: "..self:getFullName())
		spec.updateKeys = false
		UniversalAutoload.updateActionEventKeys(self)
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
	
	UniversalAutoload.updateToggleLoadingActionEvent(self)
	UniversalAutoload.updateToggleBeltsActionEvent(self)

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
							-- print("valid config: "..n)
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

	local configFileName = self.configFileName
	local xmlFile = XMLFile.load("configXml", configFileName, Vehicle.xmlSchema)

	if self.customEnvironment ~= nil then
	
		-- local directory = g_modNameToDirectory[self.customEnvironment]
		-- print("directory:       " .. directory)
		-- print("g_modsDirectory: " .. g_modsDirectory)
		-- configFileName = self.customEnvironment .. "/" .. configFileName:gsub(directory, "")
		
		--print("configFileName:    " .. configFileName)
		configFileName = configFileName:gsub(g_modsDirectory, "")
	end
	
	if xmlFile ~= 0 then
		if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] ~= nil then
			-- print("EXISTS: " .. configFileName)
			local configGroup = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
			for selectedConfigs, config in pairs(configGroup) do
				-- DebugUtil.printTableRecursively(config, "--", 0, 1)
				local validConfig = UniversalAutoload.getIsValidConfiguration(self, selectedConfigs, xmlFile, key)
				if validConfig ~= nil then
					print("UniversalAutoload - supported vehicle: "..self:getFullName().." - "..validConfig)
					-- define the loading area parameters from supported vehicles settings file
					spec.loadArea = {}
					spec.loadArea.width  = config.width
					spec.loadArea.length = config.length
					spec.loadArea.height = config.height
					spec.loadArea.offset = config.offset
					spec.isBoxTrailer = config.isBoxTrailer
					spec.isCurtainTrailer = config.isCurtainTrailer
					spec.enableRearLoading = config.enableRearLoading
					spec.enableSideLoading = config.enableSideLoading
					spec.noLoadingIfFolded = config.noLoadingIfFolded
					spec.noLoadingIfUnfolded = config.noLoadingIfUnfolded
					--spec.disableAutoStrap = config.disableAutoStrap
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
					spec.loadArea.width  = xmlFile:getValue(key..".loadingArea#width")
					spec.loadArea.length = xmlFile:getValue(key..".loadingArea#length")
					spec.loadArea.height = xmlFile:getValue(key..".loadingArea#height")
					spec.loadArea.offset = xmlFile:getValue(key..".loadingArea#offset", "0 0 0", true)
					spec.isBoxTrailer = xmlFile:getValue(key..".options#isBoxTrailer", false)
					spec.isCurtainTrailer = xmlFile:getValue(key..".options#isCurtainTrailer", false)
					spec.enableRearLoading = xmlFile:getValue(key..".options#enableRearLoading", false)
					spec.enableSideLoading = xmlFile:getValue(key..".options#enableSideLoading", false)
					spec.noLoadingIfFolded = xmlFile:getValue(key..".options#noLoadingIfFolded", false)
					spec.noLoadingIfUnfolded = xmlFile:getValue(key..".options#noLoadingIfUnfolded", false)
					--spec.disableAutoStrap = xmlFile:getValue(key..".options#disableAutoStrap", false)
					spec.showDebug = xmlFile:getValue(key..".options#showDebug", false)
					-- print("  >> "..configFileName)
					break
				end

				i = i + 1
			end
		end
		xmlFile:delete()
	end
	
	if  spec.loadArea ~= nil and spec.loadArea.width ~= nil and spec.loadArea.length ~= nil and spec.loadArea.height ~= nil and spec.loadArea.offset ~= nil then
		-- print("UNIVERSAL AUTOLOAD - SETTINGS FOUND FOR '"..self:getFullName().."'")
		spec.isAutoloadEnabled = true
	else
		-- print("UNIVERSAL AUTOLOAD - SETTINGS NOT FOUND FOR '"..self:getFullName().."'")
		spec.isAutoloadEnabled = false
		return
	end

    if self.isServer then

		--initialise server only arrays
		spec.triggers = {}
		spec.currentLoadingPattern = {}
		spec.availableObjects = {}
		spec.loadedObjects = {}
		spec.autoLoadingObjects = {}
		
		-- create loading area
		local offsetX, offsetY, offsetZ = unpack(spec.loadArea.offset)
		spec.loadArea.rootNode = createTransformGroup("LoadAreaCentre")
		link(self.rootNode, spec.loadArea.rootNode)
		setTranslation(spec.loadArea.rootNode, offsetX, offsetY, offsetZ)

		spec.loadArea.startNode = createTransformGroup("LoadAreaStart")
		link(self.rootNode, spec.loadArea.startNode)
		setTranslation(spec.loadArea.startNode, offsetX, offsetY, offsetZ+(spec.loadArea.length/2))
		
		spec.loadArea.endNode = createTransformGroup("LoadAreaEnd")
		link(self.rootNode, spec.loadArea.endNode)
		setTranslation(spec.loadArea.endNode, offsetX, offsetY, offsetZ-(spec.loadArea.length/2))

		local i3dFilename = UniversalAutoload.path .. "triggers/UniversalAutoloadTriggers.i3d"
		local triggersRootNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)

		-- create triggers
		local unloadingTrigger = {}
		unloadingTrigger.node = I3DUtil.getChildByName(triggersRootNode, "unloadingTrigger")
		if unloadingTrigger.node ~= nil then
			unloadingTrigger.name = "unloadingTrigger"
			link(spec.loadArea.rootNode, unloadingTrigger.node)
			setRotation(unloadingTrigger.node, 0, 0, 0)
			setTranslation(unloadingTrigger.node, 0, spec.loadArea.height/2, 0)
			local boundary = spec.loadArea.width/4
			setScale(unloadingTrigger.node, spec.loadArea.width-boundary, spec.loadArea.height, spec.loadArea.length-boundary)
			
			table.insert(spec.triggers, unloadingTrigger)
            addTrigger(unloadingTrigger.node, "unloadingTrigger_Callback", self)
		end
		
		local playerTrigger = {}
		playerTrigger.node = I3DUtil.getChildByName(triggersRootNode, "playerTrigger")
		if playerTrigger.node ~= nil then
			playerTrigger.name = "playerTrigger"
			link(spec.loadArea.rootNode, playerTrigger.node)
			setRotation(playerTrigger.node, 0, 0, 0)
			setTranslation(playerTrigger.node, 0, spec.loadArea.height/2, 0)
			setScale(playerTrigger.node, 5*spec.loadArea.width, 2*spec.loadArea.height, spec.loadArea.length+2*spec.loadArea.width)
			
			table.insert(spec.triggers, playerTrigger)
            addTrigger(playerTrigger.node, "playerTrigger_Callback", self)
		end

        local leftPickupTrigger = {}
		leftPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "pickupTrigger1")
		if leftPickupTrigger.node ~= nil then
			leftPickupTrigger.name = "leftPickupTrigger"
			link(spec.loadArea.rootNode, leftPickupTrigger.node)
			
			local width, height, length = 1.66*spec.loadArea.width, 2*spec.loadArea.height, spec.loadArea.length+spec.loadArea.width/2

			setRotation(leftPickupTrigger.node, 0, 0, 0)
			setTranslation(leftPickupTrigger.node, 1.1*(width+spec.loadArea.width)/2, 0, 0)
			setScale(leftPickupTrigger.node, width, height, length)

			table.insert(spec.triggers, leftPickupTrigger)
			addTrigger(leftPickupTrigger.node, "loadingTrigger_Callback", self)
		end
		
		local rightPickupTrigger = {}
		rightPickupTrigger.node = I3DUtil.getChildByName(triggersRootNode, "pickupTrigger2")
		if rightPickupTrigger.node ~= nil then
			rightPickupTrigger.name = "rightPickupTrigger"
			link(spec.loadArea.rootNode, rightPickupTrigger.node)
			
			local width, height, length = 1.66*spec.loadArea.width, 2*spec.loadArea.height, spec.loadArea.length+spec.loadArea.width/2

			setRotation(rightPickupTrigger.node, 0, 0, 0)
			setTranslation(rightPickupTrigger.node, -1.1*(width+spec.loadArea.width)/2, 0, 0)
			setScale(rightPickupTrigger.node, width, height, length)

			table.insert(spec.triggers, rightPickupTrigger)
			addTrigger(rightPickupTrigger.node, "loadingTrigger_Callback", self)
		end
		
		if spec.enableRearLoading then
			local rearAutoTrigger = {}
			rearAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "autoTrigger1")
			if rearAutoTrigger.node ~= nil then
				rearAutoTrigger.name = "rearAutoTrigger"
				link(spec.loadArea.rootNode, rearAutoTrigger.node)
				
				local depth = 0.05
				local recess = 0
				local boundary = 0
				if spec.isCurtainTrailer or spec.isBoxTrailer then
					recess = spec.loadArea.width/3
					boundary = spec.loadArea.width/4
				end
				local width, height, length = spec.loadArea.width-boundary, spec.loadArea.height, depth

				setRotation(rearAutoTrigger.node, 0, 0, 0)
				setTranslation(rearAutoTrigger.node, 0, spec.loadArea.height/2, recess-(spec.loadArea.length/2)-depth )
				setScale(rearAutoTrigger.node, width, height, length)

				table.insert(spec.triggers, rearAutoTrigger)
				addTrigger(rearAutoTrigger.node, "autoLoadingTrigger_Callback", self)
			end
		end
		
		if spec.enableSideLoading then
			local leftAutoTrigger = {}
			leftAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "autoTrigger2")
			if leftAutoTrigger.node ~= nil then
				leftAutoTrigger.name = "leftAutoTrigger"
				link(spec.loadArea.rootNode, leftAutoTrigger.node)
				
				local depth = 0.05
				local recess = 0
				local boundary = 0
				if spec.isCurtainTrailer then
					recess = spec.loadArea.width/3
					boundary = 2*spec.loadArea.width/3
				end
				local width, height, length = depth, spec.loadArea.height, spec.loadArea.length-boundary

				setRotation(leftAutoTrigger.node, 0, 0, 0)
				setTranslation(leftAutoTrigger.node, 2*depth+(spec.loadArea.width/2)-recess, spec.loadArea.height/2, 0)
				setScale(leftAutoTrigger.node, width, height, length)

				table.insert(spec.triggers, leftAutoTrigger)
				addTrigger(leftAutoTrigger.node, "autoLoadingTrigger_Callback", self)
			end
			local rightAutoTrigger = {}
			rightAutoTrigger.node = I3DUtil.getChildByName(triggersRootNode, "autoTrigger3")
			if rightAutoTrigger.node ~= nil then
				rightAutoTrigger.name = "rightAutoTrigger"
				link(spec.loadArea.rootNode, rightAutoTrigger.node)
				
				local depth = 0.05
				local recess = 0
				local boundary = 0
				if spec.isCurtainTrailer or spec.isBoxTrailer then
					recess = spec.loadArea.width/3
					boundary = 2*spec.loadArea.width/3
				end
				local width, height, length = depth, spec.loadArea.height, spec.loadArea.length-boundary

				setRotation(rightAutoTrigger.node, 0, 0, 0)
				setTranslation(rightAutoTrigger.node, -(2*depth+(spec.loadArea.width/2)-recess), spec.loadArea.height/2, 0)
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
		spec.totalUnloadCount = 0
		spec.validLoadCount = 0
		spec.validUnloadCount = 0

	end

	table.insert(UniversalAutoload.VEHICLES, self)
	spec.actionEvents = {}
	spec.playerInTrigger = {}
	
	--client+server
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
				spec.currentLoadHeight = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadHeight", 0)
				spec.currentLoadLength = savegame.xmlFile:getValue(savegame.key..".universalAutoload#loadLength", 0)
				spec.currentActualWidth = savegame.xmlFile:getValue(savegame.key..".universalAutoload#actualWidth", 0)
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
				spec.currentLoadWidth = 0
				spec.currentLoadHeight = 0
				spec.currentLoadLength = 0
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
		end
	end
end

-- "ON DELETE" CLEANUP TRIGGER NODES
function UniversalAutoload:onPreDelete()
	-- print("UniversalAutoload - onPreDelete")
	local spec = self.spec_universalAutoload
	if UniversalAutoload.VEHICLES[self] ~= nil then
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
		spec.foldAnimationRemaining = self.spec_foldable.maxFoldAnimDuration
		UniversalAutoload.updateActionEventText(self)
	end
end
--
function UniversalAutoload:getIsFolding()

    local spec = self.spec_universalAutoload
	for _, foldingPart in pairs(self.spec_foldable.foldingParts) do
		if self:getIsAnimationPlaying(foldingPart.animationName) then
			return true
		end
	end
	
	return false
end

-- NETWORKING FUNCTIONS
function UniversalAutoload:onReadStream(streamId, connection)
	-- print("onReadStream")
    local spec = self.spec_universalAutoload
	
	if streamReadBool(streamId) then
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
	else
		spec.isAutoloadEnabled = false
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
		
		streamWriteString(streamId, spec.currentTipside)
		streamWriteString(streamId, spec.currentLoadside)
		streamWriteInt32(streamId, spec.currentMaterialIndex)
		streamWriteInt32(streamId, spec.currentContainerIndex)
		streamWriteBool(streamId, spec.currentLoadingFilter)
		streamWriteBool(streamId, spec.isLoading)
		streamWriteBool(streamId, spec.isUnloading)
		streamWriteInt32(streamId, spec.validLoadCount)
		streamWriteInt32(streamId, spec.validUnloadCount)
	end
end

-- MAIN AUTOLOAD ONUPDATE LOOP
function UniversalAutoload:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	-- print("UniversalAutoload - onUpdate")
	local spec = self.spec_universalAutoload
	
	if not spec.isAutoloadEnabled then
		if not spec.removedEventListeners then
			spec.removedEventListeners = true
			UniversalAutoload.removeEventListeners(self)
		end
		return
	end
	
	if spec.isAutoloadEnabled and self.isServer then

		-- DETECT WHEN FOLDING STOPS IF IT WAS STARTED
		if spec.foldAnimationStarted then
			if spec.foldAnimationRemaining < 0 then
				-- print("*** FOLDING COMPLETE ***")
				spec.foldAnimationStarted = false
				spec.foldAnimationRemaining = 0
				UniversalAutoload.updateActionEventText(self)
			else
				spec.foldAnimationRemaining = spec.foldAnimationRemaining - dt
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
				spec.doSetTensionBelts = true
				spec.doPostLoadDelay = true
				if UniversalAutoload.loadObject(self, object) then
					-- print("LOADED PALLET FROM AUTO TRIGGER")
					spec.autoLoadingObjects[object] = nil
				else
					--UNABLE_TO_LOAD_OBJECT
					UniversalAutoload.showWarningMessage(self, 3)
				end
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
		if isActiveForInputIgnoreSelection or isActiveForLoading or playerTriggerActive then

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
							if spec.trailerIsFull or UniversalAutoload.testLoadAreaIsEmpty(self) then
								-- print("RESET PATTERN to fill in any gaps")
								spec.partiallyUnloaded = true
								spec.resetLoadingPattern = true
							end
						else
							if spec.firstAttemptToLoad and not spec.trailerIsMoving then
								--UNABLE_TO_LOAD_OBJECT
								UniversalAutoload.showWarningMessage(self, 3)
								spec.partiallyUnloaded = true
								spec.resetLoadingPattern = true
							end
							-- print("STOP LOADING")
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
	
	return UniversalAutoload.getPalletIsSelectedMaterial(self, object) and UniversalAutoload.getPalletIsSelectedContainer(self, object) and 
	(spec.autoLoadingObjects[object] ~= nil or ( spec.loadedObjects[object] == nil and UniversalAutoload.getPalletIsSelectedLoadside(self, object) )) and
	(not spec.currentLoadingFilter or (spec.currentLoadingFilter and UniversalAutoload.getPalletIsFull(object)) ) and
	(not spec.noLoadingIfFolded or self:getIsUnfolded()) and (not spec.noLoadingIfUnfolded or not self:getIsUnfolded())
end
--
function UniversalAutoload:isValidForUnloading(object)
	local spec = self.spec_universalAutoload

	return UniversalAutoload.getPalletIsSelectedMaterial(self, object) and UniversalAutoload.getPalletIsSelectedContainer(self, object) and spec.autoLoadingObjects[object] == nil
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

	-- if spec.totalAvailableCount ~= totalAvailableCount then
		-- --spec.totalAvailableCount = totalAvailableCount
		-- print("TOTAL AVAILABLE COUNT ERROR: "..tostring(spec.totalAvailableCount).." vs "..tostring(totalAvailableCount))
	-- end
	-- if spec.totalUnloadCount ~= totalUnloadCount then
		-- --spec.totalUnloadCount = totalUnloadCount
		-- print("TOTAL UNLOAD COUNT ERROR: "..tostring(spec.totalUnloadCount).." vs "..tostring(totalUnloadCount))
	-- end
end

-- LOADING AND UNLOADING FUNCTIONS
function UniversalAutoload:loadObject(object)
	-- print("UniversalAutoload - loadObject")
	if object ~= nil and UniversalAutoload.getIsAutoloadingAllowed(self) and UniversalAutoload.isValidForLoading(self, object) then

		local spec = self.spec_universalAutoload
		local containerType = UniversalAutoload.getContainerType(object)
		local loadPlace = UniversalAutoload.getLoadPlace(self, containerType)
		if loadPlace ~= nil then

			if UniversalAutoload.moveObjectNodes(self, object, loadPlace) then
				UniversalAutoload.clearPalletFromAllVehicles(self, object)
				UniversalAutoload.addLoadedObject(self, object)
			
				-- print(string.format("LOADED OBJECT: %s [%.3f, %.3f, %.3f]", containerType.name, containerType.sizeX, containerType.sizeY, containerType.sizeZ))
				--g_currentMission:addMoney(-100, self:getOwnerFarmId(), MoneyType.AI)
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
	
	
	local _, HEIGHT, _ = getTranslation(spec.loadArea.rootNode)
	for _, object in pairs(spec.loadedObjects) do
		if UniversalAutoload.isValidForUnloading(vehicle, object) then
		
			local node = UniversalAutoload.getObjectNode(object)
			if node ~= nil then
				x, y, z = localToLocal(node, spec.loadArea.rootNode, 0, 0, 0)
				rx, ry, rz = localRotationToLocal(node, spec.loadArea.rootNode, 0, 0, 0)
				
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
				
				local offsetX = 1.5*spec.loadArea.width
				if spec.currentTipside == "right" then offsetX = -offsetX end
				
				unloadPlace.node = createTransformGroup("unloadPlace")
				link(spec.loadArea.rootNode, unloadPlace.node)
				setTranslation(unloadPlace.node, x+offsetX, y, z)
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

function UniversalAutoload:addLoadPlace(containerType)
    local spec = self.spec_universalAutoload

	spec.currentLoadWidth = spec.currentLoadWidth or 0
	spec.currentLoadLength = spec.currentLoadLength or 0
	spec.currentActualWidth = spec.currentActualWidth or 0
	local lastLoadPlace = spec.currentLoadingPattern[spec.currentPlaceIndex]
	
	--CALCUATE POSSIBLE ARRAY SIZES
	local width = spec.loadArea.width
	local length = spec.loadArea.length - spec.currentLoadLength
	local N1 = math.floor(width / containerType.sizeX)
	local M1 = math.floor(length / containerType.sizeZ)
	local N2 = math.floor(width / containerType.sizeZ)
	local M2 = math.floor(length / containerType.sizeX)
	
	if N2*M2 == N1*M1 then
		-- if equal then use same packing as an empty trailer
		N1 = math.floor(spec.loadArea.width / containerType.sizeX)
		M1 = math.floor(spec.loadArea.length / containerType.sizeZ)
		N2 = math.floor(spec.loadArea.width / containerType.sizeZ)
		M2 = math.floor(spec.loadArea.length / containerType.sizeX)
	end

	--CHOOSE BEST PACKING ORIENTATION
	local N, M, sizeX, sizeY, sizeZ, rotation
	local doRotate = nil
	if lastLoadPlace~=nil and lastLoadPlace.containerType==containerType then
		doRotate = (lastLoadPlace.rotation == (math.pi/2))
	else
		doRotate = (((N2*M2) > (N1*M1)) or containerType.alwaysRotate) and not containerType.neverRotate
	end
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
	local roundbaleOffset = 0
	local useRoundbalePacking = false
	if containerType.isBale and sizeX==sizeZ then
		isRoundbale = true
		NR = math.floor(width / (r*containerType.sizeX))
		MR = math.floor(length / (r*containerType.sizeX))
		if NR > N and width >= ((3+r)/2)*containerType.sizeX then
			useRoundbalePacking = true
			N, M = NR, MR
			sizeX = ((3/4)+(r/4))*containerType.sizeX
		end
	end
	
	if not useRoundbalePacking and (lastLoadPlace~=nil and lastLoadPlace.useRoundbalePacking) then
		spec.currentLoadLength = spec.currentLoadLength + lastLoadPlace.roundbaleOffset + 0.01
	end

	--UPDATE NEW PACKING DIMENSIONS
	spec.currentLoadHeight = 0
	if spec.currentLoadWidth==0 or spec.currentLoadWidth + sizeX > spec.loadArea.width then
		spec.currentLoadWidth = sizeX
		spec.currentActualWidth = N * sizeX
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
	
	if spec.currentLoadLength<spec.loadArea.length and spec.currentLoadWidth<=spec.currentActualWidth then
		--CREATE NEW LOADING PLACE
		loadPlace = {}
		loadPlace.index = #spec.currentLoadingPattern + 1
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
		link(spec.loadArea.startNode, loadPlace.node)
		setTranslation(loadPlace.node, posX, 0, posZ)
		setRotation(loadPlace.node, 0, rotation, 0)
		
		--INSERT PLACE INTO CURRENT TABLE
		table.insert(spec.currentLoadingPattern, loadPlace)
		spec.currentPlaceIndex = #spec.currentLoadingPattern	
	else
		-- print("FULL - NO MORE ROOM")
		spec.trailerIsFull = true
	end
end

function UniversalAutoload:getLoadPlace(containerType)
    local spec = self.spec_universalAutoload
	
	if containerType ~= nil then
		if spec.resetLoadingPattern ~= false then
			-- print("RESET LOADING PATTERN")
			spec.currentLoadingPattern = {}
			spec.currentLoadWidth = 0
			spec.currentLoadHeight = 0
			spec.currentLoadLength = 0
			spec.makeNewLoadingPlace = true
			spec.resetLoadingPattern = false
		end

		while spec.currentLoadLength < spec.loadArea.length do
		
			spec.currentLoadHeight = spec.currentLoadHeight or 0
			if spec.currentLoadHeight + containerType.sizeY > spec.loadArea.height then
				spec.makeNewLoadingPlace = true
			end
		
			if spec.makeNewLoadingPlace ~= false then
				-- print(string.format("ADDING NEW PLACE FOR: %s [%.3f, %.3f, %.3f]", containerType.name, containerType.sizeX, containerType.sizeY, containerType.sizeZ))
				UniversalAutoload.addLoadPlace(self, containerType)
				spec.makeNewLoadingPlace = false
			end

			local thisLoadHeight = spec.currentLoadHeight
			local thisLoadPlace = spec.currentLoadingPattern[spec.currentPlaceIndex]
			if thisLoadPlace ~= nil then
			
				local containerFitsInLoadSpace = containerType.flipYZ == thisLoadPlace.flipYZ and
					((containerType.sizeX <= thisLoadPlace.sizeX and containerType.sizeZ <= thisLoadPlace.sizeZ)
					or (loadPlace.useRoundbalePacking and containerType.sizeX==containerType.sizeZ))

				local x0,y0,z0 = getTranslation(thisLoadPlace.node)
				setTranslation(thisLoadPlace.node, x0, thisLoadHeight, z0)
				
				if containerFitsInLoadSpace then
					local useThisLoadSpace = false
					if self.lastSpeedReal < 0.0005 then
						spec.trailerIsMoving = false
						while thisLoadHeight >= 0 do
							if UniversalAutoload.testLocationIsEmpty(self, thisLoadPlace) and (thisLoadHeight==0 or containerType.isBale or
							UniversalAutoload.testLocationIsFull(self, thisLoadPlace, -containerType.sizeY)) then
								useThisLoadSpace = true
								break
							end
							-- print("Not empty OR no pallet found below position")
							thisLoadHeight = thisLoadHeight - 0.1
						end
					else
						spec.trailerIsMoving = true
						if containerType.isBale and not spec.partiallyUnloaded and not spec.trailerIsFull then
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
						-- print("USING LOAD PLACE: " .. tostring(loadPlace.index) )
						if containerType.neverStack then
							spec.makeNewLoadingPlace = true
						end
						spec.currentLoadHeight = spec.currentLoadHeight + containerType.sizeY
						return thisLoadPlace
					end
				end
			end

			-- print("DID NOT FIT HERE...")
			spec.makeNewLoadingPlace = true
		end
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
function UniversalAutoload:getIsAutoloadingAllowed()
    -- check that the vehicle has not fallen on its side
    local _, y1, _ = getWorldTranslation(self.components[1].node)
    local _, y2, _ = localToWorld(self.components[1].node, 0, 1, 0)
    if y2 - y1 < 0.5 then
        return false
    end

    return true
end
--
function UniversalAutoload:getDynamicMountTimeToMount(superFunc)
	return UniversalAutoload.getIsAutoloadingAllowed(self) and -1 or math.huge
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
	spec.foundObjectId = 0
	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)

	return spec.foundObject
end
--
function UniversalAutoload:testLocationIsEmpty(loadPlace, offset)
	local spec = self.spec_universalAutoload
	local r = 0.025
	local sizeX, sizeY, sizeZ = (loadPlace.sizeX/2)-r, (loadPlace.sizeY/2)-r, (loadPlace.sizeZ/2)-r
	local x, y, z = localToWorld(loadPlace.node, 0, offset or 0, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.foundObjectId = 0

	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)
	
	if spec.test == nil then
		spec.test = {}
	end
	spec.test.node = loadPlace.node
	spec.test.sizeX = 2*sizeX
	spec.test.sizeY = 2*sizeY
	spec.test.sizeZ = 2*sizeZ

	return not spec.foundObject
end
--
function UniversalAutoload:testLocationOverlap_Callback(hitObjectId, x, y, z, distance)
	
    if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.SHAPE) then
        local spec = self.spec_universalAutoload
        local object = g_currentMission:getNodeObject(hitObjectId)

        if object ~= nil and object ~= self then
			-- print(object.i3dFilename)
            spec.foundObject = true
			spec.foundObjectId = hitObjectId
        end
    end
end
--
function UniversalAutoload:testLoadAreaIsEmpty()
	local spec = self.spec_universalAutoload
	local sizeX, sizeY, sizeZ = spec.loadArea.width/2, spec.loadArea.height/2, spec.loadArea.length/2
	local x, y, z = localToWorld(spec.loadArea.rootNode, 0, 0, 0)
	local rx, ry, rz = getWorldRotation(spec.loadArea.rootNode)
	local dx, dy, dz = localDirectionToWorld(spec.loadArea.rootNode, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.foundObjectId = 0

	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "testLocationOverlap_Callback", self, collisionMask, true, false, true)

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
function UniversalAutoload.moveObjectNode( objectNodeId, p )
	if p.x ~= nil then
		setWorldTranslation(objectNodeId, p.x, p.y, p.z)
	end
	if p.rx ~= nil then
		setWorldRotation(objectNodeId, p.rx, p.ry, p.rz)
	end
end
--
function UniversalAutoload:moveObjectNodes( object, position )
	local nodes = {}
	if object.components ~= nil then
		for i = 1, #object.components do
			table.insert(nodes, object.components[i].node)
		end
	else
		table.insert(nodes, object.nodeId)
	end
	
	local node = nodes[1]	
	if node ~= nil and node ~= 0 and g_currentMission.nodeToObject[node]~=nil then
	
		UniversalAutoload.unmountDynamicMount(object)

		-- if self.lastSpeedReal > 0.001 then
			-- print("Last Speed: " .. tostring(self.lastSpeedReal))
			-- print("Last Distance: " .. tostring(self.lastMovedDistance))
			-- print("Last Acceleration: " .. tostring(self.lastSpeedAcceleration * 1000 * 1000))
			-- --print("g_physicsDt: " .. tostring(g_physicsDt))
			-- --print("g_physicsDtNonInterpolated: " .. tostring(g_physicsDtNonInterpolated))
		-- end

		local wasAddedToPhysics = false
		if object.isAddedToPhysics then
			wasAddedToPhysics = true
			object:removeFromPhysics()
		elseif object.isRoundbale~=nil then
			removeFromPhysics(node)
		end

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
		for i = 1, #nodes do
			UniversalAutoload.moveObjectNode(nodes[i], n[i])
		end
		
		if wasAddedToPhysics then
			object:addToPhysics()
		elseif object.isRoundbale~=nil then
			addToPhysics(node)
		end

		for i = 1, #nodes do
			setLinearVelocity(nodes[i], getLinearVelocity(self.rootNode))
		end
		
		object:raiseActive()
		object.networkTimeInterpolator:reset()
		UniversalAutoload.raiseObjectDirtyFlags(object)

		return true
	end
end

-- TRIGGER CALLBACK FUNCTIONS
function UniversalAutoload:playerTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
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
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsAutoloadingAllowed(self) and UniversalAutoload.getIsValidObject(self, object) then
				if onEnter then
					UniversalAutoload.addAvailableObject(self, object)
				elseif onLeave then
					UniversalAutoload.removeAvailableObject(self, object)
				end
			end
		end
    end
end
--
function UniversalAutoload:unloadingTrigger_Callback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsAutoloadingAllowed(self) and UniversalAutoload.getIsValidObject(self, object) then
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
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if UniversalAutoload.getIsAutoloadingAllowed(self) and UniversalAutoload.getIsValidObject(self, object) then
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
	if spec.loadedObjects[object] == nil then
		spec.loadedObjects[object] = object
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
		spec.totalUnloadCount = spec.totalUnloadCount - 1
		if object.removeDeleteListener ~= nil then
			object:removeDeleteListener(self, "onDeleteLoadedObject_Callback")
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
	
	if object.dynamicMountObject ~= nil then
		if spec.autoLoadingObjects[object] == nil then
			spec.autoLoadingObjects[object] = object
			if object.addDeleteListener ~= nil then
				object:addDeleteListener(self, "onDeleteAutoLoadingObject_Callback")
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

-- PALLET IDENTIFICATION AND SELECTION FUNCTIONS
function UniversalAutoload.getObjectNameFromPath(i3d_path)
	local i3d_name = i3d_path:match("[^/]*.i3d$")
	return i3d_name:sub(0, #i3d_name - 4)
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
	local name = UniversalAutoload.getObjectNameFromPath(object.i3dFilename)
	if object.customEnvironment ~= nil then
		name = object.customEnvironment..":"..name
	end
	
	local objectType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
	if objectType == nil then
		if UniversalAutoload.UNKNOWN_TYPES[name] == nil then
			UniversalAutoload.UNKNOWN_TYPES[name] = true
			print("UNKNOWN OBJECT TYPE: ".. name )
		end
	end
	
	return objectType
end
--
function UniversalAutoload.getMaterialType(object)
	if object.fillType ~= nil then
		return object.fillType
	elseif object.spec_fillUnit ~= nil then
		local fillUnitIndex = object.spec_fillUnit.fillUnits[1].fillType
		return fillUnitIndex
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

	local node = UniversalAutoload.getObjectNode(object)
	if node == nil then
		return false
	end
	
	if g_currentMission.nodeToObject[self.rootNode]==nil then
		return false
	end
	
	local x, y, z = localToLocal(node, spec.loadArea.rootNode, 0, 0, 0)
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

	if (UniversalAutoload.debugEnabled or spec.showDebug) and not g_gui:getIsGuiVisible() then
	
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
		
		if spec.currentLoadingPattern ~= nil then
			for _, test in ipairs(spec.currentLoadingPattern) do
				UniversalAutoload.DrawDebugPallet( test.node, test.sizeX, test.sizeY, test.sizeZ, true, false, GREY)
			end
		end
		if spec.test ~= nil then
			UniversalAutoload.DrawDebugPallet( spec.test.node, spec.test.sizeX, spec.test.sizeY, spec.test.sizeZ, true, false, WHITE)
		end

		if spec.showDebug then
			for _, trigger in pairs(spec.triggers) do
				if trigger.name == "rearAutoTrigger" or trigger.name == "leftAutoTrigger" or trigger.name == "rightAutoTrigger" then
					DebugUtil.drawDebugCube(trigger.node, 1,1,1, unpack(YELLOW))
				elseif trigger.name == "leftPickupTrigger" or trigger.name == "rightPickupTrigger" then
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

		local W, H, L = spec.loadArea.width, spec.loadArea.height, spec.loadArea.length
		if not spec.showDebug then H = 0 end
		UniversalAutoload.DrawDebugPallet( spec.loadArea.rootNode,  W, H, L, true, false, WHITE )
		UniversalAutoload.DrawDebugPallet( spec.loadArea.startNode, W, 0, 0, true, false, GREEN )
		UniversalAutoload.DrawDebugPallet( spec.loadArea.endNode,   W, 0, 0, true, false, RED )

	end
end
--
function UniversalAutoload.DrawDebugPallet( node, w, h, l, showCube, showAxis, colour, offset )

	if node ~= nil and node ~= 0 then
		-- colour for square
		local r, g, b = unpack(colour) --(r or 1), (g or 1), (b or 1)
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