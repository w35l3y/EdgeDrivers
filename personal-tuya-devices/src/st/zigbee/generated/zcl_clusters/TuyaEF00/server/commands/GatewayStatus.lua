local data_types = require "st.zigbee.data_types"
local utils = require "st.zigbee.utils"
local log = require "log"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"


local GatewayStatus = {}
GatewayStatus.NAME = "GatewayStatusServer"
GatewayStatus.ID = 0x25
GatewayStatus.args_def = {
  {
    name = "transid",
    optional = false,
    data_type = data_types.Uint16,
    is_complex = false,
    is_array = false,
    default = 0x00,
  },
  {
    name = "status",
    optional = true,
    data_type = data_types.Uint8,
    is_complex = false,
    is_array = false,
    default = 0x01, -- 0=offline / 1=online / 2=timeout
  },
}

function GatewayStatus:get_fields()
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

GatewayStatus.get_length = utils.length_from_fields
GatewayStatus._serialize = utils.serialize_from_fields
GatewayStatus.pretty_print = utils.print_from_fields

--- Deserialize this command
---
--- @param buf buf the bytes of the command body
--- @return GatewayStatus
function GatewayStatus.deserialize(buf)
  local out = {}
  for _, v in ipairs(GatewayStatus.args_def) do
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
      log.debug("Missing command arg " .. v.name .. " for deserializing GatewayStatusServer")
    end
  end
  setmetatable(out, {__index = GatewayStatus})
  out:set_field_names()
  return out
end

function GatewayStatus:set_field_names()
  for _, v in ipairs(self.args_def) do
    if self[v.name] then
      self[v.name].field_name = v.name
    end
  end
end

--- Build a version of this message as if it came from the device
---
--- @param device st.zigbee.Device the device to build the message from
--- @return st.zigbee.ZigbeeMessageRx The full Zigbee message containing this command body
function GatewayStatus.build_test_rx(device)
  local out = {}
  local args = {}
  for i,v in ipairs(Toggle.args_def) do
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
  setmetatable(out, {__index = GatewayStatus})
  out:set_field_names()
  return GatewayStatus._cluster:build_test_rx_cluster_specific_command(device, out, "server")
end

--- Initialize the GatewayStatus command
---
--- @param self GatewayStatus the template class for this command
--- @param device st.zigbee.Device the device to build this message to
--- @return st.zigbee.ZigbeeMessageTx the full command addressed to the device
function GatewayStatus:init(device, transid, status)
  local out = {}
  local args = { transid, status or 1 }
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
    __index = GatewayStatus,
    __tostring = GatewayStatus.pretty_print
  })
  out:set_field_names()
  local msg = self._cluster:build_cluster_specific_command(device, out, "server")
  -- msg.body.zcl_header.seqno = data_types.Uint8(0x01)
  msg.body.zcl_header.frame_ctrl:set_disable_default_response()
  -- msg.body.zcl_header.frame_ctrl:set_mfg_specific()
  return msg
end

function GatewayStatus:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(GatewayStatus, {__call = GatewayStatus.init})

return GatewayStatus
