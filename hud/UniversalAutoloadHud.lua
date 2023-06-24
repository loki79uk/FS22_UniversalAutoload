-- ============================================================= --
-- Universal Autoload MOD - SPECIALISATION
-- ============================================================= --
UniversalAutoloadHud = {}
UniversalAutoloadHud.eventName = {}
UniversalAutoloadHud.material = nil
UniversalAutoloadHud.container = nil
UniversalAutoloadHud.filter = nil
UniversalAutoloadHud.horizontalLoading = nil
UniversalAutoloadHud.tipside = nil

UniversalAutoloadHud.Colors = {}
UniversalAutoloadHud.Colors[1] = {'col_white', {1, 1, 1, 1}}
UniversalAutoloadHud.Colors[2] = {'col_black', {0, 0, 0, 1}}
UniversalAutoloadHud.Colors[3] = {'col_grey', {0.7411, 0.7450, 0.7411, 1}}
UniversalAutoloadHud.Colors[4] = {'col_blue', {0.0044, 0.15, 0.6376, 1}}
UniversalAutoloadHud.Colors[5] = {'col_red', {0.8796, 0.0061, 0.004, 1}}
UniversalAutoloadHud.Colors[6] = {'col_green', {0.0263, 0.3613, 0.0212, 1}}
UniversalAutoloadHud.Colors[7] = {'col_yellow', {0.9301, 0.7605, 0.0232, 1}}
UniversalAutoloadHud.Colors[8] = {'col_pink', {0.89, 0.03, 0.57, 1}}
UniversalAutoloadHud.Colors[9] = {'col_turquoise', {0.07, 0.57, 0.35, 1}}
UniversalAutoloadHud.Colors[10] = {'col_brown', {0.1912, 0.1119, 0.0529, 1}}

function UniversalAutoloadHud:init()
end

function UniversalAutoloadHud:draw()
    -- Just render and burn CPU with all the other crap when the actual HUD is visible and we're on a client
    if g_client ~= nil and g_currentMission.hud.isVisible and not g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
        local posX, posY = g_currentMission.hud.vehicleSchema:getPosition()
        local size = g_currentMission.inGameMenu.hud.inputHelp.helpTextSize
        if g_currentMission.controlledVehicle == nil then
            posY = g_currentMission.inGameMenu.hud.inputHelp.origY
        else
            posY = posY - size - g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY
        end

        -- moving down so it doesn't overlap
        posY = posY - size * 2

        if self.material ~= nil then
            UniversalAutoloadHud:renderText(posX, posY, size, self.material, false, 1)
            posY = posY - size
        end

        if self.container ~= nil then
            UniversalAutoloadHud:renderText(posX, posY, size, self.container, false, 1)
            posY = posY - size
        end

        if self.filter ~= nil then
            UniversalAutoloadHud:renderText(posX, posY, size, self.filter, false, 1)
            posY = posY - size
        end

        if self.horizontalLoading ~= nil then
            UniversalAutoloadHud:renderText(posX, posY, size, self.horizontalLoading, false, 1)
            posY = posY - size
        end

        if self.tipside ~= nil then
            UniversalAutoloadHud:renderText(posX, posY, size, self.tipside, false, 1)
            posY = posY - size
        end
    end
end

function UniversalAutoloadHud:updateMaterial(material)
    self.material = material
end

function UniversalAutoloadHud:updateContainer(container)
    self.container = container
end

function UniversalAutoloadHud:updateFilter(filter)
    self.filter = filter
end

function UniversalAutoloadHud:updateHorizontalLoading(horizontalLoading)
    self.horizontalLoading = horizontalLoading
end

function UniversalAutoloadHud:updateTipside(tipside)
    self.tipside = tipside
end

function UniversalAutoloadHud:renderText(x, y, size, text, bold, colorId)
    setTextColor(unpack(self.Colors[colorId][2]))
    setTextBold(bold)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x, y, size, text)

    -- Back to defaults
    setTextBold(false)
    setTextColor(unpack(self.Colors[1][2])) -- Back to default color which is white
    setTextAlignment(RenderText.ALIGN_LEFT)
end
