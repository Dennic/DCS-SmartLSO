-- 创建枚举表
function Enum(...)
	local items = {...}
	if (#items == 1 and type(items[1]) == "table") then
		items = items[1]
	end
	local enum = {}
	local index = 0
	for i, v in ipairs(items) do
        enum[v] = index + i
    end
	return enum
end

lso = {}

lso.debug = true
-- 航母单位名称
lso.carrierName = "Mother"
-- 使用真实无线电频率
lso.useRadioFrequency = true
-- 航母无线电单位名称
lso.carrierRadioName = "Mother Radio"
-- 航母自动航行
lso.carrierSailing = true
-- 航母航行区域名称
lso.carrierSailArea = "Sail Area"
-- 航母航行速度（节）
lso.carrierSpeed = 25


-- 音频库
lso.Sound = {
	LSO = {
		PADDLES_CONTACT = "l10n/DEFAULT/paddles_contact.ogg", 
		KEEP_TURN = "l10n/DEFAULT/keep_your_turn_in.ogg", 
		CALL_THE_BALL = "l10n/DEFAULT/call_the_ball.ogg", 
		ROGER_BALL = "l10n/DEFAULT/roger_ball.ogg", 
		BOLTER = "l10n/DEFAULT/bolter.ogg", 
		WAVEOFF = "l10n/DEFAULT/waveoff.ogg", 
		EASY = "l10n/DEFAULT/easy_with_it.ogg", 
		LEFT = "l10n/DEFAULT/come_left.ogg", 
		RIGHT = "l10n/DEFAULT/right_for_lineup.ogg", 
		HIGH = "l10n/DEFAULT/youre_high.ogg", 
		LOW = "l10n/DEFAULT/little_power.ogg", 
		TOO_LOW = "l10n/DEFAULT/power.ogg", 
		FAST = "l10n/DEFAULT/youre_fast.ogg", 
		SLOW = "l10n/DEFAULT/youre_slow.ogg", 
		CENTER = "l10n/DEFAULT/youre_on_centerline.ogg", 
	}
}


-- 数据库模块
-- 包含了所需的固定数据
lso.data = {}
lso.data.carriers = {
	["VINSON"] = {
		offset = {180.9, 95.2},
		height = 20,
		deck = 10,
		gs = 3.5,
	},
	["Stennis"] = {
		offset = {181.4, 92.6},
		height = 20,
		deck = 10,
		gs = 3.5,
	},
	["KUZNECOW"] = {
		offset = {188.67, 58.02},
		height = 18,
		deck = 8,
		gs = 4,
	},
}
lso.data.aircrafts = {
	["FA-18C_hornet"] = {
		name = "hornet",
		aoa = 8,
	},
	["Su-33"] = {
		name = "falcon",
		aoa = 9,
	},
}
lso.data.coalitions = {
	[0] = "neutrals",
	[1] = "red",
	[2] = "blue",
}
function lso.data.getAircraft(unit)
	if (unit) then
		local typeName = unit:getTypeName()
		for name, data in pairs(lso.data.aircrafts) do
			if (name == typeName) then
				return data
			end
		end
	end
	return nil
end


function lso.log(msg, duration, useMist, name)
	if lso.debug == true then
		if useMist then
			mist.message.add({
				text =  msg,
				displayTime = duration,
				msgFor = {coa = {"all"}},
				name = name,
			})
		else
			trigger.action.outText(msg, duration)
		end
	end
end


-- 检测帧实现模块
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
			local status, err = pcall(function(frame)
				frame:onFrame(frameTime)
				return true
			end, lso.checkFrames[i].frame)
			if (not status) then
				error(err)
			end
		end
		i = i + 1
	end
	return timer.getTime() + 2
end
timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)


-- 事件广播模块
lso.Broadcast = {}
lso.Broadcast.count = 0
lso.Broadcast.event = Enum(
	"TURNING_START",
	"TURNING_STOP",
	"RECOVERY_START",
	"RECOVERY_STOP"
)
lso.Broadcast.listeners = {}
lso.Broadcast.queue = {}
function lso.Broadcast:send(event, data, timestamp)
	if event then
		if not timestamp then
			timestamp = timer.getTime()
		end
		table.insert(self.queue, {
			event = event,
			data = data,
			timestamp = timestamp
		})
	end
end
function lso.Broadcast:remove(funcOrId)
	local removed = false
	if funcOrId then
		if (type(funcOrId) == "number") then
			for e, listeners in pairs(self.listeners) do
				for i, listener in ipairs(listeners) do
					if listener.id == funcOrId then
						table.remove(listeners, i)
						removed = true
					end
				end
			end
		else
			for e, listeners in pairs(self.listeners) do
				for i, listener in ipairs(listeners) do
					if listener.callback == funcOrId then
						table.remove(listeners, i)
						removed = true
					end
				end
			end
		end
	end
	return removed
end
function lso.Broadcast:receive(events, func)
	if (events or (type(events) == "table" and #events > 0)) and (type(func) == "function") then
		self.count = self.count + 1
		local listenerId = self.count
		if (type(events) == "number") then
			events = {events}
		end
		for i, event in ipairs(events) do
			if self.listeners[event] == nil then
				self.listeners[event] = {}
			end
			table.insert(self.listeners[event], {
				id = listenerId,
				callback = func
			})
		end
		return listenerId
	end
end
function lso.Broadcast.loop(args, timestamp)
	while #lso.Broadcast.queue > 0 do
		local item = table.remove(lso.Broadcast.queue, 1)
		for i, listener in ipairs(lso.Broadcast.listeners[item.event] or {}) do
			listener.callback(item.event, item.data, item.timestamp)
		end
	end
	return timer.getTime() + 0.005
end
timer.scheduleFunction(lso.Broadcast.loop, nil, timer.getTime() + 1)



-- 数据库模块
lso.DB = {}
-- 飞机集合
lso.DB.planes = {}
function lso.DB.init()
	local coalition = lso.data.coalitions[lso.Carrier.unit:getCoalition()]
	for coaName, coaData in pairs(env.mission.coalition) do
		if (coaName == coalition) then
			if (coaData.country) then
				for countryID, countryData in pairs(coaData.country) do
					for categoryName, categoryData in pairs(countryData) do
						if (categoryName == "ship") then
							if (categoryData.group and type(categoryData.group) == 'table' and #categoryData.group > 0) then
								for groupID, groupData in pairs(categoryData.group) do
									if (groupData.units and type(groupData.units) == 'table' and #groupData.units > 0) then
										for unitID, unitData in pairs(groupData.units) do
											local unitName
											if env.mission.version > 7 then
												unitName = env.getValueDictByKey(unitData.name)
											else
												unitName = unitData.name
											end
											if (unitName == lso.Carrier.unit:getName()) then
												lso.Carrier:loadTasks(groupData)
											end
										end
									end
								end
							end
						elseif (categoryName == "plane") then
							if (categoryData.group and type(categoryData.group) == 'table' and #categoryData.group > 0) then
								for groupID, groupData in pairs(categoryData.group) do
									if (groupData.units and type(groupData.units) == 'table' and #groupData.units > 0) then
										for unitID, unitData in pairs(groupData.units) do
											if (unitData.skill == "Player" or unitData.skill == "Client") then
												if (lso.data.aircrafts[unitData.type]) then
													local unitName
													if env.mission.version > 7 then
														unitName = env.getValueDictByKey(unitData.name)
													else
														unitName = unitData.name
													end
													local aircraftData = lso.data.aircrafts[unitData.type]
													local onboardNumber = unitData.onboard_num
													local plane = lso.Plane:new(unitName, aircraftData, onboardNumber)
													if (plane) then
														lso.DB.planes[unitName] = plane
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


-- 航母模块
lso.Carrier = {
	recovery = false, -- 是否正在回收作业
	case = 1, -- 回收作业 Case 1-3
	unit, -- 航母单位
	radio, -- 航母无线电单位
	data, -- 航母信息
	initPoint, -- 航母初始位置 vec2
	nextPoint, -- 最后一个路径点 vec2
	lastHeadding, -- 最近一次记录的航向
	needToTurn = false, -- 是否需要转向
	turning = false,
	turningTime = 0,
	pointCount = 0,
	inProcess = {}, -- 等待回收中的飞机
	recoveryStop, -- 结束回收计划
	backToCruise = false, -- 正在返回巡航区域
}
function lso.Carrier:addPlane(plane)
	local recoveryStarted = false
	if not (lso.utils.listContains(self.inProcess, plane)) then
		plane.case = self.case
		table.insert(self.inProcess, plane)
		if (self.recovery == false and self.backToCruise == false) then
			local eat = lso.Carrier:getEAT()
			if (eat and (eat - timer.getTime() > 15 * 60)) then
				self:addRoute(true)
				recoveryStarted = true
			end
		end
		if (self.recoveryStop ~= nil) then
			timer.removeFunction(self.recoveryStop)
			self.recoveryStop = nil
		end
		return true, recoveryStarted
	else
		return false, recoveryStarted
	end
end
function lso.Carrier:removePlane(plane)
	if (lso.utils.listContains(self.inProcess, plane)) then
		lso.utils.listRemove(self.inProcess, plane)
		if (#self.inProcess == 0) then
			local stopRecovery = function(args, timestamp)
				if (self.recovery == true) then
					self:addRoute(true)
					self.recovery = false
					lso.Broadcast:send(lso.Broadcast.event.RECOVERY_STOP)
				end
			end
			-- 3分钟内没有新飞机加入回收队列则结束回收作业
			recoveryStop = timer.scheduleFunction(stopRecovery, nil, timer.getTime() + 180)
		end
		return true
	else
		return false
	end
end
function lso.Carrier:init()
	local unit = Unit.getByName(lso.carrierName)
	local radio = Unit.getByName(lso.useRadioFrequency and lso.carrierRadioName or lso.carrierName)
	if (
		unit ~= nil and radio ~= nil
		and unit:isExist() and radio:isExist()
	) then
		self.unit = unit
		self.radio = radio
		self.initPoint = {x=unit:getPoint().x, y=unit:getPoint().z}
		self.nextPoint = {x=unit:getPoint().x, y=unit:getPoint().z}
		local typeName = unit:getTypeName()
		for name, data in pairs(lso.data.carriers) do
			if (name == typeName) then
				self.data = data
				break
			end
		end
		if (self.data ~= nil) then
			return true
		end
	end
	return false
end
function lso.Carrier:loadTasks(groupData)
	if (lso.carrierSailing) then
		local group = self.unit:getGroup()
		if group then
			local groupCon = group:getController()
			if groupCon then
				local route = groupData.route
				if (#route.points > 1) then
					route.points = {route.points[1]}
				end
				local tasks = groupData.tasks
				groupCon:setTask({
					id = 'Mission',
					params = {
						route = route
					},
				})
				for i, task in pairs(tasks) do
					if (task.id == "WrappedAction") then
						local action = task.params.action
						if (action.id == "Option") then
							groupCon:setOption(action.params.name, action.params.value)
						else
							groupCon:setCommand(action)
						end
					end
				end
			end
		end
		self.needToTurn = true
	end
end
function lso.Carrier:addRoute(clearAll)
	local nowPoint = self.unit:getPoint()
	local nextPoint = nil
	local zone = trigger.misc.getZone(lso.carrierSailArea)
	local center, radius
	if type(zone) == "table" then
		center = zone.point
		radius = zone.radius
	else
		center = self.initPoint
		radius = lso.Converter.NM_M(10)
	end
	self.backToCruise = false
	if (#self.inProcess > 0 and self.recovery == false) then
		local dir, speed = lso.utils.getWindInfo(nowPoint, self.data.height + 20) -- 甲板上方 20 米风
		for dist = 20, 1, -1 do
			local x, y = lso.math.getOffsetPoint(nowPoint.x, nowPoint.z, math.deg(dir), lso.Converter.NM_M(dist))
			local point = {x=x, y=y}
			if not (lso.utils.checkLand(point, {x=nowPoint.x, y=nowPoint.z})) then
				nextPoint = point
				self.recovery = true
				lso.Broadcast:send(lso.Broadcast.event.RECOVERY_START)
				break
			end
		end
	else
		if (self.recovery == true) then
			self.recovery = false
			self.backToCruise = true
			lso.Broadcast:send(lso.Broadcast.event.RECOVERY_STOP)
		end
	end
	
	-- 在航行区域内随机选择下一个路径点
	if (nextPoint == nil) then
		local tried = 0
		repeat
			if (tried > 1000) then
				return false
			end
			local point = lso.utils.getRandPointInCircle(center, radius)
			local dist = lso.utils.getDistance(point.x, point.y, nowPoint.x, nowPoint.z)
			if (dist > radius * math.max(0.3, math.min(6000 / radius, 0.8))) then
				if not (lso.utils.checkLand(point, {x=nowPoint.x, y=nowPoint.z})) then
					nextPoint = point
				end
			end
			tried = tried + 1
		until (nextPoint ~= nil)
	end
	
	local waypoint = {}
	waypoint.x = nextPoint.x
	waypoint.y = nextPoint.y
	waypoint.x = nextPoint.x
	waypoint.alt = 0
	waypoint.type = "Turning Point"
	waypoint.speed = lso.Converter.KNOT_MS(lso.carrierSpeed)
    waypoint.action = "Turning Point"
	waypoint.task = {
		id = 'WrappedAction',
		params = {
			action = {
				id = 'Script',
				params = {
					command = "lso.Carrier:reachPoint()",
				},
			},
		},
	}
	
	local misTask = {
		id = 'Mission',
		params = {
			route = {
				points = {waypoint},
			},
		},
	}
	
	local group = self.unit:getGroup()
	if group then
		local groupCon = group:getController()
		if groupCon then
			if (clearAll) then
				groupCon:setTask(misTask)
			else
				groupCon:pushTask(misTask)
			end
		end
	end
	
	self.nextPoint = nextPoint
	self.pointCount = self.pointCount + 1
	trigger.action.markToAll(self.pointCount, string.format("%d", self.pointCount), {x=self.nextPoint.x, y=0, z=self.nextPoint.y})
	return true
end
function lso.Carrier:reachPoint()
	self.needToTurn = true
end
function lso.Carrier:getRecoveryCase()
	if (self.case == 1) then
		return "Case I"
	elseif (self.case == 2) then
		return "Case II"
	elseif (self.case == 3) then
		return "Case III"
	else
		return ""
	end
end
-- 获取到达下一路径点的预计时间
function lso.Carrier:getEAT()
	local speed = lso.Carrier:getSpeed(self.unit)
	if speed > 0 then
		local point = self.unit:getPoint()
		local dist = lso.utils.getDistance(point.x, point.z, self.nextPoint.x, self.nextPoint.y)
		local timeInSec = dist / speed
		return timer.getTime() + timeInSec
	end
end
function lso.Carrier:getBRC(current)
	if (current) then
		return lso.Carrier:getHeadding(true) or 0
	else
		local cPoint = self.unit:getPoint()
		local nextBRC = lso.math.round(lso.math.getAzimuth(cPoint.z, cPoint.x, lso.Carrier.nextPoint.y, lso.Carrier.nextPoint.x, true))
		return nextBRC
	end
end
function lso.Carrier:getTemperatureAndPressure()
	local point = self.unit:getPoint()
	point.y = 0
	local temperature, pressure = atmosphere.getTemperatureAndPressure(point)
	return lso.Converter.K_C(temperature), lso.Converter.PA_INHG(pressure)
end
-- 计算当前航母的接地点坐标
-- 返回值 bx, by: 接地点 vec2 坐标
function  lso.Carrier:getLandingPoint()
	local carrierPoint = self.unit:getPoint()
	local carrierHeadding = lso.Carrier:getHeadding(true)
	local dir = (carrierHeadding + self.data.offset[1]) % 360
	local x, y = lso.math.getOffsetPoint(carrierPoint.z, carrierPoint.x, dir, lso.Carrier.data.offset[2])
	return x, y
end
-- 根据距离和高度，计算出当前所处下滑道角度
-- distance: 距离
-- altitude: 高度
-- 返回值: 下滑道角度
function lso.Carrier:getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - self.data.height)/distance))
end
-- 获取航母航向
-- degrees: 是否返回角度值
-- 返回值: 航母航向
function lso.Carrier:getHeadding(degrees)
	return math.deg(lso.utils.getHeading(self.unit, degrees) or 0)
end
-- 计算当前进近角相对于当前着陆甲板朝向的角度偏差
-- angle: 当前进近角
-- degrees: 是否返回角度值
-- 返回值: 角度偏差
function lso.Carrier:getAngleError(angle, degrees)
	local carrierHeadding = lso.Carrier:getHeadding(true)
	local stdAngle = (carrierHeadding - self.data.deck) % 360
	local offset = lso.math.getAzimuthError(angle, stdAngle, true)
	if (degrees) then
		return offset
	else
		return math.rad(offset)
	end
end
function lso.Carrier:getSpeed()
	return lso.utils.getGroundSpeed(self.unit)
end
function lso.Carrier:onFrame()
	-- lso.log(string.format("Case %d\ninProcess %d\nrecovery %s\nbackToCruise %s", self.case, #self.inProcess, self.recovery and "true" or "false", self.backToCruise and "true" or "false"), 1, true, "carrierFrame")
	if (self.needToTurn) then
		if (
			#lso.process.getUnitsInStatus(lso.process.Status.INITIAL) == 0
			and #lso.process.getUnitsInStatus(lso.process.Status.BREAK) == 0
			and #lso.process.getUnitsInStatus(lso.process.Status.PADDLES) == 0
		) then
			self.needToTurn = false
			self:addRoute()
		end
	end
	
	-- 检测航母是否在转向
	local heading = lso.Carrier:getHeadding(true)
	if (self.lastHeadding and math.abs(lso.math.getAzimuthError(heading, self.lastHeadding, true)) > 0.1) then
	-- if (self.lastHeadding and heading ~= self.lastHeadding) then
		if (not self.turning) then
			self.turningTime = timer.getTime()
			lso.Broadcast:send(lso.Broadcast.event.TURNING_START)
		end
		-- 转向超过 5 分钟重置路径防卡死
		if (timer.getTime() - self.turningTime > 60 * 5) then
			local group = self.unit:getGroup()
			if group then
				local groupCon = group:getController()
				if groupCon then
					groupCon:popTask()
					self:addRoute()
				end
			end
		end
		self.turning = true
	else
		if (self.turning) then
			lso.Broadcast:send(lso.Broadcast.event.TURNING_STOP)
		end
		self.turning = false
	end
	self.lastHeadding = heading
	
	-- 判断当前回收状况 Case 1-3
	local case = 0
	local now = lso.utils.getTime()
	local ceiling = lso.Converter.M_FT(env.mission.weather.clouds.base)
	local visibility = 10
	if (env.mission.weather.enable_fog or env.mission.weather.fog.thickness > 0) then
		visibility = lso.Converter.M_NM(env.mission.weather.fog.visibility)
	end
	if (now.h > 7 and now.h < 18) then
		if (visibility >= 5) then
			if (ceiling >= 3000) then
				case = 1
			elseif (ceiling >= 1000) then
				case = 2
			else
				case = 3
			end
		else
			case = 3
		end
	else
		case = 3
	end
	if (case ~= 0) then
		self.case = case
	end
end


-- 飞机类
-- 包含了所需的飞行参数
lso.Plane = {
	case, -- 飞机正在执行的回收状况
	unit, -- 飞机单位
	name, -- 飞机单位名称
	model, -- 飞机型号
	number, -- 机身编号
	point, -- 飞机位置
	altitude, -- 飞机高度（米）
	heading, -- 飞机航向（角度）
	azimuth, -- 飞机位于航母的方位角（角度）
	angle, -- 飞机到着陆点角度（角度）
	angleError, -- 相对着陆甲板角度误差（角度）
	distance, -- 到着陆点的平面距离（米）
	rtg, -- Range-to-go 到着陆点的下滑道剩余距离（米）
	gs, -- 当前下滑道角度（角度）
	gsError, -- 当前下滑道相对标准下滑道误差（角度）
	aoa, -- 攻角（角度）
	roll, -- 侧倾角
	speed, -- 示空速（m/s）
	vs, -- 垂直速度（m/s）
	fuel, -- 剩余油量（kg）
}
function lso.Plane:new(unit, aircraftData, onboardNumber)
	local unitObj, unitName
	if (type(unit) == "string") then
		unitObj = Unit.getByName(unit)
		if not unitObj then
			return nil
		end
		unitName = unit
	else
		unitObj = unit
		if not unitObj then
			return nil
		end
		unitName = unit:getName()
	end
	local obj = {
		unit = unitObj,
		name = unitName,
		model = aircraftData,
		number = onboardNumber
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __tostring = self.toString})
	return obj
end
function lso.Plane:updateData()
	if (self.unit and self.unit:isExist()) then
		self.point = self.unit:getPoint()
		self.altitude = self.point.y
		self.heading = math.deg(lso.utils.getHeading(self.unit, true) or 0)
		local lx, ly = lso.Carrier:getLandingPoint()
		self.angle = lso.math.getAzimuth(self.point.z, self.point.x, lx, ly, true)
		self.angleError = lso.Carrier:getAngleError(self.angle, true)
		self.azimuth = (self.angle + 180 - lso.Carrier:getHeadding(true)) % 360
		self.distance = lso.utils.getDistance(self.point.z, self.point.x, lx, ly)
		self.rtg = self.distance * math.cos(math.rad(self.angleError))
		self.gs = lso.Carrier:getGlideSlope(self.distance, self.point.y)
		self.gsError = self.gs - lso.Carrier.data.gs
		self.aoa = math.deg(lso.utils.getAoA(self.unit) or 0)
		self.roll = math.deg(lso.utils.getRoll(self.unit) or 0)
		self.speed = lso.utils.getIndicatedAirSpeed(self.unit)
		self.vs = lso.utils.getVerticalSpeed(self.unit)
		local fuelMassMax = self.unit:getDesc().fuelMassMax -- 总油重 千克
		self.fuel = fuelMassMax * self.unit:getFuel()
		return true
	else
		return false
	end
end
function lso.Plane.equalTo(self, another)
	local selfName, anotherName
	if (type(self) == "table") then
		selfName = self:getName()
	else
		selfName = self
	end
	if (type(another) == "table") then
		anotherName = another:getName()
	else
		anotherName = another
	end
	return selfName == anotherName
end
function lso.Plane.toString(self)
	return self.unit:getName()
end
function lso.Plane.get(unitName)
	local unit
	if (type(unitName) == "table") then
		unit = unitName
		unitName = unitName:getName()
	else
		unit = Unit.getByName(unitName)
	end
	local plane = lso.DB.planes[unitName]
	if (plane) then
		plane.unit = unit
		if (plane:updateData()) then
			return plane
		end
	end
	return nil
end


-- RadioCommand 类
-- 创建和发送无线电指令
lso.RadioCommand = {__class="RadioCommand", id, tag, speaker, msg, sound, duration, priority, callback}
lso.RadioCommand.count = 0
lso.RadioCommand.Priority = Enum(
	"LOW",
	"NORMAL",
	"HIGH",
	"IMMEDIATELY"
)
function lso.RadioCommand:new(tag, speaker, msg, sound, duration, priority, unit, data)
	assert(msg ~= nil, "RadioCommand: msg cannot be nil");
	self.count = self.count + 1
	local obj = {
		id = self.count,
		tag = tag or ("RadioCommand"..self.count),
		speaker = speaker,
		msg = msg,
		sound = sound or "l10n/DEFAULT/radio_on.wav",
		duration = duration or 1,
		priority = priority or lso.RadioCommand.Priority.NORMAL,
	}
	setmetatable(obj, {__index=self, __eq=self.equalTo, __tostring=self.toString, __add=self.concat, __concat=self.concat})
	return obj
end
function lso.RadioCommand.concat(self, another)
	if (type(another) == "table") then
		local group
		if (another.__class == "RadioCommand") then
			group = lso.RadioCommandGroup:new({self, another})
		elseif (another.__class == "RadioCommandGroup") then
			group = another
			group:add(self, 1)
		end
		return group
	end
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
function lso.RadioCommand:onFinish(callback)
	self.callback = callback
	return self
end
function lso.RadioCommand:getDuration()
	return self.duration
end
function lso.RadioCommand:prepare(unit, data)
	self.unit = unit
	self.data = data
	return self
end
function lso.RadioCommand:send(unit, data)
	unit = unit or self.unit
	data = data or self.data
	local content = self.msg:format(unpack(data or {}))
	local msg = string.format("%s: %s", self.speaker, content)
	if (unit and unit:isExist()) then
		if (lso.useRadioFrequency) then
			local controller = unit:getController()
			if (controller) then
				local command = { 
					id = 'TransmitMessage',
					params = {
						duration = self.duration,
						subtitle = msg,
						loop = false,
						file = self.sound,
					}
				}
				controller:setCommand(command)
			end
		else
			trigger.action.outTextForCoalition(unit:getCoalition(), msg, self.duration)
			trigger.action.outSoundForCoalition(unit:getCoalition(), self.sound)
		end
		if (self.callback) then
			timer.scheduleFunction(self.callback, self, timer.getTime() + self.duration)
		end
	end
end


-- RadioCommandGroup 类
-- 创建和发送无线电指令组
lso.RadioCommandGroup = {__class="RadioCommandGroup", id, msgQueue, callback, sendTask}
lso.RadioCommandGroup.count = 0
function lso.RadioCommandGroup:new(msgQueue)
	msgQueue = type(msgQueue) == "table" and msgQueue or {}
	self.count = self.count + 1
	local obj = {
		id = self.count,
		msgQueue = msgQueue,
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __add=self.concat, __concat=self.concat})
	return obj
end
function lso.RadioCommandGroup:add(msg, index)
	local i = index or #self.msgQueue + 1
	if (type(msg) == "table") then
		if (msg.__class == "RadioCommand") then
			table.insert(self.msgQueue, i, msg)
		else
			for __i, v in ipairs(msg) do
				table.insert(self.msgQueue, i, v)
				i = i + 1
			end
		end
	end
end
function lso.RadioCommandGroup.concat(self, another)
	if (type(another) == "table") then
		if (another.__class == "RadioCommand") then
			self:add(another)
		elseif (another.__class == "RadioCommandGroup") then
			self:add(another)
		end
		return self
	end
end
function lso.RadioCommandGroup.equalTo(self, another)
	if (
		type(self) == "table" and type(another) == "table"
		and self.__class == "RadioCommandGroup" and another.__class == "RadioCommandGroup"
	) then
		return self.id == another.id
	else
		return false
	end
end
function lso.RadioCommandGroup:onFinish(callback)
	self.callback = callback
	return self
end
function lso.RadioCommandGroup:getDuration()
	local duration = 0
	for i, msg in self.msgQueue do
		duration = duration + msg.duration
	end
	return duration
end
function lso.RadioCommandGroup:send()
	local sendQueue = function(args, timestamp)
		local msg = table.remove(self.msgQueue, 1)
		if msg then
			msg:send()
			return timer.getTime() + msg.duration
		else
			if self.callback then
				self.callback(self)
			end
			return nil
		end
	end
	self.sendTask = timer.scheduleFunction(sendQueue, nil, timer.getTime() + 0.01)
end


-- 单位转换器
lso.Converter = {
	KG_LB = function(src)
		return src * 2.204623
	end,
	LB_KG = function(src)
		return src / 2.204623
	end,
	M_MI = function(src)
		return src * 0.000621
	end,
	MI_M = function(src)
		return src / 0.000621
	end,
	M_NM = function(src)
		return src * 0.00054
	end,
	NM_M = function(src)
		return src / 0.00054
	end,
	M_FT = function(src)
		return src * 3.28084
	end,
	FT_M = function(src)
		return src / 3.28084
	end,
	PA_INHG = function(src)
		return src * 0.007502 * 0.03937
	end,
	INHG_PA = function(src)
		return src / 0.007502 / 0.03937
	end,
	K_C = function(src)
		return src - 273.15
	end,
	C_K = function(src)
		return src + 273.15
	end,
	MS_KNOT = function(src)
		return src * 1.944012
	end,
	KNOT_MS = function(src)
		return src / 1.944012
	end,
}


-- 工具模块
lso.utils = {}

function lso.utils.deepCopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
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

-- 获取当前游戏中时间
function lso.utils.getTime(t)
	local timeInSec = 0
	if t and type(t) == 'number' then
		timeInSec = t
	else
		timeInSec = lso.math.round(timer.getAbsTime() + env.mission.start_time)
	end
	local timeData = {h=0, m=0, s=0}
	timeInSec = timeInSec % 86400
	while timeInSec >= 3600 do
		timeData.h = timeData.h + 1
		timeInSec = timeInSec - 3600
	end
	while timeInSec >= 60 do
		timeData.m = timeData.m + 1
		timeInSec = timeInSec - 60
	end
	timeData.s = timeInSec
	return timeData
end

-- 计算两点欧氏距离
function lso.utils.getDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

-- 获取指定坐标点风数据 (风向，风速)
function lso.utils.getWindInfo(gPoint, alt)
	local point = lso.utils.deepCopy(gPoint)
	if not point.z then --convert vec2 to Vec3
		point.z = point.y
		point.y = 1
	else
		if point.y < 1 then
			point.y = 1
		end
	end
	if alt ~= nil then
		point.y = alt
	end
	local wind = atmosphere.getWind(point)
	local heading = math.atan2(wind.z, wind.x)
	heading = heading + lso.utils.getNorthCorrection(point)
	if heading < 0 then
		heading = heading + 2*math.pi
	end
	heading = (heading + math.pi) % (2 * math.pi)
	local speed = lso.math.getMag(wind) or 0
	return heading, speed
end

-- 获取单位航向 MIST
function lso.utils.getHeading(unit, rawHeading)
	local unitpos = unit:getPosition()
	if unitpos then
		local heading = math.atan2(unitpos.x.z, unitpos.x.x)
		if not rawHeading then
			heading = heading + lso.utils.getNorthCorrection(unitpos.p)
		end
		if heading < 0 then
			heading = heading + 2*math.pi	-- put heading in range of 0 to 2*pi
		end
		return heading
	end
end

-- 获取单位攻角 MIST
function lso.utils.getAoA(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		local unitvel = unit:getVelocity()
		if lso.math.getMag(unitvel) ~= 0 then --must have non-zero velocity!
			local AxialVel = {}	--unit velocity transformed into aircraft axes directions
			--transform velocity components in direction of aircraft axes.
			AxialVel.x = lso.math.getDP(unitpos.x, unitvel)
			AxialVel.y = lso.math.getDP(unitpos.y, unitvel)
			AxialVel.z = lso.math.getDP(unitpos.z, unitvel)
			-- AoA is angle between unitpos.x and the x and y velocities
			local AoA = math.acos(lso.math.getDP({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = AxialVel.y, z = 0})/lso.math.getMag({x = AxialVel.x, y = AxialVel.y, z = 0}))
			--now set correct direction:
			if AxialVel.y > 0 then
				AoA = -AoA
			end
			return AoA
		end
	end
end

-- 获取单位俯仰角 MIST
function lso.utils.getPitch(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		return math.asin(unitpos.x.y)
	end
end

-- 获取单位侧倾角 MIST
function lso.utils.getRoll(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		-- now get roll:
		--maybe not the best way to do it, but it works.
		--first, make a vector that is perpendicular to y and unitpos.x with cross product
		local cp = lso.math.getCP(unitpos.x, {x = 0, y = 1, z = 0})
		--now, get dot product of of this cross product with unitpos.z
		local dp = lso.math.getDP(cp, unitpos.z)
		--now get the magnitude of the roll (magnitude of the angle between two vectors is acos(vec1.vec2/|vec1||vec2|)
		local Roll = math.acos(dp/(lso.math.getMag(cp)*lso.math.getMag(unitpos.z)))
		--now, have to get sign of roll.
		-- by convention, making right roll positive
		-- to get sign of roll, use the y component of unitpos.z.	For right roll, y component is negative.
		if unitpos.z.y > 0 then -- left roll, flip the sign of the roll
			Roll = -Roll
		end
		return Roll
	end
end

-- 获取单位偏航角 MIST
function lso.utils.getYaw(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		-- get unit velocity
		local unitvel = unit:getVelocity()
		if lso.math.getMag(unitvel) ~= 0 then --must have non-zero velocity!
			local AxialVel = {}	--unit velocity transformed into aircraft axes directions
			--transform velocity components in direction of aircraft axes.
			AxialVel.x = lso.math.getDP(unitpos.x, unitvel)
			AxialVel.y = lso.math.getDP(unitpos.y, unitvel)
			AxialVel.z = lso.math.getDP(unitpos.z, unitvel)
			--Yaw is the angle between unitpos.x and the x and z velocities
			--define right yaw as positive
			local Yaw = math.acos(lso.math.getDP({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = 0, z = AxialVel.z})/lso.math.getMag({x = AxialVel.x, y = 0, z = AxialVel.z}))
			--now set correct direction:
			if AxialVel.z > 0 then
				Yaw = -Yaw
			end
			return Yaw
		end
	end
end

-- 获取单位垂直速度 m/s
function lso.utils.getVerticalSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	return unit:getVelocity().y
end

-- 获取单位真空速 m/s
function lso.utils.getAirSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	return lso.math.getMag(unit:getVelocity()) or 0
end

-- 获取单位地速 m/s
function lso.utils.getGroundSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local vel = unit:getVelocity()
	return lso.math.getMag(vel.x, vel.z) or 0
end

-- 获取单位示空速 m/s
function lso.utils.getIndicatedAirSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local tas = lso.utils.getAirSpeed(unit)
	local point = unit:getPoint()
	local t, p = atmosphere.getTemperatureAndPressure(point)
	local t0 = 288.15 -- 15℃标准气温（开尔文）
	point.y = 0
	local tsl, p0 = atmosphere.getTemperatureAndPressure(point)
	-- EAS = √((TAS^2)/(p0/p)/(T/T0))
	local eas = math.sqrt(math.pow(tas, 2) / (p0/p) / (t/t0))
	return eas
end

-- 获取单位气压高度 m （实验）
function lso.utils.getBaroAltitude(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local point = unit:getPoint()
	local t, p = atmosphere.getTemperatureAndPressure(point)
	point.y = 0
	local t0, p0 = atmosphere.getTemperatureAndPressure(point)
	local alt = (1 - math.pow(p/p0, 1/5.256)) / 0.00002257
	return alt
end

-- 获取圈中随机点 MIST
function lso.utils.getRandPointInCircle(point, radius, innerRadius)
	local theta = 2*math.pi*math.random()
	local rad = math.random() + math.random()
	if rad > 1 then
		rad = 2 - rad
	end

	local radMult
	if innerRadius and innerRadius <= radius then
		radMult = (radius - innerRadius)*rad + innerRadius
	else
		radMult = radius*rad
	end

	if not point.z then --might as well work with vec2/3
		point.z = point.y
	end

	local rndCoord
	if radius > 0 then
		rndCoord = {x = math.cos(theta)*radMult + point.x, y = math.sin(theta)*radMult + point.z}
	else
		rndCoord = {x = point.x, y = point.z}
	end
	return rndCoord
end

-- 获取指定坐标点的北修正量
function lso.utils.getNorthCorrection(gPoint)
	local point = lso.utils.deepCopy(gPoint)
	if not point.z then --convert vec2 to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end

-- 检查两点之间是否存在陆地 Vec2
function lso.utils.checkLand(point1, point2)
	local dist = lso.utils.getDistance(point1.x, point1.y, point2.x, point2.y)
	local dx = point1.x - point2.x
	local dy = point1.y - point2.y

	local hasLand = false
	for delta = 1, dist do
		local x = point2.x + (dx * (delta / dist))
		local y = point2.y + (dy * (delta / dist))
		if (land.getSurfaceType({x=x, y=y}) ~= land.SurfaceType.WATER) then
			hasLand = true
			break
		end
	end
	return hasLand
end

-- 数学计算工具模块
lso.math ={}

function lso.math.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function lso.math.dirToAngle(direction, degrees)
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
function lso.math.angleToDir(angle, degrees)
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

function lso.math.getOffsetPoint(x, y, dir, dist)
	local angle = math.rad(lso.math.dirToAngle(dir, true))
	local dx = math.cos(angle) * dist
	local dy = math.sin(angle) * dist
	return x + dx, y + dy
end


-- 计算相对方位角
-- 根据给定的坐标，计算出两点的相对方位角
-- xs,ys:基准点坐标
-- xt,yt:目标点坐标
-- degrees:布尔值，是否返回角度（默认返回弧度）
function  lso.math.getAzimuth(xs, ys, xt, yt, degrees)
	local dx = xt - xs
	local dy = yt - ys

	if (dx == 0) then
		return 0
	else
		local deg = lso.math.angleToDir(math.atan(dy/dx))
		deg = (deg + lso.utils.getNorthCorrection({x=xs, y=ys})) % 360
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

function lso.math.getAzimuthError(a1, a2, degrees)
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
function lso.math.getAverage(data)
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
function lso.math.getVariance(data)
	if (#data < 2) then
		return 0
	end
	local avg = lso.math.getAverage(data)
	local sum = 0
	for i, v in ipairs(data) do
		sum = sum + math.pow(v - avg, 2)
	end

	return sum / #data
end

-- 计算向量合
function lso.math.getMag(...)
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

-- 计算向量点积
function lso.math.getDP(vec1, vec2)
	return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
end

-- 计算向量交叉乘积
function lso.math.getCP(vec1, vec2)
	return { x = vec1.y*vec2.z - vec1.z*vec2.y, y = vec1.z*vec2.x - vec1.x*vec2.z, z = vec1.x*vec2.y - vec1.y*vec2.x}
end


lso.process = {}
lso.process.status = {}
lso.process.Status = Enum(
	"NONE",
	"CHECK_IN",
	"IN_SIGHT",
	"INITIAL",
	"BREAK",
	"PADDLES",
	"DEPART"
)
function lso.process.changeStatus(unit, newStatus)
	lso.process.status[unit:getName()] = newStatus
end
function lso.process.getStatus(unit)
	return lso.process.status[unit:getName()]
end
function lso.process.initPlane(unit)
	local plane = lso.Plane.get(unit)
	if plane then
		lso.Carrier:removePlane(plane)
	end
	lso.process.changeStatus(unit, lso.process.Status.NONE)
	lso.menu.initMenu(unit)
end
function lso.process.removePlane(unit)
	lso.Carrier:removePlane(plane)
	lso.process.changeStatus(unit, nil)
end
function lso.process.getUnitsInStatus(status)
	local units = {}
	for unitName, currStatus in pairs(lso.process.status) do
		if currStatus == status then
			table.insert(units, Unit.getByName(unitName))
		end
	end
	return units
end


lso.menu = {}
lso.menu.Command = {
	CHECK_IN = "Check in",
	INFO = "Information",
	IN_SIGHT = "In Sight",
	DEPART = "Depart",
	ABORT = "Abort",
}
lso.menu.order = {
	[1] = lso.menu.Command.CHECK_IN,
	[2] = lso.menu.Command.IN_SIGHT,
	[3] = lso.menu.Command.INFO,
	[4] = lso.menu.Command.DEPART,
	[5] = lso.menu.Command.ABORT,
}
lso.menu.path = {}
function lso.menu.addMenu(unit, menu, handler)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	if (lso.menu.path[unit:getName()][menu] == nil) then
		lso.menu.clearMenu(unit)
		for i, m in ipairs(lso.menu.order) do
			if (lso.menu.hasMenu(unit, m)) then
				local mData = lso.menu.getMenu(unit, m)
				lso.menu.path[unit:getName()][m].path = missionCommands.addCommandForGroup(unit:getGroup():getID(), m, nil, mData.handler, unit)
			elseif (m == menu) then
				lso.menu.path[unit:getName()][menu] = {
					path = missionCommands.addCommandForGroup(unit:getGroup():getID(), menu, nil, handler, unit),
					handler = handler,
				}
			end
		end
		-- lso.menu.path[unit:getName()][menu] = missionCommands.addCommandForGroup(unit:getGroup():getID(), menu, nil, handler, unit)
		return true
	else
		return false
	end
end
function lso.menu.removeMenu(unit, menu)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	if (lso.menu.path[unit:getName()][menu] ~= nil) then
		missionCommands.removeItemForGroup(unit:getGroup():getID(), lso.menu.path[unit:getName()][menu].path)
		lso.menu.path[unit:getName()][menu] = nil
		return true
	else
		return false
	end
end
function lso.menu.getMenu(unit, menu)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	return lso.menu.path[unit:getName()][menu]
end
function lso.menu.hasMenu(unit, menu)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	return lso.menu.path[unit:getName()][menu] ~= nil
end
function lso.menu.initMenu(unit)
	lso.menu.clearMenu(unit)
	lso.menu.path[unit:getName()] = {}
	lso.menu.addMenu(unit, lso.menu.Command.CHECK_IN, lso.menu.handler.checkIn)
end
function lso.menu.clearMenu(unit)
	missionCommands.removeItemForGroup(unit:getGroup():getID())
end

lso.menu.handler = {}
function lso.menu.handler.checkIn(unit)
	if (not lso.menu.hasMenu(unit, lso.menu.Command.CHECK_IN)) then
		return
	end
	if (lso.process.getStatus(unit) == lso.process.Status.NONE) then
		local plane = lso.Plane.get(unit)
		if (plane) then
			local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
			local angel = lso.math.round(lso.Converter.M_FT(plane.altitude) / 1000) -- 千英尺
			local distance = lso.math.round(lso.Converter.M_NM(plane.distance)) -- 海里
			
			lso.RadioCommand:new(string.format("%s.check_in", plane.number), plane.number, string.format("Marshal, %s, %03d for %d, Angels %d, State %.1f.", plane.number, (plane.angle + 180) % 360, distance, angel, fuelMess), nil, 4, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:checkIn(unit)
				end)
				:send(unit)
		end
	end
end
function lso.menu.handler.inSight(unit)
	if (not lso.menu.hasMenu(unit, lso.menu.Command.IN_SIGHT)) then
		return
	end
	if (lso.process.getStatus(unit) == lso.process.Status.CHECK_IN) then
		local plane = lso.Plane.get(unit)
		if (plane) then
			local distance = lso.math.round(lso.Converter.M_NM(plane.distance)) -- 海里
			
			lso.RadioCommand:new(string.format("%s.see_you", plane.number), plane.number, string.format("Marshal, %s, See you at %d.", plane.number, distance), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:inSight(unit)
				end)
				:send(unit)
		end
	end
end
function lso.menu.handler.information(unit)
	if (not lso.menu.hasMenu(unit, lso.menu.Command.INFO)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		lso.Marshal:offerInformation()
	end
end
function lso.menu.handler.depart(unit)
	if (not lso.menu.hasMenu(unit, lso.menu.Command.DEPART)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		local status = lso.process.getStatus(unit)
		if (
			status == lso.process.Status.INITIAL
			or status == lso.process.Status.BREAK
			or status == lso.process.Status.PADDLES
		) then
			lso.RadioCommand:new(string.format("%s.depart", plane.number), plane.number, string.format("%s, Departing.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
					lso.Tower:checkIn(plane.unit)
				end)
				:send(unit)
		end
	end
end
function lso.menu.handler.abort(unit)
	if (not lso.menu.hasMenu(unit, lso.menu.Command.ABORT)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		lso.Carrier:removePlane(plane)
		lso.process.initPlane(unit)
		-- lso.process.changeStatus(unit, lso.process.Status.NONE)
		-- lso.menu.initMenu(unit)
		-- lso.menu.removeMenu(unit, lso.menu.Command.INFO)
		-- lso.menu.removeMenu(unit, lso.menu.Command.IN_SIGHT)
		-- lso.menu.removeMenu(unit, lso.menu.Command.DEPART)
		-- lso.menu.removeMenu(unit, lso.menu.Command.ABORT)
		-- lso.menu.addMenu(unit, lso.menu.Command.CHECK_IN, lso.menu.handler.checkIn)
		-- lso.RadioCommand:new(string.format("%s.abort", plane.number), plane.number, string.format("%s, Departing.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
			-- :send(unit)
	end
end



-- Marshal 雷达控制员模块

lso.Marshal = {}
lso.Marshal.check = {} -- 等待Check In的单位
lso.Marshal.visual = {} -- 报告See Me的单位
lso.Marshal.coolDownTime = 0 -- 冷却时间
lso.Marshal.needInformation = false -- 需要播报航母信息
lso.Marshal.queue = {} -- 待处理事项队列
function lso.Marshal:coolDown(cdTime)
	self.coolDownTime = timer.getTime() + cdTime
end
function lso.Marshal:isCoolDown()
	return timer.getTime() > self.coolDownTime
end
function lso.Marshal:checkIn(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.check, unitName)) then
		return false
	else
		table.insert(self.check, unitName)
		return true
	end
end

function lso.Marshal:inSight(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.visual, unitName)) then
		return false
	else
		table.insert(self.visual, unitName)
		return true
	end
end

function lso.Marshal:offerInformation()
	if (self.needInformation == false) then
		self.needInformation = true
		table.insert(self.queue, function(timestamp)
			local temperature, pressure = lso.Carrier:getTemperatureAndPressure()
			local information
			if (lso.Carrier.turning) then
				local nextBRC = lso.Carrier:getBRC()
				information = string.format("99, Mother is turning, expected BRC is %03d, Altimeter %.2f.", nextBRC, pressure)
			else
				local brc = lso.Carrier:getBRC(true)
				information = string.format("99, Mother's BRC is %03d, Altimeter %.2f.", brc, pressure)
			end
			local radio = lso.RadioCommand:new("mather_information", "Marshal", information, nil, 4, lso.RadioCommand.Priority.NORMAL)
			radio:send(lso.Carrier.radio)
			self:coolDown(radio:getDuration())
			self.needInformation = false
		end)
	end
end
-- 广播航母开始转向或停止转向
function lso.Marshal:startOrStopTurning(event)
	if (event == lso.Broadcast.event.TURNING_START) then
		table.insert(self.queue, function(timestamp)
			local nextBRC = lso.Carrier:getBRC()
			local radio = lso.RadioCommand:new("turning", "Marshal", string.format("99, Mother start turning, Expected BRC is %03d.", nextBRC), nil, 5, lso.RadioCommand.Priority.NORMAL)
			radio:send(lso.Carrier.radio)
			self:coolDown(radio:getDuration())
		end)
	elseif (event == lso.Broadcast.event.TURNING_STOP) then
		table.insert(self.queue, function(timestamp)
			local brc = lso.Carrier:getBRC(true)
			local radio = lso.RadioCommand:new("turning", "Marshal", string.format("99, Mother's new BRC is %03d.", brc), nil, 5, lso.RadioCommand.Priority.NORMAL)
			radio:send(lso.Carrier.radio)
			self:coolDown(radio:getDuration())
		end)
	end
end
-- 广播航母开始回收或停止回收作业
function lso.Marshal:startOrStopRecovery(event)
	if (event == lso.Broadcast.event.RECOVERY_START) then
		table.insert(self.queue, function(timestamp)
			local radio = lso.RadioCommand:new("recovery", "Marshal", "99, Charlie.", nil, 4, lso.RadioCommand.Priority.NORMAL)
			radio:send(lso.Carrier.radio)
			self:coolDown(radio:getDuration())
		end)
	elseif (event == lso.Broadcast.event.RECOVERY_STOP) then
		if (#lso.Carrier.inProcess > 0) then
			table.insert(self.queue, function(timestamp)
				local eat = lso.Carrier:getEAT()
				if eat then
					local radio = lso.RadioCommand:new("recovery", "Marshal", string.format("99, Expected Charlie time %d.", math.ceil((eat - timer.getTime()) / 60)), nil, 4, lso.RadioCommand.Priority.NORMAL)
					radio:send(lso.Carrier.radio)
					self:coolDown(radio:getDuration())
				end
			end)
		end
	end
end
-- 初始化 Marshal 模块
function lso.Marshal:init()
	self.frameID = lso.addCheckFrame(self) -- 添加 Marshal 检测帧程序
	
	lso.Broadcast:receive({lso.Broadcast.event.RECOVERY_START, lso.Broadcast.event.RECOVERY_STOP}, function(event)
		self:startOrStopRecovery(event)
	end)
	lso.Broadcast:receive({lso.Broadcast.event.TURNING_START, lso.Broadcast.event.TURNING_STOP}, function(event)
		self:startOrStopTurning(event)
	end)
end
-- 处理管制飞机
function lso.Marshal:process()
	if (#self.queue == 0) then
		if (#self.visual > 0) then
			for i, unitName in pairs(self.visual) do
				local plane = lso.Plane.get(unitName)
				if (plane and lso.process.getStatus(plane.unit) == lso.process.Status.CHECK_IN) then
					lso.RadioCommand:new(string.format("%s.switch_tower", plane.name), "Marshal", string.format("%s, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
						:onFinish(function()
							lso.RadioCommand:new(string.format("%s.switch_tower_roger", plane.name), plane.number, string.format("%s, Roger, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
								:send(plane.unit)
						end)
						:send(lso.Carrier.radio)
					self.coolDownTime = timer.getTime() + 4
					lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
					lso.menu.removeMenu(plane.unit, lso.menu.Command.IN_SIGHT)
					lso.Tower:checkIn(plane.unit)
					table.remove(self.visual, i)
					break
				else
					table.remove(self.visual, i)
				end
			end
		elseif (#self.check > 0) then
			for i, unitName in pairs(self.check) do
				local plane = lso.Plane.get(unitName)
				if (plane) then
					local _, recoveryStarted = lso.Carrier:addPlane(plane)
					local eat = lso.Carrier:getEAT()
					local charlieTime = (recoveryStarted or eat == nil) and "" or string.format(", Expected Charlie time %d", math.ceil((eat - timer.getTime()) / 60))
					local charlieTimeRoger = (recoveryStarted or eat == nil) and "" or string.format(", Charlie time %d", math.ceil((eat - timer.getTime()) / 60))
					local temperature, pressure = lso.Carrier:getTemperatureAndPressure()
					local replyMsg, rogerMsg
					if (lso.Carrier.turning) then
						local nextBRC = lso.Carrier:getBRC()
						replyMsg = string.format("%s, Radar contact, Case I recovery, Expected BRC is %03d, Altimeter %.2f%s, Report see me.", plane.number, nextBRC, pressure, charlieTime)
						rogerMsg = string.format("%s, Roger, Expected BRC %03d, %.2f%s.", plane.number, nextBRC, pressure, charlieTimeRoger)
					else
						local brc = lso.Carrier:getBRC(true)
						replyMsg = string.format("%s, Radar contact, Case I recovery, BRC is %03d, Altimeter %.2f%s, Report see me.", plane.number, brc, pressure, charlieTime)
						rogerMsg = string.format("%s, Roger, BRC %03d, %.2f%s.", plane.number, brc, pressure, charlieTimeRoger)
					end
					local radio = lso.RadioCommand:new(string.format("%s.check_in_reply", plane.name), "Marshal", replyMsg, nil, 4, lso.RadioCommand.Priority.NORMAL)
							:prepare(lso.Carrier.radio)
						+ lso.RadioCommand:new(string.format("%s.check_in_roger", plane.name), plane.number, rogerMsg, nil, 4, lso.RadioCommand.Priority.NORMAL)
							:prepare(plane.unit)
					radio:send()
					self.coolDownTime = timer.getTime() + 8
					lso.process.changeStatus(plane.unit, lso.process.Status.CHECK_IN)
					lso.menu.removeMenu(plane.unit, lso.menu.Command.CHECK_IN)
					lso.menu.addMenu(plane.unit, lso.menu.Command.IN_SIGHT, lso.menu.handler.inSight)
					lso.menu.addMenu(plane.unit, lso.menu.Command.INFO, lso.menu.handler.information)
					lso.menu.addMenu(plane.unit, lso.menu.Command.ABORT, lso.menu.handler.abort)
					table.remove(self.check, i)
					break
				else
					table.remove(self.check, i)
				end
			end
		end
	end
end
function lso.Marshal:onFrame()
	-- mist.message.add({
		-- text =  string.format("Marshal检测帧工作中 %d %d", #self.check, #self.visual),
		-- displayTime = 1,
		-- msgFor = {coa = {"all"}},
		-- name = "marshalFrame",
	-- })
	if (self:isCoolDown() and lso.LSO.contact ~= true) then
		self:process()
		if (#self.queue > 0) then
			local func = table.remove(self.queue, 1)
			func(timer.getTime())
		end
	end
end



-- Tower 塔台模块

lso.Tower = {}
lso.Tower.monitoring = {} -- 雷达监控中的单位
lso.Tower.coolDownTime = 0

function lso.Tower:checkIn(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.monitoring, unitName)) then
		return false
	else
		table.insert(self.monitoring, unitName)
		return true
	end
end
function lso.Tower:onFrame()
	-- mist.message.add({
		-- text =  string.format("Tower检测帧工作中 %d", #self.monitoring),
		-- displayTime = 1,
		-- msgFor = {coa = {"all"}},
		-- name = "TowerFrame",
	-- })
	if (timer.getTime() > self.coolDownTime and lso.LSO.contact ~= true) then
		for i, unitName in pairs(self.monitoring) do
			local plane = lso.Plane.get(unitName)
			if (plane) then
				local status = lso.process.getStatus(plane.unit)
				-- if (lso.Carrier.turning) then
					-- if (
						-- status == lso.process.Status.BREAK
						-- or status == lso.process.Status.INITIAL
					-- ) then
						-- lso.RadioCommand:new(string.format("%s.reenter", plane.name), "Tower", string.format("%s, Re-enter holding pattern.", plane.number), nil, 3, lso.RadioCommand.Priority.NORMAL)
							-- :onFinish(function()
								-- lso.RadioCommand:new(string.format("%s.reenter_reply", plane.name), plane.number, string.format("%s, Roger.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
									-- :send(plane.unit)
							-- end)
							-- :send(lso.Carrier.radio)
						-- self.coolDownTime = timer.getTime() + 5
						-- lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
						-- lso.menu.removeMenu(plane.unit, lso.menu.Command.DEPART)
					-- end
				-- end
				
				if (status == lso.process.Status.DEPART) then
					lso.RadioCommand:new(string.format("%s.re-enter", plane.name), "Tower", string.format("%s, Re-enter holding pattern.", plane.number), nil, 3, lso.RadioCommand.Priority.NORMAL)
						:send(lso.Carrier.radio)
					self.coolDownTime = timer.getTime() + 3
					lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
					lso.menu.removeMenu(plane.unit, lso.menu.Command.DEPART)
				elseif (status == lso.process.Status.BREAK) then
					if (lso.LSO:checkContact(plane)) then
						table.remove(self.monitoring, i)
						break
					end
					if (
						lso.Converter.M_FT(plane.altitude) > 1200
						or lso.Converter.MS_KNOT(plane.speed) > 400
						or lso.Converter.M_NM(plane.distance) > 4
					) then
						lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
					end
					if (lso.Converter.MS_KNOT(plane.speed - lso.Carrier:getSpeed()) < 10) then
						lso.process.initPlane(plane.unit)
					end
				else
					local carrierHeadding = lso.Carrier:getHeadding(true)
					if (status == lso.process.Status.IN_SIGHT) then
						if (not lso.Carrier.turning) then
							-- 在航母的相对方位 160-200° 之间
							if (plane.azimuth > 160 and plane.azimuth < 200) then
								-- 距离 1-3 nm
								if (lso.Converter.M_NM(plane.distance) > 1 and lso.Converter.M_NM(plane.distance) < 3) then
									-- 高度低于 1300 ft，速度小于 400 节 
									if (lso.Converter.M_FT(plane.altitude) < 1300 and lso.Converter.MS_KNOT(plane.speed) < 400) then
										-- 航向为航母航向 ±20°
										if (math.abs(lso.math.getAzimuthError(plane.heading, carrierHeadding, true)) < 20) then
											lso.RadioCommand:new(string.format("%s.initial", plane.name), plane.number, string.format("%s, Initial.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
												:onFinish(function()
													lso.RadioCommand:new(string.format("%s.initial_reply", plane.name), "Tower", string.format("Roger, %s.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
														:send(lso.Carrier.radio)
												end)
												:send(plane.unit)
											self.coolDownTime = timer.getTime() + 4
											lso.process.changeStatus(plane.unit, lso.process.Status.INITIAL)
											lso.menu.addMenu(plane.unit, lso.menu.Command.DEPART, lso.menu.handler.depart)
										end
									end
								elseif (lso.Converter.M_NM(plane.distance) < 1 and lso.Converter.M_FT(plane.altitude) < 1200) then
									lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
								end
							else
								if (lso.Converter.M_NM(plane.distance) < 2 and lso.Converter.M_FT(plane.altitude) < 1200) then
									lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
								end
							end
						else
							if (lso.Converter.M_NM(plane.distance) < 2 and lso.Converter.M_FT(plane.altitude) < 1200) then
								lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
							end
						end
					elseif (status == lso.process.Status.INITIAL) then
						-- 在航母的相对方位 270-360° 之间
						if (plane.azimuth > 270 and plane.azimuth < 360) then
							-- 高度低于 1000 ft，速度小于 400 节 
							if (lso.Converter.M_FT(plane.altitude) < 1000 and lso.Converter.MS_KNOT(plane.speed) < 400) then
								-- 航向为航母航向向左大于5度
								if (lso.math.getAzimuthError(plane.heading, carrierHeadding, true) < -5) then
									-- 飞机侧倾角向左大于15度
									if (plane.roll < -15) then
										lso.RadioCommand:new(string.format("%s.break", plane.name), plane.number, string.format("%s, Breaking.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
											:onFinish(function()
												lso.RadioCommand:new(string.format("%s.break_reply", plane.name), "Tower", string.format("%s, Dirty up.", plane.number), nil, 3, lso.RadioCommand.Priority.NORMAL)
													:send(lso.Carrier.radio)
											end)
											:send(plane.unit)
										self.coolDownTime = timer.getTime() + 5
										lso.process.changeStatus(plane.unit, lso.process.Status.BREAK)
									end
								end
							end
						end
						if (
							lso.Converter.M_FT(plane.altitude) > 1300
							or lso.Converter.MS_KNOT(plane.speed) > 450
							or lso.Converter.M_NM(plane.distance) > 3
							or math.abs(lso.math.getAzimuthError(plane.heading, carrierHeadding, true)) > 90
						) then
							lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
						end
					else
						table.remove(self.monitoring, i)
					end
				end
			else
				table.remove(self.monitoring, i)
			end
		end
	end
end



-- Paddles 着舰信号官模块
lso.LSO = {}
lso.LSO.contact = false -- 是否接触
lso.LSO.trackProcess = nil -- 当前指挥程序

-- 着舰信号官固定指令
lso.LSO.command = {
	CONTACT 	= 	lso.RadioCommand:new("lso.CONTACT", 		"LSO", "%s, Paddles contact.", 			lso.Sound.LSO.PADDLES_CONTACT	, 4, lso.RadioCommand.Priority.NORMAL),
	CALL_BALL 	= 	lso.RadioCommand:new("lso.CALL_THE_BALL", 	"LSO", "%s, 3/4 miles, Call the ball.", lso.Sound.LSO.CALL_THE_BALL		, 2, lso.RadioCommand.Priority.NORMAL),
	ROGER_BALL 	= 	lso.RadioCommand:new("lso.ROGER_BALL", 		"LSO", "Roger ball.", 					lso.Sound.LSO.ROGER_BALL		, 1, lso.RadioCommand.Priority.NORMAL),
					
	KEEP_TURN	= 	lso.RadioCommand:new("lso.KEEP_TURN", 		"LSO", "Keep your turn in!", 			lso.Sound.LSO.KEEP_TURN			, 2, lso.RadioCommand.Priority.NORMAL),
	HIGH 		= 	lso.RadioCommand:new("lso.HIGH", 			"LSO", "You're high!", 					lso.Sound.LSO.HIGH				, 2, lso.RadioCommand.Priority.NORMAL),
	LOW 		= 	lso.RadioCommand:new("lso.LOW", 			"LSO", "Little power!", 				lso.Sound.LSO.LOW				, 2, lso.RadioCommand.Priority.NORMAL),
	TOO_LOW 	= 	lso.RadioCommand:new("lso.TOO_LOW", 		"LSO", "Power!", 						lso.Sound.LSO.TOO_LOW			, 2, lso.RadioCommand.Priority.HIGH),
	LEFT 		= 	lso.RadioCommand:new("lso.LEFT", 			"LSO", "Right for lineup!", 			lso.Sound.LSO.RIGHT				, 2, lso.RadioCommand.Priority.NORMAL),
	RIGHT 		= 	lso.RadioCommand:new("lso.RIGHT", 			"LSO", "Come left!", 					lso.Sound.LSO.LEFT				, 2, lso.RadioCommand.Priority.NORMAL),
	EASY 		= 	lso.RadioCommand:new("lso.EASY", 			"LSO", "Easy with it.", 				lso.Sound.LSO.EASY				, 2, lso.RadioCommand.Priority.NORMAL),
	FAST 		= 	lso.RadioCommand:new("lso.FAST", 			"LSO", "You're fast!", 					lso.Sound.LSO.FAST				, 2, lso.RadioCommand.Priority.NORMAL),
	SLOW 		= 	lso.RadioCommand:new("lso.SLOW", 			"LSO", "You're slow!", 					lso.Sound.LSO.SLOW				, 2, lso.RadioCommand.Priority.NORMAL),

	FOUL_DECK	= 	lso.RadioCommand:new("lso.FOUL_DECK",		"LSO", "Wave off, Foul deck.", 			lso.Sound.LSO.WAVEOFF			, 3, lso.RadioCommand.Priority.IMMEDIATELY),
	WAVE_OFF	= 	lso.RadioCommand:new("lso.WAVE_OFF",		"LSO", "Wave off! Wave off!", 			lso.Sound.LSO.WAVEOFF			, 3, lso.RadioCommand.Priority.IMMEDIATELY),
	BOLTER 		= 	lso.RadioCommand:new("lso.BOLTER", 			"LSO", "Bolter! Bolter! Bolter!", 		lso.Sound.LSO.BOLTER			, 3, lso.RadioCommand.Priority.IMMEDIATELY),
}

-- 着舰信号官指令记录
lso.LSO.commands = {
	currentCommand = nil, -- 当前指令
	sendTime = nil, -- 当前指令下达时间
	coolDown = {}, -- 指令冷却状态
}

-- 下达指令
function lso.LSO:showCommand(cmd, unit, force, data, coolTime)
	local sender = unit or lso.Carrier.radio
	local commandData = self.commands
	local nowTime = timer.getTime()
	
	-- 检查上一条指令是否结束
	-- 当上一条指令已结束或新指令优先级高于上一条指令时，将上一条指令设置冷却，并继续执行
	-- 否则忽略新指令
	if ((not force) and commandData.currentCommand and commandData.sendTime) then
		local prior = cmd.priority > commandData.currentCommand.priority
		local endTime = commandData.sendTime + commandData.currentCommand.duration
		if (prior or nowTime >= endTime) then
			local cd = commandData.coolDown or {}
			cd[commandData.currentCommand.tag] = {
				command = commandData.currentCommand,
				coolTime = endTime + (coolTime or 2)
			}
			commandData.coolDown = cd
			commandData.sendTime = nil
			commandData.currentCommand = nil
			self.commands = commandData
		else
			return false
		end
	end

	-- 更新所有指令的冷却状态
	-- 并检查新指令是否处于冷却期
	local cooling = false
	for tag, cdItem in pairs(commandData.coolDown) do
		if (nowTime >= cdItem.coolTime) then
			commandData.coolDown[tag] = nil
		else
			if (cdItem.command == cmd) then
				cooling = true
			end
		end
	end
	self.commands = commandData

	-- 如果新指令未处于冷却期或新指令优先级为“立即执行”，则下达新指令
	if ((not force) and cooling and cmd.priority ~= lso.RadioCommand.Priority.IMMEDIATELY) then
		return false
	else
		commandData.currentCommand = cmd
		commandData.sendTime = nowTime
		self.commands = commandData
		cmd:send(sender, data)
		return true
	end
end


-- 追踪数据类
-- 用于记录着陆阶段所有飞行数据
lso.LSO.TrackData = {plane, data, commands, processTime}
function lso.LSO.TrackData:new(plane)
		assert(plane ~= nil, "TrackData: unit cannot be nil");
		local obj = {
			plane = plane,
			data = {},
			commands = {},
			processTime = {
				start,middle,close,ramp,
			},
		}
		setmetatable(obj, {__index = self})
		return obj
end
function lso.LSO.TrackData:addData(flightData)
		table.insert(self.data, flightData)
end
function lso.LSO.TrackData:getData()
	if (#self.data > 0) then
		return self.data[#self.data]
	else
		return nil
	end
end
function lso.LSO.TrackData:getDataRecord(dataType, length)
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
function lso.LSO.TrackData:addCommand(command, timestamp)
	table.insert(self.commands, {
		command = command,
		timestamp = timestamp or timer.getTime()
	})
end


function lso.LSO:checkContact(plane)
	if (lso.LSO.contact) then
		return false
	end
	local carrierHeadding = lso.Carrier:getHeadding(true)
	local carrierTail = (carrierHeadding + 180) % 360
	local deckAngle = (carrierHeadding - lso.Carrier.data.deck) % 360
	
	-- local data1 = string.format("飞机航向 %.3f\n飞机速度 %.3f", plane.heading, lso.Converter.MS_KNOT(plane.speed))
	-- local data2 = string.format("船航向 %.3f\n船尾 %.3f\n倾斜甲板 %.3f", carrierHeadding, carrierTail, deckAngle)
	-- local data3 = string.format("距离 %.3f\n方位角 %.3f", plane.distance, plane.azimuth)
	-- local data4 = string.format("相对船尾角度 %.3f\n高度 %.3f", lso.math.getAzimuthError(plane.heading, carrierTail, true), plane.altitude)
	-- mist.message.add({
		-- text = data1 .. "\n" .. data2 .. "\n" .. data3 .. "\n" .. data4,
		-- displayTime = 5,
		-- msgFor = {units={plane.unit:getName()}},
		-- name = plane.unit:getName() .. "checkContact",
	-- })
	
	-- 在航母的相对方位 225-265° 之间
	if (plane.azimuth > 225 and plane.azimuth < 265) then
		-- 距离 0.2-1.7 nm
		if (lso.Converter.M_NM(plane.distance) > 0.2 and lso.Converter.M_NM(plane.distance) < 1.7) then
			-- 高度低于 800 ft，速度小于 220 节 
			if (lso.Converter.M_FT(plane.altitude) < 800 and lso.Converter.MS_KNOT(plane.speed) < 220) then
				-- 航向为航母舰尾 ±45°
				if (math.abs(lso.math.getAzimuthError(plane.heading, carrierTail, true)) < 45) then
					-- 改变状态 Paddles Contact
					lso.process.changeStatus(plane.unit, lso.process.Status.PADDLES)
					lso.menu.removeMenu(plane.unit, lso.menu.Command.ABORT)
					
					self.command.CONTACT:send(lso.Carrier.radio, {plane.number})
					
					local paddleFrame = function(args, timestamp)
						local carrierHeadding = lso.Carrier:getHeadding(true)
						local carrierTail = (carrierHeadding + 180) % 360
						if (plane:updateData()) then -- 更新飞行数据
							if (
								plane.azimuth > 90 and plane.azimuth < 270 -- 在航母后半圆
								and lso.Converter.M_NM(plane.distance) < 2 -- 距离小于 2.5 nm
								and lso.Converter.M_FT(plane.altitude) < 800 -- 高度低于 800 ft
							) then
								-- local data1 = string.format("方位偏差 %.3f\n角度偏差 %.3f", plane.angleError, lso.math.getAzimuthError(plane.heading, deckAngle, true))
								-- local data2 = string.format("距离下滑道 %.3f", math.sin(math.rad(math.abs(plane.angleError))) * plane.distance)
								-- mist.message.add({
									-- text = data1 .. "\n" .. data2,
									-- displayTime = 1,
									-- msgFor = {units={plane.unit:getName()}},
									-- name = plane.unit:getName() .. "paddles_contact",
								-- })
								
								if (lso.Converter.M_FT(plane.altitude) < 200) then
									self:showCommand(self.command.TOO_LOW)
								end
								if (
									plane.angleError > 0
									and math.sin(math.rad(plane.angleError)) * plane.distance < 650 -- 到下滑道垂足距离
									and math.abs(lso.math.getAzimuthError(plane.heading, deckAngle, true)) > 90
								)then
									-- Keep your turn in
									self:showCommand(self.command.KEEP_TURN)
								end
								if (
									math.abs(lso.math.getAzimuthError(plane.heading, deckAngle, true)) < 15
									or math.abs(plane.angleError) < 8
									-- and plane.gsError < 2.5 and plane.gsError > -1
								) then
									if (self:track(plane)) then
										return nil
									end
								end
								return timer.getTime() + 0.1
							else
								lso.LSO.contact = false
								lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
								lso.Tower:checkIn(plane.unit)
								return nil
							end
						else
							self.command.FOUL_DECK
								:onFinish(function()
									lso.LSO.contact = false
								end)
								:send(lso.Carrier.radio)
							return nil
						end
					end
					timer.scheduleFunction(paddleFrame, nil, timer.getTime() + 1)
					lso.LSO.contact = true
					return true
				end
			end
		end
	end
	return false
end


-- 着舰信号官开始指挥
-- 成功返回 true
-- 着舰信号官正忙返回 false
function lso.LSO:track(plane)
	if self.trackProcess ~= nil then
		return false
	end
	local callTheBall = 0
	local trackData = self.TrackData:new(plane)
	local trackCommand = function (cmd, check, timestamp)
		if check then
			if self:showCommand(cmd) then
				trackData:addCommand(cmd, timestamp)
			end
		end
	end
	local landFinish = function()
		self.trackProcess = nil
		lso.LSO.contact = false
		lso.process.initPlane(plane.unit)
	end
	local goAround = function()
		self.trackProcess = nil
		lso.LSO.contact = false
		if (lso.Carrier.needToTurn) then
			lso.process.changeStatus(plane.unit, lso.process.Status.DEPART)
		else
			lso.process.changeStatus(plane.unit, lso.process.Status.BREAK)
		end
		lso.menu.addMenu(plane.unit, lso.menu.Command.ABORT, lso.menu.handler.abort)
		lso.Tower:checkIn(plane.unit)
	end
	local trackFrame = function(args, trackTime)
		if (plane:updateData() and (not lso.Carrier.turning)) then -- 更新飞行数据
		
			-- 当剩余距离小于20m时停止指挥，开始连续检测是否成功钩上
			if (plane.rtg < 20) then
				local previousData = trackData:getData()
				if ((plane.speed - lso.Carrier:getSpeed()) < lso.Converter.KNOT_MS(20) or (previousData and (previousData.speed - plane.speed) > 6)) then -- 迅速减速，着舰完成
					lso.RadioCommand:new("lso.on_board", "LSO", "You're on board.", nil, 3, lso.RadioCommand.Priority.NORMAL)
						:send(lso.Carrier.radio)
					-- mist.message.add({
						-- text = "着舰完成",
						-- displayTime = 5,
						-- msgFor = {units={plane.unit:getName()}},
						-- name = plane.unit:getName() .. "done",
					-- })
					landFinish()
					return nil
				elseif (plane.rtg < -80 and (plane.speed - lso.Carrier:getSpeed()) > lso.Converter.KNOT_MS(40)) then -- 穿过着舰区，脱钩
					trackCommand(self.command.BOLTER, true, trackTime)
					goAround()
					return nil
				else
					return timer.getTime() + 0.01
				end
			end
			
			-- 记录新的飞行数据
			trackData:addData({
				heading = plane.heading,
				rtg = plane.rtg, -- range to go
				angle = plane.angleError,
				gs = plane.gs,
				aoa = plane.aoa,
				roll = plane.roll,
				atltitude = plane.point.y,
				speed = plane.speed,
				vs = plane.vs,
				timestamp = trackTime,
			})
			
			-- 计算历史飞行数据
			local rollVariance = lso.math.getVariance(trackData:getDataRecord("roll", 20))
			local vsVariance = lso.math.getVariance(trackData:getDataRecord("vs", 20))
			local aoaAvg = lso.math.getAverage(trackData:getDataRecord("aoa", 20))
			local aoaDiff = aoaAvg - plane.model.aoa
			
			-- 近距离时将角度误差转换为距离误差，以消除快速发散
			local angleError = plane.angleError * math.min(1, plane.rtg / 120)
			local gsError = plane.gsError * math.min(1, plane.rtg / 120)

			-- 判断是否需要复飞
		 	local waveOff = (plane.rtg > 30 and (
				math.abs(angleError) > 8
				or gsError > 3 or gsError < -1
				or (plane.rtg < 300 and gsError < -0.8)
			))
			if (waveOff) then
				trackCommand(self.command.WAVE_OFF, true, trackTime)
				goAround()
				return nil
			end

			-- 记录进入每个着舰阶段的时间
			if (trackData.processTime.start == nil and plane.rtg > 800) then
				trackData.processTime.start = trackTime
			elseif (trackData.processTime.middle == nil and plane.rtg <= 800 and plane.rtg > 400) then
				trackData.processTime.middle = trackTime
			elseif (trackData.processTime.close == nil and plane.rtg <= 400 and plane.rtg > 160) then
				trackData.processTime.close = trackTime
			elseif (trackData.processTime.ramp == nil and plane.rtg < 60) then
				trackData.processTime.ramp = trackTime
			end
			
			-- local timestamp = string.format("时间 %.3f", trackTime)
			-- local data = string.format("偏移距 %.3f\n方位角 %.3f", plane.rtg, plane.angle)
			-- local msg = string.format("标准下滑道 %.3f\n下滑道 %.3f", lso.Carrier.data.gs, plane.gs)
			-- local diff = string.format("偏移角 %.3f\n下滑道偏离 %.3f", plane.angleError, gsError)
			-- local aoa = string.format("攻角 %.3f\n平均攻角 %.3f\n攻角偏差 %.3f", plane.aoa, aoaAvg, aoaDiff)
			-- local vs = string.format("垂直速度 %.3f\n垂速变化 %.3f", plane.vs, vsVariance or 0)
			-- local roll = string.format("倾角 %.3f\n倾角变化 %.3f", plane.roll, rollVariance or 0)
			-- local length = string.format("数据数量 %d\n指令数量 %d", #trackData.data, #trackData.commands)
			-- mist.message.add({
				-- text = plane.unit:getTypeName() .. "\n".. timestamp .. "\n" .. data .. "\n" .. msg .. "\n" .. diff .. "\n" .. aoa .. "\n" .. vs.. "\n" .. roll.. "\n" .. length,
				-- displayTime = 5,
				-- msgFor = {units={plane.unit:getName()}},
				-- name = plane.unit:getName() .. "test",
			-- })
			
			if (
				(callTheBall == 0 or callTheBall == 1)
				and plane.distance < 1287 and plane.distance > 804 
			) then
				callTheBall = 1
				if (self:showCommand(self.command.CALL_BALL, nil, nil, {plane.number})) then
					callTheBall = 2
				end
			elseif (callTheBall == 2) then
				local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
				cmd = lso.RadioCommand:new(	"lso.BALL_CALL", plane.number, string.format("%s, %s ball, %.1f.", plane.number, plane.model.name, fuelMess), nil, 2, lso.RadioCommand.Priority.NORMAL)
				if (self:showCommand(cmd, plane.unit)) then
					callTheBall = 3
				end
			elseif (callTheBall == 3) then
				if (self:showCommand(self.command.ROGER_BALL)) then
					callTheBall = -1
				end
			end
			
			if callTheBall < 1 then

				-- 根据飞行数据下达指令
				-- 遵循“先爬升后加速，先减速后下高”原则
				trackCommand(self.command.TOO_LOW, 		(gsError < -0.6), 						trackTime)
				trackCommand(self.command.LOW, 			(gsError < -0.3 and gsError >= -0.6), 	trackTime)
				trackCommand(self.command.SLOW, 		(aoaDiff > 0.8), 						trackTime)
				
				trackCommand(self.command.LEFT, 		(angleError > 1.5), 					trackTime)
				trackCommand(self.command.RIGHT, 		(angleError < -1.5), 					trackTime)
				
				trackCommand(self.command.FAST, 		(aoaDiff < -0.8), 						trackTime)
				trackCommand(self.command.HIGH, 		(gsError > 0.6), 						trackTime)
				
				trackCommand(self.command.EASY, 		(vsVariance > 1 or rollVariance > 100), trackTime)
				
			end

			return timer.getTime() + 0.1
		else
			-- error("LSO onFrame lost unit.")
			self:showCommand(self.command.FOUL_DECK)
			goAround()
			return nil
		end
	end

	self.tracking = plane
	self.trackProcess = timer.scheduleFunction(trackFrame, nil, timer.getTime() + 2)
	return true
end


-- 主检测帧
function lso:onFrame()
	local point = lso.Carrier.unit:getPoint()
	local wh, ws = lso.utils.getWindInfo(point)
	lso.log(string.format("风向 %d, 风速 %d", math.deg(wh), lso.Converter.MS_KNOT(ws)), 1, true, "windData")

	-- 遍历所有飞机
	-- local allPlanes = coalition.getPlayers(lso.Carrier.unit:getCoalition())
	-- local lx, ly = lso.Carrier:getLandingPoint()
	-- for i, unit in ipairs(allPlanes) do
		-- local plane = lso.Plane.get(unit)
		-- if plane and plane:updateData() then
			-- local point = unit:getPoint()
			-- local t, p = atmosphere.getTemperatureAndPressure(point)
			-- local wh, ws = lso.utils.getWindInfo(point)
			-- mist.message.add({
				-- text =  string.format("风向 %.3f\n风速 %.3f\n气压\n%.3f\n%.3f\n真空速 %.3f\n示空速 %.3f\n气压高 %.3f", 
					-- math.deg(wh),
					-- lso.Converter.MS_KNOT(ws),
					-- (p / 100),
					-- lso.Converter.PA_INHG(p),
					-- lso.Converter.MS_KNOT(plane.speed),
					-- lso.Converter.MS_KNOT(lso.utils.getIndicatedAirSpeed(plane.unit)),
					-- lso.Converter.M_FT(lso.utils.getBaroAltitude(unit))
				-- ),
				-- displayTime = 2,
				-- msgFor = {units={plane.unit:getName()}},
				-- name = plane.name .. "data",
			-- })
		-- end
	-- end
	mist.message.add({
		text =  "主检测帧工作中",
		displayTime = 1,
		msgFor = {coa = {"all"}},
		name = "mainProcess",
	})
end

-- 全局事件处理器
lso.eventHandler = {}
function lso.eventHandler:onEvent(event)
	local status, err = pcall(function(event)
        if event == nil or event.initiator == nil then
            return false
        end
		if (
			world.event.S_EVENT_BIRTH == event.id
			) then
			lso.process.initPlane(event.initiator)
        end
		-- if (
			-- world.event.S_EVENT_LAND == event.id
			-- ) then
			-- lso.process.initPlane(event.initiator)
			-- if event.place == lso.Carrier.unit then
				-- mist.message.add({
					-- text = "着舰",
					-- displayTime = 5,
					-- msgFor = {units={event.initiator:getName()}},
					-- name = event.initiator:getName() .. "donedone",
				-- })
			-- end
        -- end
		if (
			world.event.S_EVENT_CRASH == event.id
			or world.event.S_EVENT_EJECTION == event.id
			or world.event.S_EVENT_DEAD == event.id
			or world.event.S_EVENT_PILOT_DEAD == event.id
			) then
			lso.process.removePlane(event.initiator)
        end
		return true
    end, event)
    if (not status) then
        env.error("Error while handling event")
    end
end

-- 初始化函数
function lso.init()
	if (not lso.Carrier:init()) then
		error("Carrier not ready.")
		-- error(carrier.unit, string.format("Carrier not ready. unsupported carrier type <%s>.", typeName))
	end
	lso.DB.init() -- 初始化数据库
	-- lso.mainProcess = lso.addCheckFrame(lso) -- 添加主检测帧程序
	lso.Carrier.frameID = lso.addCheckFrame(lso.Carrier) -- 添加航母检测帧程序
	lso.Marshal:init() -- 初始化 Marshal 模块
	lso.Tower.frameID = lso.addCheckFrame(lso.Tower) -- 添加 Tower 检测帧程序

	world.addEventHandler(lso.eventHandler)
	
	-- 遍历初始化所有飞机状态
	for unitName, plane in pairs(lso.DB.planes) do
		if (plane:updateData()) then
			lso.process.initPlane(plane.unit)
		end
	end
end


lso.init() -- 初始化


