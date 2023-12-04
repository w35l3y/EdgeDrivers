-- Copyright 2021 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
local zb_utils = require "st.zigbee.utils"
local st_utils = require "st.utils"

--- @class st.zigbee.data_types.IntABC: st.zigbee.data_types.DataType
---
--- Classes being created using the IntABC class represent Zigbee data types whose lua "value" is stored
----- as a signed number.  In general these are the Zigbee data types Int8-Int56 represented by IDs 0x28-0x2E.
----- Int64 has to be treated differently due to lua limitations.
local IntABC = {}

--- This function will create a new metatable with the appropriate functionality for a Zigbee Int
--- @param base table the base meta table, this will include the ID and NAME of the type being represented
--- @param byte_length number the length in bytes of this Int
function IntABC.new_mt(base, byte_length, little_endian)
  local mt = {}
  mt.__index = base or {}
  mt.__index.byte_length = byte_length
  mt.__index.little_endian = little_endian
  mt.__index.is_fixed_length = true
  mt.__index.is_discrete = false
  mt.__index._serialize = function(s)
    return st_utils.serialize_int(s.value, s.byte_length, true, s.little_endian)
  end
  mt.__index.get_length = function(self)
    return self.byte_length
  end
  mt.__index.deserialize = function(buf, field_name)
    local o = {}
    setmetatable(o, mt)
    o.byte_length = byte_length
    o.little_endian = little_endian
    o.value = buf:read_int(byte_length, true, little_endian)
    o.field_name = field_name
    return o
  end
  mt.__index.pretty_print = function(self)
    if self.value == nil then
      return "Uninitialized " .. self.NAME
    end
    local pattern = (self.little_endian and "<I" or ">I") .. self.byte_length
    return string.format("%s: 0x%s (%s)", self.field_name or self.NAME, zb_utils.pretty_print_hex_str(string.pack(pattern, self.value)), self.little_endian and "LE" or "BE")
  end
  mt.__call = function(orig, val)
    if type(val) ~= "number" or val ~= math.floor(val) then
      error(string.format("%s value must be an integer", orig.NAME), 2)
    elseif val >= (1 << ((byte_length * 8) - 1)) then
      error(string.format("%s too large for type", orig.NAME), 2)
    elseif val < -1 * (1 << ((byte_length * 8) - 1)) then
      error(string.format("%svalue too negative for type", orig.NAME), 2)
    end
    local o = {}
    setmetatable(o, mt)
    o.value = val
    return o
  end
  mt.__tostring = function(self)
    return self:pretty_print()
  end
  return mt
end

return IntABC
