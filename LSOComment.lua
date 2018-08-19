dofile("DumpData.lua")

--SmartLSO简评与评分模块
lso.Comment = {}

lso.Comment.commentData = {
	["PRE"] = {},
	["AW"] = {},
	["X"] = {},
	["IM"] = {},
	["IC"] = {},
	["AR"] = {},
	["POST"] = {}
}

lso.Comment.ShorthandNote = {
	x = {}
}

function lso.Comment:addComment(section, comment, level)
	switch(section,
		{"PRE",function()
			table.insert(lso.Comment.commentData["PRE"], comment)
			return true
		end},
		{"AW",function()
			table.insert(lso.Comment.commentData["AW"], comment)
			return true
		end},
		{"X",function()
			table.insert(lso.Comment.commentData["X"], comment)
			return true
		end},
		{"IM",function()
			table.insert(lso.Comment.commentData["IM"], comment)
			return true
		end},
		{"IC",function()
			table.insert(lso.Comment.commentData["IC"], comment)
			return true
		end},
		{"AR",function()
			table.insert(lso.Comment.commentData["AR"], comment)
			return true
		end},
		{"POST",function()
			table.insert(lso.Comment.commentData["POST"], comment)
			return true
		end},
		{nil,function()
			return true
		end}
	)
end

--处理程序入口
function lso.Comment:process(flightData, result, cause, wire)
  
	--遍历处理
	for i,v in ipairs(flightData.data)
		do print(v.timestamp .. "," .. v.speed)
	end  

	--最后一条数据
	local last_data = flightData.data[#flightData.data]

	--计算着舰横向偏移
	local dist_land_horz = math.sin(last_data.angleError * math.pi / 180) * last_data.distance
	--判断是否有过大偏差
	if(dist_land_horz > 3) then
		lso.Comment:addComment("POST", "LL")
	elseif(dist_land_horz < -3) then
		lso.Comment:addComment("POST", "LR")
	end

	--判断着舰时飞机坡度
	if(last_data.roll > 5) then
		lso.Comment:addComment("POST", "LLWD")
	elseif(last_data.roll < -5) then
		lso.Comment:addComment("POST", "LRWD")
	end

	--test
	lso.Comment:addComment("PRE", "AA")
	lso.Comment:addComment("X", "H")
	lso.Comment:addComment("X", "F")
	lso.Comment:addComment("POST", "LRWD")

	--计算评级
	local gradeStr = "(OK)"

	--拼接简评
	local commentStr = ""

	--PRE
	local preStr = ""
	for i,v in ipairs(lso.Comment.commentData["PRE"])do preStr = preStr .. v .. " " end
	if(preStr ~= "") then commentStr = commentStr .. preStr end

	--X
	local xStr = ""
	for i,v in ipairs(lso.Comment.commentData["X"])do xStr = xStr .. v end
	if(xStr ~= "") then commentStr = commentStr .. xStr .. "X" .. " " end

	--IM
	local imStr = ""
	for i,v in ipairs(lso.Comment.commentData["IM"])do imStr = imStr .. v end
	if(imStr ~= "") then commentStr = commentStr .. imStr .. "IM" .. " " end

	--IC
	local icStr = ""
	for i,v in ipairs(lso.Comment.commentData["IC"])do commentStr = commentStr .. v end
	if(icStr ~= "") then commentStr = commentStr .. icStr .. "IC" .. " " end

	--AR
	local arStr = ""
	for i,v in ipairs(lso.Comment.commentData["AR"])do commentStr = commentStr .. v end
	if(arStr ~= "") then commentStr = commentStr .. arStr .. "AR" .. " " end

	--POST
	local postStr = ""
	for i,v in ipairs(lso.Comment.commentData["POST"])do postStr = postStr .. v .. " " end
	if(postStr ~= "") then commentStr = commentStr .. postStr end

	print(commentStr .. "= " .. gradeStr)
	return {["commentStr"] = commentStr, ["Grade"] = gradeStr}
end

--模拟调用
local result = lso.test()