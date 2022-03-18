UniversalAutoloadStopLoadingEvent = {}
local UniversalAutoloadStopLoadingEvent_mt = Class(UniversalAutoloadStopLoadingEvent, Event)
InitEventClass(UniversalAutoloadStopLoadingEvent, "UniversalAutoloadStopLoadingEvent")
-- print("  UniversalAutoload - StopLoadingEvent")

function UniversalAutoloadStopLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStopLoadingEvent_mt)
	return self
end

function UniversalAutoloadStopLoadingEvent.new(vehicle)
	local self = UniversalAutoloadStopLoadingEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadStopLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadStopLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadStopLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.stopLoading(self.vehicle, true)
	end
end

function UniversalAutoloadStopLoadingEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Stop Loading Event")
			g_server:broadcastEvent(UniversalAutoloadStopLoadingEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Stop Loading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStopLoadingEvent.new(vehicle))
		end
	end
end