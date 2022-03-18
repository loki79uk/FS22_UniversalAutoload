UniversalAutoloadPlayerTriggerEvent = {}
local UniversalAutoloadPlayerTriggerEvent_mt = Class(UniversalAutoloadPlayerTriggerEvent, Event)
InitEventClass(UniversalAutoloadPlayerTriggerEvent, "UniversalAutoloadPlayerTriggerEvent")
-- print("  UniversalAutoload - PlayerTriggerEvent")

function UniversalAutoloadPlayerTriggerEvent.emptyNew()
	local self = Event.new(UniversalAutoloadPlayerTriggerEvent_mt)
	return self
end

function UniversalAutoloadPlayerTriggerEvent.new(vehicle, player, inTrigger)
	local self = UniversalAutoloadPlayerTriggerEvent.emptyNew()
	self.vehicle = vehicle
	self.player = player
	self.inTrigger = inTrigger
	return self
end

function UniversalAutoloadPlayerTriggerEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		self.player = streamReadInt32(streamId)
	end
	if streamReadBool(streamId) then
		self.inTrigger = streamReadBool(streamId)
	end
	self:run(connection)
end

function UniversalAutoloadPlayerTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	if self.player ~= nil then
		streamWriteBool(streamId, true)
		streamWriteInt32(streamId, self.player)
	else
		streamWriteBool(streamId, false)
	end
	if self.inTrigger ~= nil then
		streamWriteBool(streamId, true)
		streamWriteBool(streamId, self.inTrigger)
	else
		streamWriteBool(streamId, false)
	end
end

function UniversalAutoloadPlayerTriggerEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		--print("PLAYER IN TRIGGER: "..tostring(self.inTrigger))
		UniversalAutoload.updatePlayerTriggerState(self.vehicle, self.player, self.inTrigger, true)
	end
end

function UniversalAutoloadPlayerTriggerEvent.sendEvent(vehicle, player, inTrigger, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Player Trigger Event")
			g_server:broadcastEvent(UniversalAutoloadPlayerTriggerEvent.new(vehicle, player, inTrigger), nil, nil, vehicle)
		else
			--print("client: Player Trigger Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadPlayerTriggerEvent.new(vehicle, player, inTrigger))
		end
	end
end