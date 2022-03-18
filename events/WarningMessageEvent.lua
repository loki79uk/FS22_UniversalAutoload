UniversalAutoloadWarningMessageEvent = {}
local UniversalAutoloadWarningMessageEvent_mt = Class(UniversalAutoloadWarningMessageEvent, Event)
InitEventClass(UniversalAutoloadWarningMessageEvent, "UniversalAutoloadWarningMessageEvent")
-- print("  UniversalAutoload - WarningMessageEvent")

function UniversalAutoloadWarningMessageEvent.emptyNew()
	local self = Event.new(UniversalAutoloadWarningMessageEvent_mt)
	return self
end

function UniversalAutoloadWarningMessageEvent.new(vehicle, messageId)
	local self = UniversalAutoloadWarningMessageEvent.emptyNew()
	self.vehicle = vehicle
	self.messageId = messageId
	return self
end

function UniversalAutoloadWarningMessageEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.messageId = streamReadInt32(streamId)
	self:run(connection)
end

function UniversalAutoloadWarningMessageEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteInt32(streamId, self.messageId)
end

function UniversalAutoloadWarningMessageEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.showWarningMessage(self.vehicle, self.messageId, true)
	end
end

function UniversalAutoloadWarningMessageEvent.sendEvent(vehicle, messageId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Warning Message Event")
			g_server:broadcastEvent(UniversalAutoloadWarningMessageEvent.new(vehicle, messageId), nil, nil, object)
		else
			--print("client: Warning Message Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadWarningMessageEvent.new(vehicle, messageId))
		end
	end
end