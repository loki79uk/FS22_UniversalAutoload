UniversalAutoloadStartLoadingEvent = {}
local UniversalAutoloadStartLoadingEvent_mt = Class(UniversalAutoloadStartLoadingEvent, Event)
InitEventClass(UniversalAutoloadStartLoadingEvent, "UniversalAutoloadStartLoadingEvent")
-- print("  UniversalAutoload - StartLoadingEvent")

function UniversalAutoloadStartLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStartLoadingEvent_mt)
	return self
end

function UniversalAutoloadStartLoadingEvent.new(vehicle)
	local self = UniversalAutoloadStartLoadingEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function UniversalAutoloadStartLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function UniversalAutoloadStartLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function UniversalAutoloadStartLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.startLoading(self.vehicle, true)
	end
end

function UniversalAutoloadStartLoadingEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Start Loading Event")
			g_server:broadcastEvent(UniversalAutoloadStartLoadingEvent.new(vehicle), nil, nil, object)
		else
			--print("client: Start Loading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStartLoadingEvent.new(vehicle))
		end
	end
end