local lso = {}
lso.logger = mist.Logger:new("LSO", "info")


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
	return frameTime + 0.5
end

timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)

function lso.init()
	local carrier = {}
	local unit = Unit.getByName(lso.carrierName)
	local typeName = unit:getTypeName()
	for k, data in pairs(lso.data.carriers) do
		if (data.name == typeName) then
			carrier.data = data
			carrier.unit = unit
			break
		end
	end
	assert(carrier.unit, "Carrier not ready.")
	lso.carrier = carrier
end

lso.data = {}
lso.data.carriers = {
	KUZ = {
		name = "KUZNECOW",
		offset = {58, 14.5},
		height = 18.5,
		deck = 8,
		gs = 4,
	}
}

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

function lso.utils.tableContains(t, k)
	for key, val in pairs(t) do
		if (key == k) then
			return true
		end
	end
	return false
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

function  lso.utils.getLandingPoint()
	local carrierPoint = lso.carrier.unit:getPoint()
	local carrierHeadding = mist.getHeading(lso.carrier.unit, true)
	local cx, cy = lso.utils.math.getOffsetPoint(carrierPoint.z, carrierPoint.x, carrierHeadding, lso.carrier.data.offset[1])
	local bx, by = lso.utils.math.getOffsetPoint(cx, cy ,carrierHeadding + math.pi * 0.5, lso.carrier.data.offset[2])
	return bx, by
end


function lso.utils.getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - lso.carrier.data.height)/distance))
end

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

function lso.utils.getDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

lso.test = {}

function lso.test:onFrame()
	local plane = Unit.getByName("plane")
	local planePoint = plane:getPoint()
	local lx, ly = lso.utils.getLandingPoint()

	local pointOffset = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
	local bearing = lso.utils.math.getBearing(lx, ly, planePoint.z, planePoint.x)
	local angleOffset = lso.utils.getAngleOffset(bearing, true)
	local gs = lso.utils.getGlideSlope(pointOffset, planePoint.y)

	local data = string.format("偏移距 %.3f\n方位角 %.3f", pointOffset, math.deg(bearing))
	local msg = string.format("偏离角 %.3f\n下滑道 %.3f", angleOffset, gs)

	mist.message.add({
		text = data .. "\n" .. msg,
		displayTime = 5,
		msgFor = {coa = {"all"}},
		name = "test",
	})
end


lso.approch = {}
lso.approch.tracking = {}
lso.approch.status = {
	HIGH = 1,
	LOW = 2,
	LEFT = 3,
	RIGHT = 4,
}

lso.approch.message = {
	[lso.approch.status.HIGH] = "You're high!",
	[lso.approch.status.LOW] = "Power!",
	[lso.approch.status.LEFT] = "Right for lineup!",
	[lso.approch.status.RIGHT] = "Come left!",
}

lso.approch.commands = {}
function lso.approch.showCommand(unit, msg, tag)
	local unitName = unit:getName()
	lso.approch.commands[unitName .. tag] = mist.message.add({
		text = "LSO: " .. msg,
		displayTime = 10,
		msgFor = {units={unitName}},
		name = unitName .. tag,
	})
end
function lso.approch.dismissCommand(unit, tag)
	local unitName = unit:getName()
	if (lso.approch.commands[unitName .. tag]) then
		mist.message.removeById(lso.approch.commands[unitName .. tag])
		lso.approch.commands[unitName .. tag] = nil
	end
end

lso.approch.context = {}
lso.approch.context.status = {}

function lso.approch.context.getStatus(unit)
	local unitStatus = lso.approch.context.status[unit:getName()]
	if (not unitStatus) then
		unitStatus = {}
		lso.approch.context.status[unit:getName()] = unitStatus
	end
	return unitStatus
end
function lso.approch.context.addStatus(unit, status)
	local unitStatus = lso.approch.context.getStatus(unit)
	if (not lso.utils.listContains(unitStatus, status)) then
		table.insert(unitStatus, status)
		lso.approch.showCommand(unit, lso.approch.message[status], "status" .. status)
		return true
	else
		return false
	end
end
function lso.approch.context.removeStatus(unit, status)
	local unitStatus = lso.approch.context.getStatus(unit)
	if (lso.utils.listContains(unitStatus, status)) then
		lso.utils.listRemove(unitStatus, status)
		lso.approch.dismissCommand(unit, "status" .. status)
		return true
	else
		return false
	end
end
function lso.approch.context.setStatus(unit, status, toggle)
	if (toggle) then
		lso.approch.context.addStatus(unit, status)
	else
		lso.approch.context.removeStatus(unit, status)
	end
end
function lso.approch.context.hasStatus(unit, status)
	local unitStatus = lso.approch.context.getStatus(unit)
	return lso.utils.listContains(unitStatus, status)
end

function lso.approch:onFrame()
	local allPlanes = mist.makeUnitTable({"[all][plane]"})
	local lx, ly = lso.utils.getLandingPoint()

	for i, planeName in ipairs(allPlanes) do
		local plane = Unit.getByName(planeName)
		local planePoint = plane:getPoint()
		local range = lso.utils.getDistance(planePoint.z, planePoint.x, lx, ly)
		local bearing = lso.utils.math.getBearing(lx, ly, planePoint.z, planePoint.x)
		local angleOffset = lso.utils.getAngleOffset(bearing, true)
		local gs = lso.utils.getGlideSlope(range, planePoint.y)

		local track = (range <= 3200 and range > 50 and math.abs(angleOffset) <= 20 and math.abs(gs - lso.carrier.data.gs) < 2)

		local data = string.format("偏移距 %.3f\n方位角 %.3f", range, math.deg(bearing))
		local msg = string.format("偏离角 %.3f\n下滑道 %.3f", angleOffset, gs)

		mist.message.add({
			text = data .. "\n" .. msg .. "\n开始监视 " .. (track and "true" or "false"),
			displayTime = 5,
			msgFor = {coa = {"all"}},
			name = "test",
		})

		if (track) then
			lso.approch.tracking[plane:getName()] = {
				unit = plane,
				range = range,
				angle = angleOffset,
				gs = gs,
			}
		else
			lso.approch.tracking[plane:getName()] = nil
		end
	end

	for name, plane in pairs(lso.approch.tracking) do
		lso.approch.context.setStatus(plane.unit, lso.approch.status.HIGH, (plane.gs - lso.carrier.data.gs > 0.5))
		lso.approch.context.setStatus(plane.unit, lso.approch.status.LOW, (plane.gs - lso.carrier.data.gs < -0.4))
		lso.approch.context.setStatus(plane.unit, lso.approch.status.LEFT, (plane.angle > 1.5))
		lso.approch.context.setStatus(plane.unit, lso.approch.status.RIGHT, (plane.angle < -1.5))
	end

end

lso.init()
-- lso.addCheckFrame(lso.test)
lso.approch.id = lso.addCheckFrame(lso.approch)
