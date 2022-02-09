UniversalAutoloadUnloadingBlockedEvent = {}
UniversalAutoloadUnloadingBlockedEvent_mt = Class(UniversalAutoloadUnloadingBlockedEvent, Event)
InitEventClass(UniversalAutoloadUnloadingBlockedEvent, "UniversalAutoloadUnloadingBlockedEvent")
print("  UniversalAutoload - UnloadingBlockedEvent")

function UniversalAutoloadUnloadingBlockedEvent.emptyNew()
	local self = Event.new(UniversalAutoloadUnloadingBlockedEvent_mt)
	return self
end

function UniversalAutoloadUnloadingBlockedEvent.new(vehicle)
	local self = UniversalAutoloadUnloadingBlockedEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadUnloadingBlockedEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadUnloadingBlockedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadUnloadingBlockedEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:stopUnloading(true)
	end
end

function UniversalAutoloadUnloadingBlockedEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Unloading Blocked Event")
			g_server:broadcastEvent(UniversalAutoloadUnloadingBlockedEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Unloading Blocked Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadUnloadingBlockedEvent.new(vehicle))
		end
	end
end