-- 创建枚举表
function Enum(...)
	local enum = {}
	local index = 0
	for i, v in ipairs({...}) do
        enum[v] = index + i
    end
	return enum
end

local lso = {}
lso.logger = mist.Logger:new("LSO", "info")

-- 航母 unit name
lso.carrierName = "ship"


lso.frameId = 1
lso.checkFrames = {}
function lso.addCheckFrame(frame)
	assert(type(frame) == "table", "argument expected table, got " .. type(frame))
	assert(frame.onFrame ~= nil and type(frame.onFrame) == "function", "didn't implement function 'onFrame'")
	local id = lso.frameId
	table.insert(lso.checkFrames, {frame = frame, id = id})
	lso.frameId = lso.frameId + 1
	return id
end
function lso.removeCheckFrame(id)
	for k, v in pairs(lso.checkFrames) do
		if (v.id == id) then
			lso.checkFrames[k] = nil
		end
	end
end

function lso.doFrame(arg, frameTime)
	local i = 1
	while i <= #lso.checkFrames do
		if lso.checkFrames[i] ~= nil then
			lso.checkFrames[i].frame:onFrame()
		end
		i = i + 1
	end
	return timer.getTime() + 2
end

timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)

function lso.init()
	local carrier = {}
	local unit = Unit.getByName(lso.carrierName)
	local typeName = unit:getTypeName()
	for name, data in pairs(lso.data.carriers) do
		if (name == typeName) then
			carrier.data = data
			carrier.unit = unit
			break
		end
	end
	assert(carrier.unit, "Carrier not ready.")
	lso.carrier = carrier
end

lso.RadioCommand = {id, tag, msg, sound, duration, priority}
lso.RadioCommand.count = 0
lso.RadioCommand.Priority = Enum(
	"LOW",
	"NORMAL",
	"HIGH",
	"IMMEDIATELY"
)
function lso.RadioCommand:new(tag, msg, sound, duration, priority)
	assert(msg ~= nil, "RadioCommand: msg cannot be nil");
	self.count = self.count + 1
	local obj = {
		id = self.count,
		tag = tag or ("RadioCommand"..self.count),
		msg = msg,
		sound = sound,
		duration = duration or 1,
		priority = priority or lso.RadioCommand.Priority.NORMAL,
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __tostring = self.toString})
	return obj
end
function lso.RadioCommand.equalTo(self, another)
	local selfObj, anotherObj
	if (type(self) == "table") then
		selfObj = self.tag
	else
		selfObj = self
	end
	if (type(another) == "table") then
		anotherObj = another.tag
	else
		anotherObj = another
	end
	return selfObj == anotherObj
end
function lso.RadioCommand.toString(self)
	return self.tag
end
function lso.RadioCommand:send(name, msgFor)
	local messageID =  mist.message.add({
		text = self.msg,
		displayTime = self.duration,
		msgFor = msgFor,
		name = name
	})
	self.messageID = messageID
	return messageID
end
function lso.RadioCommand:remove()
	if (self.messageID) then
		return mist.message.removeById(self.messageID)
	else
		return false
	end
end
function lso.RadioCommand.removeById(id)
	return mist.message.removeById(id)
end

lso.data = {}
lso.data.carriers = {
	["KUZNECOW"] = {
		offset = {58, 14.5},
		height = 18.5,
		deck = 8,
		gs = 4,
	}
}
lso.data.aircrafts = {
	["Su-33"] = {
		aoa = 9,
	}
}
function lso.data.getAircraft(unit)
	local typeName = unit:getTypeName()
	for name, data in pairs(lso.data.aircrafts) do
		if (name == typeName) then
			return data
		end
	end
	return nil
end

lso.utils = {}
lso.utils.math = {}

-- 计算斜率
-- 根据给定的航向，计算出航线斜率
-- r:当前航向(弧度)
function lso.utils.math.getK(r)
	local deg = 90 - math.deg(r) % 360
	local k = tonumber(string.format("%.3f",math.tan(math.rad(deg))))
	return k
end

-- 计算x,y偏移量
-- 根据给定的偏移距离和航向，计算出向反朝向偏移所需移动的x,y偏移量
-- l:偏移距离
-- d:当前航向(弧度)
function lso.utils.math.getOffset(l, d)
	local k = lso.utils.math.getK(d)
	local dx = l / math.sqrt(math.pow(k, 2) + 1)
	local dy = l * k / math.sqrt(math.pow(k, 2) + 1)
	if (d % (math.pi * 2) > math.pi) then
		return dx, dy
	else
		return -dx, -dy
	end
end

-- 计算偏移点坐标
-- 根据给定的偏移距离和航向，计算出向反朝向偏移后的点坐标
-- x,y:基准点坐标
-- h:当前朝向(弧度)
-- l:偏移距离
function lso.utils.math.getOffsetPoint(x, y, h, l)
	local dx, dy = lso.utils.math.getOffset(l, h)
	return x+dx, y+dy
end

-- 计算相对方位角
-- 根据给定的坐标，计算出两点的相对方位角
-- xs,ys:基准点坐标
-- xt,yt:目标点坐标
-- degrees:布尔值，是否返回角度（默认返回弧度）
function  lso.utils.math.getBearing(xs, ys, xt, yt, degrees)
	local dx = xt - xs
	local dy = yt - ys

	if (dx == 0) then
		return 0
	else
		local deg = 90 - math.deg(math.atan(dy/dx))
		if (xt < xs) then
			deg = deg + 180
		end
		if (type(degrees) == "boolean" and degrees) then
			return deg
		else
			return math.rad(deg)
		end
	end
end

-- 计算劣角
-- 根据给定两个角度，计算劣角
-- a1,a2:两个给定角度
-- degrees:布尔值，参数和返回值是否为角度（默认为弧度）
function lso.utils.math.getInferiorAngle(a1, a2, degrees)
	local da = math.abs(a2 - a1)
	local ia = 0
	if (type(degrees) == "boolean" and degrees) then
		if (da > 180) then
			da = 360 - da
		end
	else
		if (da > math.pi) then
			da = 2 * math.pi - da
		end
	end
	if (a2 > a1) then
		return da
	else
		return -da
	end
end

-- 计算方差
-- 计算一组数据的方差
-- data:数据 table
function lso.utils.math.getVariance(data)
	if (#data < 2) then
		return 0
	end
	local avg = 0	-- 平均值
	for i, v in ipairs(data) do
		avg = avg + v
	end
	avg = avg / #data

	local sum = 0
	for i, v in ipairs(data) do
		sum = sum + math.pow(v - avg, 2)
	end

	return sum / #data
end


function lso.utils.tableSize(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

function lso.utils.listContains(t, v)
	for key, val in ipairs(t) do
		if (val == v) then
			return true, key
		end
	end
	return false, -1
end

function lso.utils.listRemove(t, v)
	local contains, key = lso.utils.listContains(t, v)
	if (contains) then
		table.remove(t, key)
		return true
	else
		return false
	end
end

-- 计算当前航母的接地点坐标
-- 返回值 bx, by: 接地点 vec2 坐标
function  lso.utils.getLandingPoint()
	local carrierPoint = lso.carrier.unit:getPoint()
	local carrierHeadding = mist.getHeading(lso.carrier.unit, true)
	local cx, cy = lso.utils.math.getOffsetPoint(carrierPoint.z, carrierPoint.x, carrierHeadding, lso.carrier.data.offset[1])
	local bx, by = lso.utils.math.getOffsetPoint(cx, cy ,carrierHeadding + math.pi * 0.5, lso.carrier.data.offset[2])
	return bx, by
end

-- 根据距离和高度，计算出当前所处下滑道角度
-- distance: 距离
-- altitude: 高度
-- 返回值: 下滑道角度
function lso.utils.getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - lso.carrier.data.height)/distance))
end

-- 计算当前航向相对于当前着陆甲板朝向的角度偏差
-- bearing: 当前航向
-- degrees: 是否返回角度值
-- 返回值: 角度偏差
function lso.utils.getAngleOffset(bearing, degrees)
	local carrierHeadding = mist.getHeading(lso.carrier.unit, true)
	local stdAngle = (carrierHeadding - math.rad(lso.carrier.data.deck) + math.pi) % (math.pi * 2)
	local offset = lso.utils.math.getInferiorAngle(stdAngle, bearing)
	if (type(degrees) == "boolean" and degrees) then
		return math.deg(offset)
	else
		return offset
	end
end

-- 计算两点欧氏距离
function lso.utils.getDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

-- 获取飞机垂直速度 m/s
function lso.utils.getVerticalSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	local unitVel = unit:getVelocity()
	return unitVel.y
end


lso.approch = {}
lso.approch.radio = {}
lso.approch.tracking = {}

lso.approch.TrackData = {plane, data}
function lso.approch.TrackData:new(unit)
		assert(unit ~= nil, "TrackData: unit cannot be nil");
		local obj = {
			plane = unit,
			data = {},
		}
		setmetatable(obj, {__index = self})
		return obj
end
function lso.approch.TrackData:addData(flightData)
		table.insert(self.data, 1, flightData)
		if (#self.data > 20) then -- 只记录最近20条飞行数据，即 20 * 0.1 = 2秒内数据
			table.remove(self.data, #self.data)
		end
end
function lso.approch.TrackData:getData()
	if (#self.data > 0) then
		return self.data[1]
	else
		return nil
	end
end
function lso.approch.TrackData:getDataRecord(dataType)
	dataType = string.lower(dataType)
	local data = {}
	for k, v in ipairs(self.data) do
		if (v[dataType] ~= nil) then
			table.insert(data, v[dataType])
		end
	end
	return data
end

lso.approch.command = {
	HIGH = lso.RadioCommand:new("approch.HIGH", "LSO: You're high!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	LOW = lso.RadioCommand:new("approch.LOW", "LSO: Little power!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	TOO_LOW = lso.RadioCommand:new("approch.TOO_LOW", "LSO: Power!", nil, 2, lso.RadioCommand.Priority.HIGH),
	LEFT = lso.RadioCommand:new("approch.LEFT", "LSO: Right for lineup!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	RIGHT = lso.RadioCommand:new("approch.RIGHT", "LSO: Come left!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	EASY = lso.RadioCommand:new("approch.EASY", "LSO: Easy with it.", nil, 2, lso.RadioCommand.Priority.NORMAL),
	FAST = lso.RadioCommand:new("approch.FAST", "LSO: You're fast!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	SLOW = lso.RadioCommand:new("approch.SLOW", "LSO: You're slow!", nil, 2, lso.RadioCommand.Priority.NORMAL),
}

lso.approch.commands = {}
function lso.approch:showCommand(unit, cmd)
	local unitName = unit:getName()
	local commandData = self.commands[unitName] or {}
	local nowTime = timer.getTime()
	if (commandData.currentCommand and commandData.sendTime) then
		local prior = cmd.priority > commandData.currentCommand.priority
		local endTime = commandData.sendTime + commandData.currentCommand.duration
		if (prior or nowTime >= endTime) then
			local cd = commandData.coolDown or {}
			cd[commandData.currentCommand.tag] = {
				command = commandData.currentCommand,
				coolTime = endTime + 2
			}
			commandData.coolDown = cd
			commandData.message = nil
			commandData.sendTime = nil
			commandData.currentCommand = nil
			self.commands[unitName] = commandData
		else
			return false
		end
	end

	local cooling = false
	if (commandData.coolDown) then
		for tag, cdItem in pairs(commandData.coolDown) do
			if (nowTime >= cdItem.coolTime) then
				commandData.coolDown[tag] = nil
			else
				if (cdItem.command == cmd) then
					cooling = true
				end
			end
		end
	end
	self.commands[unitName] = commandData

	if (cooling and cmd.priority ~= lso.RadioCommand.Priority.IMMEDIATELY) then
		return false
	else
		commandData.currentCommand = cmd
		commandData.sendTime = nowTime
		commandData.message = cmd:send(unitName .. "approch", {units={unitName}})
		self.commands[unitName] = commandData
		return true
	end
end
function lso.approch:dismissCommand(unit, cmd)
	local unitName = unit:getName()
	local commandData = self.commands[unitName] or {}
	local nowTime = timer.getTime()
	cmd:remove()
	if (commandData.currentCommand and commandData.sendTime and commandData.currentCommand == cmd) then
		local endTime = commandData.sendTime + commandData.currentCommand.duration
		local cd = commandData.coolDown or {}
		cd[commandData.currentCommand.tag] = {
			command = commandData.currentCommand,
			coolTime = endTime + 2
		}
		commandData.coolDown = cd
		commandData.message = nil
		commandData.sendTime = nil
		commandData.currentCommand = nil
		self.commands[unitName] = commandData
	end
end
function lso.approch:setCommand(unit, cmd, set)
	if (set) then
		self:showCommand(unit, cmd)
	end
end
function lso.approch:clearCommand(unit)
	local unitName
	if (type(unit) == "string") then
		unitName = unit
	else
		unitName = unit:getName()
	end
	self.commands[unitName] = nil
end

function lso.approch:track()
	local allPlanes = mist.makeUnitTable({"[all][plane]"})
	local lx, ly = lso.utils.getLandingPoint()
	for i, planeName in ipairs(allPlanes) do
		local plane = Unit.getByName(planeName)
		if (plane and plane:isActive() and plane:isExist() and plane:getPlayerName() ~= nil) then
			local planePoint = plane:getPoint()
			local range = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
			local bearing = lso.utils.math.getBearing(lx, ly, planePoint.z, planePoint.x)
			local angleOffset = lso.utils.getAngleOffset(bearing, true)
			local gs = lso.utils.getGlideSlope(range, planePoint.y)
		 	track = (range <= 4000 and math.abs(angleOffset) <= 20 and math.abs(gs - lso.carrier.data.gs) < 2)
			if (track) then
				self:check(plane)
			end
		end
	end
	-- mist.message.add({
	-- 	text =  "检测中",
	-- 	displayTime = 1,
	-- 	msgFor = {coa = {"all"}},
	-- 	name = "tracking",
	-- })
end

function lso.approch:check(unit)

	if (self.tracking[unit:getName()]) then
		return false
	end

	local aircraft = lso.data.getAircraft(unit)
	local trackData = self.TrackData:new(unit)
	local trackFrame = function(args, trackTime)
		local plane = trackData.plane
		if (plane and plane:isActive() and plane:isExist() and plane:getPlayerName() ~= nil) then
			local planePoint = plane:getPoint()
			local lx, ly = lso.utils.getLandingPoint()
			local range = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
			local bearing = lso.utils.math.getBearing(lx, ly, planePoint.z, planePoint.x)
			local angleOffset = lso.utils.getAngleOffset(bearing, true)
			local gs = lso.utils.getGlideSlope(range, planePoint.y)
			local aoa = math.deg(mist.getAoA(plane))
			local vs = lso.utils.getVerticalSpeed(plane)
			local flightData = {
				range = range,
				bearing = bearing,
				angle = angleOffset,
				gs = gs,
				aoa = aoa,
				atltitude = planePoint.y,
				vs = vs,
			}
		 	waveOff = (math.abs(angleOffset) > 20 and math.abs(gs - lso.carrier.data.gs) > 2)
			if (not waveOff) then
				trackData:addData(flightData)
			else
				self:clearCommand(plane)
				self.tracking[plane:getName()] = nil
				return nil
			end

			local vsVariance = lso.utils.math.getVariance(trackData:getDataRecord("vs"))
			local gsDiff = gs - lso.carrier.data.gs
			local aoaDiff = aoa - aircraft.aoa

			-- local data = string.format("偏移距 %.3f\n方位角 %.3f", range, math.deg(bearing))
			-- local msg = string.format("标准下滑道 %.3f\n下滑道 %.3f", lso.carrier.data.gs, gs)
			-- local diff = string.format("偏移角 %.3f\n下滑道偏离 %.3f", angleOffset, gsDiff)
			-- local aoa = string.format("攻角 %.3f", aoa)
			-- local vs = string.format("垂直速度 %.3f\n垂速变化 %.3f", vs, vsVariance or 0)
			-- mist.message.add({
			-- 	text = plane:getTypeName() .. "\n" .. data .. "\n" .. msg .. "\n" .. diff .. "\n" .. aoa .. "\n" .. vs,
			-- 	displayTime = 5,
			-- 	msgFor = {units={plane:getName()}},
			-- 	name = plane:getName() .. "test",
			-- })

			self:setCommand(plane, self.command.TOO_LOW, (gsDiff < -0.4))
			self:setCommand(plane, self.command.LOW, (gsDiff < -0.3 and gsDiff >= -0.6))
			self:setCommand(plane, self.command.HIGH, (gsDiff > 0.6))
			self:setCommand(plane, self.command.LEFT, (angleOffset > 1.5))
			self:setCommand(plane, self.command.RIGHT, (angleOffset < -1.5))
			self:setCommand(plane, self.command.EASY, (vsVariance > 1))

			self:setCommand(plane, self.command.FAST, (aoaDiff < -1.2))
			self:setCommand(plane, self.command.SLOW, (aoaDiff > 1.2))

			return timer.getTime() + 0.1
		else
			self.tracking[plane:getName()] = nil
			return nil
		end
	end

	local id = timer.scheduleFunction(trackFrame, nil, timer.getTime() + 2)
	self.tracking[unit:getName()] = id
	return true
end

function lso.approch:onFrame()
	self:track()
end

lso.init()
lso.approch.id = lso.addCheckFrame(lso.approch)
