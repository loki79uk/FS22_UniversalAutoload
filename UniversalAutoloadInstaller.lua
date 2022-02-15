-- ============================================================= --
-- Universal Autoload MOD - MANAGER
-- ============================================================= --

-- manager
UniversalAutoloadManager = {}
addModEventListener(UniversalAutoloadManager)

-- specialisation
g_specializationManager:addSpecialization('universalAutoload', 'UniversalAutoload', Utils.getFilename('UniversalAutoload.lua', g_currentModDirectory), true)

for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
	if vehicleName == 'trailer' or vehicleName == 'dynamicMountAttacherTrailer' then
		if SpecializationUtil.hasSpecialization(FillUnit, vehicleType.specializations) and
		   SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) then
			g_vehicleTypeManager:addSpecialization(vehicleName, 'universalAutoload')
		end
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
	["TOGGLE_BELTS"]	      = "UNIVERSALAUTOLOAD_TOGGLE_BELTS"
}

UniversalAutoload.TYPES = {
	[1] = "ALL",
	[2] = "EURO_PALLET",
	[3] = "BIGBAG_PALLET",
	[4] = "LIQUID_TANK",
	[5] = "BIGBAG"
}

-- DEFINE DEFAULTS FOR LOADING TYPES
UniversalAutoload.ALL            = { sizeX = 1.250, sizeY = 0.850, sizeZ = 0.850 }
UniversalAutoload.EURO_PALLET    = { sizeX = 1.250, sizeY = 0.790, sizeZ = 0.850 }
UniversalAutoload.BIGBAG_PALLET  = { sizeX = 1.525, sizeY = 1.075, sizeZ = 1.200 }
UniversalAutoload.LIQUID_TANK    = { sizeX = 1.433, sizeY = 1.500, sizeZ = 1.415 }
UniversalAutoload.BIGBAG         = { sizeX = 1.050, sizeY = 2.000, sizeZ = 0.900 }

UniversalAutoload.VEHICLES = {}
UniversalAutoload.UNKNOWN_TYPES = {}

-- IMPORT LOADING TYPE DEFINITIONS
UniversalAutoload.VEHICLE_CONFIGURATIONS = {}
function UniversalAutoload.ImportVehicleConfigurations(xmlFilename)

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
			
			UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] = {}
			local config = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
			config.selectedConfigs = xmlFile:getValue(configKey.."#selectedConfigs")
			config.width  = xmlFile:getValue(configKey..".loadingArea#width")
			config.length = xmlFile:getValue(configKey..".loadingArea#length")
			config.height = xmlFile:getValue(configKey..".loadingArea#height")
			config.offset = xmlFile:getValue(configKey..".loadingArea#offset", "0 0 0", true)
			config.isCurtainTrailer = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
			config.enableRearLoading = xmlFile:getValue(configKey..".options#enableRearLoading", false)
			config.noLoadingIfUnfolded = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
			config.showDebug = xmlFile:getValue(configKey..".options#showDebug", false)
			
			print("  >> "..configFileName)

			i = i + 1
		end

		xmlFile:delete()
	end
end

-- IMPORT LOADING TYPE DEFINITIONS
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
			if tableContainsValue(UniversalAutoload.TYPES, containerType) then
			
				local default = UniversalAutoload[containerType]
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
					newType.containerType = containerType or "ALL"
					newType.containerIndex = UniversalAutoload.INDEX[containerType] or 1
					newType.sizeX = xmlFile:getValue(objectTypeKey.."#sizeX", default.sizeX)
					newType.sizeY = xmlFile:getValue(objectTypeKey.."#sizeY", default.sizeY)
					newType.sizeZ = xmlFile:getValue(objectTypeKey.."#sizeZ", default.sizeZ)
					newType.alwaysRotate = xmlFile:getValue(objectTypeKey.."#alwaysRotate", false)
					
					if alwaysRotate then
						newType.width = newType.sizeZ
						newType.length = newType.sizeX
					else
						newType.width = math.min(newType.sizeX, newType.sizeZ)
						newType.length = math.max(newType.sizeX, newType.sizeZ)
					end
					newType.height = newType.sizeY
					
					print(string.format("  >> %s [%.3f, %.3f, %.3f] %s", newType.name,
						newType.sizeX, newType.sizeY, newType.sizeZ, tostring(newType.alwaysRotate) ))
					
					j = j + 1
				end
				
			else
				print("  UNKNOWN CONTAINER TYPE: "..containerType)
			end

			i = i + 1
		end

		xmlFile:delete()
	end

	print("  ADDITIONAL container types:")
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
        if fillType.palletFilename ~= nil then	
			local xmlFile = XMLFile.load("configXml", fillType.palletFilename, Vehicle.xmlSchema)
			if xmlFile ~= 0 then
				--print( "  >> " .. fillType.palletFilename )

				local i3d_path = xmlFile:getValue("vehicle.base.filename")
				local name = UniversalAutoload.getObjectNameFromPath(i3d_path)
				
				if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] == nil then
				
					local category = xmlFile:getValue("vehicle.storeData.category")
					local width = xmlFile:getValue("vehicle.base.size#width", 2.0)
					local height = xmlFile:getValue("vehicle.base.size#height", 2.0)
					local length = xmlFile:getValue("vehicle.base.size#length", 2.0)
					
					local containerType
					if category == "bigbagPallets" then containerType = "BIGBAG_PALLET"
					elseif name == "liquidTank" then containerType = "LIQUID_TANK"
					elseif name == "bigBag" then containerType = "BIGBAG"
					elseif string.find(i3d_path, "FS22_Seedpotato_Farm_Pack") then containerType = "POTATOBOX"
					else containerType = "ALL"
					end

					UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
					newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
					newType.name = name
					newType.containerType = containerType or "ALL"
					newType.containerIndex = UniversalAutoload.INDEX[containerType] or 1
					newType.sizeX = width
					newType.sizeY = height
					newType.sizeZ = length
					newType.alwaysRotate = false
					newType.width = math.min(newType.sizeX, newType.sizeZ)
					newType.length = math.max(newType.sizeX, newType.sizeZ)
						
					print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name,
						newType.sizeX, newType.sizeY, newType.sizeZ, containerType ))
						
				end
	
			end
			--DebugUtil.printTableRecursively(fillType, "--", 0, 1)
        end
    end


	
end

function UniversalAutoloadManager:loadMap(name)

	print("  IMPORT KNOWN MODS:")
	if g_modIsLoaded["FS22_Seedpotato_Farm_Pack"] then
		print("** Seedpotato Farm Pack is loaded **")
		table.insert(UniversalAutoload.TYPES, "POTATOBOX")
		UniversalAutoload.POTATOBOX = { sizeX = 1.850, sizeY = 1.100, sizeZ = 1.200 }
	end

	UniversalAutoload.INDEX = {}
	for i, key in ipairs(UniversalAutoload.TYPES) do
		UniversalAutoload.INDEX[key] = i
	end
	
	UniversalAutoload.MATERIALS = {}
	table.insert(UniversalAutoload.MATERIALS, "ALL")
	for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
		if fillType.palletFilename ~= nil then
			table.insert(UniversalAutoload.MATERIALS, fillType.name)
		end
	end
		
	local vehicleSettingsFile = Utils.getFilename("config/SupportedVehicles.xml", UniversalAutoload.path)
	UniversalAutoload.ImportVehicleConfigurations(vehicleSettingsFile)
	local ContainerTypeSettingsFile = Utils.getFilename("config/ContainerTypes.xml", UniversalAutoload.path)
	UniversalAutoload.ImportContainerTypeConfigurations(ContainerTypeSettingsFile)

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
