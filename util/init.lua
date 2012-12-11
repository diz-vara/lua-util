require 'torch'
require 'os'

util = {}


--------------------------------
-- Namespace functions
--------------------------------


-- Reload a lua module that has already been required.
-- (Useful when testing code from the repl, so you don't have to restart the
-- program.)
function util.reload(module)
  package.loaded[module] = nil
  require(module)
end


--------------------------------
-- Metatable functions
--------------------------------

-- Returns a table that will return the default value v when a key that has not
-- been set is indexed.
function util.table_with_default(v)
    local tbl = {}
    local mt = {__index = function () return v end}
    setmetatable(tbl, mt)
    return tbl
end


-- Set the __index function in the metatable of tbl, so that tbl[i] will
-- return the value of f(self, i).
function util.set_index_fn(tbl, fn)
    local mt = getmetatable(tbl) or {}
    rawset(mt, '__index', fn)
    setmetatable(tbl, mt)
end


-- Set the __len function in the metatable of tbl, so that #tbl will
-- return a valid size.
-- NOTE: doesn't work on tables until __len support is added in Lua 5.2.
function util.set_size_fn(tbl, fn)
    local mt = getmetatable(tbl) or {}
    rawset(mt, '__len', fn)
    setmetatable(tbl, mt)
end


--------------------------------
-- Map functions
--------------------------------


-- Return all of the keys in a table
function util.keys(tbl)
    local keys = {}

    for k,v in pairs(tbl) do
        table.insert(keys, k)
    end

    return keys
end


-- Return all of the values in a table
function util.vals(tbl)
    local vals = {}

    for k,v in pairs(tbl) do
        table.insert(vals, v)
    end

    return vals
end


--------------------------------
-- Tensor utility functions
--------------------------------


-- Returns true of obj is a torch.Tensor.
-- TODO: find out if there is a better way to inspect userdata objects...
function util.is_tensor(obj)
	return type(obj) == 'userdata' and obj.dim ~= nil
end


-- Returns true of obj is a function.
function util.is_fn(obj)
    return type(obj) == 'function'
end

--------------------------------
-- Table utility functions
--------------------------------

-- Returns true if the two tables contain the same values.
-- NOTE: only does a shallow equality comparison by value.
function util.table_eq(a, b)
    return unpack(a) == unpack(b)
end

-- Returns true of obj is a table.
function util.is_table(obj)
    return type(obj) == 'table'
end


-- Returns a new shallow copy of a table, with original metatable
function util.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return setmetatable(t2, getmetatable(t))
end


-- Recursively deep copy all values in t, works for nested tables
function util.deep_copy(t)
    if type(t) ~= 'table' then
      return t
    end

    local mt = getmetatable(t)
    local res = {}

    for k,v in pairs(t) do
        if type(v) == 'table' then
           v = util.deep_copy(v)
        elseif util.is_tensor(v) then
           res[k] = v:clone()
        else
           res[k] = v
        end
    end

    setmetatable(res,mt)
    return res
end


-- Recursively copies elements of table b into table a, overwriting any keys that have
-- values in both tables to be the values in table b.
function util.merge(a, b)
    for k, v in pairs(b) do
        if (type(v) == "table") and (type(a[k] or false) == "table") then
            util.merge(a[k], b[k])
        else
            a[k] = v
        end
    end

    return a
end


-- Returns a new table containing the sequential (numeric indices) elements of
-- tables a and b.
function util.concat(a, b)
    local res = {}
    for _, v in ipairs(a) do
        table.insert(res, v)
    end

    for _, v in ipairs(b) do
        table.insert(res, v)
    end

    return res
end

-- Pause the process for n seconds.
function util.sleep(n)
    os.execute("sleep " .. n)
end


--------------------------------
-- Argument handling
--------------------------------

-- Default argument parsing that takes the arg table, mandatory arg list with
-- optional type per argument, and optional arg list with default values per arg.
-- e.g.
--
--   -- where a and b are mandatory args
--   args = util.args(..., {'a', 'b'}) 
--
--   -- or with a,b,c mandatory and foo optional with a default
--   args = util.args(..., {'a', 'b', 'c' = 'string'}, {'foo' = 2})
--
function util.args(argv, required, optional)
   argv = util.merge(optional, argv)

   for k, v in pairs(required) do
      local name, arg_type

      if type(k) == 'number' then
         name = v
         arg_type = nil
      else
         name = k
         arg_type = v
      end

      --print('check arg: ', name, ' of type: ', arg_type, " ==> ", argv[name])
      if argv[name] == nil then
         error(string.format('Missing argument: \'%s\'', name), 3)
      end

      if arg_type and type(argv[name]) ~= arg_type then
         error(string.format('Incorrect argument type for arg: \'%s\' that should be a %s',
                             name, arg_type),
               3)
      end

      if #argv ~= (#util.keys(required) + #util.keys(optional)) then
         local all_keys = util.concat(util.keys(required), util.keys(optional))
         local keymap = {}
         for _, v in ipairs(all_keys) do
            keymap[v] = true
         end

         for k,v in pairs(argv) do
            if keymap[k] == nil then
               error(string.format('Unknown argument found in arglist: \'%s\'', k), 3)
            end
         end
      end
   end

   return argv
end

