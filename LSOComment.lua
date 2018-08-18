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
  ["POST"] = {},
}

function lso.Comment:addComment(section, comment)
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
    lso.Comment.addComment("POST", "LR")
  elseif(dist_land_horz < -3) then
    lso.Comment.addComment("POST", "LL")
  end

  --判断着舰时飞机坡度
  if(last_data.roll > 5) then
    lso.Comment.addComment("POST", "LRWD")
  elseif(last_data.roll < -5) then
    lso.Comment.addComment("POST", "LLWD")
  end

  lso.Comment.addComment("POST", "F")
  --计算评级
  
  --拼接简评
  local commentStr = ""
  
  for i,v in ipairs(lso.Comment)do
    for i,v2 in ipairs(v)do
      commentStr = commentStr .. v2 .. " "
    end
  end
  
  print(commentStr)
end

--模拟调用
local result = lso.test()