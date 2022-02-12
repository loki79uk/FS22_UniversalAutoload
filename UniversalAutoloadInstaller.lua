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
	["TOGGLE_LOADING"]  = "UNIVERSALAUTOLOAD_TOGGLE_LOADING",
	["UNLOAD_ALL"]      = "UNIVERSALAUTOLOAD_UNLOAD_ALL",
	["TOGGLE_TIPSIDE"]  = "UNIVERSALAUTOLOAD_TOGGLE_TIPSIDE",
	["TOGGLE_FILTER"]   = "UNIVERSALAUTOLOAD_TOGGLE_FILTER",
	["CYCLE_TYPES_FW"]  = "UNIVERSALAUTOLOAD_CYCLE_TYPES_FW",
	["CYCLE_TYPES_BW"]  = "UNIVERSALAUTOLOAD_CYCLE_TYPES_BW",
	["SELECT_ALL"]      = "UNIVERSALAUTOLOAD_SELECT_ALL",
	["TOGGLE_BELTS"]	= "UNIVERSALAUTOLOAD_TOGGLE_BELTS"
}

UniversalAutoload.TYPES = {
	[1] = "ALL",
	[2] = "EURO_PALLET",
	[3] = "BIGBAG_PALLET",
	[4] = "LIQUID_TANK",
	[5] = "BIGBAG"
}

-- DEFINE DEFAULTS FOR LOADING TYPES
UniversalAutoload.EURO_PALLET   = { sizeX = 1.250, sizeY = 0.790, sizeZ = 0.850, alwaysRotate = false }
UniversalAutoload.BIGBAG_PALLET = { sizeX = 1.525, sizeY = 1.075, sizeZ = 1.200, alwaysRotate = false }
UniversalAutoload.LIQUID_TANK   = { sizeX = 1.433, sizeY = 1.500, sizeZ = 1.415, alwaysRotate = false }
UniversalAutoload.BIGBAG        = { sizeX = 1.050, sizeY = 2.000, sizeZ = 0.900, alwaysRotate = true }

 
UniversalAutoload.VEHICLES = {}
UniversalAutoload.UNKNOWN_TYPES = {}

-- IMPORT LOADING TYPE DEFINITIONS
UniversalAutoload.VEHICLE_CONFIGURATIONS = {}
function UniversalAutoload.ImportVehicleConfigurations(xmlFilename)
	print("  IMPORT supported vehicle configurations")
	
	-- define the loading area parameters from settings file
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then

		local key = "universalAutoload.vehicleConfigurations"
		local i = 0
		while true do
			local configKey = string.format("%s.vehicleConfiguration(%d)", key, i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local xmlName = xmlFile:getValue(configKey.."#name")
			
			UniversalAutoload.VEHICLE_CONFIGURATIONS[xmlName] = {}
			local config = UniversalAutoload.VEHICLE_CONFIGURATIONS[xmlName]
			
			config.xmlName = xmlName
			config.width  = xmlFile:getValue(configKey..".loadingArea#width")
			config.length = xmlFile:getValue(configKey..".loadingArea#length")
			config.height = xmlFile:getValue(configKey..".loadingArea#height")
			config.offset = xmlFile:getValue(configKey..".loadingArea#offset", "0 0 0", true)
			config.isCurtainTrailer = xmlFile:getValue(configKey..".options#isCurtainTrailer", false)
			config.enableRearLoading = xmlFile:getValue(configKey..".options#enableRearLoading", false)
			config.noLoadingIfUnfolded = xmlFile:getValue(configKey..".options#noLoadingIfUnfolded", false)
			
			print("  >> "..xmlName)

			i = i + 1
		end

		xmlFile:delete()
	end
end

-- IMPORT LOADING TYPE DEFINITIONS
UniversalAutoload.LOADING_TYPE_CONFIGURATIONS = {}
function UniversalAutoload.ImportLoadingTypeConfigurations(xmlFilename)

	print("  IMPORT KNOWN MODS:")
	if g_modIsLoaded["FS22_Seedpotato_Farm_Pack"] then
		print("** Seedpotato Farm Pack is loaded **")
		table.insert(UniversalAutoload.TYPES, "POTATOBOX")
		UniversalAutoload.POTATOBOX = { sizeX = 1.850, sizeY = 1.100, sizeZ = 1.200, alwaysRotate = false }
	end
	
	print("  IMPORT custom loading types")
	-- define the loading area parameters from settings file
	local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
	if xmlFile ~= 0 then

		local key = "universalAutoload.loadingTypeConfigurations"
		local i = 0
		while true do
			local loadingTypeKey = string.format("%s.loadingTypeConfiguration(%d)", key, i)

			if not xmlFile:hasProperty(loadingTypeKey) then
				break
			end

			local loadingType = xmlFile:getValue(loadingTypeKey.."#loadingType")
			if tableContainsValue(UniversalAutoload.TYPES, loadingType) then
			
				local default = UniversalAutoload[loadingType]
				print("  "..loadingType..":")
				
				local j = 0
				while true do
					local objectTypeKey = string.format("%s.objectType(%d)", loadingTypeKey, j)
					
					if not xmlFile:hasProperty(objectTypeKey) then
						break
					end
				
					local name = xmlFile:getValue(objectTypeKey.."#name")
					UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
					newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
					newType.name = name
					newType.loadingType = loadingType or "ANY"
					newType.loadingIndex = UniversalAutoload.INDEX[loadingType] or 1
					newType.sizeX = xmlFile:getValue(objectTypeKey.."#sizeX", default.sizeX)
					newType.sizeY = xmlFile:getValue(objectTypeKey.."#sizeY", default.sizeY)
					newType.sizeZ = xmlFile:getValue(objectTypeKey.."#sizeZ", default.sizeZ)
					newType.alwaysRotate = xmlFile:getValue(objectTypeKey.."#alwaysRotate", default.alwaysRotate)
					
					if alwaysRotate then
						newType.width = newType.sizeX
						newType.length = newType.sizeZ
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
				print("  UNKNOWN LOADING TYPE: "..loadingType)
			end

			i = i + 1
		end

		xmlFile:delete()
	end

	print("  ADD default loading types")
	local palletTypes = {}
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
					
					local loadingType
					if category == "bigbagPallets" then loadingType = "BIGBAG_PALLET"
					elseif name == "liquidTank" then loadingType = "LIQUID_TANK"
					elseif name == "bigBag" then loadingType = "BIGBAG"
					elseif string.find(i3d_path, "Pallet") then loadingType = "EURO_PALLET"
					elseif string.find(i3d_path, "FS22_Seedpotato_Farm_Pack") then loadingType = "POTATOBOX"
					else loadingType = "ANY"
					end

					UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
					newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
					newType.name = name
					newType.loadingType = loadingType or "ANY"
					newType.loadingIndex = UniversalAutoload.INDEX[loadingType] or 1
					newType.sizeX = width
					newType.sizeY = height
					newType.sizeZ = length
					newType.alwaysRotate = false
					newType.width = math.min(newType.sizeX, newType.sizeZ)
					newType.length = math.max(newType.sizeX, newType.sizeZ)
						
					print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name,
						newType.sizeX, newType.sizeY, newType.sizeZ, loadingType ))
						
				end
	
			end
			--DebugUtil.printTableRecursively(fillType, "--", 0, 1)
        end
    end


	
end

function UniversalAutoloadManager:loadMap(name)
	print("  Loaded: Universal Autoload Manager")
	
	UniversalAutoload.INDEX = {}
	for i, key in ipairs(UniversalAutoload.TYPES) do
		UniversalAutoload.INDEX[key] = i
	end
		
	local vehicleSettingsFile = Utils.getFilename("config/SupportedVehicles.xml", UniversalAutoload.path)
	UniversalAutoload.ImportVehicleConfigurations(vehicleSettingsFile)
	local LoadingTypeSettingsFile = Utils.getFilename("config/LoadingTypes.xml", UniversalAutoload.path)
	UniversalAutoload.ImportLoadingTypeConfigurations(LoadingTypeSettingsFile)

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
