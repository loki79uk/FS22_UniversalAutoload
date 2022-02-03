UniversalAutoloadStopUnloadingEvent = {}
UniversalAutoloadStopUnloadingEvent_mt = Class(UniversalAutoloadStopUnloadingEvent, Event)
InitEventClass(UniversalAutoloadStopUnloadingEvent, "UniversalAutoloadStopUnloadingEvent")
print("  UniversalAutoload - StopUnloadingEvent")

function UniversalAutoloadStopUnloadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStopUnloadingEvent_mt)
	return self
end

function UniversalAutoloadStopUnloadingEvent.new(vehicle)
	local self = UniversalAutoloadStopUnloadingEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadStopUnloadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadStopUnloadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadStopUnloadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:stopUnloading(true)
	end
end

function UniversalAutoloadStopUnloadingEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Stop Unloading Event")
			g_server:broadcastEvent(UniversalAutoloadStopUnloadingEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Stop Unloading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStopUnloadingEvent.new(vehicle))
		end
	end
end