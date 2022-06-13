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
        g_vehicleTypeManager:addSpecialization(vehicleName, g_currentModName .. '.universalAutoload')
    end
end

-- tables
UniversalAutoload.ACTIONS = {
	["TOGGLE_LOADING"]        = "UNIVERSALAUTOLOAD_TOGGLE_LOADING",
	["UNLOAD_ALL"]            = "UNIVERSALAUTOLOAD_UNLOAD_ALL",
	["TOGGLE_TIPSIDE"]        = "UNIVERSALAUTOLOAD_TOGGLE_TIPSIDE",
	["TOGGLE_FILTER"]         = "UNIVERSALAUTOLOAD_TOGGLE_FILTER",
	["CYCLE_MATERIAL_FW"]     = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_FW",
	["CYCLE_MATERIAL_BW"]     = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_BW",
	["SELECT_ALL_MATERIALS"]  = "UNIVERSALAUTOLOAD_SELECT_ALL_MATERIALS",
	["CYCLE_CONTAINER_FW"]    = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW",
	["CYCLE_CONTAINER_BW"]    = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_BW",
	["SELECT_ALL_CONTAINERS"] = "UNIVERSALAUTOLOAD_SELECT_ALL_CONTAINERS",
	["TOGGLE_BELTS"]	      = "UNIVERSALAUTOLOAD_TOGGLE_BELTS",
	["TOGGLE_DOOR"]           = "UNIVERSALAUTOLOAD_TOGGLE_DOOR",
	["TOGGLE_CURTAIN"]	      = "UNIVERSALAUTOLOAD_TOGGLE_CURTAIN",
	["TOGGLE_DEBUG"]	      = "UNIVERSALAUTOLOAD_TOGGLE_DEBUG"
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
function UniversalAutoload.ImportVehicleConfigurations(xmlFilename, overwriteExisting)

	print("  IMPORT supported vehicle configurations")
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then
	
		local i = 0
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
				
				local config = configGroup[selectedConfigs]
				config.width  = xmlFile:getValue(configKey..".loadingArea#width")
				config.length = xmlFile:getValue(configKey..".loadingArea#length")
				config.height = xmlFile:getValue(configKey..".loadingArea#height")
				config.offset = xmlFile:getValue(configKey..".loadingArea#offset", "0 0 0", true)
				config.isBoxTrailer = xmlFile:getValue(configKey..".options#isBoxTrailer", false)
				config.isCurtainTrailer = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
				config.enableRearLoading = xmlFile:getValue(configKey..".options#enableRearLoading", false)
				config.enableSideLoading = xmlFile:getValue(configKey..".options#enableSideLoading", false)
				config.noLoadingIfFolded = xmlFile:getValue(configKey..".options#noLoadingIfFolded", false)
				config.noLoadingIfUnfolded = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
				--config.disableAutoStrap = xmlFile:getValue(configKey..".options#disableAutoStrap", false)
				config.showDebug = xmlFile:getValue(configKey..".options#showDebug", false)

				print("  >> "..configFileName.." ("..selectedConfigs..")")
			else
				print("  CONFIG ALREADY EXISTS: "..configFileName.." ("..selectedConfigs..")")
			end
			
			i = i + 1
		end

		xmlFile:delete()
	end
end

-- IMPORT CONTAINER TYPE DEFINITIONS
UniversalAutoload.LOADING_TYPE_CONFIGURATIONS = {}
function UniversalAutoload.ImportContainerTypeConfigurations(xmlFilename)

	print("  IMPORT container types")
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then

		local key = "universalAutoload.containerTypeConfigurations"
		local i = 0
		while true do
			local containerTypeKey = string.format("%s.containerTypeConfiguration(%d)", key, i)

			if not xmlFile:hasProperty(containerTypeKey) then
				break
			end

			local containerType = xmlFile:getValue(containerTypeKey.."#containerType")
			if tableContainsValue(UniversalAutoload.CONTAINERS, containerType) then
			
				local default = UniversalAutoload[containerType] or {}
				print("  "..containerType..":")
				
				local j = 0
				while true do
					local objectTypeKey = string.format("%s.objectType(%d)", containerTypeKey, j)
					
					if not xmlFile:hasProperty(objectTypeKey) then
						break
					end
				
					local name = xmlFile:getValue(objectTypeKey.."#name")
					UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
					newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
					newType.name = name
					newType.type = containerType or "ALL"
					newType.containerIndex = UniversalAutoload.CONTAINERS_INDEX[containerType] or 1
					newType.sizeX = xmlFile:getValue(objectTypeKey.."#sizeX", default.sizeX or 1.5)
					newType.sizeY = xmlFile:getValue(objectTypeKey.."#sizeY", default.sizeY or 1.5)
					newType.sizeZ = xmlFile:getValue(objectTypeKey.."#sizeZ", default.sizeZ or 1.5)
					newType.isBale = xmlFile:getValue(objectTypeKey.."#isBale", default.isBale or false)
					newType.flipYZ = xmlFile:getValue(objectTypeKey.."#flipYZ", default.flipYZ or false)
					newType.neverStack = xmlFile:getValue(objectTypeKey.."#neverStack", default.neverStack or false)
					newType.neverRotate = xmlFile:getValue(objectTypeKey.."#neverRotate", default.neverRotate or false)
					newType.alwaysRotate = xmlFile:getValue(objectTypeKey.."#alwaysRotate", default.alwaysRotate or false)
					print(string.format("  >> %s [%.3f, %.3f, %.3f]", newType.name, newType.sizeX, newType.sizeY, newType.sizeZ ))
					
					j = j + 1
				end
				
			else
				print("  UNKNOWN CONTAINER TYPE: "..tostring(containerType))
			end

			i = i + 1
		end

		xmlFile:delete()
	end
	
	print("  ADDITIONAL fill type containers:")
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
		if fillType.palletFilename then
			local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(fillType.palletFilename)
			UniversalAutoload.importContainerTypeFromXml(fillType.palletFilename, customEnvironment)
		end
    end
	
	print("  ADDITIONAL bales:")
	for index, baleType in ipairs(g_baleManager.bales) do
		if baleType.isAvailable then
			local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(baleType.xmlFilename)
			UniversalAutoload.importContainerTypeFromXml(baleType.xmlFilename, customEnvironment)
		end
	end
	
	print("  ADDITIONAL store item containers:")
	for _, storeItem in pairs(g_storeManager:getItems()) do
		if storeItem.isMod and
		   storeItem.categoryName == "BALES" or
		   storeItem.categoryName == "BIGBAGS" or
		   storeItem.categoryName == "PALLETS" or
		   storeItem.categoryName == "BIGBAGPALLETS"
		then
			UniversalAutoload.importContainerTypeFromXml(storeItem.xmlFilename, storeItem.customEnvironment)
		end	
	end

end
--
function UniversalAutoload.importContainerTypeFromXml(xmlFilename, customEnvironment)

	if xmlFilename ~= nil and not string.find(xmlFilename, "multiPurchase") then	
		--print( "  >> " .. xmlFilename )
		local loadedVehicleXML = false
		local xmlFile = XMLFile.load("configXml", xmlFilename, Vehicle.xmlSchema)

		if xmlFile~=nil and xmlFile:hasProperty("vehicle.base") then
			loadedVehicleXML = true
			UniversalAutoload.importPalletTypeFromXml(xmlFile, customEnvironment)
		end
		xmlFile:delete()
		
		if not loadedVehicleXML then
			xmlFile = XMLFile.load("baleConfigXml", xmlFilename, BaleManager.baleXMLSchema)
			if xmlFile~=nil and xmlFile:hasProperty("bale") then
				UniversalAutoload.importBaleTypeFromXml(xmlFile, customEnvironment)
			end
			xmlFile:delete()
		end
		
	end
end
--
function UniversalAutoload.importPalletTypeFromXml(xmlFile, customEnvironment)
	
	local i3d_path = xmlFile:getValue("vehicle.base.filename")
	local i3d_name = UniversalAutoload.getObjectNameFromPath(i3d_path)
	
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
				print("  USING DEFAULT CONTAINER TYPE: "..name.." - "..category)
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
function UniversalAutoload.importBaleTypeFromXml(xmlFile, customEnvironment)
	
	local i3d_path = xmlFile:getValue("bale.filename")
	local i3d_name = UniversalAutoload.getObjectNameFromPath(i3d_path)
	
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
--
function UniversalAutoload.detectKeybindingConflicts()
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

function UniversalAutoloadManager:loadMap(name)

	if g_modIsLoaded["FS22_Seedpotato_Farm_Pack"] then
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
		
	local vehicleSettingsFile = Utils.getFilename("config/SupportedVehicles.xml", UniversalAutoload.path)
	UniversalAutoload.ImportVehicleConfigurations(vehicleSettingsFile)
	local ContainerTypeSettingsFile = Utils.getFilename("config/ContainerTypes.xml", UniversalAutoload.path)
	UniversalAutoload.ImportContainerTypeConfigurations(ContainerTypeSettingsFile)
	
	UniversalAutoload.detectKeybindingConflicts()

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
