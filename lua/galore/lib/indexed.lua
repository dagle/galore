local Ordered = {}

function Ordered.insert(t, k, v)
  if v == nil then
    t.remove(k)
    return
  end
  local idx = rawget(t._values, k)
  if not idx then
    table.insert(t._list, v)
    idx = #t._list
    t._values[k] = idx
  else
    t._list[idx] = v
  end
end

function Ordered.remove(t, k)
  local idx = rawget(t._values, k)
  if idx then
    table.remove(t._list, idx)
    t._values[k] = nil
  end
end

function Ordered.index(t, k)
  if type(k) == "number" then
    return t._list[k]
  else
    local idx = rawget(t._values, k)
    return t._list[idx]
  end
end

function Ordered._pairs(t, k)
  local nkey, idx = next(t._values, k)
  if nkey then
    return nkey, t._list[idx]
  end
end

function Ordered.pairs(t)
  return Ordered._pairs, t, nil
end

function Ordered._ipairs(t, i)
  i = i + 1
  local v = t._list[i]
  if v then
    return i, v
  end
end

function Ordered.ipairs(t)
  return Ordered._ipairs, t, 0
end

function Ordered.len(t)
  return #t._list
end

function Ordered.new()
  local tbl = { _values = {}, _list = {} }
  return setmetatable(tbl, {
    __newindex = Ordered.insert,
    __len = Ordered.len, -- doesn't work in luajit
    __pairs = Ordered.pairs, -- doesn't work in luajit
    __ipairs = Ordered.pairs, -- doesn't work in luajit
    __index = Ordered.index,
  })
end
