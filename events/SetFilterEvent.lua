UniversalAutoloadSetFilterEvent = {}
local UniversalAutoloadSetFilterEvent_mt = Class(UniversalAutoloadSetFilterEvent, Event)
InitEventClass(UniversalAutoloadSetFilterEvent, "UniversalAutoloadSetFilterEvent")
-- print("  UniversalAutoload - SetFilterEvent")

function UniversalAutoloadSetFilterEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetFilterEvent_mt)
	return self
end

function UniversalAutoloadSetFilterEvent.new(vehicle, state)
	local self = UniversalAutoloadSetFilterEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state
	return self
end

function UniversalAutoloadSetFilterEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadSetFilterEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.state)
end

function UniversalAutoloadSetFilterEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setLoadingFilter(self.vehicle, self.state, true)
	end
end

function UniversalAutoloadSetFilterEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set state Event")
			g_server:broadcastEvent(UniversalAutoloadSetFilterEvent.new(vehicle, state), nil, nil, object)
		else
			--print("client: Set state Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetFilterEvent.new(vehicle, state))
		end
	end
end