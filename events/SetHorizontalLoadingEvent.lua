UniversalAutoloadSetHorizontalLoadingEvent = {}
local UniversalAutoloadSetHorizontalLoadingEvent_mt = Class(UniversalAutoloadSetHorizontalLoadingEvent, Event)
InitEventClass(UniversalAutoloadSetHorizontalLoadingEvent, "UniversalAutoloadSetHorizontalLoadingEvent")
-- print("  UniversalAutoload - SetHorizontalLoadingEvent")

function UniversalAutoloadSetHorizontalLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetHorizontalLoadingEvent_mt)
	return self
end

function UniversalAutoloadSetHorizontalLoadingEvent.new(vehicle, state)
	local self = UniversalAutoloadSetHorizontalLoadingEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state
	return self
end

function UniversalAutoloadSetHorizontalLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadSetHorizontalLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.state)
end

function UniversalAutoloadSetHorizontalLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setHorizontalLoading(self.vehicle, self.state, true)
	end
end

function UniversalAutoloadSetHorizontalLoadingEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set state Event")
			g_server:broadcastEvent(UniversalAutoloadSetHorizontalLoadingEvent.new(vehicle, state), nil, nil, object)
		else
			--print("client: Set state Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetHorizontalLoadingEvent.new(vehicle, state))
		end
	end
end