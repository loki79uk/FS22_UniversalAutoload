-- ============================================================= --
-- Universal Autoload MOD - MANAGER
-- ============================================================= --
-- manager
UniversalAutoloadManager = {}
addModEventListener(UniversalAutoloadManager)

-- specialisation
g_specializationManager:addSpecialization('universalAutoload', 'UniversalAutoload', Utils.getFilename('UniversalAutoload.lua', g_currentModDirectory), "")

TypeManager.validateTypes = Utils.appendedFunction(TypeManager.validateTypes, function(self)
    if self.typeName == "vehicle" then
        for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
            -- Anything with tension belts could potentially require autoload
            if SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) then
                g_vehicleTypeManager:addSpecialization(vehicleName, UniversalAutoload.name .. '.universalAutoload')
                -- print("  UAL INSTALLED: "..vehicleName)
            end
        end
    end
end)

-- Create a new store pack to group all UAL supported vehicles
-- @Loki Cannot do this in the modDesc using 'storePacks.storePack' as Giants forgot to localise l10n
g_storeManager:addModStorePack("UNIVERSALAUTOLOAD", g_i18n:getText("configuration_universalAutoload", g_currentModName), "icons/storePack_ual.dds", g_currentModDirectory)

-- variables
UniversalAutoload.userSettingsFile = "modSettings/UniversalAutoload.xml"
UniversalAutoload.SHOP_ICON = UniversalAutoload.path .. "icons/shop_icon.dds"

-- tables
UniversalAutoload.ACTIONS = {["TOGGLE_LOADING"] = "UNIVERSALAUTOLOAD_TOGGLE_LOADING", ["UNLOAD_ALL"] = "UNIVERSALAUTOLOAD_UNLOAD_ALL", ["TOGGLE_TIPSIDE"] = "UNIVERSALAUTOLOAD_TOGGLE_TIPSIDE",
                             ["TOGGLE_FILTER"] = "UNIVERSALAUTOLOAD_TOGGLE_FILTER", ["TOGGLE_HORIZONTAL"] = "UNIVERSALAUTOLOAD_TOGGLE_HORIZONTAL",
                             ["CYCLE_MATERIAL_FW"] = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_FW", ["CYCLE_MATERIAL_BW"] = "UNIVERSALAUTOLOAD_CYCLE_MATERIAL_BW",
                             ["SELECT_ALL_MATERIALS"] = "UNIVERSALAUTOLOAD_SELECT_ALL_MATERIALS", ["CYCLE_CONTAINER_FW"] = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_FW",
                             ["CYCLE_CONTAINER_BW"] = "UNIVERSALAUTOLOAD_CYCLE_CONTAINER_BW", ["SELECT_ALL_CONTAINERS"] = "UNIVERSALAUTOLOAD_SELECT_ALL_CONTAINERS",
                             ["TOGGLE_BELTS"] = "UNIVERSALAUTOLOAD_TOGGLE_BELTS", ["TOGGLE_DOOR"] = "UNIVERSALAUTOLOAD_TOGGLE_DOOR", ["TOGGLE_CURTAIN"] = "UNIVERSALAUTOLOAD_TOGGLE_CURTAIN",
                             ["TOGGLE_SHOW_DEBUG"] = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_DEBUG", ["TOGGLE_SHOW_LOADING"] = "UNIVERSALAUTOLOAD_TOGGLE_SHOW_LOADING",
                             ["TOGGLE_BALE_COLLECTION"] = "UNIVERSALAUTOLOAD_TOGGLE_BALE_COLLECTION"}

UniversalAutoload.WARNINGS = {[1] = "warning_UNIVERSALAUTOLOAD_CLEAR_UNLOADING_AREA", [2] = "warning_UNIVERSALAUTOLOAD_NO_OBJECTS_FOUND", [3] = "warning_UNIVERSALAUTOLOAD_UNABLE_TO_LOAD_OBJECT",
                              [4] = "warning_UNIVERSALAUTOLOAD_NO_LOADING_UNLESS_STATIONARY"}

UniversalAutoload.CONTAINERS = {[1] = "ALL", [2] = "EURO_PALLET", [3] = "BIGBAG_PALLET", [4] = "LIQUID_TANK", [5] = "BIGBAG", [6] = "BALE", [7] = "LOGS"}

UniversalAutoload.VALID_OBJECTS = {[1] = "pallet", [2] = "bigBag", [3] = "treeSaplingPallet", [4] = "pdlc_pumpsAndHosesPack.hosePallet", [5] = "pdlc_forestryPack.woodContainer"}

-- DEFINE DEFAULTS FOR CONTAINER TYPES
UniversalAutoload.ALL = {sizeX = 1.250, sizeY = 0.850, sizeZ = 0.850}
UniversalAutoload.EURO_PALLET = {sizeX = 1.250, sizeY = 0.790, sizeZ = 0.850}
UniversalAutoload.BIGBAG_PALLET = {sizeX = 1.525, sizeY = 1.075, sizeZ = 1.200}
UniversalAutoload.LIQUID_TANK = {sizeX = 1.433, sizeY = 1.500, sizeZ = 1.415}
UniversalAutoload.BIGBAG = {sizeX = 1.050, sizeY = 1.666, sizeZ = 0.866, neverStack = true}
UniversalAutoload.BALE = {isBale = true}

UniversalAutoload.VEHICLES = {}
UniversalAutoload.UNKNOWN_TYPES = {}

-- IMPORT VEHICLE CONFIGURATIONS
UniversalAutoload.VEHICLE_CONFIGURATIONS = {}

function UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, overwriteExisting)

    if g_currentMission.isMultiplayer then
        print("Custom configurations are not supported in multiplayer")
        return
    end

    local N, M = 0, 0
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
        UniversalAutoload.highPriority = true
        UniversalAutoload.disableAutoStrap = false
        UniversalAutoload.manualLoadingOnly = false
        UniversalAutoload.pricePerLog = 0
        UniversalAutoload.pricePerBale = 0
        UniversalAutoload.pricePerPallet = 0
        UniversalAutoload.minLogLength = 0
    end

    return N, M
end
--
function UniversalAutoload.ImportUserConfigurations(userSettingsFile, overwriteExisting)
    print("*** OLD VERSION OF UNIVERSAL AUTOLOAD MODHUB ADD-ON DETECTED - please update to latest version ***")
    return UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, overwriteExisting)
end
--
function UniversalAutoloadManager.ImportGlobalSettings(xmlFilename, overwriteExisting)

    if g_currentMission:getIsServer() then

        local xmlFile = XMLFile.load("configXml", xmlFilename, UniversalAutoload.xmlSchema)
        if xmlFile ~= 0 and xmlFile ~= nil then

            if overwriteExisting or not UniversalAutoload.globalSettingsLoaded then
                print("IMPORT Universal Autoload global settings")
                UniversalAutoload.globalSettingsLoaded = true
                UniversalAutoload.showDebug = xmlFile:getValue("universalAutoload#showDebug", false)
                UniversalAutoload.highPriority = xmlFile:getValue("universalAutoload#highPriority", true)
                UniversalAutoload.disableAutoStrap = xmlFile:getValue("universalAutoload#disableAutoStrap", false)
                UniversalAutoload.manualLoadingOnly = xmlFile:getValue("universalAutoload#manualLoadingOnly", false)
                UniversalAutoload.pricePerLog = xmlFile:getValue("universalAutoload#pricePerLog", 0)
                UniversalAutoload.pricePerBale = xmlFile:getValue("universalAutoload#pricePerBale", 0)
                UniversalAutoload.pricePerPallet = xmlFile:getValue("universalAutoload#pricePerPallet", 0)
                UniversalAutoload.minLogLength = xmlFile:getValue("universalAutoload#minLogLength", 0)
                print("  >> Show Debug Display: " .. tostring(UniversalAutoload.showDebug))
                print("  >> Menu High Priority: " .. tostring(UniversalAutoload.highPriority))
                print("  >> Manual Loading Only: " .. tostring(UniversalAutoload.manualLoadingOnly))
                print("  >> Automatic Tension Belts: " .. tostring(not UniversalAutoload.disableAutoStrap))
                print("  >> Price Per Log: " .. tostring(UniversalAutoload.pricePerLog))
                print("  >> Price Per Bale: " .. tostring(UniversalAutoload.pricePerBale))
                print("  >> Price Per Pallet: " .. tostring(UniversalAutoload.pricePerPallet))
                print("  >> Minimum Log Length: " .. tostring(UniversalAutoload.minLogLength))
            end

            local objectTypesKey = "universalAutoload.objectTypes"
            if xmlFile:hasProperty(objectTypesKey) then
                print("ADDING EXTRA object types")
                local i = 0
                while true do
                    local objectTypeKey = string.format(objectTypesKey .. ".objectType(%d)", i)
                    if not xmlFile:hasProperty(objectTypeKey) then
                        break
                    end
                    local objectType = xmlFile:getValue(objectTypeKey .. "#name")
                    objectType = objectType:gsub(":", ".")

                    local customEnvironment, _ = objectType:match("^(.-)%.(.+)$")
                    if customEnvironment == nil or g_modIsLoaded[customEnvironment] then
                        if not tableContainsValue(UniversalAutoload.VALID_OBJECTS, objectType) then
                            table.insert(UniversalAutoload.VALID_OBJECTS, objectType)
                            print("  >> " .. tostring(objectType))
                        end
                    end

                    i = i + 1
                end
            end
            xmlFile:delete()
        else
            print("Universal Autoload - could not open global settings file")
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

            local configFileName = xmlFile:getValue(configKey .. "#configFileName")
            local validXmlFilename = UniversalAutoload.getValidXmlName(configFileName)

            if validXmlFilename ~= nil then

                if UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] == nil then
                    UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName] = {}
                    -- Update the store pack with available vehicle
                    -- StoreManager.addPackItem' allows duplicates when using 'gsStoreItemsReload' so not used
                    table.addElement(g_storeManager:getPackItems("UNIVERSALAUTOLOAD"), validXmlFilename)
                end

                local configGroup = UniversalAutoload.VEHICLE_CONFIGURATIONS[configFileName]
                local selectedConfigs = xmlFile:getValue(configKey .. "#selectedConfigs", "ALL")
                local useConfigName = xmlFile:getValue(configKey .. "#useConfigName", nil)
                if configGroup[selectedConfigs] == nil or overwriteExisting then
                    configGroup[selectedConfigs] = {}
                    configGroup[selectedConfigs].loadingArea = {}

                    local config = configGroup[selectedConfigs]
                    config.useConfigName = useConfigName
                    config.xmlFilename = validXmlFilename

                    local j = 0
                    local hasBaleHeight = false
                    while true do
                        local loadAreaKey = string.format("%s.loadingArea(%d)", configKey, j)
                        if not xmlFile:hasProperty(loadAreaKey) then
                            break
                        end
                        config.loadingArea[j + 1] = {}
                        config.loadingArea[j + 1].width = xmlFile:getValue(loadAreaKey .. "#width", nil)
                        config.loadingArea[j + 1].length = xmlFile:getValue(loadAreaKey .. "#length", nil)
                        config.loadingArea[j + 1].height = xmlFile:getValue(loadAreaKey .. "#height", nil)
                        config.loadingArea[j + 1].baleHeight = xmlFile:getValue(loadAreaKey .. "#baleHeight", nil)
                        config.loadingArea[j + 1].widthAxis = xmlFile:getValue(loadAreaKey .. "#widthAxis", nil)
                        config.loadingArea[j + 1].lengthAxis = xmlFile:getValue(loadAreaKey .. "#lengthAxis", nil)
                        config.loadingArea[j + 1].heightAxis = xmlFile:getValue(loadAreaKey .. "#heightAxis", nil)
                        config.loadingArea[j + 1].offset = xmlFile:getValue(loadAreaKey .. "#offset", "0 0 0", true)
                        config.loadingArea[j + 1].offsetRoot = xmlFile:getValue(loadAreaKey .. "#offsetRoot", nil)
                        config.loadingArea[j + 1].noLoadingIfFolded = xmlFile:getValue(loadAreaKey .. "#noLoadingIfFolded", false)
                        config.loadingArea[j + 1].noLoadingIfUnfolded = xmlFile:getValue(loadAreaKey .. "#noLoadingIfUnfolded", false)
                        config.loadingArea[j + 1].noLoadingIfCovered = xmlFile:getValue(loadAreaKey .. "#noLoadingIfCovered", false)
                        config.loadingArea[j + 1].noLoadingIfUncovered = xmlFile:getValue(loadAreaKey .. "#noLoadingIfUncovered", false)
                        hasBaleHeight = hasBaleHeight or type(config.loadingArea[j + 1].baleHeight) == 'number'
                        j = j + 1
                    end

                    local isBaleTrailer = xmlFile:getValue(configKey .. ".options#isBaleTrailer", nil)
                    local horizontalLoading = xmlFile:getValue(configKey .. ".options#horizontalLoading", nil)

                    config.horizontalLoading = horizontalLoading or isBaleTrailer or false
                    config.isBaleTrailer = isBaleTrailer or hasBaleHeight

                    config.isBoxTrailer = xmlFile:getValue(configKey .. ".options#isBoxTrailer", false)
                    config.isLogTrailer = xmlFile:getValue(configKey .. ".options#isLogTrailer", false)
                    config.isCurtainTrailer = xmlFile:getValue(configKey .. ".options#isCurtainTrailer", false)
                    config.enableRearLoading = xmlFile:getValue(configKey .. ".options#enableRearLoading", false)
                    config.enableSideLoading = xmlFile:getValue(configKey .. ".options#enableSideLoading", false)
                    config.noLoadingIfFolded = xmlFile:getValue(configKey .. ".options#noLoadingIfFolded", false)
                    config.noLoadingIfUnfolded = xmlFile:getValue(configKey .. ".options#noLoadingIfUnfolded", false)
                    config.noLoadingIfCovered = xmlFile:getValue(configKey .. ".options#noLoadingIfCovered", false)
                    config.noLoadingIfUncovered = xmlFile:getValue(configKey .. ".options#noLoadingIfUncovered", false)
                    config.rearUnloadingOnly = xmlFile:getValue(configKey .. ".options#rearUnloadingOnly", false)
                    config.frontUnloadingOnly = xmlFile:getValue(configKey .. ".options#frontUnloadingOnly", false)
                    config.disableAutoStrap = xmlFile:getValue(configKey .. ".options#disableAutoStrap", false)
                    config.disableHeightLimit = xmlFile:getValue(configKey .. ".options#disableHeightLimit", false)
                    config.zonesOverlap = xmlFile:getValue(configKey .. ".options#zonesOverlap", false)
                    config.offsetRoot = xmlFile:getValue(configKey .. ".options#offsetRoot", nil)
                    config.minLogLength = xmlFile:getValue(configKey .. ".options#minLogLength", UniversalAutoload.minLogLength)
                    config.showDebug = xmlFile:getValue(configKey .. ".options#showDebug", debugAll)

                    if not config.showDebug then
                        print("  >> " .. configFileName .. " (" .. selectedConfigs .. ")")
                    else
                        print("  >> " .. configFileName .. " (" .. selectedConfigs .. ") DEBUG")
                    end
                else
                    if UniversalAutoload.showDebug then
                        print("  ALREADY EXISTS: " .. configFileName .. " (" .. selectedConfigs .. ")")
                    end
                end

            else
                if UniversalAutoload.showDebug then
                    print("  NOT FOUND: " .. configFileName)
                end
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
            local configKey = string.format(containerRootKey .. ".containerConfiguration(%d)", i)

            if not xmlFile:hasProperty(configKey) then
                break
            end

            local containerType = xmlFile:getValue(configKey .. "#containerType", "ALL")
            if tableContainsValue(UniversalAutoload.CONTAINERS, containerType) then

                local default = UniversalAutoload[containerType] or {}

                local name = xmlFile:getValue(configKey .. "#name")
                local customEnvironment, _ = name:match("^(.-):(.+)$")
                if customEnvironment == nil or g_modIsLoaded[customEnvironment] then
                    local config = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
                    if config == nil or overwriteExisting then
                        UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] = {}
                        newType = UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name]
                        newType.name = name
                        newType.type = containerType
                        newType.containerIndex = UniversalAutoload.CONTAINERS_INDEX[containerType] or 1
                        newType.sizeX = xmlFile:getValue(configKey .. "#sizeX", default.sizeX or 1.5)
                        newType.sizeY = xmlFile:getValue(configKey .. "#sizeY", default.sizeY or 1.5)
                        newType.sizeZ = xmlFile:getValue(configKey .. "#sizeZ", default.sizeZ or 1.5)
                        newType.isBale = xmlFile:getValue(configKey .. "#isBale", default.isBale or false)
                        newType.flipYZ = xmlFile:getValue(configKey .. "#flipYZ", default.flipYZ or false)
                        newType.neverStack = xmlFile:getValue(configKey .. "#neverStack", default.neverStack or false)
                        newType.neverRotate = xmlFile:getValue(configKey .. "#neverRotate", default.neverRotate or false)
                        newType.alwaysRotate = xmlFile:getValue(configKey .. "#alwaysRotate", default.alwaysRotate or false)
                        print(string.format("  >> %s %s [%.3f, %.3f, %.3f]", newType.type, newType.name, newType.sizeX, newType.sizeY, newType.sizeZ))
                    end
                end

            else
                if UniversalAutoload.showDebug then
                    print("  UNKNOWN CONTAINER TYPE: " .. tostring(containerType))
                end
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

    if xmlFilename ~= nil and not (string.find(xmlFilename, "multiPurchase") or string.find(xmlFilename, "multipleItemPurchase")) then
        -- print( "  >> " .. xmlFilename )

        local foundExisting = false
        if customEnvironment ~= nil then
            foundExisting = UniversalAutoloadManager.importUnknownSpecFromExisting(xmlFilename, customEnvironment)
        end

        if not foundExisting then
            local loadedVehicleXML = false
            local xmlFile = XMLFile.load("configXml", xmlFilename, Vehicle.xmlSchema)

            if xmlFile ~= nil and xmlFile:hasProperty("vehicle.base") then
                loadedVehicleXML = true
                UniversalAutoloadManager.importPalletTypeFromXml(xmlFile, customEnvironment)
            end
            xmlFile:delete()

            if not loadedVehicleXML then
                xmlFile = XMLFile.load("baleConfigXml", xmlFilename, BaleManager.baleXMLSchema)
                if xmlFile ~= nil and xmlFile:hasProperty("bale") then
                    UniversalAutoloadManager.importBaleTypeFromXml(xmlFile, customEnvironment)
                end
                xmlFile:delete()
            end
        end

    end
end
--
function UniversalAutoloadManager.importObjectTypeTypeFromXml(xmlInput, customEnvironment)

    local xmlFile = xmlInput
    if type(xmlInput) == 'string' then
        xmlFile = XMLFile.load("configXml", xmlInput, Vehicle.xmlSchema)
    end

    if xmlFile ~= nil then
        local vehicleType = xmlFile:getValue("vehicle#type")
        if vehicleType ~= nil and customEnvironment ~= nil then
            local objectType = customEnvironment .. "." .. vehicleType
            if not tableContainsValue(UniversalAutoload.VALID_OBJECTS, objectType) then
                table.insert(UniversalAutoload.VALID_OBJECTS, objectType)
            end
        end
        if type(xmlInput) == 'string' then
            xmlFile:delete()
        end
    end
end
--
function UniversalAutoloadManager.importUnknownSpecFromExisting(xmlFilename, customEnvironment)

    local objectName = UniversalAutoload.getObjectNameFromXml(xmlFilename)
    local customName = customEnvironment .. ":" .. objectName

    if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[customName] ~= nil then
        -- print("FOUND CUSTOM CONFIG FOR " .. customName)
        return true
    end

    if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[objectName] ~= nil then
        -- print("USING BASE CONFIG FOR " .. customName)

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
        print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name, newType.sizeX, newType.sizeY, newType.sizeZ, newType.type))
        UniversalAutoloadManager.importObjectTypeTypeFromXml(xmlFilename, customEnvironment)
        return true
    end
end
--
function UniversalAutoloadManager.importPalletTypeFromXml(xmlFile, customEnvironment)

    local i3d_path = xmlFile:getValue("vehicle.base.filename")

    if i3d_path == nil then
        print("  MISSING 'vehicle.base.filename' in " .. tostring(xmlFile.filename))
        return
    end

    local i3d_name = UniversalAutoload.getObjectNameFromI3d(i3d_path)

    if i3d_name ~= nil then
        local name
        if customEnvironment == nil then
            name = i3d_name
        else
            name = customEnvironment .. ":" .. i3d_name
        end

        if UniversalAutoload.LOADING_TYPE_CONFIGURATIONS[name] == nil then

            local category = xmlFile:getValue("vehicle.storeData.category", "NONE")
            local width = xmlFile:getValue("vehicle.base.size#width", 1.5)
            local height = xmlFile:getValue("vehicle.base.size#height", 1.5)
            local length = xmlFile:getValue("vehicle.base.size#length", 1.5)

            local containerType
            if string.find(i3d_name, "liquidTank") or string.find(i3d_name, "IBC") then
                containerType = "LIQUID_TANK"
            elseif string.find(i3d_name, "bigBag") or string.find(i3d_name, "BigBag") then
                containerType = "BIGBAG"
            elseif string.find(i3d_name, "pallet") or string.find(i3d_name, "Pallet") then
                containerType = "EURO_PALLET"
            elseif category == "pallets" then
                containerType = "EURO_PALLET"
            elseif category == "bigbags" then
                containerType = "BIGBAG"
            elseif category == "bigbagPallets" then
                containerType = "BIGBAG_PALLET"
            else
                containerType = "ALL"
                if UniversalAutoload.showDebug then
                    print("  USING DEFAULT CONTAINER TYPE: " .. name .. " - " .. category)
                end
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

            print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name, newType.sizeX, newType.sizeY, newType.sizeZ, containerType))
            UniversalAutoloadManager.importObjectTypeTypeFromXml(xmlFile, customEnvironment)
            return true
        end
    end
end
--
function UniversalAutoloadManager.importBaleTypeFromXml(xmlFile, customEnvironment)

    local i3d_path = xmlFile:getValue("bale.filename")

    if i3d_path == nil then
        print("importBaleTypeFromXml: i3d_path == NIL")
        print(tostring(xmlFile.filename))
        return
    end

    local i3d_name = UniversalAutoload.getObjectNameFromI3d(i3d_path)

    if i3d_name ~= nil then
        local name
        if customEnvironment == nil then
            name = i3d_name
        else
            name = customEnvironment .. ":" .. i3d_name
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

            print(string.format("  >> %s [%.3f, %.3f, %.3f] - %s", newType.name, newType.sizeX, newType.sizeY, newType.sizeZ, containerType))
            return true
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
                print("**  OR update container config key to: 'containerConfigurations'   **")
                print("*********************************************************************")
            end
            xmlFile:delete()
        end
    end
end
--
function UniversalAutoloadManager.detectKeybindingConflicts()
    -- DETECT 'T' KEYS CONFLICT
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
                        local bindingKey = key .. string.format('.binding(%d)', i)
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
                        local bindingKey = key .. string.format('.binding(%d)', i)
                        local bindingInput = getXMLString(xmlFile, bindingKey .. '#input')
                        if bindingInput ~= nil then
                            print("  Using '" .. bindingInput .. "' for 'CYCLE_CONTAINER'")
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

    UniversalAutoloadManager.resetNextVehicle()

end
--
function UniversalAutoloadManager:consoleImportUserConfigurations()

    local oldVehicleConfigurations = deepCopy(UniversalAutoload.VEHICLE_CONFIGURATIONS)
    local oldContainerConfigurations = deepCopy(UniversalAutoload.LOADING_TYPE_CONFIGURATIONS)
    local userSettingsFile = Utils.getFilename(UniversalAutoload.userSettingsFile, getUserProfileAppPath())
    local vehicleCount, objectCount = UniversalAutoloadManager.ImportUserConfigurations(userSettingsFile, true)

    g_currentMission.isReloadingVehicles = true
    if vehicleCount > 0 then
        vehicleCount = 0
        local doResetVehicle = false
        for key, configGroup in pairs(UniversalAutoload.VEHICLE_CONFIGURATIONS) do
            local foundFirstMatch = false
            for index, config in pairs(configGroup) do
                if oldVehicleConfigurations[key] and oldVehicleConfigurations[key][index] and not deepCompare(oldVehicleConfigurations[key][index], config) then
                    -- FIRST LOOK IF THIS IS THE CURRENT CONTROLLED VECHILE
                    for _, vehicle in pairs(UniversalAutoload.VEHICLES) do
                        -- print(vehicle.configFileName .. " - " .. tostring(vehicle.spec_universalAutoload.boughtConfig) .. " / " .. index)
                        if string.find(vehicle.configFileName, key) and vehicle.spec_universalAutoload.boughtConfig == index then
                            local rootVehicle = vehicle:getRootVehicle()
                            if rootVehicle == g_currentMission.controlledVehicle then
                                foundFirstMatch = true
                                print("APPLYING UPDATED SETTINGS: " .. vehicle:getFullName())
                                if not UniversalAutoloadManager.resetVehicle(vehicle) then
                                    print("THIS IS CURRENT CONTROLLED VEHICLE: " .. vehicle:getFullName())
                                    doResetVehicle = true
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
                                    doResetVehicle = true
                                end
                            else
                                print("ONLY ONE OF EACH VEHICLE CONFIGURATION CAN BE RESET USING THIS COMMAND")
                            end
                        end
                    end
                end
            end
        end
        if doResetVehicle then
            g_currentMission:consoleCommandReloadVehicle()
        else
            g_currentMission.isReloadingVehicles = false
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
        pallets[palletType] = xmlFilename
    end

    if g_currentMission.controlledVehicle ~= nil then

        local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
        local count = 0

        if next(vehicles) ~= nil then
            for vehicle, hasAutoload in pairs(vehicles) do
                if hasAutoload and vehicle:getIsActiveForInput() then
                    if UniversalAutoload.createPallets(vehicle, pallets) then
                        count = count + 1
                    end
                end
            end
        end

        if count > 0 then
            return "Begin adding pallets now.."
        end
    end
    return "Please enter a vehicle with a UAL trailer attached to use this command"
end
--
function UniversalAutoloadManager:consoleAddLogs(arg1, arg2)

    local length = nil
    local treeTypeName = "PINE"

    if tonumber(arg1) then
        length = tonumber(arg1)
        treeTypeName = arg2
    elseif tonumber(arg2) then
        length = tonumber(arg2)
        treeTypeName = arg1
    elseif arg1 ~= nil then
        treeTypeName = arg1
    end

    local availableLogTypes

    if not g_modIsLoaded["pdlc_forestryPack"] then
        availableLogTypes = {OAK = 3.5, ELM = 3.5, PINE = 30, BIRCH = 5, MAPLE = 2, POPLAR = 18, SPRUCE = 34, WILLOW = 2.5, CYPRESS = 2.5, HICKORY = 4.2, STONEPINE = 8}
    else
        availableLogTypes = {OAK = 3.5, ELM = 3.5, PINE = 30, BIRCH = 5, MAPLE = 2, POPLAR = 18, SPRUCE = 34, WILLOW = 2.5, CYPRESS = 2.5, HICKORY = 4.2, DEADWOOD = 20, STONEPINE = 8,
                             GIANTSEQUOIA = 7, PONDEROSAPINE = 32, LODGEPOLEPINE = 32}
    end

    treeTypeName = string.upper(treeTypeName or "")
    if availableLogTypes[treeTypeName] == nil then
        return "Error: Invalid lumber type. Valid types are " .. table.concatKeys(availableLogTypes, ", ")
    end

    local maxLength = availableLogTypes[treeTypeName]
    if treeTypeName == 'ELM' then
        treeTypeName = 'AMERICANELM'
    end
    if treeTypeName == 'HICKORY' then
        treeTypeName = 'SHAGBARKHICKORY'
    end
    if length == nil then
        length = maxLength
    end
    if length > maxLength then
        print("using maximum length " .. maxLength .. "m")
        length = maxLength
    end

    if g_currentMission.controlledVehicle ~= nil then

        local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
        local count = 0

        if next(vehicles) ~= nil then
            for vehicle, hasAutoload in pairs(vehicles) do
                if hasAutoload and vehicle:getIsActiveForInput() then
                    local maxSingleLength = UniversalAutoload.getMaxSingleLength(vehicle)
                    if length > maxSingleLength then
                        length = maxSingleLength - 0.1
                        print("resizing to fit trailer " .. length .. "m")
                    end
                    if UniversalAutoload.createLogs(vehicle, treeTypeName, length) then
                        count = count + 1
                    end
                end
            end
        end

        if count > 0 then
            return "Begin adding logs now.."
        end
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
                if hasAutoload and vehicle:getIsActiveForInput() then
                    if UniversalAutoload.createBales(vehicle, bale) then
                        count = count + 1
                    end
                end
            end
        end

        if count > 0 then
            return "Begin adding bales now.."
        end
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

    local palletCount, balesCount, logCount = 0, 0, 0
    if g_currentMission.controlledVehicle ~= nil then
        local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)
        if next(vehicles) ~= nil then
            for vehicle, hasAutoload in pairs(vehicles) do
                if hasAutoload and vehicle:getIsActiveForInput() then
                    P, B, L = UniversalAutoload.clearLoadedObjects(vehicle)
                    palletCount = palletCount + P
                    balesCount = balesCount + B
                    logCount = logCount + L
                end
            end
        end
    end

    if palletCount > 0 and balesCount == 0 and logCount == 0 then
        return string.format("REMOVED: %d pallets", palletCount)
    end
    if balesCount > 0 and palletCount == 0 and logCount == 0 then
        return string.format("REMOVED: %d bales", balesCount)
    end
    if logCount > 0 and palletCount == 0 and balesCount == 0 then
        return string.format("REMOVED: %d logs", logCount)
    end
    return string.format("REMOVED: %d pallets, %d bales, %d logs", palletCount, balesCount, logCount)
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
    return "Bounding box created successfully"
end
--
function UniversalAutoloadManager:consoleSpawnTestPallets()
    local usage = "Usage: consoleSpawnTestPallets"

    if g_currentMission.controlledVehicle ~= nil then

        local vehicles = UniversalAutoloadManager.getAttachedVehicles(g_currentMission.controlledVehicle)

        if next(vehicles) ~= nil then
            for vehicle, hasAutoload in pairs(vehicles) do
                if hasAutoload and vehicle:getIsActiveForInput() then

                    UniversalAutoload.testPallets = {}
                    UniversalAutoload.testPalletsCount = 0;
                    for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
                        local xmlName = fillType.palletFilename
                        if xmlName ~= nil and not xmlName:find("fillablePallet") then
                            print(string.format("%s - %s", fillType, xmlName))
                            UniversalAutoload.createPallet(vehicle, xmlName)
                        end
                    end
                    return "Test pallets created successfully"
                end
            end
        end

        -- if next(UniversalAutoload.testPallets) and isActiveForInputIgnoreSelection then
        -- if #UniversalAutoload.testPallets == UniversalAutoload.testPalletsCount then
        -- print("TEST PALLETS SPAWNED")
        -- print(string.format("%s, %s, %s, %s", "name", "volume", "mass", "density"))
        -- for _, pallet in pairs(UniversalAutoload.testPallets) do
        -- local config = UniversalAutoload.getContainerType(pallet)
        -- local mass = UniversalAutoload.getContainerMass(pallet)
        -- local volume = config.sizeX * config.sizeY * config.sizeZ
        -- print(string.format("%s, %f, %f, %f", config.name, volume, mass, mass/volume))
        -- g_currentMission:removeVehicle(pallet, true)
        -- end
        -- UniversalAutoload.testPallets = {}
        -- end
        -- end
    end
    return "Please enter a vehicle with a UAL trailer attached to use this command"

end
--
function UniversalAutoloadManager.addAttachedVehicles(vehicle, vehicles)

    if vehicle.getAttachedImplements ~= nil then
        local attachedImplements = vehicle:getAttachedImplements()
        for _, implement in pairs(attachedImplements) do
            local spec = implement.object.spec_universalAutoload
            vehicles[implement.object] = spec ~= nil
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
    vehicles[rootVehicle] = spec ~= nil
    UniversalAutoloadManager.addAttachedVehicles(rootVehicle, vehicles)
    return vehicles
end

--
function UniversalAutoloadManager.resetNextVehicle()

    local resetList = UniversalAutoloadManager.resetList
    if resetList ~= nil and next(resetList) ~= nil then
        local vehicle = resetList[#resetList]
        table.remove(resetList, #resetList)
        if not UniversalAutoloadManager.resetVehicle(vehicle) then
            UniversalAutoloadManager.resetCount = UniversalAutoloadManager.resetCount + 1
            UniversalAutoloadManager.resetControlledVehicle = true
            UniversalAutoloadManager.resetNextVehicle()
        end
    else
        if UniversalAutoloadManager.resetControlledVehicle then
            UniversalAutoloadManager.resetControlledVehicle = false
            g_currentMission:consoleCommandReloadVehicle()
            g_currentMission.isReloadingVehicles = true
        else
            g_currentMission.isReloadingVehicles = false
        end
        UniversalAutoloadManager.resetCount = nil
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
        if rootVehicle:getFullName():find("Locomotive") then
            print("*** CANNOT RESET TRAIN - terrible things will happen ***")
            if UniversalAutoloadManager.resetCount then
                UniversalAutoloadManager.resetNextVehicle()
            end
            return true
        end
        if rootVehicle == g_currentMission.controlledVehicle then
            print("*** Resetting with standard console command ***")
            UniversalAutoload.clearLoadedObjects(vehicle)
            return false
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
                    -- g_currentMission:removeVehicle(vehicle)
                end
                if newVehicle ~= nil then
                    print("ERROR RESETTING NEW VEHICLE: " .. newVehicle:getFullName())
                    -- g_currentMission:removeVehicle(newVehicle)
                end
            end

            xmlFile:delete()
            UniversalAutoloadManager.resetNextVehicle()
        end

        VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, true, true, nil, true, asyncCallbackFunction, nil, {})
        -- (xmlFile, key, resetVehicle, allowDelayed, xmlFilename, keepPosition, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

    end
    return true
end
--

function UniversalAutoloadManager.consoleFullTest()

    UniversalAutoloadManager.runFullTest = true

end

-- MAIN LOAD MAP FUNCTION
function UniversalAutoloadManager:loadMap(name)

    for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
        -- Anything with tension belts could potentially require autoload
        if SpecializationUtil.hasSpecialization(TensionBelts, vehicleType.specializations) and not SpecializationUtil.hasSpecialization(UniversalAutoload, vehicleType.specializations) then
            g_vehicleTypeManager:addSpecialization(vehicleName, UniversalAutoload.name .. '.universalAutoload')
            print("  UAL INSTALLED: " .. vehicleName)
        end
    end

    if g_modIsLoaded["pdlc_forestryPack"] then
        print("** Forestry Pack is loaded **")
        table.insert(UniversalAutoload.CONTAINERS, "SHIPPING_CONTAINER")
        UniversalAutoload.SHIPPING_CONTAINER = {sizeX = 2.44, sizeY = 2.59, sizeZ = 0.00}
    end

    if g_modIsLoaded["FS22_Seedpotato_Farm_Pack"] or g_modIsLoaded["FS22_SeedPotatoFarmBuildings"] then
        print("** Seedpotato Farm Pack is loaded **")
        table.insert(UniversalAutoload.CONTAINERS, "POTATOBOX")
        UniversalAutoload.POTATOBOX = {sizeX = 1.850, sizeY = 1.100, sizeZ = 1.200}
    end

    UniversalAutoload.CONTAINERS_INDEX = {}
    for i, key in ipairs(UniversalAutoload.CONTAINERS) do
        UniversalAutoload.CONTAINERS_INDEX[key] = i
    end

    UniversalAutoload.MATERIALS = {}
    table.insert(UniversalAutoload.MATERIALS, "ALL")
    UniversalAutoload.MATERIALS_FILLTYPE = {}
    table.insert(UniversalAutoload.MATERIALS_FILLTYPE, {["title"] = g_i18n:getText("universalAutoload_ALL")})
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
        if fillType.name ~= "UNKNOWN" then
            table.insert(UniversalAutoload.MATERIALS, fillType.name)
            table.insert(UniversalAutoload.MATERIALS_FILLTYPE, fillType)
        end
    end

    -- print("  ALL MATERIALS:")
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
    print("ADDITIONAL containers")
    for index, fillType in ipairs(g_fillTypeManager.fillTypes) do
        if fillType.palletFilename then
            local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(fillType.palletFilename)
            UniversalAutoloadManager.importContainerTypeFromXml(fillType.palletFilename, customEnvironment)
        end
    end
    print("ADDITIONAL bales")
    for index, baleType in ipairs(g_baleManager.bales) do
        if baleType.isAvailable then
            local customEnvironment = UniversalAutoload.getEnvironmentNameFromPath(baleType.xmlFilename)
            UniversalAutoloadManager.importContainerTypeFromXml(baleType.xmlFilename, customEnvironment)
        end
    end
    print("ADDITIONAL items")
    for _, storeItem in pairs(g_storeManager:getItems()) do
        if storeItem.isMod and storeItem.categoryName == "BALES" or storeItem.categoryName == "BIGBAGS" or storeItem.categoryName == "PALLETS" or storeItem.categoryName == "BIGBAGPALLETS" then
            UniversalAutoloadManager.importContainerTypeFromXml(storeItem.xmlFilename, storeItem.customEnvironment)
        end
    end

    -- DISPLAY LIST OF VALID OBJECT TYPES
    print("USING custom object types")
    table.sort(UniversalAutoload.VALID_OBJECTS) -- function(a, b) return a:lower() < b:lower() end
    for _, objectType in pairs(UniversalAutoload.VALID_OBJECTS) do
        if objectType:find("%.") and not objectType:find("pdlc_") then
            print("  >> " .. objectType)
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
        addConsoleCommand("ualAddLogs", "Fill current vehicle with specified logs (length / fill type)", "consoleAddLogs", UniversalAutoloadManager)
        addConsoleCommand("ualClearLoadedObjects", "Remove all loaded objects from current vehicle", "consoleClearLoadedObjects", UniversalAutoloadManager)
        addConsoleCommand("ualResetVehicles", "Reset all vehicles with autoload (and any attached) to the shop", "consoleResetVehicles", UniversalAutoloadManager)
        addConsoleCommand("ualImportUserConfigurations", "Force reload configurations from mod settings", "consoleImportUserConfigurations", UniversalAutoloadManager)
        addConsoleCommand("ualCreateBoundingBox", "Create a bounding box around all loaded pallets", "consoleCreateBoundingBox", UniversalAutoloadManager)
        addConsoleCommand("ualSpawnTestPallets", "Create one of each pallet type (not loaded)", "consoleSpawnTestPallets", UniversalAutoloadManager)
        addConsoleCommand("ualFullTest", "Test all the different loading types", "consoleFullTest", UniversalAutoloadManager)

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
            removeConsoleCommand("ualAddLogs")
            removeConsoleCommand("ualClearLoadedObjects")
            removeConsoleCommand("ualResetVehicles")
            removeConsoleCommand("ualImportUserConfigurations")
            removeConsoleCommand("ualCreateBoundingBox")
            removeConsoleCommand("ualSpawnTestPallets")
            removeConsoleCommand("ualFullTest")
            oldCleanUp()
        end
    end
end

-- SYNC SETTINGS:
Player.readStream = Utils.overwrittenFunction(Player.readStream, function(self, superFunc, streamId, connection, objectId)
    superFunc(self, streamId, connection, objectId)
    -- print("Player.readStream")
    UniversalAutoload.disableAutoStrap = streamReadBool(streamId)
    UniversalAutoload.manualLoadingOnly = streamReadBool(streamId)
end)
Player.writeStream = Utils.overwrittenFunction(Player.writeStream, function(self, superFunc, streamId, connection)
    superFunc(self, streamId, connection)
    -- print("Player.writeStream")
    streamWriteBool(streamId, UniversalAutoload.disableAutoStrap or false)
    streamWriteBool(streamId, UniversalAutoload.manualLoadingOnly or false)
end)

-- SEND SETTINGS TO CLIENT:
FSBaseMission.sendInitialClientState = Utils.overwrittenFunction(FSBaseMission.sendInitialClientState, function(self, superFunc, connection, user, farm)
    superFunc(self, connection, user, farm)

    if debugMultiplayer then
        print("  user: " .. tostring(user.nickname) .. " " .. tostring(farm.name))
    end
    print("connectedToDedicatedServer: " .. tostring(g_currentMission.connectedToDedicatedServer))

    -- UniversalAutoload.disableAutoStrap = UniversalAutoload.disableAutoStrap or false
    -- UniversalAutoload.manualLoadingOnly = UniversalAutoload.manualLoadingOnly or false
    -- UniversalAutoload.pricePerLog = UniversalAutoload.pricePerLog or 0
    -- UniversalAutoload.pricePerBale = UniversalAutoload.pricePerBale or 0
    -- UniversalAutoload.pricePerPallet = UniversalAutoload.pricePerPallet or 0

    -- streamWriteBool(streamId, UniversalAutoload.disableAutoStrap)
    -- streamWriteBool(streamId, UniversalAutoload.manualLoadingOnly)
    -- streamWriteInt32(streamId, spec.pricePerLog)
    -- streamWriteInt32(streamId, spec.pricePerBale)
    -- streamWriteInt32(streamId, spec.pricePerPallet)
    -- streamWriteInt32(streamId, spec.minLogLength)

    -- UniversalAutoload.disableAutoStrap = streamReadBool(streamId)
    -- UniversalAutoload.manualLoadingOnly = streamReadBool(streamId)
    -- spec.pricePerLog = streamReadInt32(streamId)
    -- spec.pricePerBale = streamReadInt32(streamId)
    -- spec.pricePerPallet = streamReadInt32(streamId)
    -- spec.minLogLength = streamReadInt32(streamId)
end)

function UniversalAutoloadManager:setupHud()
    UniversalAutoloadManager.infoTextHud = UniversalAutoloadHud
    UniversalAutoloadManager.infoTextHud:init()
end

function UniversalAutoloadManager:draw()
    -- if not g_gui:getIsGuiVisible() and not g_noHudModeEnabled then
    --     UniversalAutoloadManager.infoTextHud:draw()
    -- end
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
    if tbl1 == nil or tbl2 == nil then
        return false
    end
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

ShopConfigScreen.processAttributeData = Utils.overwrittenFunction(ShopConfigScreen.processAttributeData, function(self, superFunc, storeItem, vehicle, saleItem)

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

        if vehicle.spec_universalAutoload.isLogTrailer then
            local maxSingleLengthString
            local maxSingleLength = UniversalAutoload.getMaxSingleLength(vehicle)
            local nearestHalfValue = math.floor(2 * maxSingleLength) / 2
            if nearestHalfValue % 1 < 0.1 then
                maxSingleLengthString = string.format("  %dm", nearestHalfValue)
            else
                maxSingleLengthString = string.format("  %.1fm", nearestHalfValue)
            end

            local itemElement2 = self.attributeItem:clone(self.attributesLayout)
            local iconElement2 = itemElement2:getDescendantByName("icon")
            local textElement2 = itemElement2:getDescendantByName("text")

            itemElement2:reloadFocusHandling(true)
            iconElement2:applyProfile(ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH)
            textElement2:setText(g_i18n:getText("infohud_length") .. maxSingleLengthString)
        end

        self.attributesLayout:invalidateLayout()

    end

end)

-- Add valid store items to the 'UNIVERSALAUTOLOAD' store pack if it exists.
-- Using 'table.addElement' will avoid duplicates and errors if Store Pack does not load or exist for some reason ;-)
StoreManager.loadItem = Utils.overwrittenFunction(StoreManager.loadItem, function(self, superFunc, ...)
    local storeItem = superFunc(self, ...)

    if storeItem ~= nil and storeItem.isMod and storeItem.species == "vehicle" then
        local xmlFile = XMLFile.load("loadItemXml", storeItem.xmlFilename, storeItem.xmlSchema)

        -- @Loki Could do more checks if required but why would a mod have the XML key if not UAL?
        if xmlFile:hasProperty("vehicle.universalAutoload") then
            -- StoreManager.addPackItem' allows duplicates when using 'gsStoreItemsReload' so not used
            table.addElement(g_storeManager:getPackItems("UNIVERSALAUTOLOAD"), storeItem.xmlFilename)
        end

        xmlFile:delete()
    end

    return storeItem
end)
