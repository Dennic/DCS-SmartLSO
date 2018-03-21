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
		offset = {188.67, 58.02},
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
lso.utils.math ={}

function lso.utils.math.dirToAngle(direction, degrees)
	local dir
	if (degrees) then
		dir = direction
	else
		dir = math.deg(direction)
	end
	local diff = 450 - dir
	local angle
	if (dir > 90 and dir < 270) then
		angle = -(360 % diff)
	else
		angle = diff % 360
	end
	if (degrees) then
		return angle
	else
		return math.rad(angle)
	end
end
function lso.utils.math.angleToDir(angle, degrees)
	local agl
	if (degrees) then
		agl = angle
	else
		agl = math.deg(angle)
	end
	local diff = agl - 90
	local dir
	if (diff > 0) then
		dir = 450 - agl
	else
		dir = math.abs(diff)
	end
	if (degrees) then
		return dir
	else
		return math.rad(dir)
	end
end

function lso.utils.math.getOffsetPoint(x, y, dir, dist)
	local angle = math.rad(lso.utils.math.dirToAngle(dir, true))
	local dx = math.cos(angle) * dist
	local dy = math.sin(angle) * dist
	return x + dx, y + dy
end


-- 计算相对方位角
-- 根据给定的坐标，计算出两点的相对方位角
-- xs,ys:基准点坐标
-- xt,yt:目标点坐标
-- degrees:布尔值，是否返回角度（默认返回弧度）
function  lso.utils.math.getAzimuth(xs, ys, xt, yt, degrees)
	local dx = xt - xs
	local dy = yt - ys

	if (dx == 0) then
		return 0
	else
		local deg = lso.utils.math.angleToDir(math.atan(dy/dx))
		if (xt < xs) then
			deg = deg + math.pi
		end
		if (degrees) then
			return math.deg(deg)
		else
			return deg
		end
	end
end

function lso.utils.math.getAzimuthError(a1, a2, degrees)
	local diff
	if (degrees) then
		diff = a1 - a2
	else
		diff = math.deg(a1-a2)
	end
	local angleDiff
	if (diff <= 180) then
		 angleDiff = diff
	else
		angleDiff = diff - 360
	end
	if (degrees) then
		return angleDiff
	else
		return math.rad(angleDiff)
	end
end

-- 计算平均值
-- 计算一组数据的平均值
-- data:数据 table
function lso.utils.math.getAverage(data)
	if (#data == 0) then
		return 0
	end
	local avg = 0	-- 平均值
	for i, v in ipairs(data) do
		avg = avg + v
	end
	avg = avg / #data
	return avg
end

-- 计算方差
-- 计算一组数据的方差
-- data:数据 table
function lso.utils.math.getVariance(data)
	if (#data < 2) then
		return 0
	end
	local avg = lso.utils.math.getAverage(data)
	local sum = 0
	for i, v in ipairs(data) do
		sum = sum + math.pow(v - avg, 2)
	end

	return sum / #data
end

-- 计算矢量合
function lso.utils.math.getMag(...)
	local vec = {...}
	local sum = 0
	if (#vec == 0) then
		return sum
	end
	if (type(vec[1]) == "table") then
		vec = vec[1]
	end
	for i, v in pairs(vec) do
		sum = sum + math.pow(v, 2)
  end
	return math.sqrt(sum)
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
	local carrierHeadding = math.deg(mist.getHeading(lso.carrier.unit, true))
	local dir = (carrierHeadding + lso.carrier.data.offset[1]) % 360
	local x, y = lso.utils.math.getOffsetPoint(carrierPoint.z, carrierPoint.x, dir, lso.carrier.data.offset[2])
	return x, y
end

-- 根据距离和高度，计算出当前所处下滑道角度
-- distance: 距离
-- altitude: 高度
-- 返回值: 下滑道角度
function lso.utils.getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - lso.carrier.data.height)/distance))
end

-- 计算当前进近角相对于当前着陆甲板朝向的角度偏差
-- angle: 当前进近角
-- degrees: 是否返回角度值
-- 返回值: 角度偏差
function lso.utils.getAngleError(angle, degrees)
	local carrierHeadding = math.deg(mist.getHeading(lso.carrier.unit, true))
	local stdAngle = (carrierHeadding - lso.carrier.data.deck) % 360
	local offset = lso.utils.math.getAzimuthError(angle, stdAngle, true)
	if (degrees) then
		return offset
	else
		return math.rad(offset)
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
	return unit:getVelocity().y
end

-- 获取飞机真空速 m/s
function lso.utils.getAirSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	return lso.utils.math.getMag(unit:getVelocity())
end

-- 获取飞机地速 m/s
function lso.utils.getGroundSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	local vel = unit:getVelocity()
	return lso.utils.math.getMag(vel.x, vel.z)
end

lso.approch = {}
lso.approch.tracking = {}

lso.approch.command = {
	HIGH = lso.RadioCommand:new("approch.HIGH", "LSO: You're high!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	LOW = lso.RadioCommand:new("approch.LOW", "LSO: Little power!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	TOO_LOW = lso.RadioCommand:new("approch.TOO_LOW", "LSO: Power!", nil, 2, lso.RadioCommand.Priority.HIGH),
	LEFT = lso.RadioCommand:new("approch.LEFT", "LSO: Right for lineup!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	RIGHT = lso.RadioCommand:new("approch.RIGHT", "LSO: Come left!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	EASY = lso.RadioCommand:new("approch.EASY", "LSO: Easy with it.", nil, 2, lso.RadioCommand.Priority.NORMAL),
	FAST = lso.RadioCommand:new("approch.FAST", "LSO: You're fast!", nil, 2, lso.RadioCommand.Priority.NORMAL),
	SLOW = lso.RadioCommand:new("approch.SLOW", "LSO: You're slow!", nil, 2, lso.RadioCommand.Priority.NORMAL),

	WAVE_OFF = lso.RadioCommand:new("approch.WAVE_OFF", "LSO: Wave off! Wave off! Wave off!", nil, 3, lso.RadioCommand.Priority.IMMEDIATELY),
	BOLTER = lso.RadioCommand:new("approch.BOLTER", "LSO: Bolter! Bolter! Bolter!", nil, 2, lso.RadioCommand.Priority.IMMEDIATELY),
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
		return self:showCommand(unit, cmd)
	else
		return false
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


lso.approch.TrackData = {plane, data, commands, processTime}
function lso.approch.TrackData:new(unit)
		assert(unit ~= nil, "TrackData: unit cannot be nil");
		local obj = {
			plane = unit,
			data = {},
			commands = {},
			processTime = {
				start,middle,close,ramp,
			},
		}
		setmetatable(obj, {__index = self})
		return obj
end
function lso.approch.TrackData:addData(flightData)
		table.insert(self.data, flightData)
end
function lso.approch.TrackData:getData()
	if (#self.data > 0) then
		return self.data[#self.data]
	else
		return nil
	end
end
function lso.approch.TrackData:getDataRecord(dataType, length)
	dataType = string.lower(dataType)
	length = length <= #self.data and length or #self.data
	local data = {}
	for i = #self.data, #self.data - length + 1, -1 do
		if (self.data[i][dataType] ~= nil) then
			table.insert(data, self.data[i][dataType])
		end
	end
	return data
end
function lso.approch.TrackData:addCommand(command, timestamp)
		table.insert(self.commands, {
			command = command,
			timestamp = timestamp or timer.getTime()
		})
end


function lso.approch:track()
	local allPlanes = mist.makeUnitTable({"[all][plane]"})
	local lx, ly = lso.utils.getLandingPoint()
	for i, planeName in ipairs(allPlanes) do
		local plane = Unit.getByName(planeName)
		if (plane and plane:isActive() and plane:isExist() and plane:getPlayerName() ~= nil) then
			local planePoint = plane:getPoint()
			local dist = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
			local angle = lso.utils.math.getAzimuth(planePoint.z, planePoint.x, lx, ly, true)
			local angleError = lso.utils.getAngleError(angle, true)
			local gs = lso.utils.getGlideSlope(dist, planePoint.y)
		 	track = (dist <= 4000 and math.abs(angleError) <= 20 and math.abs(gs - lso.carrier.data.gs) < 2)
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
		local trackCommand = function (cmd, check)
			if (self:setCommand(plane, cmd, check)) then
				trackData:addCommand(cmd, trackTime)
			end
		end
		if (plane and plane:isActive() and plane:isExist() and plane:getPlayerName() ~= nil) then
			local planePoint = plane:getPoint()
			local planeHeading = mist.getHeading(plane, true)
			local lx, ly = lso.utils.getLandingPoint()
			local angle = lso.utils.math.getAzimuth(planePoint.z, planePoint.x, lx, ly, true)
			local angleError = lso.utils.getAngleError(angle, true)
			local dist = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
			local rtg = dist * math.cos(math.rad(angleError))
			local gs = lso.utils.getGlideSlope(dist, planePoint.y)
			local aoa = math.deg(mist.getAoA(plane))
			local speed = lso.utils.getAirSpeed(plane)
			local vs = lso.utils.getVerticalSpeed(plane)

			if (rtg < 20) then
				local previousData = trackData:getData()
				if (previousData and (previousData.speed - speed) > 6) then
					-- 着舰完成
					self.tracking[plane:getName()] = nil
					return nil
				elseif (rtg < -80) then -- bolter
					trackCommand(self.command.BOLTER, true)
					self.tracking[plane:getName()] = nil
					return nil
				end
				return timer.getTime() + 0.01
			end

			local flightData = {
				heading = planeHeading,
				rtg = rtg, -- range to go
				angle = angleError,
				gs = gs,
				aoa = aoa,
				atltitude = planePoint.y,
				speed = speed,
				vs = vs,
				timestamp = trackTime,
			}
			trackData:addData(flightData)

			local vsVariance = lso.utils.math.getVariance(trackData:getDataRecord("vs", 20))
			local gsDiff = gs - lso.carrier.data.gs
			local aoaAvg = lso.utils.math.getAverage(trackData:getDataRecord("aoa", 20))
			local aoaDiff = aoaAvg - aircraft.aoa

		 	local waveOff = (
				math.abs(angleError) * math.min(1, rtg / 60) > 10
				or math.abs(gsDiff) * math.min(1, rtg / 160) > 2
				or (gsDiff < 0 and -gsDiff or 0) > 2
			)
			if (waveOff) then
				trackCommand(self.command.WAVE_OFF, true)
				self.tracking[plane:getName()] = nil
				return nil
			end


			if (trackData.processTime.start == nil and rtg > 800) then
				trackData.processTime.start = trackTime
			elseif (trackData.processTime.middle == nil and rtg <= 800 and rtg > 400) then
				trackData.processTime.middle = trackTime
			elseif (trackData.processTime.close == nil and rtg <= 400 and rtg > 160) then
				trackData.processTime.close = trackTime
			elseif (trackData.processTime.ramp == nil and rtg < 60) then
				trackData.processTime.ramp = trackTime
			end

			local timestamp = string.format("时间 %.3f", trackTime)
			local data = string.format("偏移距 %.3f\n方位角 %.3f", rtg, angle)
			local msg = string.format("标准下滑道 %.3f\n下滑道 %.3f", lso.carrier.data.gs, gs)
			local diff = string.format("偏移角 %.3f\n下滑道偏离 %.3f", angleError, gsDiff)
			local aoa = string.format("攻角 %.3f", aoa)
			local vs = string.format("垂直速度 %.3f\n垂速变化 %.3f", vs, vsVariance or 0)
			local length = string.format("数据数量 %d\n指令数量 %d", #trackData.data, #trackData.commands)
			mist.message.add({
				text = plane:getTypeName() .. "\n".. timestamp .. "\n" .. data .. "\n" .. msg .. "\n" .. diff .. "\n" .. aoa .. "\n" .. vs.. "\n" .. length,
				displayTime = 5,
				msgFor = {units={plane:getName()}},
				name = plane:getName() .. "test",
			})

			trackCommand(self.command.TOO_LOW, (gsDiff < -0.4))
			trackCommand(self.command.LOW, (gsDiff < -0.3 and gsDiff >= -0.6))
			trackCommand(self.command.HIGH, (gsDiff > 0.6))
			trackCommand(self.command.LEFT, (angleError > 1.5))
			trackCommand(self.command.RIGHT, (angleError < -1.5))
			trackCommand(self.command.EASY, (vsVariance > 1))

			trackCommand(self.command.FAST, (aoaDiff < -1.2))
			trackCommand(self.command.SLOW, (aoaDiff > 1.2))

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
