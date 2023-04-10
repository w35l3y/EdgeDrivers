-- 01 A7 40

local data_types = require "st.zigbee.data_types"
local utils = require "st.zigbee.utils"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local McuVersionResponse = {}
McuVersionResponse.NAME = "McuVersionResponse"
McuVersionResponse.ID = 0x11
McuVersionResponse.args_def = {
  {
    name = "transid",
    optional = false,
    data_type = tuya_types.Uint16,
    is_complex = false,
    is_array = false,
    default = 0x00,
  },
  {
    name = "data",
    optional = false,
    data_type = tuya_types.McuVersion,
    is_complex = false,
    is_array = false,
    default = 0x00,
  },
}

function McuVersionResponse:get_fields()
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

McuVersionResponse.get_length = utils.length_from_fields
McuVersionResponse._serialize = utils.serialize_from_fields
McuVersionResponse.pretty_print = utils.print_from_fields

function McuVersionResponse.deserialize(buf)
  local out = {}
  for _, v in ipairs(McuVersionResponse.args_def) do
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
      log.debug("Missing command arg " .. v.name .. " for deserializing McuVersionResponse")
    end
  end
  setmetatable(out, {__index = McuVersionResponse})
  out:set_field_names()
  return out
end

function McuVersionResponse:set_field_names()
  for _, v in ipairs(self.args_def) do
    if self[v.name] then
      self[v.name].field_name = v.name
    end
  end
end

function McuVersionResponse.build_test_rx(device)
  local out = {}
  local args = {}
  for i,v in ipairs(McuVersionResponse.args_def) do
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
  setmetatable(out, {__index = McuVersionResponse})
  out:set_field_names()
  return McuVersionResponse._cluster:build_test_rx_cluster_specific_command(device, out, "client")
end

function McuVersionResponse:init(device)
  local out = {}
  local args = {}
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
    __index = McuVersionResponse,
    __tostring = McuVersionResponse.pretty_print
  })
  out:set_field_names()
  return self._cluster:build_cluster_specific_command(device, out, "client")
end

function McuVersionResponse:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(McuVersionResponse, {__call = McuVersionResponse.init})

return McuVersionResponse
