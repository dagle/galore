local Ordered = {}

function Ordered.insert(t,k,v)
	if v == nil then
		t.remove(k)
		return
	end
	if not rawget(t._values, k) then
		table.insert(t._list, k)
		t._values[k] = v
	end
end

local function find(t, v)
  for i,v2 in ipairs(t) do
    if v == v2 then
      return i
    end
  end
end

function Ordered.remove(t, k)
	local v = t._values[k]
	if v then
		table.remove(t._list, find(t._list, k))
		t._values[k] = nil
	end
end

function Ordered.index(t, k)
	return rawget(t._values, k)
end

function Ordered.pairs(t)
  local i = 0
  return function()
    i = i + 1
    local key = t._list[i]
    if key ~= nil then
      return key, t._values[key]
    end
  end
end

function Ordered.new()
	local tbl = {_values={}, _list={}}
	return setmetatable(tbl,
    {__newindex=Ordered.insert,
    __len=function(t) return #t._list end,
    __pairs=Ordered.pairs, -- doesn't work in luajit
    __index=tbl._values
    })
end

return Ordered
