-- ============================================================= --
-- Universal Autoload MOD - MANAGER
-- ============================================================= --

-- manager
UniversalAutoloadManager = {}
addModEventListener(UniversalAutoloadManager)

-- specialisation
g_specializationManager:addSpecialization('universalAutoload', 'UniversalAutoload', Utils.getFilename('UniversalAutoload.lua', g_currentModDirectory), "")

for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
	-- Anything with tension belts could potentially require autoload
	if SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) then
		g_vehicleTypeManager:addSpecialization(vehicleName, UniversalAutoload.name .. '.universalAutoload')
		-- print("  UAL INSTALLED: "..vehicleName)
	end
end

-- variables
UniversalAutoload.userSettingsFile = "modSettings/UniversalAutoload.xml"
UniversalAutoload.SHOP_ICON = UniversalAutoload.path .. "icons/shop_icon.dds"

-- tables
UniversalAutoload.ACTIONS = {
	["TOGGLE_LOADING"]         = "UNIVERSALAUTOLOAD_TOGGLE_LOADING",
	["UNLOAD_ALL"]             = "UNIVERSALAUTOLOAD_UNLOAD_ALL",
	["TOGGLE_TIPSIDE"]         = "UNIVERSALAUTOLOAD_TOGGLE_TIPSIDE",
	["TOGGLE_FILTER"]          = "UNIVERSALAUTOLOAD_TOGGLE_FILTER",
	["CYCLE_MATERIAL_FW"]      = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_FW",
	["CYCLE_MATERIAL_BW"]      = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_BW",
	["SELECT_ALL_MATERIALS"]   = "UNIVERSALAUTOLOAD_SELECT_ALL_MATERIALS",
	["CYCLE_CONTAINER_FW"]     = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW",
	["CYCLE_CONTAINER_BW"]     = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_BW",
	["SELECT_ALL_CONTAINERS"]  = "UNIVERSALAUTOLOAD_SELECT_ALL_CONTAINERS",
	["TOGGLE_BELTS"]	       = "UNIVERSALAUTOLOAD_TOGGLE_BELTS",
	["TOGGLE_DOOR"]            = "UNIVERSALAUTOLOAD_TOGGLE_DOOR",
	["TOGGLE_CURTAIN"]	       = "UNIVERSALAUTOLOAD_TOGGLE_CURTAIN",
	["TOGGLE_SHOW_DEBUG"]	   = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_DEBUG",
	["TOGGLE_SHOW_LOADING"]	   = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_LOADING",
	["TOGGLE_BALE_COLLECTION"] = "UNIVERSALAUTOLOAD_TOGGLE_BALE_COLLECTION"
}

UniversalAutoload.WARNINGS = {
	[1] = "warning_UNIVERSALAUTOLOAD_CLEAR_UNLOADING_AREA",
	[2] = "warning_UNIVERSALAUTOLOAD_NO_OBJECTS_FOUND",
	[3] = "warning_UNIVERSALAUTOLOAD_UNABLE_TO_LOAD_OBJECT",
	[4] = "warning_UNIVERSALAUTOLOAD_NO_LOADING_UNLESS_STATIONARY"
}

UniversalAutoload.CONTAINERS = {
	[1] = "ALL",
	[2] = "EURO_PALLET",
	[3] = "BIGBAG_PALLET",
	[4] = "LIQUID_TANK",
	[5] = "BIGBAG",
	[6] = "BALE"
}

-- DEFINE DEFAULTS FOR CONTAINER TYPES
UniversalAutoload.ALL            = { sizeX = 1.250, sizeY = 0.850, sizeZ = 0.850 }
UniversalAutoload.EURO_PALLET    = { sizeX = 1.250, sizeY = 0.790, sizeZ = 0.850 }
UniversalAutoload.BIGBAG_PALLET  = { sizeX = 1.525, sizeY = 1.075, sizeZ = 1.200 }
UniversalAutoload.LIQUID_TANK    = { sizeX = 1.433, sizeY = 1.500, sizeZ = 1.415 }
UniversalAutoload.BIGBAG         = { sizeX = 1.050, sizeY = 1.666, sizeZ = 0.866, neverStack=true }
UniversalAutoload.BALE           = { isBale=true }

UniversalAutoload.VEHICLES = {}
UniversalAutoload.UNKNOWN_TYPES = {}

-- IMPORT VEHICLE CONFIGURATIONS
UniversalAutoload.VEHICLE_CONFIGURATIONS = {}

function UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, overwriteExisting)

	if g_currentMission.isMultiplayer then
		print("Custom configurations are not supported in multiplayer")
		return
	end
	
	local N,M = 0,0
	if fileExists(userSettingsFile) then
		UniversalAutoloadManager.ImportGlobalSettings(userSettingsFile, overwriteExisting)
		print("IMPORT user vehicle configurations")
		N = N + UniversalAutoloadManager.ImportVehicleConfigurations(userSettingsFile, overwriteExisting)
		print("IMPORT user container configurations")
		M = M + UniversalAutoloadManager.ImportContainerTypeConfigurations(userSettingsFile, overwriteExisting)
	else
		print("CREATING user settings file")
		local defaultSettingsFile = Utils.getFilename("config/UniversalAutoload.xml", UniversalAutoload.path)
		copyFile(defaultSettingsFile, userSettingsFile, false)

		UniversalAutoload.showDebug = false
		UniversalAutoload.disableAutoStrap = false
		UniversalAutoload.manualLoadingOnly = false
		UniversalAutoload.pricePerPallet = 0
	end
	
	return N,M
end
--
function UniversalAutoload.ImportUserConfigurations(userSettingsFile, overwriteExisting)
	print("*** OLD VERSION OF UNIVERSAL AUTOLOAD MODHUB ADD-ON DETECTED - please update to latest version ***")
	return UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, overwriteExisting)
end
--
function UniversalAutoloadManager.ImportGlobalSettings(xmlFilename, overwriteExisting)

	if g_currentMission:getIsServer() and (overwriteExisting or not UniversalAutoload.globalSettingsLoaded) then
	
		local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
		if xmlFile ~= 0 then
			print("IMPORT Universal Autoload global settings")
			UniversalAutoload.globalSettingsLoaded = true
			UniversalAutoload.showDebug = xmlFile:getValue("universalAutoload#showDebug", false)
			UniversalAutoload.disableAutoStrap = xmlFile:getValue("universalAutoload#disableAutoStrap", false)
			UniversalAutoload.manualLoadingOnly = xmlFile:getValue("universalAutoload#manualLoadingOnly", false)
			UniversalAutoload.pricePerPallet = xmlFile:getValue("universalAutoload#pricePerPallet", 0)
			print("  >> Show Debug Display: " .. tostring(UniversalAutoload.showDebug))
			print("  >> Manual Loading Only: " .. tostring(UniversalAutoload.manualLoadingOnly))
			print("  >> Automatic Tension Belts: " .. tostring(not UniversalAutoload.disableAutoStrap))
			print("  >> Price Per Pallet: " .. tostring(UniversalAutoload.pricePerPallet))
			xmlFile:delete()
		end
	else
		print("Universal Autoload - global settings are only loaded for the server")
	end
end
--
function UniversalAutoloadManager.ImportVehicleConfigurations(xmlFilename, overwriteExisting)

	local i = 0
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then
	
		local debugAll = xmlFile:getValue("universalAutoload.vehicleConfigurations#showDebug", false)
		
		while true do
			local configKey = string.format("universalAutoload.vehicleConfigurations.vehicleConfiguration(%d)", i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local configFileName = xmlFile:getValue(configKey.."#configFileName")
			if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] == nil then
				UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] = {}
			end
				
			local configGroup = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
			local selectedConfigs = xmlFile:getValue(configKey.."#selectedConfigs") or "ALL"
			if configGroup[selectedConfigs] == nil or overwriteExisting then
				configGroup[selectedConfigs] = {}
				configGroup[selectedConfigs].loadingArea = {}
				
				local config = configGroup[selectedConfigs]
				
					local j = 0
					while true do
						local loadAreaKey = string.format("%s.loadingArea(%d)", configKey, j)
						if not xmlFile:hasProperty(loadAreaKey) then
							break
						end
						config.loadingArea[j+1] = {}
						config.loadingArea[j+1].width  = xmlFile:getValue(loadAreaKey.."#width")
						config.loadingArea[j+1].length = xmlFile:getValue(loadAreaKey.."#length")
						config.loadingArea[j+1].height = xmlFile:getValue(loadAreaKey.."#height")
						config.loadingArea[j+1].baleHeight = xmlFile:getValue(loadAreaKey.."#baleHeight", nil)
						config.loadingArea[j+1].offset = xmlFile:getValue(loadAreaKey.."#offset", "0 0 0", true)
						config.loadingArea[j+1].noLoadingIfFolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfFolded", false)
						config.loadingArea[j+1].noLoadingIfUnfolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfUnfolded", false)
						config.loadingArea[j+1].noLoadingIfCovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfCovered", false)
						config.loadingArea[j+1].noLoadingIfUncovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfUncovered", false)
						j = j + 1
					end
					
				config.isBoxTrailer = xmlFile:getValue(configKey..".options#isBoxTrailer", false)
				config.isBaleTrailer = xmlFile:getValue(configKey..".options#isBaleTrailer", false)
				config.isCurtainTrailer = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
				config.enableRearLoading = xmlFile:getValue(configKey..".options#enableRearLoading", false)
				config.enableSideLoading = xmlFile:getValue(configKey..".options#enableSideLoading", false)
				config.noLoadingIfFolded = xmlFile:getValue(configKey..".options#noLoadingIfFolded", false)
				config.noLoadingIfUnfolded = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
				config.noLoadingIfCovered = xmlFile:getValue(configKey..".options#noLoadingIfCovered", false)
				config.noLoadingIfUncovered = xmlFile:getValue(configKey..".options#noLoadingIfUncovered", false)
				config.rearUnloadingOnly = xmlFile:getValue(configKey..".options#rearUnloadingOnly", false)
				config.frontUnloadingOnly = xmlFile:getValue(configKey..".options#frontUnloadingOnly", false)
				config.disableAutoStrap = xmlFile:getValue(configKey..".options#disableAutoStrap", false)
				config.zonesOverlap = xmlFile:getValue(configKey..".options#zonesOverlap", false)
				config.showDebug = xmlFile:getValue(configKey..".options#showDebug", debugAll)

				if not config.showDebug then
					print("  >> "..configFileName.." ("..selectedConfigs..")")
				else
					print("  >> "..configFileName.." ("..selectedConfigs..") DEBUG")
				end
			else
				if UniversalAutoload.debugEnabled then print("  CONFIG ALREADY EXISTS: "..configFileName.." ("..selectedConfigs..")") end
			end
			
			i = i + 1
		end

		xmlFile:delete()
	end
	return i
end
--
function UniversalAutoload.ImportVehicleConfigurations(xmlFilename, overwriteExisting)
	print("*** OLD VERSION OF UNIVERSAL AUTOLOAD MODHUB ADD-ON DETECTED - please update to latest version ***")
	return UniversalAutoloadManager.ImportVehicleConfigurations(xmlFilename, overwriteExisting)
end

-- IMPORT CONTAINER TYPE DEFINITIONS
UniversalAutoload.LOADING_TYPE_CONFIGURATIONS = {}
function UniversalAutoloadManager.ImportContainerTypeConfigurations(xmlFilename, overwriteExisting)

	local i = 0
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then
	
		local containerRootKey = "universalAutoload.containerConfigurations"
		local legacyContainerRootKey = "universalAutoload.containerTypeConfigurations"
		if not xmlFile:hasProperty(containerRootKey) and xmlFile:hasProperty(legacyContainerRootKey) then
			print("*** OLD VERSION OF CONFIG FILE DETECTED - please use <containerConfigurations> ***")
			containerRootKey = legacyContainerRootKey
		end

		while true do
			local configKey = string.format(containerRootKey..".containerConfiguration(%d)", i)
			
			if not xmlFile:hasProperty(configKey) then
				break
			end

			local containerType = xmlFile:getValue(configKey.."#containerType", "ALL")
			if tableContainsValue(UniversalAutoload.CONTAINERS, containerType) then
			
				local default = UniversalAutoload[containerType] or {}

				local name = xmlFile:getValue(configKey.."#name")
				local config = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
				if config == nil or overwriteExisting then
					UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
					newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
					newType.name = name
					newType.type = containerType
					newType.containerIndex = UniversalAutoload.CONTAINERS_INDEX[containerType] or 1
					newType.sizeX = xmlFile:getValue(configKey.."#sizeX", default.sizeX or 1.5)
					newType.sizeY = xmlFile:getValue(configKey.."#sizeY", default.sizeY or 1.5)
					newType.sizeZ = xmlFile:getValue(configKey.."#sizeZ", default.sizeZ or 1.5)
					newType.isBale = xmlFile:getValue(configKey.."#isBale", default.isBale or false)
					newType.flipYZ = xmlFile:getValue(configKey.."#flipYZ", default.flipYZ or false)
					newType.neverStack = xmlFile:getValue(configKey.."#neverStack", default.neverStack or false)
					newType.neverRotate = xmlFile:getValue(configKey.."#neverRotate", default.neverRotate or false)
					newType.alwaysRotate = xmlFile:getValue(configKey.."#alwaysRotate", default.alwaysRotate or false)
					print(string.format("  >> %s %s [%.3f, %.3f, %.3f]", newType.type, newType.name, newType.sizeX, newType.sizeY, newType.sizeZ ))
				end

			else
				if UniversalAutoload.showDebug then print("  UNKNOWN CONTAINER TYPE: "..tostring(containerType)) end
			end

			i = i + 1
		end

		xmlFile:delete()
	end
	return i

end
--
function UniversalAutoload.ImportContainerTypeConfigurations(xmlFilename, overwriteExisting)
	print("*** OLD VERSION OF UNIVERSAL AUTOLOAD MODHUB ADD-ON DETECTED - please update to latest version ***")
	return UniversalAutoloadManager.ImportContainerTypeConfigurations(xmlFilename, overwriteExisting)
end
--
function UniversalAutoloadManager.importContainerTypeFromXml(xmlFilename, customEnvironment)

	if xmlFilename ~= nil and not string.find(xmlFilename, "multiPurchase") then	
		-- print( "  >> " .. xmlFilename )
		
		if customEnvironment ~= nil then
			local objectName = UniversalAutoload.getObjectNameFromXml(xmlFilename)
			local customName = customEnvironment..":"..objectName

			if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[customName] ~= nil then
				-- print("FOUND CUSTOM CONFIG FOR " .. xmlFilename)
				return
			end
			
			if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[objectName] ~= nil then
				-- print("USING BASE CONFIG FOR " .. xmlFilename)
				
				UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[customName] = {}
				newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[customName]
				oldType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[objectName]

				newType.name = customName
				newType.type = oldType.type
				newType.containerIndex = oldType.containerIndex
				newType.sizeX = oldType.sizeX
				newType.sizeY = oldType.sizeY
				newType.sizeZ = oldType.sizeZ
				newType.isBale = oldType.isBale
				newType.flipYZ = oldType.flipYZ
				newType.neverStack = oldType.neverStack
				newType.neverRotate = oldType.neverRotate
				newType.alwaysRotate = oldType.alwaysRotate

				if oldType.isBale then
					newType.width = oldType.width
					newType.length = oldType.length
				end
				print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name, newType.sizeX, newType.sizeY, newType.sizeZ, newType.type ))
				return
			end
		end
		
		local loadedVehicleXML = false
		local xmlFile = XMLFile.load("configXml", xmlFilename, Vehicle.xmlSchema)

		if xmlFile~=nil and xmlFile:hasProperty("vehicle.base") then
			loadedVehicleXML = true
			UniversalAutoloadManager.importPalletTypeFromXml(xmlFile, customEnvironment)
		end
		xmlFile:delete()
		
		if not loadedVehicleXML then
			xmlFile = XMLFile.load("baleConfigXml", xmlFilename, BaleManager.baleXMLSchema)
			if xmlFile~=nil and xmlFile:hasProperty("bale") then
				UniversalAutoloadManager.importBaleTypeFromXml(xmlFile, customEnvironment)
			end
			xmlFile:delete()
		end

	end
end
--
function UniversalAutoloadManager.importPalletTypeFromXml(xmlFile, customEnvironment)
	
	local i3d_path = xmlFile:getValue("vehicle.base.filename")
	local i3d_name = UniversalAutoload.getObjectNameFromI3d(i3d_path)
	
	if i3d_name ~= nil then
		local name
		if customEnvironment == nil then
			name = i3d_name
		else
			name = customEnvironment..":"..i3d_name
		end
		
		if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] == nil then
		
			local category = xmlFile:getValue("vehicle.storeData.category", "NONE")
			local width = xmlFile:getValue("vehicle.base.size#width", 1.5)
			local height = xmlFile:getValue("vehicle.base.size#height", 1.5)
			local length = xmlFile:getValue("vehicle.base.size#length", 1.5)
			
			local containerType
			if string.find(i3d_name, "liquidTank") or string.find(i3d_name, "IBC") then containerType = "LIQUID_TANK"
			elseif string.find(i3d_name, "bigBag") or string.find(i3d_name, "BigBag") then containerType = "BIGBAG"
			elseif string.find(i3d_name, "pallet") or string.find(i3d_name, "Pallet") then containerType = "EURO_PALLET"
			elseif category == "pallets" then containerType = "EURO_PALLET"
			elseif category == "bigbags" then containerType = "BIGBAG"
			elseif category == "bigbagPallets" then containerType = "BIGBAG_PALLET"
			else
				containerType = "ALL"
				if UniversalAutoload.debugEnabled then print("  USING DEFAULT CONTAINER TYPE: "..name.." - "..category) end
			end

			UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
			newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
			newType.name = name
			newType.type = containerType or "ALL"
			newType.containerIndex = UniversalAutoload.CONTAINERS_INDEX[containerType] or 1
			newType.sizeX = width
			newType.sizeY = height
			newType.sizeZ = length
			newType.isBale = false
			newType.flipYZ = false
			newType.neverStack = (containerType == "BIGBAG") or false
			newType.neverRotate = false
			newType.alwaysRotate = false
			newType.width = math.min(newType.sizeX, newType.sizeZ)
			newType.length = math.max(newType.sizeX, newType.sizeZ)
				
			print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name,
				newType.sizeX, newType.sizeY, newType.sizeZ, containerType ))
				
		end
	end
end
--
function UniversalAutoloadManager.importBaleTypeFromXml(xmlFile, customEnvironment)
	
	local i3d_path = xmlFile:getValue("bale.filename")
	local i3d_name = UniversalAutoload.getObjectNameFromI3d(i3d_path)
	
	if i3d_name ~= nil then
		local name
		if customEnvironment == nil then
			name = i3d_name
		else
			name = customEnvironment..":"..i3d_name
		end
		
		if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] == nil then
		
			local containerType = "BALE"
			local width = xmlFile:getValue("bale.size#width", 1.5)
			local height = xmlFile:getValue("bale.size#height", 1.5)
			local length = xmlFile:getValue("bale.size#length", 2.4)
			local diameter = xmlFile:getValue("bale.size#diameter", 1.8)
			local isRoundbale = xmlFile:getValue("bale.size#isRoundbale", "false")

			UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
			newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
			newType.name = name
			newType.type = containerType
			newType.containerIndex = UniversalAutoload.CONTAINERS_INDEX[containerType] or 1
			if isRoundbale then
				newType.sizeX = diameter
				newType.sizeY = width
				newType.sizeZ = diameter
			else
				newType.sizeX = width
				newType.sizeY = height
				newType.sizeZ = length
			end
			newType.isBale = true
			newType.flipYZ = isRoundbale
			newType.neverStack = false
			newType.neverRotate = false
			newType.alwaysRotate = false
			newType.width = math.min(newType.sizeX, newType.sizeZ)
			newType.length = math.max(newType.sizeX, newType.sizeZ)
				
			print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name,
				newType.sizeX, newType.sizeY, newType.sizeZ, containerType ))
				
		end
	end
end

-- DETECT CONFLICTS/ISSUES
function UniversalAutoloadManager.detectOldConfigVersion()
	local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())

	if fileExists(userSettingsFile) then

		local xmlFile = XMLFile.load("configXml", userSettingsFile, UniversalAutoload.xmlSchema)
		if xmlFile ~= 0 then
			local oldConfigKey = "universalAutoload.containerTypeConfigurations"
			if xmlFile:hasProperty(oldConfigKey) then
				print("*********************************************************************")
				print("**  UNIVERSAL AUTOLOAD - LOCAL MOD SETTINGS FILE IS OUT OF DATE    **")
				print("*********************************************************************")
				print("**  Please delete old 'UniversalAutoload.xml' file in modSettings  **")
				print("**  OR update container config key to: <containerConfigurations>   **")
				print("*********************************************************************")
			end
			xmlFile:delete()
		end
	end
end
--
function UniversalAutoloadManager.detectKeybindingConflicts()
	--DETECT 'T' KEYS CONFLICT
	if g_currentMission.missionDynamicInfo.isMultiplayer and not g_dedicatedServer then

		local chatKey = ""
		local containerKey = "KEY_t"
		local xmlFile = loadXMLFile('TempXML', g_gui.inputManager.settingsPath)	
		local actionBindingCounter = 0
		if xmlFile ~= 0 then
			while true do
				local key = string.format('inputBinding.actionBinding(%d)', actionBindingCounter)
				local actionString = getXMLString(xmlFile, key .. '#action')
				if actionString == nil then
					break
				end
				if actionString == 'CHAT' then
					local i = 0
					while true do
						local bindingKey = key .. string.format('.binding(%d)',i)
						local bindingInput = getXMLString(xmlFile, bindingKey .. '#input')
						if bindingInput == "KEY_t" then
							print("  Using 'KEY_t' for 'CHAT'")
							chatKey = bindingInput
						elseif bindingInput == nil then
							break
						end

						i = i + 1
					end
				end
				
				if actionString == 'UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW' then
					local i = 0
					while true do
						local bindingKey = key .. string.format('.binding(%d)',i)
						local bindingInput = getXMLString(xmlFile, bindingKey .. '#input')
						if bindingInput ~= nil then
							print("  Using '"..bindingInput.."' for 'CYCLE_CONTAINER'")
							containerKey = bindingInput
						elseif bindingInput == nil then
							break
						end

						i = i + 1
					end
				end
				
				actionBindingCounter = actionBindingCounter + 1
			end
		end
		delete(xmlFile)
		
		if chatKey == containerKey then
			print("**CHAT KEY CONFLICT DETECTED** - Disabling CYCLE_CONTAINER for Multiplayer")
			print("(Please reassign 'CHAT' or 'CYCLE_CONTAINER' to a different key and RESTART the game)")
			UniversalAutoload.chatKeyConflict = true
		end
		
	end
end

-- CONSOLE FUNCTIONS
function UniversalAutoloadManager:consoleResetVehicles()

	if g_gui.currentGuiName == "ShopMenu" or g_gui.currentGuiName == "ShopConfigScreen" then
		return "Reset vehicles is not supported while in shop!"
	end
	
	UniversalAutoloadManager.resetList = {}
	UniversalAutoloadManager.resetCount = 1
	g_currentMission.isReloadingVehicles = true
	
	for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		table.insert(UniversalAutoloadManager.resetList, vehicle)
	end
	UniversalAutoload.VEHICLES = {}
	print(string.format("Resetting %d vehicles now..", #UniversalAutoloadManager.resetList))
	
	UniversalAutoloadManager.resetNextVehicle(UniversalAutoloadManager.resetList)
	
end
--
function UniversalAutoloadManager:consoleImportUserConfigurations()

	local oldVehicleConfigurations = deepCopy(UniversalAutoload.VEHICLE_CONFIGURATIONS)
	local oldContainerConfigurations = deepCopy(UniversalAutoload.LOADING_TYPE_CONFIGURATIONS)
	local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
	local vehicleCount, objectCount = UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, true)
	
	if vehicleCount > 0 then
		vehicleCount = 0
		for key, configGroup in pairs(UniversalAutoload.VEHICLE_CONFIGURATIONS) do
			for index, config in pairs(configGroup) do
				if not deepCompare(oldVehicleConfigurations[key][index], config) then
					local foundFirstMatch = false
					-- FIRST LOOK IF THIS IS THE CURRENT CONTROLLED VECHILE
					for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
						if string.find(vehicle.configFileName, key) and vehicle.spec_universalAutoload.boughtConfig == index then
							local rootVehicle = vehicle:getRootVehicle()
							if rootVehicle == g_currentMission.controlledVehicle then
								foundFirstMatch = true
								print("APPLYING UPDATED SETTINGS: " .. vehicle:getFullName())
								if not UniversalAutoloadManager.resetVehicle(vehicle) then
									g_currentMission:consoleCommandReloadVehicle()
								end
							end
						end
					end
					-- THEN CHECK ALL THE OTHERS - but we can only reset one at a time
					for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
						if string.find(vehicle.configFileName, key) and vehicle.spec_universalAutoload.boughtConfig == index then
							if not foundFirstMatch then
								foundFirstMatch = true
								vehicleCount = vehicleCount + 1
								print("APPLYING UPDATED SETTINGS: " .. vehicle:getFullName())
								if not UniversalAutoloadManager.resetVehicle(vehicle) then
									g_currentMission:consoleCommandReloadVehicle()
								end
							else
								print("ONLY ONE OF EACH VEHICLE CONFIGURATION CAN BE RESET USING THIS COMMAND")
							end
						end
					end
				end
			end
		end
	end
	
	if objectCount > 0 then
		objectCount = 0
		for key, value in pairs(UniversalAutoload.LOADING_TYPE_CONFIGURATIONS) do
			if not deepCompare(oldContainerConfigurations[key], value) then
				objectCount = objectCount + 1
			end
		end
	end
	
	if vehicleCount > 0 and objectCount == 0 then
		return string.format("UPDATED: %d vehicle configurations", vehicleCount)
	end
	if objectCount > 0 and vehicleCount == 0 then
		return string.format("UPDATED: %d container configurations", objectCount)
	end
	return string.format("UPDATED: %d vehicle configurations, %d container configurations", vehicleCount, objectCount)
end
--
function UniversalAutoloadManager:consoleAddPallets(palletType)

	local pallets = {}
	local palletsOnly = true
	for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
		local xmlName = fillType.palletFilename
		if xmlName ~= nil and not xmlName:find("fillablePallet") then
			pallets[fillType.name] = xmlName
		end
	end
		
	if palletType then
		palletType = string.upper(palletType or "")
		local xmlFilename = pallets[palletType]
		if xmlFilename == nil then
			return "Error: Invalid pallet type. Valid types are " .. table.concatKeys(pallets, ", ")
		end
		
		pallets = {}
		palletsOnly = false
		pallets[palletType] = xmlFilename
	end
	
	if g_currentMission.controlledVehicle ~= nil then

		local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		local count = 0
		
		if next(vehicles) ~= nil then
			for vehicle, hasAutoload in pairs(vehicles) do
				if hasAutoload then
					count = count + 1
					UniversalAutoload.setMaterialTypeIndex(vehicle, 1)
					if palletsOnly then
						UniversalAutoload.setContainerTypeIndex(vehicle, 2)
					else
						UniversalAutoload.setContainerTypeIndex(vehicle, 1)
					end
					UniversalAutoload.clearLoadedObjects(vehicle)
					UniversalAutoload.createPallets(vehicle, pallets)
				end
			end
		end
	
		if count>0 then return "Begin adding pallets now.." end
	end
	return "Please enter a vehicle with a UAL trailer attached to use this command"
end
--
function UniversalAutoloadManager:consoleAddBales(fillTypeName, isRoundbale, width, height, length, wrapState, modName)
	local usage = "ualAddBales fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]"

	fillTypeName = Utils.getNoNil(fillTypeName, "STRAW")
	isRoundbale = Utils.stringToBoolean(isRoundbale)
	width = width ~= nil and tonumber(width) or nil
	height = height ~= nil and tonumber(height) or nil
	length = length ~= nil and tonumber(length) or nil

	if wrapState ~= nil and tonumber(wrapState) == nil then
		Logging.error("Invalid wrapState '%s'. Number expected", wrapState, usage)

		return
	end

	wrapState = tonumber(wrapState or 0)
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	if fillTypeIndex == nil then
		Logging.error("Invalid fillTypeName '%s' (e.g. STRAW). Use %s", fillTypeName, usage)

		return
	end

	local xmlFilename, _ = g_baleManager:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, height, modName)

	if xmlFilename == nil then
		Logging.error("Could not find bale for given size attributes! (%s)", usage)
		g_baleManager:consoleCommandListBales()

		return
	end
	
	bale = {}
	bale.xmlFile = xmlFilename
	bale.fillTypeIndex = fillTypeIndex
	bale.wrapState = wrapState
	
	if g_currentMission.controlledVehicle ~= nil then

		local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		local count = 0
		
		if next(vehicles) ~= nil then
			for vehicle, hasAutoload in pairs(vehicles) do
				if hasAutoload then
					count = count + 1
					UniversalAutoload.clearLoadedObjects(vehicle)
					UniversalAutoload.setMaterialTypeIndex(vehicle, 1)
					UniversalAutoload.setContainerTypeIndex(vehicle, 1)
					UniversalAutoload.createBales(vehicle, bale)
				end
			end
		end

		if count>0 then return "Begin adding bales now.." end
	end
	return "Please enter a vehicle with a UAL trailer attached to use this command"
end
--
function UniversalAutoloadManager:consoleAddRoundBales_125(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.25")
end
--
function UniversalAutoloadManager:consoleAddRoundBales_150(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.5")
end
--
function UniversalAutoloadManager:consoleAddRoundBales_180(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "DRYGRASS_WINDROW", "true", "1.2", "1.8")
end
--
function UniversalAutoloadManager:consoleAddSquareBales_180(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "1.8")
end
--
function UniversalAutoloadManager:consoleAddSquareBales_220(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "2.2")
end
--
function UniversalAutoloadManager:consoleAddSquareBales_240(fillTypeName)
	return UniversalAutoloadManager:consoleAddBales(fillTypeName or "STRAW", "false", "1.2", "0.9", "2.4")
end
--
function UniversalAutoloadManager:consoleClearLoadedObjects()
	
	local palletCount, balesCount = 0, 0
	if g_currentMission.controlledVehicle ~= nil then
		local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
		if next(vehicles) ~= nil then
			for vehicle, hasAutoload in pairs(vehicles) do
				if hasAutoload then
					N, M = UniversalAutoload.clearLoadedObjects(vehicle)
					palletCount = palletCount + N
					balesCount = balesCount + M
				end
			end
		end
	end

	if palletCount > 0 and balesCount == 0 then
		return string.format("REMOVED: %d pallets", palletCount)
	end
	if balesCount > 0 and palletCount == 0 then
		return string.format("REMOVED: %d bales", balesCount)
	end
	return string.format("REMOVED: %d pallets, %d bales", palletCount, balesCount)
end
--
function UniversalAutoloadManager:consoleCreateBoundingBox()
	local usage = "Usage: ualCreateBoundingBox"

	for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
		if vehicle ~= nil then
			print("CREATING BOUNDING BOX: " .. vehicle:getFullName())
			UniversalAutoload.createBoundingBox(vehicle)
		end
	end
	return "Bounding box created sucessfully"
end
--
function UniversalAutoloadManager.addAttachedVehicles(vehicle, vehicles)

	if vehicle.getAttachedImplements ~= nil then
		local attachedImplements = vehicle:getAttachedImplements()
		for _, implement in pairs(attachedImplements) do
			local spec = implement.object.spec_universalAutoload
			vehicles[implement.object] = spec ~= nil and spec.isAutoloadEnabled
			UniversalAutoloadManager.addAttachedVehicles(implement.object, vehicles)
		end
	end
	return vehicles
end
--
function UniversalAutoloadManager.getAttachedVehicles(vehicle)
	local vehicles = {}
	local rootVehicle = vehicle:getRootVehicle()
	local spec = rootVehicle.spec_universalAutoload
	vehicles[rootVehicle] = spec ~= nil and spec.isAutoloadEnabled
	UniversalAutoloadManager.addAttachedVehicles(rootVehicle, vehicles)
	return vehicles
end

-- 
function UniversalAutoloadManager.resetNextVehicle(resetList)

	if resetList ~= nil and next(resetList) ~= nil then
		local vehicle = resetList[#resetList]
		table.remove(resetList, #resetList)
		if not UniversalAutoloadManager.resetVehicle(vehicle) then
			g_currentMission:consoleCommandReloadVehicle()
			g_currentMission.isReloadingVehicles = true
			UniversalAutoloadManager.resetNextVehicle(UniversalAutoloadManager.resetList)
		end
	else
		UniversalAutoloadManager.resetCount = nil
		g_currentMission.isReloadingVehicles = false
	end
end
--
function UniversalAutoloadManager.resetVehicle(vehicle)
	if UniversalAutoloadManager.resetCount then
		print(string.format("RESETTING #%d: %s", UniversalAutoloadManager.resetCount, vehicle:getFullName()))
	else
		print(string.format("RESETTING: %s", vehicle:getFullName()))
	end

	local rootVehicle = vehicle:getRootVehicle()
	if rootVehicle ~= nil then
		print("ROOT VEHICLE: " .. rootVehicle:getFullName())
		if rootVehicle == g_currentMission.controlledVehicle then
			if rootVehicle:getFullName() == "Diesel Locomotive" then
				print("*** CANNOT RESET TRAIN - terrible things will happen ***")
				return true
			else
				print("*** Resetting with standard console command ***")
				UniversalAutoload.clearLoadedObjects(vehicle)
				return false
			end
		end
	end
	
	UniversalAutoload.clearLoadedObjects(vehicle)

	local xmlFile = Vehicle.getReloadXML(vehicle)
	local key = "vehicles.vehicle(0)"

	if xmlFile ~= nil and xmlFile ~= 0 then
		local function asyncCallbackFunction(_, newVehicle, vehicleLoadState, arguments)
			if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
				g_messageCenter:publish(MessageType.VEHICLE_RESET, vehicle, newVehicle)
				g_currentMission:removeVehicle(vehicle)
				if UniversalAutoloadManager.resetCount then
					UniversalAutoloadManager.resetCount = UniversalAutoloadManager.resetCount + 1
				end
			else
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_ERROR then
					print(" >> VEHICLE_LOAD_ERROR")
				end
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_DELAYED then
					print(" >> VEHICLE_LOAD_DELAYED")
				end
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE then
					print(" >> There was no space available at the shop")
				end
				if vehicle ~= nil then
					print("ERROR RESETTING OLD VEHICLE: " .. vehicle:getFullName())
					--g_currentMission:removeVehicle(vehicle)
				end
				if newVehicle ~= nil then
					print("ERROR RESETTING NEW VEHICLE: " .. newVehicle:getFullName())
					--g_currentMission:removeVehicle(newVehicle)
				end
			end
			
			xmlFile:delete()
			UniversalAutoloadManager.resetNextVehicle(UniversalAutoloadManager.resetList)
		end
		
		VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, true, true, nil, true, asyncCallbackFunction, nil, {})
		--(xmlFile, key, resetVehicle, allowDelayed, xmlFilename, keepPosition, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

	end
	return true
end
--

-- MAIN LOAD MAP FUNCTION
function UniversalAutoloadManager:loadMap(name)

	for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
		-- Anything with tension belts could potentially require autoload
		if SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) 
		and not SpecializationUtil.hasSpecialization(UniversalAutoload, vehicleType.specializations) then
			g_vehicleTypeManager:addSpecialization(vehicleName, UniversalAutoload.name .. '.universalAutoload')
			print("  UAL INSTALLED: "..vehicleName)
		end
	end

	if g_modIsLoaded["FS22_Seedpotato_Farm_Pack"] or g_modIsLoaded["FS22_SeedPotatoFarmBuildings"] then
		print("** Seedpotato Farm Pack is loaded **")
		table.insert(UniversalAutoload.CONTAINERS, "POTATOBOX")
		UniversalAutoload.POTATOBOX = { sizeX = 1.850, sizeY = 1.100, sizeZ = 1.200 }
	end

	UniversalAutoload.CONTAINERS_INDEX = {}
	for i, key in ipairs(UniversalAutoload.CONTAINERS) do
		UniversalAutoload.CONTAINERS_INDEX[key] = i
	end
	
	UniversalAutoload.MATERIALS = {}
	table.insert(UniversalAutoload.MATERIALS, "ALL" )
	UniversalAutoload.MATERIALS_FILLTYPE = {}
	table.insert( UniversalAutoload.MATERIALS_FILLTYPE, {["title"]= g_i18n:getText("universalAutoload_ALL")} )
	for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
		if fillType.name ~= "UNKNOWN" then
			table.insert(UniversalAutoload.MATERIALS, fillType.name )
			table.insert(UniversalAutoload.MATERIALS_FILLTYPE, fillType )
		end
	end
	
	--print("  ALL MATERIALS:")
	UniversalAutoload.MATERIALS_INDEX = {}
	for i, key in ipairs(UniversalAutoload.MATERIALS) do
		-- print("  - "..i..": "..key.." = "..UniversalAutoload.MATERIALS_FILLTYPE[i].title)
		UniversalAutoload.MATERIALS_INDEX[key] = i
	end
	
	-- USER SETTINGS FIRST
	local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
	UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile)
	
	-- DEFAULT SETTINGS SECOND
	print("IMPORT supported vehicle configurations")
	local vehicleSettingsFile = Utils.getFilename("config/SupportedVehicles.xml", UniversalAutoload.path)
	UniversalAutoloadManager.ImportVehicleConfigurations(vehicleSettingsFile)
	print("IMPORT supported container configurations")
	local ContainerTypeSettingsFile = Utils.getFilename("config/ContainerTypes.xml", UniversalAutoload.path)
	UniversalAutoloadManager.ImportContainerTypeConfigurations(ContainerTypeSettingsFile)
	
	-- ADDITIONAL SETTINGS THIRD
	print("ADDITIONAL fill type containers")
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
		if fillType.palletFilename then
			local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(fillType.palletFilename)
			UniversalAutoloadManager.importContainerTypeFromXml(fillType.palletFilename, customEnvironment)
		end
    end
	for index, baleType in ipairs(g_baleManager.bales) do
		if baleType.isAvailable then
			local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(baleType.xmlFilename)
			UniversalAutoloadManager.importContainerTypeFromXml(baleType.xmlFilename, customEnvironment)
		end
	end
	for _, storeItem in pairs(g_storeManager:getItems()) do
		if storeItem.isMod and
		   storeItem.categoryName == "BALES" or
		   storeItem.categoryName == "BIGBAGS" or
		   storeItem.categoryName == "PALLETS" or
		   storeItem.categoryName == "BIGBAGPALLETS"
		then
			UniversalAutoloadManager.importContainerTypeFromXml(storeItem.xmlFilename, storeItem.customEnvironment)
		end	
	end
	
	UniversalAutoloadManager.detectOldConfigVersion()
	UniversalAutoloadManager.detectKeybindingConflicts()
	
	
	if g_currentMission:getIsServer() and not g_currentMission.missionDynamicInfo.isMultiplayer then
		addConsoleCommand("ualAddBales", "Fill current vehicle with specified bales", "consoleAddBales", UniversalAutoloadManager)
		addConsoleCommand("ualAddRoundBales_125", "Fill current vehicle with small round bales", "consoleAddRoundBales_125", UniversalAutoloadManager)
		addConsoleCommand("ualAddRoundBales_150", "Fill current vehicle with medium round bales", "consoleAddRoundBales_150", UniversalAutoloadManager)
		addConsoleCommand("ualAddRoundBales_180", "Fill current vehicle with large round bales", "consoleAddRoundBales_180", UniversalAutoloadManager)
		addConsoleCommand("ualAddSquareBales_180", "Fill current vehicle with small square bales", "consoleAddSquareBales_180", UniversalAutoloadManager)
		addConsoleCommand("ualAddSquareBales_220", "Fill current vehicle with medium square bales", "consoleAddSquareBales_220", UniversalAutoloadManager)
		addConsoleCommand("ualAddSquareBales_240", "Fill current vehicle with large square bales", "consoleAddSquareBales_240", UniversalAutoloadManager)
		addConsoleCommand("ualAddPallets", "Fill current vehicle with specified pallets (fill type)", "consoleAddPallets", UniversalAutoloadManager)
		addConsoleCommand("ualClearLoadedObjects", "Remove all loaded objects from current vehicle", "consoleClearLoadedObjects", UniversalAutoloadManager)
		addConsoleCommand("ualResetVehicles", "Reset all vehicles with autoload (and any attached) to the shop", "consoleResetVehicles", UniversalAutoloadManager)
		addConsoleCommand("ualImportUserConfigurations", "Force reload configurations from mod settings", "consoleImportUserConfigurations", UniversalAutoloadManager)
		addConsoleCommand("ualCreateBoundingBox", "Create a bounding box around all loaded pallets", "consoleCreateBoundingBox", UniversalAutoloadManager)
		
		
		local oldCleanUp = getmetatable(_G).__index.cleanUp
		getmetatable(_G).__index.cleanUp = function()
			-- print("UNIVERSAL AUTOLOAD: CLEAN UP")
			removeConsoleCommand("ualAddBales")
			removeConsoleCommand("ualAddRoundBales_125")
			removeConsoleCommand("ualAddRoundBales_150")
			removeConsoleCommand("ualAddRoundBales_180")
			removeConsoleCommand("ualAddSquareBales_180")
			removeConsoleCommand("ualAddSquareBales_220")
			removeConsoleCommand("ualAddSquareBales_240")
			removeConsoleCommand("ualAddPallets")
			removeConsoleCommand("ualClearLoadedObjects")
			removeConsoleCommand("ualResetVehicles")
			removeConsoleCommand("ualImportUserConfigurations")
			removeConsoleCommand("ualCreateBoundingBox")
			oldCleanUp()
		end
	end
end

function UniversalAutoloadManager:deleteMap()
end

function tableContainsValue(container, value)
	for k, v in pairs(container) do
		if v == value then
			return true
		end
	end
	return false
end

function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function deepCompare(tbl1, tbl2)
	if tbl1 == tbl2 then
		return true
	elseif type(tbl1) == "table" and type(tbl2) == "table" then
		for key1, value1 in pairs(tbl1) do
			local value2 = tbl2[key1]
			if value2 == nil then
				return false
			elseif value1 ~= value2 then
				if type(value1) == "table" and type(value2) == "table" then
					if not deepCompare(value1, value2) then
						return false
					end
				else
					return false
				end
			end
		end
		for key2, _ in pairs(tbl2) do
			if tbl1[key2] == nil then
				return false
			end
		end
		return true
	end
	return false
end

ShopConfigScreen.processAttributeData = Utils.overwrittenFunction(ShopConfigScreen.processAttributeData,
	function(self, superFunc, storeItem, vehicle, saleItem)

		superFunc(self, storeItem, vehicle, saleItem)
		
		if vehicle.spec_universalAutoload ~= nil and vehicle.spec_universalAutoload.isAutoloadEnabled then
		
			local itemElement = self.attributeItem:clone(self.attributesLayout)
			local iconElement = itemElement:getDescendantByName("icon")
			local textElement = itemElement:getDescendantByName("text")

			itemElement:reloadFocusHandling(true)
			iconElement:applyProfile(ShopConfigScreen.GUI_PROFILE.CAPACITY)
			iconElement:setImageFilename(UniversalAutoload.SHOP_ICON)
			iconElement:setImageUVs(nil, 0, 0, 0, 1, 1, 0, 1, 1)
			iconElement:setVisible(true)
			textElement:setText(g_i18n:getText("configuration_universalAutoload"))
			self.attributesLayout:invalidateLayout()
		end

	end
)
