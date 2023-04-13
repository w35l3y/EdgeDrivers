local log = require('log')
local utils = require "st.zigbee.utils"
local data_types = require "st.zigbee.data_types"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-universal-docking-access-standard?id=K9ik6zvofpzql#subtitle-8-DP%20data%20format

local McuSyncTimeData = {}
McuSyncTimeData.NAME = "McuSyncTimeData"
McuSyncTimeData.args_def = {
  {
    name = "standardTimestamp",
    optional = false,
    data_type = tuya_types.UtcTime,
    is_complex = false,
    is_array = false,
  },
  {
    name = "localTimestamp",
    optional = false,
    data_type = tuya_types.UtcTime,
    is_complex = false,
    is_array = false,
  },
}

McuSyncTimeData.get_fields = function(self)
  local fields = {}
  for _, v in ipairs(self.args_def) do
    if v.is_array then
      if v.array_length_size ~= 0 then
        fields[#fields + 1] = self[v.name .. "_length"]
      end
      if self[v.name .. "_list"] then
        for _, entry in ipairs(self[v.name .. "_list"]) do
          fields[#fields + 1] = entry
        end
      end
    else
      if self[v.name] then
        fields[#fields + 1] = self[v.name]
      end
    end
  end
  return fields
end

McuSyncTimeData.set_field_names = function(self)
  for _, v in ipairs(self.args_def) do
    if self[v.name] then
      self[v.name].field_name = v.name
    end
  end
end

McuSyncTimeData.get_length = utils.length_from_fields

McuSyncTimeData._serialize = utils.serialize_from_fields

McuSyncTimeData.pretty_print = utils.print_from_fields

McuSyncTimeData.deserialize = function(buf)
  local out = {}
  for _, v in ipairs(McuSyncTimeData.args_def) do
    if buf:remain() > 0 then
      if v.is_array then
        if v.array_length_size ~= 0 then
          local entry_name = v.name .. "_length"
          local len = v.array_length_size or 1
          -- Start a 1 byte lenght at Uint8 and increment from there
          local len_data_type_id = 0x1F + len
          out[entry_name] = data_types.parse_data_type(len_data_type_id, buf, entry_name)
        end
        local entry_name = v.name .. "_list"
        out[entry_name] = {}
        while buf:remain() > 0 do
          out[entry_name][#out[entry_name] + 1] = v.data_type.deserialize(buf)
        end
      else
        out[v.name] = v.data_type.deserialize(buf)
      end
    elseif not v.optional then
      log.debug("Missing command arg " .. v.name .. " for deserializing McuSyncTimeData")
    end
  end
  setmetatable(out, {
    __index = McuSyncTimeData,
    __tostring = McuSyncTimeData.pretty_print
  })
  out:set_field_names()
  return out
end

-- untested
McuSyncTimeData.init = function(self, tzOffset)
  local out = {}
  local args = { os.time(os.date('!*t')), os.time(os.date('*t')) + 60 * (type(tzOffset) ~= "userdata" and tzOffset or 0) }
  if #args > #self.args_def then
    error(self.NAME .. " received too many arguments")
  end
  for i,v in ipairs(self.args_def) do
    if v.optional and args[i] == nil then
      out[v.name] = nil
    elseif not v.optional and args[i] == nil then
      out[v.name] = data_types.validate_or_build_type(v.default, v.data_type, v.name)   
    elseif v.is_array then
      local validated_list = {}
      for j, entry in ipairs(args[i]) do
        validated_list[j] = data_types.validate_or_build_type(entry, v.data_type, v.name .. tostring(j))
      end
      if v.array_length_size ~= 0 then
        local len_name =  v.name .. "_length"
        local len = v.array_length_size or 1
        -- Start a 1 byte lenght at Uint8 and increment from there
        local len_data_type = data_types.get_data_type_by_id(0x1F + len)
        out[len_name] = data_types.validate_or_build_type(#validated_list, len_data_type, len_name)
      end
      out[v.name .. "_list"] = validated_list
    else
      out[v.name] = data_types.validate_or_build_type(args[i], v.data_type, v.name)
    end
  end
  setmetatable(out, {
    __index = self,
    __tostring = self.pretty_print
  })
  out:set_field_names()
  return out
end

setmetatable(McuSyncTimeData, {__call = McuSyncTimeData.init})
return McuSyncTimeData
