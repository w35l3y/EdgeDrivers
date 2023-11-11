local log = require "log"
local utils = require "st.zigbee.utils"
local data_types = require "st.zigbee.data_types"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-universal-docking-access-standard?id=K9ik6zvofpzql#subtitle-8-DP%20data%20format

local DatapointSegment = {}
DatapointSegment.NAME = "DatapointSegment"
DatapointSegment.get_fields = function(self)
  return {
    self.dpid,
    self.type,
    self.length,
    self.value
  }
end
DatapointSegment.set_field_names = function(self)
  self.dpid.field_name = "dpid"
  self.type.field_name = "type"
  self.length.field_name = "length"
  self.value.field_name = "value"
end

DatapointSegment.get_length = utils.length_from_fields

DatapointSegment._serialize = utils.serialize_from_fields

DatapointSegment.pretty_print = utils.print_from_fields

DatapointSegment.deserialize = function(buf)
  local o = {}
  o.dpid = data_types.Uint8.deserialize(buf)
  o.type = tuya_types.DatapointSegmentType.deserialize(buf)
  o.length = tuya_types.Uint16.deserialize(buf)
  local map_length_to_type = {
    [1] = data_types.Bitmap8,
    [2] = tuya_types.Bitmap16, -- BigEndian ?
    [4] = tuya_types.Bitmap32, -- BigEndian ?
  }
  
  local map_id_to_type = {
    [tuya_types.DatapointSegmentType.RAW]      = generic_body.GenericBody,
    [tuya_types.DatapointSegmentType.STRING]   = data_types.CharString,
    [tuya_types.DatapointSegmentType.BOOLEAN]  = data_types.Boolean,
    [tuya_types.DatapointSegmentType.VALUE]    = tuya_types.Int32, -- BigEndian ?
    [tuya_types.DatapointSegmentType.ENUM]     = data_types.Enum8,
    [tuya_types.DatapointSegmentType.BITMAP]   = map_length_to_type[o.length.value],
  }
  
  o.value = map_id_to_type[o.type.value].deserialize(buf)

  setmetatable(o, {
    __index = DatapointSegment,
    __tostring = DatapointSegment.pretty_print,
  })
  o:set_field_names()
  return o
end

local types = {
  [generic_body.GenericBody] = tuya_types.DatapointSegmentType.RAW,
  [data_types.CharString.ID] = tuya_types.DatapointSegmentType.STRING,
  [data_types.Boolean.ID] = tuya_types.DatapointSegmentType.BOOLEAN,
  [data_types.Enum8.ID] = tuya_types.DatapointSegmentType.ENUM,
  [tuya_types.Int32.ID] = tuya_types.DatapointSegmentType.VALUE,
  [data_types.Bitmap8.ID] = tuya_types.DatapointSegmentType.BITMAP,
  [tuya_types.Bitmap16.ID] = tuya_types.DatapointSegmentType.BITMAP,
  [tuya_types.Bitmap32.ID] = tuya_types.DatapointSegmentType.BITMAP,
}

-- untested
DatapointSegment.init = function(self, dpid, value)
  --log.info(string.format("DatapointSegment.init: %s %s", v.type, v.value))
  local _type = types[value.ID] or tuya_types.DatapointSegmentType.RAW
  local o = {}
  o.dpid = data_types.Uint8(dpid)
  o.type = tuya_types.DatapointSegmentType(_type)
  o.length = tuya_types.Uint16(value:get_length())
  o.value = value
  setmetatable(o, {
    __index = self,
    __tostring = self.pretty_print
  })
  o:set_field_names()
  return o
end

setmetatable(DatapointSegment, {__call = DatapointSegment.init})
return DatapointSegment
