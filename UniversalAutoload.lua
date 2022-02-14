-- ============================================================= --
-- Universal Autoload MOD - SPECIALISATION
-- ============================================================= --
UniversalAutoload = {}

UniversalAutoload.name = g_currentModName
UniversalAutoload.path = g_currentModDirectory
UniversalAutoload.debugEnabled = false
UniversalAutoload.delayTime = 200

print("  UNIVERSAL AUTOLOAD TEST VERSION: 005")

-- EVENTS
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
    local vehicleKey = "universalAutoload.vehicleConfigurations.vehicleConfiguration(?)"
	UniversalAutoload.xmlSchema:register(XMLValueType.STRING, vehicleKey.."#configFileName", "Vehicle config file xml full path - used to identify supported vechicles", nil)
	UniversalAutoload.xmlSchema:register(XMLValueType.VECTOR_TRANS, vehicleKey..".loadingArea#offset", "Offset to the centre of the loading area", "0 0 0")
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, vehicleKey..".loadingArea#height", "Height of the loading area", 0)
	UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, vehicleKey..".loadingArea#length", "Length of the loading area", 0)
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, vehicleKey..".loadingArea#width", "Width of the loading area", 0)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, vehicleKey..".options#isCurtainTrailer", "Automatically detect the available load side (if the trailer has curtain sides)", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, vehicleKey..".options#enableRearLoading", "Use the automatic rear loading trigger", false)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, vehicleKey..".options#noLoadingIfUnfolded", "Prevent loading when unfolded", false)
	
	local containerTypeKey = "universalAutoload.containerTypeConfigurations.containerTypeConfiguration(?)"
	local objectTypeKey = "universalAutoload.containerTypeConfigurations.containerTypeConfiguration(?).objectType(?)"
	UniversalAutoload.xmlSchema:register(XMLValueType.STRING, containerTypeKey.."#containerType", "The loading type category to group under in the menu)", "ANY")
	UniversalAutoload.xmlSchema:register(XMLValueType.STRING, objectTypeKey.."#name", "Simplified Pallet Configuration Filename", "UNKNOWN")
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeX", "Width of the pallet", 1.5)
	UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeY", "Height of the pallet", 2.0)
    UniversalAutoload.xmlSchema:register(XMLValueType.FLOAT, objectTypeKey.."#sizeZ", "Length of the pallet", 1.5)
	UniversalAutoload.xmlSchema:register(XMLValueType.BOOL, objectTypeKey.."#alwaysRotate", "Should always rotate to face outwards for manual unloading", false)
	
	
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).universalAutoload#tipside", "Last used tip side", "none")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).universalAutoload#loadside", "Last used load side", "both")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).universalAutoload#loadWidth", "Last used load width", 0)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).universalAutoload#loadLength", "Last used load length", 0)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).universalAutoload#loadHeight", "Last used load height", 0)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).universalAutoload#actualWidth", "Last used total load width", 0)
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).universalAutoload#materialIndex", "Last used material type", 1)
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).universalAutoload#containerIndex", "Last used container type", 1)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).universalAutoload#loadingFilter", "TRUE=Load full pallets only; FALSE=Load any pallets", false)
	
	local schemaVehicle = Vehicle.xmlSchema
	local key = "vehicle.universalAutoload.vehicleConfigurations.vehicleConfiguration(?)"
	schemaVehicle:register(XMLValueType.STRING, key.."#name", "Configuration Name", "UNKNOWN")
	schemaVehicle:register(XMLValueType.VECTOR_TRANS, key..".loadingArea#offset", "Offset to the centre of the loading area", "0 0 0")
    schemaVehicle:register(XMLValueType.FLOAT, key..".loadingArea#height", "Height of the loading area", 0)
	schemaVehicle:register(XMLValueType.FLOAT, key..".loadingArea#length", "Length of the loading area", 0)
    schemaVehicle:register(XMLValueType.FLOAT, key..".loadingArea#width", "Width of the loading area", 0)
	schemaVehicle:register(XMLValueType.BOOL, key..".options#isCurtainTrailer", "Automatically detect the available load side (if the trailer has curtain sides)", false)
	schemaVehicle:register(XMLValueType.BOOL, key..".options#enableRearLoading", "Use the automatic rear loading trigger", false)
	schemaVehicle:register(XMLValueType.BOOL, key..".options#noLoadingIfUnfolded", "Prevent loading when unfolded", false)

end
--
function UniversalAutoload.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "isValidForLoading", UniversalAutoload.isValidForLoading)
    SpecializationUtil.registerFunction(vehicleType, "isValidForUnloading", UniversalAutoload.isValidForUnloading)
    SpecializationUtil.registerFunction(vehicleType, "getPalletIsSelectedType", UniversalAutoload.getPalletIsSelectedType)
    SpecializationUtil.registerFunction(vehicleType, "getPalletIsSelectedLoadside", UniversalAutoload.getPalletIsSelectedLoadside)
	
	SpecializationUtil.registerFunction(vehicleType, "changeMaterialTypeIndex", UniversalAutoload.changeMaterialTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setMaterialTypeIndex", UniversalAutoload.setMaterialTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "changeContainerTypeIndex", UniversalAutoload.changeContainerTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setContainerTypeIndex", UniversalAutoload.setContainerTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentTipside", UniversalAutoload.setCurrentTipside)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentLoadside", UniversalAutoload.setCurrentLoadside)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingFilter", UniversalAutoload.setLoadingFilter)

    SpecializationUtil.registerFunction(vehicleType, "startLoading", UniversalAutoload.startLoading)
    SpecializationUtil.registerFunction(vehicleType, "stopLoading", UniversalAutoload.stopLoading)
    SpecializationUtil.registerFunction(vehicleType, "startUnloading", UniversalAutoload.startUnloading)
    SpecializationUtil.registerFunction(vehicleType, "resetLoadingState", UniversalAutoload.resetLoadingState)
	
    SpecializationUtil.registerFunction(vehicleType, "loadObject", UniversalAutoload.loadObject)
    SpecializationUtil.registerFunction(vehicleType, "unloadObject", UniversalAutoload.unloadObject)
    SpecializationUtil.registerFunction(vehicleType, "addLoadPlace", UniversalAutoload.addLoadPlace)
	SpecializationUtil.registerFunction(vehicleType, "getLoadPlace", UniversalAutoload.getLoadPlace)
	
    SpecializationUtil.registerFunction(vehicleType, "getIsValidObject", UniversalAutoload.getIsValidObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutoloadingAllowed", UniversalAutoload.getIsAutoloadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "addLoadedObject", UniversalAutoload.addLoadedObject)
    SpecializationUtil.registerFunction(vehicleType, "removeLoadedObject", UniversalAutoload.removeLoadedObject)
	
	SpecializationUtil.registerFunction(vehicleType, "testPalletLocationIsFull", UniversalAutoload.testPalletLocationIsFull)
	SpecializationUtil.registerFunction(vehicleType, "testPalletLocationIsEmpty", UniversalAutoload.testPalletLocationIsEmpty)
	SpecializationUtil.registerFunction(vehicleType, "testUnloadLocationIsEmpty", UniversalAutoload.testUnloadLocationIsEmpty)
    SpecializationUtil.registerFunction(vehicleType, "overlapCallback", UniversalAutoload.overlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "palletOverlapCallback", UniversalAutoload.palletOverlapCallback)
	
    SpecializationUtil.registerFunction(vehicleType, "playerTriggerCallback", UniversalAutoload.playerTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "loadingTriggerCallback", UniversalAutoload.loadingTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "unloadingTriggerCallback", UniversalAutoload.unloadingTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "rearLoadingTriggerCallback", UniversalAutoload.rearLoadingTriggerCallback)					
    SpecializationUtil.registerFunction(vehicleType, "onDeleteLoadedObject", UniversalAutoload.onDeleteLoadedObject)
	
    SpecializationUtil.registerFunction(vehicleType, "updateActionEventText", UniversalAutoload.updateActionEventText)
    SpecializationUtil.registerFunction(vehicleType, "updateActionEventKeys", UniversalAutoload.updateActionEventKeys)
	
    SpecializationUtil.registerFunction(vehicleType, "getIsFolding", UniversalAutoload.getIsFolding)
    SpecializationUtil.registerFunction(vehicleType, "forceRaiseActive", UniversalAutoload.forceRaiseActive)
    SpecializationUtil.registerFunction(vehicleType, "updatePlayerTriggerState", UniversalAutoload.updatePlayerTriggerState)
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
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", UniversalAutoload)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", UniversalAutoload)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", UniversalAutoload)
end
--
function UniversalAutoload.removeEventListeners(vehicleType)
    SpecializationUtil.removeEventListener(vehicleType, "onLoad", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onPostLoad", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onRegisterActionEvents", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onReadStream", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onWriteStream", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onDelete", UniversalAutoload)
	SpecializationUtil.removeEventListener(vehicleType, "onUpdate", UniversalAutoload)
    SpecializationUtil.removeEventListener(vehicleType, "onActivate", UniversalAutoload)
	SpecializationUtil.removeEventListener(vehicleType, "onDeactivate", UniversalAutoload)
	SpecializationUtil.removeEventListener(vehicleType, "onFoldStateChanged", UniversalAutoload)
end

-- HOOK PLAYER ON FOOT UPDATE OBJECTS/TRIGGERS
function UniversalAutoload:OverwrittenUpdateObjects(superFunc)

	if self.mission.player.isControlled ~= self.mission.player.isEntered then
		print("self.mission.player.isControlled: "..tostring(self.mission.player.isControlled))
		print("self.mission.player.isEntered: "..tostring(self.mission.player.isEntered))
	end

	if self.mission.player.isControlled or self.mission.player.isEntered then
		local player = self.mission.player
		local playerId = player.userId
	
		local closestVehicle = nil
		local closestVehicleDistance = 50 --math.huge
		for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
			local SPEC = vehicle.spec_universalAutoload
			if SPEC.playerInTrigger[playerId] == true then
				local distance = calcDistanceFrom(player.rootNode, vehicle.rootNode)
				if distance < closestVehicleDistance then
					closestVehicle = vehicle
					closestVehicleDistance = distance
				end
			end
		end

		for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
			local SPEC = vehicle.spec_universalAutoload
			
			if SPEC.playerInTrigger[playerId] == true then
				
				if vehicle == closestVehicle then
					if not SPEC.isActivated then
						-- USE THIS FOR PLAYER
						vehicle:forceRaiseActive()
						vehicle:updateActionEventKeys()
						g_currentMission:addExtraPrintText(vehicle:getFullName())
					else
						vehicle:clearActionEventsTable(SPEC.actionEvents)
					end
				else
					-- NOT CLOSEST FOR PLAYER
					vehicle:clearActionEventsTable(SPEC.actionEvents)
				end
				
			else
				-- LEAVING TRIGGER
				if SPEC.playerInTrigger[playerId] == false then
					print("PLAYER LEFT TRIGGER")
					vehicle:forceRaiseActive()
					vehicle:updatePlayerTriggerState(playerId, nil)
					vehicle:clearActionEventsTable(SPEC.actionEvents)
				end
			end

		end
		if not closestVehicle then
			return superFunc(self)
		end	
	end
end
ActivatableObjectsSystem.updateObjects = Utils.overwrittenFunction(ActivatableObjectsSystem.updateObjects, UniversalAutoload.OverwrittenUpdateObjects)


-- ACTION EVENT FUNCTIONS
function UniversalAutoload:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_universalAutoload
		
		if not spec.available or spec.actionEvents==nil then
            return
        end
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
			print("onRegisterActionEvents: "..self:getFullName())
			self:updateActionEventKeys()
        end
    end
end
--
function UniversalAutoload:updateActionEventKeys()
	if self.isClient then
		local spec = self.spec_universalAutoload
		
		if spec.actionEvents ~= nil and next(spec.actionEvents) == nil then
			-- print("updateActionEventKeys: "..self:getFullName())
			local actions = UniversalAutoload.ACTIONS
			local ignoreCollisions = false
			
			--function Vehicle:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
			
			-- function InputBinding:registerActionEvent(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings, reportAnyDeviceCollision)
			--g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)
		
			local res, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_LOADING, self, UniversalAutoload.actionEventToggleLoading, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			spec.toggleLoadingActionEventId = actionEventId
			print("toggleLoadingActionEvent:  "..tostring(res))
			

			local res, actionEventId = self:addActionEvent(spec.actionEvents, actions.UNLOAD_ALL, self, UniversalAutoload.actionEventUnloadAll, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			spec.unloadAllActionEventId = actionEventId
			print("unloadAllActionEvent:  "..tostring(res))

			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_FW, self, UniversalAutoload.actionEventCycleMaterial_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.cycleMaterialActionEventId = actionEventId

			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_MATERIAL_BW, self, UniversalAutoload.actionEventCycleMaterial_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			
			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_MATERIALS, self, UniversalAutoload.actionEventSelectAllMaterials, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			
			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_FW, self, UniversalAutoload.actionEventCycleContainer_FW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.cycleContainerActionEventId = actionEventId

			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.CYCLE_CONTAINER_BW, self, UniversalAutoload.actionEventCycleContainer_BW, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.SELECT_ALL_CONTAINERS, self, UniversalAutoload.actionEventSelectAllContainers, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			
			local _, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_FILTER, self, UniversalAutoload.actionEventToggleFilter, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.toggleLoadingFilterActionEventId = actionEventId
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_TIPSIDE, self, UniversalAutoload.actionEventToggleTipside, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.toggleTipsideActionEventId = actionEventId
			
			local valid, actionEventId = self:addActionEvent(spec.actionEvents, actions.TOGGLE_BELTS, self, UniversalAutoload.actionEventToggleBelts, false, true, false, true, nil, nil, ignoreCollisions, true)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			spec.toggleBeltsActionEventId = actionEventId
			
			UniversalAutoload.updateToggleBeltsActionEvent(self)
			UniversalAutoload.updateCycleMaterialActionEvent(self)
			UniversalAutoload.updateCycleContainerActionEvent(self)
			UniversalAutoload.updateToggleFilterActionEvent(self)
			UniversalAutoload.updateToggleTipsideActionEvent(self)
			UniversalAutoload.updateToggleLoadingActionEvent(self)
			
		end
	end
end
--
function UniversalAutoload:updateToggleBeltsActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.toggleBeltsActionEventId ~= nil then

		g_inputBinding:setActionEventActive(spec.toggleBeltsActionEventId, true)
		
		local tensionBeltsText
		if self.spec_tensionBelts.areBeltsFasten then
			tensionBeltsText = g_i18n:getText("action_unfastenTensionBelts")
		else
			tensionBeltsText = g_i18n:getText("action_fastenTensionBelts")
		end
		g_inputBinding:setActionEventText(spec.toggleBeltsActionEventId, tensionBeltsText)

	end
end
--
function UniversalAutoload:updateCycleMaterialActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.cycleMaterialActionEventId ~= nil then
	
		-- Material Type: ALL / <MATERIAL>
		if not spec.isLoading then
			local materialTypeText = g_i18n:getText("universalAutoload_materialType")..": "..UniversalAutoload.MATERIALS[spec.currentMaterialIndex]
			--g_i18n:getText("universalAutoload_"..UniversalAutoload.getSelectedTypeName(self))
			g_inputBinding:setActionEventText(spec.cycleMaterialActionEventId, materialTypeText)
		end

	end
end
--
function UniversalAutoload:updateCycleContainerActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.cycleContainerActionEventId ~= nil then
	
		-- Container Type: ALL / <PALLET_TYPE>
		if not spec.isLoading then
			local containerTypeText = g_i18n:getText("universalAutoload_containerType")..": "..g_i18n:getText("universalAutoload_"..UniversalAutoload.getSelectedTypeName(self))
			g_inputBinding:setActionEventText(spec.cycleContainerActionEventId, containerTypeText)
		end

	end
end
--
function UniversalAutoload:updateToggleFilterActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.toggleLoadingFilterActionEventId ~= nil then
	
		-- Loading Filter: ANY / FULL ONLY
		local loadingFilterText
		if spec.currentLoadingFilter then
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_enabled")
		else
			loadingFilterText = g_i18n:getText("universalAutoload_loadingFilter")..": "..g_i18n:getText("universalAutoload_disabled")
		end
		g_inputBinding:setActionEventText(spec.toggleLoadingFilterActionEventId, loadingFilterText)

	end
end
--
function UniversalAutoload:updateToggleTipsideActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.toggleTipsideActionEventId ~= nil then
		
		-- Tipside: NONE/BOTH/LEFT/RIGHT/
		if spec.currentTipside == "none" then
			g_inputBinding:setActionEventActive(spec.toggleTipsideActionEventId, false)
		else
			local tipsideText = g_i18n:getText("universalAutoload_tipside")..": "..g_i18n:getText("universalAutoload_"..spec.currentTipside)
			g_inputBinding:setActionEventText(spec.toggleTipsideActionEventId, tipsideText)
		end

	end
end
--
function UniversalAutoload:updateToggleLoadingActionEvent()
	local spec = self.spec_universalAutoload
	
	if spec.toggleLoadingActionEventId ~= nil and spec.unloadAllActionEventId ~= nil  then

		-- Activate/Deactivate the LOAD key binding
		print("UPDATE LOADING ACTION EVENT")
		if spec.isLoading then
			local stopLoadingText = g_i18n:getText("universalAutoload_stopLoading")
			g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, stopLoadingText)
		else
			if spec.doPostLoadDelay or spec.validLoadCount == 0 or spec.currentLoadside == "none" or
			   (spec.noLoadingIfUnfolded and (self:getIsFolding() or self:getIsUnfolded())) then
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, false)
			else
				local startLoadingText = g_i18n:getText("universalAutoload_startLoading")
				if UniversalAutoload.debugEnabled then startLoadingText = startLoadingText.." ("..tostring(spec.validLoadCount)..")" end
				g_inputBinding:setActionEventText(spec.toggleLoadingActionEventId, startLoadingText)
				g_inputBinding:setActionEventActive(spec.toggleLoadingActionEventId, true)
			end
		end

		-- Activate/Deactivate the UNLOAD key binding
		if spec.doPostLoadDelay or spec.isLoading or spec.isUnloading or
		   spec.validUnloadCount == 0 or spec.currentTipside == "none" then
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, false)
			
			-- print("spec.doPostLoadDelay: "..tostring(spec.doPostLoadDelay))
			-- print("spec.isLoading: "..tostring(spec.isLoading))
			-- print("spec.isUnloading: "..tostring(spec.isUnloading))
			-- print("spec.validUnloadCount: "..tostring(spec.validUnloadCount))
			-- print("spec.currentTipside: "..tostring(spec.currentTipside))
			
		else
			local unloadText = g_i18n:getText("universalAutoload_unloadAll")
			if UniversalAutoload.debugEnabled then unloadText = unloadText.." ("..tostring(spec.validUnloadCount)..")" end
			g_inputBinding:setActionEventText(spec.unloadAllActionEventId, unloadText)
			g_inputBinding:setActionEventActive(spec.unloadAllActionEventId, true)
		end
		
	end
	
end

-- ACTION EVENTS
function UniversalAutoload.actionEventToggleBelts(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventToggleBelts: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if self.spec_tensionBelts.areBeltsFasten then
		self:setAllTensionBeltsActive(false)
	else
		self:setAllTensionBeltsActive(true)
	end
	UniversalAutoload.updateToggleBeltsActionEvent(self)
end
--
function UniversalAutoload.actionEventCycleMaterial_FW(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventCycleMaterial_FW: "..self:getFullName())
	self:changeMaterialTypeIndex(1)
end
--
function UniversalAutoload.actionEventCycleMaterial_BW(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventCycleMaterial_BW: "..self:getFullName())
	self:changeMaterialTypeIndex(-1)
end
--
function UniversalAutoload.actionEventSelectAllMaterials(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventSelectAllMaterials: "..self:getFullName())
	self:setMaterialTypeIndex(1)
end
--
function UniversalAutoload.actionEventCycleContainer_FW(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventCycleContainer_FW: "..self:getFullName())
	self:changeContainerTypeIndex(1)
end
-- --
function UniversalAutoload.actionEventCycleContainer_BW(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventCycleContainer_BW: "..self:getFullName())
	self:changeContainerTypeIndex(-1)
end
--
function UniversalAutoload.actionEventSelectAllContainers(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventSelectAllContainers: "..self:getFullName())
	self:setContainerTypeIndex(1)
end
--
function UniversalAutoload.actionEventToggleFilter(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventToggleFilter: "..self:getFullName())
	local spec = self.spec_universalAutoload
	
	local state = not spec.currentLoadingFilter

	self:setLoadingFilter(state)
end
--
function UniversalAutoload.actionEventToggleTipside(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventToggleTipside: "..self:getFullName())
	local spec = self.spec_universalAutoload
	
	local tipside
	if spec.currentTipside == "left" then
		tipside = "right"
	else
		tipside = "left"
	end
	
	self:setCurrentTipside(tipside)
	
end
--
function UniversalAutoload.actionEventToggleLoading(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventToggleLoading: "..self:getFullName())
    local spec = self.spec_universalAutoload

	if not spec.isLoading then
		self:startLoading()
	else
		self:stopLoading()
	end

end
--
function UniversalAutoload.actionEventUnloadAll(self, actionName, inputValue, callbackState, isAnalog)
	print("actionEventUnloadAll: "..self:getFullName())
	
	self:startUnloading()
	
end

-- EVENT FUNCTIONS
function UniversalAutoload:changeMaterialTypeIndex(increment)
	local spec = self.spec_universalAutoload
	local typeIndex = spec.currentMaterialIndex + increment

	if typeIndex > #UniversalAutoload.MATERIALS then
		typeIndex = 1
	elseif typeIndex < 1 then
		typeIndex = #UniversalAutoload.MATERIALS
	end

	self:setMaterialTypeIndex(typeIndex)
end
--
function UniversalAutoload:setMaterialTypeIndex(typeIndex, noEventSend)
	print("setMaterialTypeIndex: "..self:getFullName().." "..tostring(typeIndex))
	local spec = self.spec_universalAutoload

	spec.currentMaterialIndex = math.min(math.max(typeIndex, 1), table.getn(UniversalAutoload.MATERIALS))

	UniversalAutoloadSetMaterialTypeEvent.sendEvent(self, typeIndex, noEventSend)
	UniversalAutoload.updateCycleMaterialActionEvent(self)
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
	end
end
--
function UniversalAutoload:changeContainerTypeIndex(increment)
	local spec = self.spec_universalAutoload
	local loadType = spec.currentContainerIndex + increment

	if loadType > #UniversalAutoload.TYPES then
		loadType = 1
	elseif loadType < 1 then
		loadType = #UniversalAutoload.TYPES
	end

	self:setContainerTypeIndex(loadType)
end
--
function UniversalAutoload:setContainerTypeIndex(typeIndex, noEventSend)
	print("setContainerTypeIndex: "..self:getFullName().." "..tostring(typeIndex))
	local spec = self.spec_universalAutoload

	spec.currentContainerIndex = math.min(math.max(typeIndex, 1), table.getn(UniversalAutoload.TYPES))

	UniversalAutoloadSetContainerTypeEvent.sendEvent(self, typeIndex, noEventSend)
	UniversalAutoload.updateCycleContainerActionEvent(self)
	if self.isServer then
		UniversalAutoload.countActivePallets(self)
	end
end
--
function UniversalAutoload:setLoadingFilter(state, noEventSend)
	print("setLoadingFilter: "..self:getFullName().." "..tostring(state))
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
	print("setTipside: "..self:getFullName().." - "..tostring(tipside))
	local spec = self.spec_universalAutoload
	
	spec.currentTipside = tipside
	
	UniversalAutoloadSetTipsideEvent.sendEvent(self, tipside, noEventSend)
	UniversalAutoload.updateToggleTipsideActionEvent(self)
end
--
function UniversalAutoload:setCurrentLoadside(loadside, noEventSend)
	print("setLoadside: "..self:getFullName().." - "..tostring(loadside))
	local spec = self.spec_universalAutoload
	
	spec.currentLoadside = loadside
	
	UniversalAutoloadSetLoadsideEvent.sendEvent(self, loadside, noEventSend)
	if self.isServer then
		self:updateActionEventText()
	end
end
--
function UniversalAutoload:startLoading(noEventSend)
	local spec = self.spec_universalAutoload

	if not spec.isLoading then
		print("Start Loading: "..self:getFullName() )
		spec.isLoading = true
		
		if self.isServer then
			spec.loadDelayTime = math.huge
		
			spec.sortedObjectsToLoad = {}
			for _, object in pairs(spec.objectsToLoad) do
				if self:isValidForLoading(object) then
					local node = object.nodeId or object.components[1].node
					local x, y, z = localToLocal(node, spec.loadArea.startNode, 0, 0, 0)
					object.distance = math.abs(x) + math.abs(z) - y
					
					local containerType = UniversalAutoload.getContainerType(object)
					object.width = containerType.width or 1
					object.length = containerType.length or 1
					object.height = containerType.height or 1
					--object.index = containerType.materialIndex
					object.index = containerType.containerIndex or 1
					table.insert(spec.sortedObjectsToLoad, object)
				end
			end
			if #spec.sortedObjectsToLoad > 1 then
				table.sort(spec.sortedObjectsToLoad, sortPalletsForLoading)
			end
			
			self:setAllTensionBeltsActive(false)
		end
		
		UniversalAutoloadStartLoadingEvent.sendEvent(self, noEventSend)
		UniversalAutoload.updateToggleLoadingActionEvent(self)
	else
		print("Start Loading CALLED TWICE...")
	end
end
--
function sortPalletsForLoading(w1,w2)

	if w1.index == w2.index and w1.width == w2.width and w1.length == w2.length and w1.height == w2.height and  w1.distance < w2.distance then
		return true
	elseif w1.index == w2.index and w1.width == w2.width and  w1.length == w2.length and  w1.height > w2.height then
		return true
	elseif w1.index == w2.index and w1.width == w2.width and  w1.length > w2.length then
		return true
	elseif w1.index == w2.index and w1.width > w2.width then
		return true
	elseif w1.index < w2.index then
		return true
	end
end
--
function UniversalAutoload:stopLoading(noEventSend)
	local spec = self.spec_universalAutoload
	
	if spec.isLoading then
		print("Stop Loading: "..self:getFullName() )
		spec.isLoading = false
		spec.doPostLoadDelay = true
		
		if self.isServer then
			spec.loadDelayTime = 0
			spec.doSetTensionBelts = true
		end
		
		UniversalAutoloadStopLoadingEvent.sendEvent(self, noEventSend)
		UniversalAutoload.updateToggleLoadingActionEvent(self)
	else
		print("Stop Loading CALLED TWICE...")
	end
end
--
function UniversalAutoload:startUnloading(noEventSend)
	local spec = self.spec_universalAutoload

	if not spec.isUnloading then
		print("Start Unloading: "..self:getFullName() )
		if spec.currentTipside ~= "none" then
			--spec.isUnloading = true

			if self.isServer then
			
				--UniversalAutoload.countActivePallets(self)
				if spec.loadedObjects ~= nil then
	
					spec.objectsToUnload = {}
					for _, object in pairs(spec.loadedObjects) do
						if self:isValidForUnloading(object) then
						
							local p = {}
							p.x, p.y, p.z, p.rx, p.ry, p.rz = UniversalAutoload.getUnloadingTransform(self, object)
							
							local unloadPlace = {}
							unloadPlace.node = createTransformGroup("unloadPlace")
							setRotation(unloadPlace.node, p.rx, p.ry, p.rz)
							setTranslation(unloadPlace.node, p.x, p.y, p.z)
							
							local autoLoadType = UniversalAutoload.getContainerType(object)
							unloadPlace.sizeX = autoLoadType.sizeX
							unloadPlace.sizeY = autoLoadType.sizeY
							unloadPlace.sizeZ = autoLoadType.sizeZ
							
							local _, heightAbovePlace, _ = localToLocal(unloadPlace.node, spec.loadArea.rootNode, 0, 0, 0)
							local heightAboveGround = DensityMapHeightUtil.getCollisionHeightAtWorldPos(p.x, p.y, p.z) + 0.1
							--local heightAboveGround = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, p.x, p.y, p.z) + 0.1
							unloadPlace.heightAbovePlace = heightAbovePlace
							unloadPlace.heightAboveGround = heightAboveGround - p.y

							spec.objectsToUnload[object] = unloadPlace
							
						end
					end
				
					spec.unloadingAreaClear = true
					for object, unloadPlace in pairs(spec.objectsToUnload) do
					
						local thisAreaClear = false
						local x, y, z = getTranslation(unloadPlace.node)
						for height = unloadPlace.heightAboveGround, 0, 0.1 do
						
							setTranslation(unloadPlace.node, x, y+height, z)
							if self:testUnloadLocationIsEmpty(unloadPlace) then
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
	
				if spec.objectsToUnload ~= nil and spec.unloadingAreaClear then
					self:setAllTensionBeltsActive(false)
					for object, unloadPlace in pairs(spec.objectsToUnload) do
						if self:isValidForUnloading(object) then
							self:unloadObject(object, unloadPlace)
						end
					end
					spec.objectsToUnload = {}
					spec.resetLoadingPattern = true

					if spec.totalUnloadCount > 0  then
						spec.doSetTensionBelts = true
					end
				else
					g_currentMission:showBlinkingWarning(g_i18n:getText("warning_UNIVERSALAUTOLOAD_CLEAR_UNLOADING_AREA"), 2000);
				end
			end
			
			--spec.isUnloading = false
			spec.doPostLoadDelay = true

		else
			print("CANNOT UNLOAD IN THIS STATE")
		end


		UniversalAutoloadStartUnloadingEvent.sendEvent(self, noEventSend)
		UniversalAutoload.updateToggleLoadingActionEvent(self)
	else
		print("Start Unloading CALLED TWICE...")
	end
end
--
function UniversalAutoload:resetLoadingState(noEventSend)
	print("RESET Loading State: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isServer then
		if spec.doSetTensionBelts then
			spec.doSetTensionBelts = false
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
	--print("updateActionEventText: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isClient then --and g_dedicatedServer==nil then
		if loadCount ~= nil then
			spec.validLoadCount = loadCount
		end
		if unloadCount ~= nil then
			spec.validUnloadCount = unloadCount
		end
		print("Valid Load Count = " .. tostring(spec.validLoadCount) .. " / " .. tostring(spec.validUnloadCount) )
	end
	
	if self.isServer then
		print("updateActionEventText - SEND EVENT")
		UniversalAutoloadUpdateActionEvents.sendEvent(self, spec.validLoadCount, spec.validUnloadCount, noEventSend)
	end
	
	UniversalAutoload.updateToggleLoadingActionEvent(self)
end
function UniversalAutoload:forceRaiseActive(state, noEventSend)
	--print("forceRaiseActive: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if self.isServer then
		--print("SERVER RAISE ACTIVE "..tostring(state))
		self:raiseActive()
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end
	
	if state ~= nil then
		spec.isActivated = state
	end
	
	UniversalAutoloadRaiseActiveEvent.sendEvent(self, state, noEventSend)
	UniversalAutoload.updateToggleLoadingActionEvent(self)

end
--
function UniversalAutoload:updatePlayerTriggerState(playerId, inTrigger, noEventSend)
	--print("updatePlayerTriggerState: "..self:getFullName() )
	local spec = self.spec_universalAutoload
	
	if playerId ~= nil then
		spec.playerInTrigger[playerId] = inTrigger
	end
	
	UniversalAutoloadPlayerTriggerEvent.sendEvent(self, playerId, inTrigger, noEventSend)
end

-- MAIN "ON LOAD" INITIALISATION FUNCTION
function UniversalAutoload:onLoad(savegame)

	self.spec_universalAutoload = {}
	local spec = self.spec_universalAutoload
	
	local configFileName = self.configFileName
	if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] ~= nil then
		-- apply to selected configurations only (with tension belts and not tippers)
		if self.spec_tensionBelts.hasTensionBelts and not self.spec_fillUnit.hasExactFillRootNodes then
			print("UniversalAutoload - supported vehicle: "..self:getFullName() )
			-- define the loading area parameters from supported vehicles settings file
			local config = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
			spec.loadArea = {}
			spec.loadArea.width  = config.width
			spec.loadArea.length = config.length
			spec.loadArea.height = config.height
			spec.loadArea.offset = config.offset	
			spec.isCurtainTrailer = config.isCurtainTrailer
			spec.enableRearLoading = config.enableRearLoading
			spec.noLoadingIfUnfolded = config.noLoadingIfUnfolded
		end
	else
		print("LOADING XML: " .. configFileName)
		local xmlFile = XMLFile.load("configXml", configFileName, Vehicle.xmlSchema)
		if xmlFile ~= 0 then
			local i = 0
			while true do
				local configKey = string.format("vehicle.universalAutoload.vehicleConfigurations.vehicleConfiguration(%d)", i)

				if not xmlFile:hasProperty(configKey) then
					break
				end
				
				print("UniversalAutoload - vaild vehicle: "..self:getFullName() )
				-- define the loading area parameters from vechicle.xml file
				--local name = xmlFile:getValue(configKey.."#name")
				spec.loadArea = {}
				spec.loadArea.width  = xmlFile:getValue(configKey..".loadingArea#width")
				spec.loadArea.length = xmlFile:getValue(configKey..".loadingArea#length")
				spec.loadArea.height = xmlFile:getValue(configKey..".loadingArea#height")
				spec.loadArea.offset = xmlFile:getValue(configKey..".loadingArea#offset", "0 0 0", true)	
				spec.isCurtainTrailer = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
				spec.enableRearLoading = xmlFile:getValue(configKey..".options#enableRearLoading", false)
				spec.noLoadingIfUnfolded = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
				print("  >> "..configFileName)

				i = i + 1
			end
		end
	end
	
	if  spec.loadArea ~= nil and
		spec.loadArea.width ~= nil and
		spec.loadArea.length ~= nil and
		spec.loadArea.height ~= nil and
		spec.loadArea.offset ~= nil then
		print("settings found for '"..self:getFullName().."'")
		spec.available = true
	else
		--print("SETTINGS NOT FOUND for '"..self:getFullName().."'")
		spec.available = false
		UniversalAutoload.removeEventListeners(self)
		return
	end

    if self.isServer then

		--initialise server only arrays
		spec.triggers = {}
		spec.currentLoadingPattern = {}
		spec.objectsToLoad = {}
		spec.loadedObjects = {}
		spec.rearLoadingObjects = {}
		
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
            addTrigger(unloadingTrigger.node, "unloadingTriggerCallback", self)
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
            addTrigger(playerTrigger.node, "playerTriggerCallback", self)
		end

        local leftTrigger = {}
		leftTrigger.node = I3DUtil.getChildByName(triggersRootNode, "pickupTrigger1")
		if leftTrigger.node ~= nil then
			leftTrigger.name = "leftTrigger"
			link(spec.loadArea.rootNode, leftTrigger.node)
			
			local width, height, length = 1.66*spec.loadArea.width, 2*spec.loadArea.height, spec.loadArea.length+spec.loadArea.width/2

			setRotation(leftTrigger.node, 0, 0, 0)
			setTranslation(leftTrigger.node, 1.1*(width+spec.loadArea.width)/2, 0, 0)
			setScale(leftTrigger.node, width, height, length)

			table.insert(spec.triggers, leftTrigger)
			addTrigger(leftTrigger.node, "loadingTriggerCallback", self)
		end
		
		local rightTrigger = {}
		rightTrigger.node = I3DUtil.getChildByName(triggersRootNode, "pickupTrigger2")
		if rightTrigger.node ~= nil then
			rightTrigger.name = "rightTrigger"
			link(spec.loadArea.rootNode, rightTrigger.node)
			
			local width, height, length = 1.66*spec.loadArea.width, 2*spec.loadArea.height, spec.loadArea.length+spec.loadArea.width/2

			setRotation(rightTrigger.node, 0, 0, 0)
			setTranslation(rightTrigger.node, -1.1*(width+spec.loadArea.width)/2, 0, 0)
			setScale(rightTrigger.node, width, height, length)

			table.insert(spec.triggers, rightTrigger)
			addTrigger(rightTrigger.node, "loadingTriggerCallback", self)
		end
		
		if spec.enableRearLoading then
			local rearTrigger = {}
			rearTrigger.node = I3DUtil.getChildByName(triggersRootNode, "pickupTrigger3")
			if rearTrigger.node ~= nil then
				rearTrigger.name = "rearTrigger"
				link(spec.loadArea.rootNode, rearTrigger.node)
				
				local depth = 0.05
				local boundary = spec.loadArea.width/4
				local width, height, length = spec.loadArea.width-boundary, spec.loadArea.height, depth

				setRotation(rearTrigger.node, 0, 0, 0)
				setTranslation(rearTrigger.node, 0, spec.loadArea.height/2, (depth+boundary-spec.loadArea.length)/2 )
				setScale(rearTrigger.node, width, height, length)

				table.insert(spec.triggers, rearTrigger)
				addTrigger(rearTrigger.node, "rearLoadingTriggerCallback", self)
			end
		end
		

		--server only
		spec.isLoading = false
		spec.isUnloading = false
		spec.doPostLoadDelay = false
		spec.doSetTensionBelts = false
		spec.totalLoadCount = 0
		spec.totalUnloadCount = 0
		spec.validLoadCount = 0
		spec.validUnloadCount = 0
		
		-- --current load dimensions
		-- spec.currentLoadWidth = 0
		-- spec.currentLoadHeight = 0
		-- spec.currentLoadLength = 0
		-- spec.currentActualWidth = 0
		spec.resetLoadingPattern = true

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

	-- if not self.isClient then
		-- SpecializationUtil.removeEventListener(self, "onDelete", UniversalAutoload)
		-- SpecializationUtil.removeEventListener(self, "onUpdate", UniversalAutoload)
		-- SpecializationUtil.removeEventListener(self, "onActivate", UniversalAutoload)
		-- SpecializationUtil.removeEventListener(self, "onDeactivate", UniversalAutoload)
		-- SpecializationUtil.removeEventListener(self, "onFoldStateChanged", UniversalAutoload)
	-- end

    spec.initialized = true
end

-- "ON POST LOAD" CALLED AFTER VEHICLE IS LOADED
function UniversalAutoload:onPostLoad(savegame)
    if self.isServer and savegame ~= nil and self.spec_universalAutoload ~= nil then
		local spec = self.spec_universalAutoload
		
		if not spec.available then
            return
        end

		spec.isLoading = false
		spec.isUnloading = false
		spec.doPostLoadDelay = false
		spec.doSetTensionBelts = false
		spec.totalLoadCount = 0
		spec.totalUnloadCount = 0
		spec.validLoadCount = 0
		spec.validUnloadCount = 0

        if savegame.resetVehicles then
			--client+server
            spec.currentTipside = "left"
            spec.currentLoadside = "both"
			spec.currentMaterialIndex = 1
			spec.currentContainerIndex = 1
			spec.currentLoadingFilter = true
			--server only
			-- spec.currentLoadWidth = 0
			-- spec.currentLoadHeight = 0
			-- spec.currentLoadLength = 0
			-- spec.currentActualWidth = 0
			spec.resetLoadingPattern = true
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
        end
	
	end
end

-- "SAVE TO XML FILE" CALLED DURING GAME SAVE
function UniversalAutoload:saveToXMLFile(xmlFile, key, usedModNames)
	if self.spec_universalAutoload ~= nil then
		local spec = self.spec_universalAutoload
		if spec.available then
			print("UniversalAutoload - saveToXMLFile: "..self:getFullName())
			--client+server
			xmlFile:setValue(key.."#tipside", spec.currentTipside)
			xmlFile:setValue(key.."#loadside", spec.currentLoadside)
			xmlFile:setValue(key.."#materialIndex", spec.currentMaterialIndex)
			xmlFile:setValue(key.."#containerIndex", spec.currentContainerIndex)
			xmlFile:setValue(key.."#loadingFilter", spec.currentLoadingFilter)
			--server only
			xmlFile:setValue(key.."#loadWidth", spec.currentLoadWidth)
			xmlFile:setValue(key.."#loadHeight", spec.currentLoadHeight)
			xmlFile:setValue(key.."#loadLength", spec.currentLoadLength)
			xmlFile:setValue(key.."#actualWidth", spec.currentActualWidth)
		end
	end
end

-- "ON DELETE" CLEANUP TRIGGER NODES
function UniversalAutoload:onDelete()
	--print("UniversalAutoload - onDelete")
    local spec = self.spec_universalAutoload

    if self.isServer then
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
	if self.isServer then
		local spec = self.spec_universalAutoload
		print("onFoldStateChanged: "..self:getFullName())
		spec.foldAnimationStarted = true
		spec.foldAnimationRemaining = self.spec_foldable.maxFoldAnimDuration
		self:updateActionEventText()
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
	--print("onReadStream")
    local spec = self.spec_universalAutoload
	
	spec.currentTipside = streamReadString(streamId)
	spec.currentLoadside = streamReadString(streamId)
	spec.currentMaterialIndex = streamReadInt32(streamId)
	spec.currentContainerIndex = streamReadInt32(streamId)
	spec.currentLoadingFilter = streamReadBool(streamId)
	spec.isLoading = streamReadBool(streamId)
	spec.isUnloading = streamReadBool(streamId)
	spec.validLoadCount = streamReadInt32(streamId)
	spec.validUnloadCount = streamReadInt32(streamId)
end
--
function UniversalAutoload:onWriteStream(streamId, connection)
	--print("onWriteStream")
    local spec = self.spec_universalAutoload
	
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

-- MAIN AUTOLOAD ONUPDATE LOOP
function UniversalAutoload:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	--print("UniversalAutoload - onUpdate")
	local spec = self.spec_universalAutoload
	
	if not spec.available then
		return
	end

	if self.isServer then
	
		-- DETECT WHEN FOLDING STOPS IF IT WAS STARTED
		if spec.foldAnimationStarted then
			if spec.foldAnimationRemaining < 0 then
				print("*** FOLDING COMPLETE ***")
				spec.foldAnimationStarted = false
				spec.foldAnimationRemaining = 0
				self:updateActionEventText()
			else
				spec.foldAnimationRemaining = spec.foldAnimationRemaining - dt
			end
		end
		
		-- ALWAYS LOAD THE REAR LOADING PALLETS
		if spec.rearLoadingObjects ~= nil then
			for _, object in pairs(spec.rearLoadingObjects) do
				--print("LOADING PALLET FROM REAR TRIGGER")
				self:setAllTensionBeltsActive(false)
				spec.doSetTensionBelts = true
				spec.doPostLoadDelay = true
				if self:loadObject(object) then
					print("LOADED PALLET FROM REAR TRIGGER")
					spec.rearLoadingObjects[object] = nil
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
					local foundObject = false
					for index, object in ipairs(spec.sortedObjectsToLoad) do
						if self:isValidForLoading(object) then
							if self:loadObject(object) then
								table.remove(spec.sortedObjectsToLoad, index)
								spec.loadDelayTime = 0
								foundObject = true
							end
							break
						end
					end
					if not foundObject then
						if #spec.sortedObjectsToLoad > 0 then
							spec.reachedLoadingCapacity = true
						end
						self:stopLoading()
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
					self:resetLoadingState()
				else
					spec.postLoadDelayTime = spec.postLoadDelayTime + dt
				end
			end
			
			UniversalAutoload.determineTipside(self)
			UniversalAutoload.countActivePallets(self)
			UniversalAutoload.drawDebugDisplay(self)

		end
	end
end
--
function UniversalAutoload:onActivate()
	print("onActivate: "..self:getFullName())
	if self.isServer then
		local spec = self.spec_universalAutoload
		UniversalAutoload.determineTipside(self)
		UniversalAutoload.countActivePallets(self)
		self:forceRaiseActive(true)
	end
	-- if self:getIsActiveForInput(true) then
		-- print("REGISTER ACTION EVENTS AGAIN...")
		-- self:registerActionEvents()
	-- end
end
--
function UniversalAutoload:onDeactivate()
	print("onDeactivate: "..self:getFullName())
	local spec = self.spec_universalAutoload
	if self.isServer then
		self:forceRaiseActive(false)
	end
	self:clearActionEventsTable(spec.actionEvents)
end
--
function UniversalAutoload:determineTipside()
	-- currently only used for the KRONE Profi Liner Curtain Trailer
	local spec = self.spec_universalAutoload

	--<trailer tipSideIndex="1" doorState="false" tipAnimationTime="1.000000" tipState="2"/>
	if spec.isCurtainTrailer and self.spec_trailer ~= nil then
		if self.spec_trailer.tipState == 2 then
			local tipSide = self.spec_trailer.tipSides[self.spec_trailer.currentTipSideIndex]
			
			if spec.currentTipside ~= "left" and string.find(tipSide.name, "Left") then
				--print("SET SIDE = LEFT")
				self:setCurrentTipside("left")
				self:setCurrentLoadside("left")	
			end
			if spec.currentTipside ~= "right" and string.find(tipSide.name, "Right") then
				--print("SET SIDE = RIGHT")
				self:setCurrentTipside("right")
				self:setCurrentLoadside("right")	
			end
		else
			if spec.currentTipside ~= "none" then
				--print("SET SIDE = NONE")
				self:setCurrentTipside("none")
				self:setCurrentLoadside("none")
			end
		end
	end
end
--
function UniversalAutoload:isValidForLoading(object)
	local spec = self.spec_universalAutoload
	return self:getPalletIsSelectedType(object) and self:getPalletIsSelectedLoadside(object) and
		(not spec.currentLoadingFilter or (spec.currentLoadingFilter and UniversalAutoload.getPalletIsFull(object)) )
end
--
function UniversalAutoload:isValidForUnloading(object)
	local spec = self.spec_universalAutoload
	return self:getPalletIsSelectedType(object) and spec.rearLoadingObjects[object] == nil
end
--
function UniversalAutoload:countActivePallets()
	local spec = self.spec_universalAutoload
	local isActiveForLoading = spec.isLoading or spec.isUnloading or spec.doPostLoadDelay
	
	local totalLoadCount = 0
	local validLoadCount = 0
	if spec.objectsToLoad ~= nil then
		for _, object in pairs(spec.objectsToLoad) do
			if object ~= nil then
				totalLoadCount = totalLoadCount + 1
				if self:isValidForLoading(object) then
					validLoadCount = validLoadCount + 1
				end
				if isActiveForLoading then
					object:raiseDirtyFlags(object.vehicleDirtyFlag)
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
				if self:isValidForUnloading(object) then
					validUnloadCount = validUnloadCount + 1
				end
				if isActiveForLoading then
					object:raiseDirtyFlags(object.vehicleDirtyFlag)
				end
			end
		end
	end

	if not isActiveForLoading then
		if (spec.validLoadCount ~= validLoadCount) or (spec.validUnloadCount ~= validUnloadCount) then
			if spec.validLoadCount ~= validLoadCount then
				spec.validLoadCount = validLoadCount
			end
			if spec.validUnloadCount ~= validUnloadCount then
				spec.validUnloadCount = validUnloadCount
			end
			self:updateActionEventText()
		end
	end

	if spec.totalLoadCount ~= totalLoadCount then
		--spec.totalLoadCount = totalLoadCount
		print("TOTAL LOAD COUNT ERROR: "..tostring(spec.totalLoadCount).." vs "..tostring(totalLoadCount))
	end
	if spec.totalUnloadCount ~= totalUnloadCount then
		--spec.totalUnloadCount = totalUnloadCount
		print("TOTAL UNLOAD COUNT ERROR: "..tostring(spec.totalUnloadCount).." vs "..tostring(totalUnloadCount))
	end
end

-- LOADING AND UNLOADING FUNCTIONS

function UniversalAutoload:loadObject(object)
	--print("UniversalAutoload - loadObject")
	if object ~= nil then
		if self:getIsAutoloadingAllowed() and self:getIsValidObject(object) then
			local spec = self.spec_universalAutoload
			if spec.loadedObjects[object] == nil or spec.rearLoadingObjects[object] ~= nil then
				local thisLoadType = UniversalAutoload.getContainerType(object)
				print(string.format("LOADING OBJECT: %s [%.3f, %.3f, %.3f]", thisLoadType.name, thisLoadType.sizeX, thisLoadType.sizeY, thisLoadType.sizeZ))
				local placeIndex, thisLoadHeight = self:getLoadPlace(thisLoadType)
				if placeIndex ~= -1 then

					local p = {}
					local loadPlace = spec.currentLoadingPattern[placeIndex]
					p.x, p.y, p.z = localToWorld(loadPlace.node, 0, thisLoadHeight, 0)
					p.rx, p.ry, p.rz = getWorldRotation(loadPlace.node)
					p.vx, p.vy, p.vz = getLinearVelocity(self.rootNode)
					
					moveObjectNodes(object, p)

					UniversalAutoload.clearPalletFromAllVehicles(self, object)
					
					self:addLoadedObject(object)

					--g_currentMission:addMoney(-100, self:getOwnerFarmId(), MoneyType.AI)
					return true
				end
			end
		end
	end
	return false
end
--
function UniversalAutoload:unloadObject(object, unloadPlace)
	--print("UniversalAutoload - unloadObject")

	if object ~= nil then
	
		local p = {}
		p.x, p.y, p.z = localToWorld(unloadPlace.node, 0, 0, 0)
		p.rx, p.ry, p.rz = getWorldRotation(unloadPlace.node)
		p.vx, p.vy, p.vz = getLinearVelocity(self.rootNode)

		moveObjectNodes(object, p)
		UniversalAutoload.clearPalletFromAllVehicles(self, object)

	end
end

--
function UniversalAutoload.getUnloadingTransform(vehicle, object)
	
	--get object node and intial postion
	local spec = vehicle.spec_universalAutoload
	local node = object.nodeId or object.components[1].node
	local x0, y0, z0 = getTranslation(node)
	
	--calculate unload offset according to tipside
	local offsetX = 1.5*spec.loadArea.width
	if spec.currentTipside == "right" then offsetX = -1 * offsetX end
	local dx, dy, dz = localDirectionToWorld(spec.loadArea.rootNode, offsetX, 0, 0)
	
	-- --calculate height offset to unload at ground level
	-- local _, offsetY, _ = unpack(spec.loadArea.offset)
	-- local _, heightAbovePlace, _ = localToLocal(node, spec.loadArea.rootNode, 0, 0, 0)
	-- local heightAboveGround = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0, y0, z0) + 0.1
	
	-- local calculatedY = heightAbovePlace + heightAboveGround-y0
	-- if heightAboveGround-y0 > offsetY then
		-- dy = dy + calculatedY
	-- end
	-- print("offsetY: "..tostring(offsetY))
	-- print("heightAboveGround: "..tostring(heightAboveGround-y0))
	
	return x0+dx, y0+dy, z0+dz, getRotation(node)	
end	
--
function UniversalAutoload.clearPalletFromAllVehicles(self, object)
	for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		local SPEC = vehicle.spec_universalAutoload
		if SPEC.objectsToLoad[object] ~= nil then
			SPEC.objectsToLoad[object] = nil
			SPEC.totalLoadCount = SPEC.totalLoadCount - 1
		end
		
		if SPEC.loadedObjects[object] ~= nil then
		
			vehicle:removeLoadedObject(object)

			if SPEC.totalUnloadCount == 0 then
				SPEC.currentLoadLength = 0
			else
				vehicle:setAllTensionBeltsActive(false)
			end

		end
	end
end
--
function UniversalAutoload.unmountDynamicMount(object)

	if object.dynamicMountObject ~= nil then
		local vehicle = object.dynamicMountObject
		print("Remove Dynamic Mount from: "..vehicle:getFullName())
		vehicle:removeDynamicMountedObject(object, false)
		object:unmountDynamic()
		if object.additionalDynamicMountJointNode ~= nil then
			delete(object.additionalDynamicMountJointNode)
			object.additionalDynamicMountJointNode = nil
		end
	end
end
--
function UniversalAutoload:onDeleteLoadedObject(object)
    local spec = self.spec_universalAutoload

	if spec.loadedObjects[object] ~= nil then
		spec.loadedObjects[object] = nil
		spec.totalUnloadCount = spec.totalUnloadCount - 1
		
		if spec.totalUnloadCount == 0 then
			spec.currentLoadLength = 0
		end
	else
		print("...PALLET WAS ALREADY DELETED")
	end
end

function UniversalAutoload:addLoadPlace(autoLoadType)
    local spec = self.spec_universalAutoload

	spec.currentLoadWidth = spec.currentLoadWidth or 0
	spec.currentLoadLength = spec.currentLoadLength or 0
	spec.currentActualWidth = spec.currentActualWidth or 0
	
	--CALCUATE POSSIBLE ARRAY SIZES
	local width = spec.loadArea.width
	local length = spec.loadArea.length - spec.currentLoadLength
	local N1 = math.floor(width / autoLoadType.sizeX)
	local M1 = math.floor(length / autoLoadType.sizeZ)
	local N2 = math.floor(width / autoLoadType.sizeZ)
	local M2 = math.floor(length / autoLoadType.sizeX)
	
	if N2*M2 == N1*M1 then
	-- if equal use same packing as an empty trailer
		M1 = math.floor(spec.loadArea.length / autoLoadType.sizeX)
		M2 = math.floor(spec.loadArea.length / autoLoadType.sizeZ)
	end
	
	--CHOOSE BEST PACKING ORIENTATION
	local N, M, sizeX, sizeY, sizeZ, rotation
	if N2*M2 > N1*M1  or autoLoadType.alwaysRotate then
		N, M = N2, M2
		rotation = math.pi/2
		sizeZ = autoLoadType.sizeX
		sizeY = autoLoadType.sizeY
		sizeX = autoLoadType.sizeZ
	else
		N, M = N1, M1
		rotation = 0
		sizeX = autoLoadType.sizeX
		sizeY = autoLoadType.sizeY
		sizeZ = autoLoadType.sizeZ
	end
	
	-- UPDATE NEW PACKING DIMENSIONS

	spec.currentLoadHeight = 0
	print("reset currentLoadHeight: "..spec.currentLoadHeight)
	
	if spec.currentLoadWidth==0 or spec.currentLoadWidth + sizeX > spec.loadArea.width then
		spec.currentLoadWidth = sizeX
		spec.currentActualWidth = N * sizeX
		print("reset currentLoadWidth: "..spec.currentLoadWidth)
		
		spec.currentLoadLength = spec.currentLoadLength + sizeZ
		print("increased currentLoadLength: "..spec.currentLoadLength)
	else
		spec.currentLoadWidth = spec.currentLoadWidth + sizeX
		print("increased currentLoadWidth: "..spec.currentLoadWidth)
	end
	
	if spec.currentLoadLength == 0 then
		spec.currentLoadLength = sizeZ
		print("reset currentLoadLength: "..spec.currentLoadLength)
	end

	if spec.currentLoadLength < spec.loadArea.length and spec.currentLoadWidth <= spec.currentActualWidth then
		--CREATE NEW LOADING PLACE
		loadPlace = {}
		loadPlace.index = #spec.currentLoadingPattern + 1
		loadPlace.node = createTransformGroup("loadPlace")
		loadPlace.sizeX = autoLoadType.sizeX
		loadPlace.sizeY = autoLoadType.sizeY
		loadPlace.sizeZ = autoLoadType.sizeZ
		loadPlace.isRotated = rotation == math.pi/2
		
		--LOAD FROM THE CORRECT SIDE
		local posX, posZ
		if spec.currentLoadside == "right" then
			print("right")
			posX = -( spec.currentLoadWidth - (spec.currentActualWidth/2) - (sizeX/2) )
		else
			print("left")
			posX = spec.currentLoadWidth - (spec.currentActualWidth/2) - (sizeX/2)
		end
		posZ = -( spec.currentLoadLength - (sizeZ/2) )
		
		--SET POSITION AND ORIENTATION
		link(spec.loadArea.startNode, loadPlace.node)
		setRotation(loadPlace.node, 0, rotation, 0)
		setTranslation(loadPlace.node, posX, 0, posZ)
		
		--INSERT PLACE INTO CURRENT TABLE
		table.insert(spec.currentLoadingPattern, loadPlace)
		spec.currentPlaceIndex = #spec.currentLoadingPattern
	end

end

function UniversalAutoload:getLoadPlace(thisLoadType)
    local spec = self.spec_universalAutoload
	
	if spec.resetLoadingPattern ~= false then
		spec.currentLoadingPattern = {}
		spec.currentLoadWidth = 0
		spec.currentLoadHeight = 0
		spec.currentLoadLength = 0
		spec.makeNewLoadingPlace = true
		spec.resetLoadingPattern = false
	end

	while spec.currentLoadLength < spec.loadArea.length do
	
		spec.currentLoadHeight = spec.currentLoadHeight or 0
		if spec.currentLoadHeight + thisLoadType.sizeY > spec.loadArea.height then
			spec.makeNewLoadingPlace = true
		end
	
		if spec.makeNewLoadingPlace ~= false then
			print(string.format("ADDING NEW PLACE FOR: %s [%.3f, %.3f, %.3f]", thisLoadType.name, thisLoadType.sizeX, thisLoadType.sizeY, thisLoadType.sizeZ))
			self:addLoadPlace(thisLoadType)
			spec.makeNewLoadingPlace = false
		end

		local thisLoadPlace = spec.currentLoadingPattern[spec.currentPlaceIndex]
		local thisLoadHeight = spec.currentLoadHeight
		
		if self:testPalletLocationIsEmpty(thisLoadPlace, thisLoadType, thisLoadHeight) then
			print("USING LOAD PLACE: " .. tostring(loadPlace.index) )
			spec.currentLoadHeight = spec.currentLoadHeight + thisLoadType.sizeY
			return spec.currentPlaceIndex, thisLoadHeight
		end
		
		print("DID NOT FIT HERE...")
		spec.makeNewLoadingPlace = true
	end

    return -1, 0
end

-- OBJECT PICKUP LOGIC FUNCTIONS
function UniversalAutoload:getIsValidObject(object)
    local spec = self.spec_universalAutoload
	-- only valid when rootnode is object id
	if object.spec_mountable == nil or object.spec_mountable.componentNode ~= object.rootNode then
		return false
	end
	if object.i3dFilename ~= nil and object.typeName == "pallet" or object.typeName == "bigBag" then
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
	return self:getIsAutoloadingAllowed() and -1 or math.huge
end
--
function UniversalAutoload:testPalletLocationIsFull(loadPlace, autoLoadType, testLoadHeight)
	local spec = self.spec_universalAutoload
	local sizeX, sizeY, sizeZ = autoLoadType.sizeX/2, autoLoadType.sizeY/2, autoLoadType.sizeZ/2
	local x, y, z = localToWorld(loadPlace.node, 0, testLoadHeight, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.foundObjectId = 0
	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "palletOverlapCallback", self, collisionMask, true, false, true)

	if spec.foundObject then
		local x0, y0, z0 = localToLocal(loadPlace.node, spec.foundObjectId, 0, 0, 0)
		return x0 < 0.2 and z0 < 0.2
	else
		return false
	end
end
--
function UniversalAutoload:testPalletLocationIsEmpty(loadPlace, autoLoadType, testLoadHeight)
	local spec = self.spec_universalAutoload
	local sizeX, sizeY, sizeZ = autoLoadType.sizeX/2, autoLoadType.sizeY/2, autoLoadType.sizeZ/2
	local x, y, z = localToWorld(loadPlace.node, 0, testLoadHeight, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
	
	spec.foundObject = false
	spec.foundObjectId = 0

	local collisionMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "palletOverlapCallback", self, collisionMask, true, false, true)

	return not spec.foundObject
end
--
function UniversalAutoload:palletOverlapCallback(hitObjectId, x, y, z, distance)
	
    if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.SHAPE) then
        local spec = self.spec_universalAutoload
        local object = g_currentMission:getNodeObject(hitObjectId)

        if object ~= nil and object ~= self then
            spec.foundObject = true
			spec.foundObjectId = hitObjectId
        end
    end
end
--
function UniversalAutoload:testUnloadLocationIsEmpty(loadPlace)

	local spec = self.spec_universalAutoload
	local sizeX, sizeY, sizeZ = loadPlace.sizeX/2, loadPlace.sizeY/2, loadPlace.sizeZ/2
	local x, y, z = localToWorld(loadPlace.node, 0, 0, 0)
	local rx, ry, rz = getWorldRotation(loadPlace.node)
	local dx, dy, dz = localDirectionToWorld(loadPlace.node, 0, sizeY, 0)
	
	spec.hasOverlap = false

	local collisionMask = CollisionFlag.STATIC_WORLD + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.ANIMAL
	overlapBox(x+dx, y+dy, z+dz, rx, ry, rz, sizeX, sizeY, sizeZ, "overlapCallback", self, collisionMask, true, true, true)

	return not spec.hasOverlap
end
--
function UniversalAutoload:overlapCallback(hitObjectId, x, y, z, distance)

	if hitObjectId ~= g_currentMission.terrainRootNode then
		local spec = self.spec_universalAutoload
		spec.hasOverlap = true
		return false
	end
	return true
end

-- OBJECT MOVEMENT FUNCTIONS
function moveObjectNode( objectNodeId, p )

	if p.x ~= nil then
		setTranslation(objectNodeId, p.x, p.y, p.z)
	end
	if p.rx ~= nil then
		setWorldRotation(objectNodeId, p.rx, p.ry, p.rz)
	end

end
--
function moveObjectNodes( object, p )

	UniversalAutoload.unmountDynamicMount(object)
	
	local wasAddedToPhysics = false
	if object.isAddedToPhysics then
		wasAddedToPhysics = true
		object:removeFromPhysics()
	end
	
	local nodes = {}
	if object.components ~= nil then
		for i = 1, #object.components do
			table.insert(nodes, object.components[i].node)
		end
	else
		table.insert(nodes, object.nodeId)
	end
	
	local n = {}
	for i = 1, #nodes do
		n[i] = {} for k, v in pairs(p) do (n[i])[k] = v end
		if n[i].x ~= nil then
			local dx, dy, dz = localToLocal(nodes[i], nodes[1], 0, 0, 0)
			n[i].x = n[i].x + dx
			n[i].y = n[i].y + dy
			n[i].z = n[i].z + dz
		end
	end
	for i = 1, #nodes do
		moveObjectNode(nodes[i], n[i] )
	end
	
	if wasAddedToPhysics then
		object:addToPhysics()
	end

	if p.vx ~= nil then
		for i = 1, #nodes do
			setLinearVelocity(nodes[i], p.vx, p.vy, p.vz)
		end
	end
	
	object.networkTimeInterpolator:reset()
	object:raiseDirtyFlags(object.vehicleDirtyFlag)

end

-- TRIGGER CALLBACK FUNCTIONS
function UniversalAutoload:playerTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		for _, player in pairs(g_currentMission.players) do
			if otherActorId == player.rootNode then
				
				if g_currentMission.accessHandler:canFarmAccess(player.farmId, self) then
				
					local spec = self.spec_universalAutoload
					local playerId = player.userId
					
					if onEnter then
						self:updatePlayerTriggerState(playerId, true)
						self:forceRaiseActive()
					else
						self:updatePlayerTriggerState(playerId, false)
						self:forceRaiseActive()
					end

				end
	
			end
		end
	end
end
--
function UniversalAutoload:loadingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if self:getIsAutoloadingAllowed() and self:getIsValidObject(object) then
				if onEnter then
					if spec.objectsToLoad[object] == nil and spec.loadedObjects[object] == nil then
						spec.objectsToLoad[object] = object
						spec.totalLoadCount = spec.totalLoadCount + 1
					end
				elseif onLeave then
					if spec.objectsToLoad[object] ~= nil then
						spec.objectsToLoad[object] = nil
						spec.totalLoadCount = spec.totalLoadCount - 1
					end
				end
			end
		end
    end
end
--
function UniversalAutoload:unloadingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if self:getIsAutoloadingAllowed() and self:getIsValidObject(object) then
				if onEnter then
					self:addLoadedObject(object)
				elseif onLeave then
					self:removeLoadedObject(object)
				end
			end
		end
	end
end
--
function UniversalAutoload:rearLoadingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local spec = self.spec_universalAutoload
		local object = g_currentMission:getNodeObject(otherActorId)
		if object ~= nil then
			if self:getIsAutoloadingAllowed() and self:getIsValidObject(object) then
				if onEnter then
					if object.dynamicMountObject ~= nil then
						if spec.rearLoadingObjects[object] == nil then
							spec.rearLoadingObjects[object] = object
							object:raiseDirtyFlags(object.vehicleDirtyFlag)
						end
						self:forceRaiseActive()
					end
				elseif onLeave then
					if spec.rearLoadingObjects[object] ~= nil then
						spec.rearLoadingObjects[object] = nil
					end
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
			object:addDeleteListener(self, "onDeleteLoadedObject")
		end
		object:raiseDirtyFlags(object.vehicleDirtyFlag)
	end
end
--
function UniversalAutoload:removeLoadedObject(object)
	local spec = self.spec_universalAutoload
	if spec.loadedObjects[object] ~= nil then
		spec.loadedObjects[object] = nil
		spec.totalUnloadCount = spec.totalUnloadCount - 1
		if object.removeDeleteListener ~= nil then
			object:removeDeleteListener(self)
		end
		object:raiseDirtyFlags(object.vehicleDirtyFlag)
	end
end

-- PALLET IDENTIFICATION AND SELECTION FUNCTIONS
function UniversalAutoload.getObjectNameFromPath(i3d_path)
	local i3d_name = i3d_path:match("[^/]*.i3d$")
	return i3d_name:sub(0, #i3d_name - 4)
end
--
function UniversalAutoload.getContainerTypeName(object)
	local palletType = UniversalAutoload.getContainerType(object)
	return palletType.containerType
end
--
function UniversalAutoload.getContainerType(object)
	local name = UniversalAutoload.getObjectNameFromPath(object.i3dFilename)
	local palletType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
	
	if palletType == nil then
		if UniversalAutoload.UNKNOWN_TYPES[name] == nil then
			UniversalAutoload.UNKNOWN_TYPES[name] = true
			print("UNKNOWN OBJECT TYPE: ".. name )
		end
	end
	
	return palletType
end
--
function UniversalAutoload.getLoadingIndex(containerType)
	for index, indexType in ipairs(UniversalAutoload.TYPES) do
		if containerType == indexType then
			return index
		end
	end
end
--
function UniversalAutoload:getSelectedTypeName()
	local spec = self.spec_universalAutoload
	return UniversalAutoload.TYPES[spec.currentContainerIndex]
end
--
function UniversalAutoload:getPalletIsSelectedType(object)

	local objectContainerType = UniversalAutoload.getContainerTypeName(object)
	local selectedContainerType = UniversalAutoload.getSelectedTypeName(self)
	
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
function UniversalAutoload:getPalletIsSelectedLoadside(object)
	local spec = self.spec_universalAutoload
	
	if spec.currentLoadside == "both" then
		return true
	end
	
	local node = object.nodeId or object.components[1].node
	if node == nil then
		return false
	end
	
	local x, y, z = localToLocal(node, spec.loadArea.rootNode, 0, 0, 0)
	if (x > 0 and spec.currentLoadside == "left") or 
	   (x < 0 and spec.currentLoadside == "right") then
		return true
	else
		return false
	end
end
--
function UniversalAutoload.getPalletIsFull(object)
	for k, _ in ipairs(object:getFillUnits()) do
		if object:getFillUnitFillLevelPercentage(k) < 1 then
			return false
		end
	end
	return true
end
--

-- DRAW DEBUG PALLET FUNCTIONS
function UniversalAutoload:drawDebugDisplay()

	if UniversalAutoload.debugEnabled and not g_gui:getIsGuiVisible() then
		local spec = self.spec_universalAutoload
		
		for _,object in pairs(spec.objectsToLoad) do
			if object ~= nil then
				local node = object.nodeId or object.components[1].node
				local autoLoadType = UniversalAutoload.getContainerType(object)
				local w, h, l = autoLoadType.sizeX, autoLoadType.sizeY, autoLoadType.sizeZ
				if self:isValidForLoading(object) then
					DrawDebugPallet( node, w, h, l, true, 0, 1, 0 )
				else
					DrawDebugPallet( node, w, h, l, false, 1, 0, 0 )
				end
			end
		end
		
		for _,object in pairs(spec.loadedObjects) do
			if object ~= nil then
				local node = object.nodeId or object.components[1].node
				local autoLoadType = UniversalAutoload.getContainerType(object)
				local w, h, l = autoLoadType.sizeX, autoLoadType.sizeY, autoLoadType.sizeZ
				if self:isValidForUnloading(object) then
					DrawDebugPallet( node, w, h, l, true, 0, 1, 0 )
				else
					DrawDebugPallet( node, w, h, l, false, 1, 1, 0 )
				end
			end
		end
		
		if spec.objectsToUnload ~= nil then
			for object, unloadPlace in pairs(spec.objectsToUnload) do

				if spec.unloadingAreaClear then
					DrawDebugPallet( unloadPlace.node, unloadPlace.sizeX, unloadPlace.sizeY, unloadPlace.sizeZ, false, 0, 1, 1 )
				else
					DrawDebugPallet( unloadPlace.node, unloadPlace.sizeX, unloadPlace.sizeY, unloadPlace.sizeZ, false, 1, 0, 0 )
				end

			end
		end

		for i=1, #spec.currentLoadingPattern do
			local loadPlace = spec.currentLoadingPattern[i]
			if loadPlace ~= nil then
				DrawDebugPallet( loadPlace.node, loadPlace.sizeX, loadPlace.sizeY, loadPlace.sizeZ, false, 0, 1, 1 )
			end
		end

		for _, trigger in pairs(spec.triggers) do
			if trigger.name == "rearTrigger" then
				DebugUtil.drawDebugCube(trigger.node, 1,1,1, 1,0,1)
			else
				DebugUtil.drawDebugCube(trigger.node, 1,1,1, 1,1,0)
			end
		end
		
		local W, H, L = spec.loadArea.width, spec.loadArea.height, spec.loadArea.length
		DrawDebugPallet( spec.loadArea.rootNode,  W, H, L, false, 1, 1, 1 )
		DrawDebugPallet( spec.loadArea.startNode, W, 0, 0, false, 0, 1, 0 )
		DrawDebugPallet( spec.loadArea.endNode,   W, 0, 0, false, 1, 0, 0 )	
	end
end
--
function DrawDebugPallet( node, w, h, l, showAxis, r, g, b )

	if node ~= nil and node ~= 0 then
		-- colour for square
		local r, g, b = (r or 1), (g or 1), (b or 1)
		local w, h, l = (w or 1), (h or 1), (l or 1)

		local xx,xy,xz = localDirectionToWorld(node, w,0,0)
		local yx,yy,yz = localDirectionToWorld(node, 0,h,0)
		local zx,zy,zz = localDirectionToWorld(node, 0,0,l)

		if showAxis then
			-- local x0,y0,z0 = localToWorld(node, 0, h/2, 0)
			-- Utils.renderTextAtWorldPosition(x0-xx/2,y0-xy/2,z0-xz/2, "-x", getCorrectTextSize(0.012), 0)
			-- Utils.renderTextAtWorldPosition(x0+xx/2,y0+xy/2,z0+xz/2, "+x", getCorrectTextSize(0.012), 0)
			-- Utils.renderTextAtWorldPosition(x0-yx/2,y0-yy/2,z0-yz/2, "-y", getCorrectTextSize(0.012), 0)
			-- Utils.renderTextAtWorldPosition(x0+yx/2,y0+yy/2,z0+yz/2, "+y", getCorrectTextSize(0.012), 0)
			-- Utils.renderTextAtWorldPosition(x0-zx/2,y0-zy/2,z0-zz/2, "-z", getCorrectTextSize(0.012), 0)
			-- Utils.renderTextAtWorldPosition(x0+zx/2,y0+zy/2,z0+zz/2, "+z", getCorrectTextSize(0.012), 0)
			-- drawDebugLine(x0-xx/2,y0-xy/2,z0-xz/2,1,1,1,x0+xx/2,y0+xy/2,z0+xz/2,1,1,1)
			-- drawDebugLine(x0-yx/2,y0-yy/2,z0-yz/2,1,1,1,x0+yx/2,y0+yy/2,z0+yz/2,1,1,1)
			-- drawDebugLine(x0-zx/2,y0-zy/2,z0-zz/2,1,1,1,x0+zx/2,y0+zy/2,z0+zz/2,1,1,1)
			
			local x0,y0,z0 = localToWorld(node, -w/2, h, -l/2)
			drawDebugLine(x0,y0,z0,r,g,b,x0+xx,y0+xy,z0+xz,r,g,b)
			drawDebugLine(x0,y0,z0,r,g,b,x0+zx,y0+zy,z0+zz,r,g,b)
			drawDebugLine(x0+xx,y0+xy,z0+xz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)
			drawDebugLine(x0+zx,y0+zy,z0+zz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)
		
		end

		local x0,y0,z0 = localToWorld(node, -w/2, 0, -l/2)
		--y0 = y0 + 0.01
		drawDebugLine(x0,y0,z0,r,g,b,x0+xx,y0+xy,z0+xz,r,g,b)
		drawDebugLine(x0,y0,z0,r,g,b,x0+zx,y0+zy,z0+zz,r,g,b)
		drawDebugLine(x0+xx,y0+xy,z0+xz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)
		drawDebugLine(x0+zx,y0+zy,z0+zz,r,g,b,x0+xx+zx,y0+xy+zy,z0+xz+zz,r,g,b)
	
	end

end

-- ADD CUSTOM STRINGS FROM ModDesc.xml TO GLOBAL g_i18n
function AddUniversalAutoloadCustomStrings()
	print("  ADD custom strings from ModDesc.xml to g_i18n")
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
		end
		
		i = i + 1
	end
end
AddUniversalAutoloadCustomStrings()