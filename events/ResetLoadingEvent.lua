UniversalAutoloadResetLoadingEvent = {}
local UniversalAutoloadResetLoadingEvent_mt = Class(UniversalAutoloadResetLoadingEvent, Event)
InitEventClass(UniversalAutoloadResetLoadingEvent, "UniversalAutoloadResetLoadingEvent")
-- print("  UniversalAutoload - ResetLoadingEvent")

function UniversalAutoloadResetLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadResetLoadingEvent_mt)
	return self
end

function UniversalAutoloadResetLoadingEvent.new(vehicle)
	local self = UniversalAutoloadResetLoadingEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadResetLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadResetLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadResetLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.resetLoadingState(self.vehicle, true)
	end
end

function UniversalAutoloadResetLoadingEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Reset Loading Event")
			g_server:broadcastEvent(UniversalAutoloadResetLoadingEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Reset Loading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadResetLoadingEvent.new(vehicle))
		end
	end
end