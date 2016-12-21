-- Quick and dirty module including some helper methods

M = {}

function tprint(t, indent)
  function printShit(k, v, indent)
  	--if k == "com" then
  	  print(string.rep(" ",indent)..k," | ",v)
  	--end
  end
  if not indent then indent = 0 end
  if type(t) == "table" then
    for k,v in pairs(t) do
      if type(v)=="table" then
        printShit(k, v, indent)
        tprint(v, indent+1)
      else
        printShit(k, v, indent)
      end
    end
  else
    print(type(t), t)
  end
end

function orderedPairs(t)

    local function orderedNext(t, state)

        local function __genOrderedIndex( t )
            local orderedIndex = {}
            for key in pairs(t) do
                table.insert( orderedIndex, key )
            end
            table.sort( orderedIndex )
            return orderedIndex
        end
        if state == nil then
            -- the first time, generate the index
            t.__orderedIndex = __genOrderedIndex( t )
            key = t.__orderedIndex[1]
            return key, t[key]
        end
        key = nil
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
        if key then
            return key, t[key]
        end
        t.__orderedIndex = nil
        return
    end
    return orderedNext, t, nil
end

-- TODO Move this to another file
function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

M.tprint = tprint
M.orderedPairs = orderedPairs

return M