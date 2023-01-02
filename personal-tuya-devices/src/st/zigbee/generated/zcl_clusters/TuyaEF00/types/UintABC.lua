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

--- @class st.zigbee.data_types.UintABC: st.zigbee.data_types.DataType
---
--- Classes being created using the UintABC class represent Zigbee data types whose lua "value" is stored
--- as an unsigned number.  In general these are the Zigbee data types Uint8-Uint56 represented by IDs 0x20-0x26.
--- Uint64 has to be treated differently due to lua limitations.  In addition there are several other ID types
--- that derive their behavior from Uint as well.
local UintABC = {}

--- This function will create a new metatable with the appropriate functionality for a Zigbee Uint
--- @param base table the base meta table, this will include the ID and NAME of the type being represented
--- @param byte_length number the length in bytes of this Uint
function  UintABC.new_mt(base, byte_length, little_endian)
  local mt = {}
  mt.__index = base
  mt.__index.byte_length = byte_length
  mt.__index.little_endian = little_endian
  mt.__index.is_fixed_length = true
  if base.is_discrete == nil then
    mt.__index.is_discrete = false
  end
  mt.__index._serialize = function(s)
    s:check_if_valid(s.value)
    return st_utils.serialize_int(s.value, s.byte_length, false, s.little_endian)
  end
  mt.__index.get_length = function(self)
    return self.byte_length
  end
  mt.__index.deserialize = function(buf, field_name)
    local o = {}
    setmetatable(o, mt)
    o.field_name = field_name
    o.byte_length = byte_length
    o.little_endian = little_endian
    o.value = buf:read_int(byte_length, false, little_endian)
    return o
  end
  mt.__index.pretty_print = function(self)
    if self.value == nil then
      return "Uninitialized " .. self.NAME
    end
    local pattern = (self.little_endian and "<I" or ">I") .. self.byte_length
    return string.format("%s: 0x%s (%s)", self.field_name or self.NAME, zb_utils.pretty_print_hex_str(string.pack(pattern, self.value)), self.little_endian and "LE" or "BE")
  end
  mt.__index.check_if_valid = function(self, int_val)
    if type(int_val) ~= "number" or int_val ~= math.floor(int_val) then
      error(string.format("%s value must be an integer", self.NAME), 2)
    elseif int_val >= (1 << (byte_length * 8)) then
      error(string.format("%s too large for type", self.NAME), 2)
    elseif int_val < 0 then
      error(string.format("%s value must be positive", self.NAME), 2)
    end
  end
  mt.__newindex = function(self, k, v)
    if k == "value" then
      self:check_if_valid(v)
      rawset(self, k, v)
    else
      rawset(self, k, v)
    end
  end
  mt.__call = function(orig, int_val)
    local o = {}
    setmetatable(o, mt)
    o.value = int_val
    return o
  end
  mt.__tostring = function(self)
    return self:pretty_print()
  end
  return mt
end
return UintABC
