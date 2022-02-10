UniversalAutoloadWarningMessageEvent = {}
UniversalAutoloadWarningMessageEvent_mt = Class(UniversalAutoloadWarningMessageEvent, Event)
InitEventClass(UniversalAutoloadWarningMessageEvent, "UniversalAutoloadWarningMessageEvent")
print("  UniversalAutoload - WarningMessageEvent")

function UniversalAutoloadWarningMessageEvent.emptyNew()
	local self = Event.new(UniversalAutoloadWarningMessageEvent_mt)
	return self
end

function UniversalAutoloadWarningMessageEvent.new(vehicle)
	local self = UniversalAutoloadWarningMessageEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadWarningMessageEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadWarningMessageEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadWarningMessageEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:stopUnloading(true)
	end
end

function UniversalAutoloadWarningMessageEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Warning Message Event")
			g_server:broadcastEvent(UniversalAutoloadWarningMessageEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Warning Message Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadWarningMessageEvent.new(vehicle))
		end
	end
end