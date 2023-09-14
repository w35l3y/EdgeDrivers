local data_types = require "st.zigbee.data_types"
local utils = require "st.zigbee.utils"
local log = require "log"
local cluster_base = require "st.zigbee.cluster_base"
local ButtonStatus = require "st.zigbee.generated.zcl_clusters.OnOff.types.ButtonStatus"

-----------------------------------------------------------
-- OnOff command ButtonPress
-----------------------------------------------------------

--- @class st.zigbee.zcl.clusters.OnOff.ButtonPress
--- @alias ButtonPress
---
--- @field public ID number 0xFD the ID of this command
--- @field public NAME string "ButtonPress" the name of this command
local ButtonPress = {}
ButtonPress.NAME = "ButtonPress"
ButtonPress.ID = 0xFD
ButtonPress.args_def = {
  {
    name = "button_status",
    optional = false,
    data_type = ButtonStatus,
    is_complex = false,
    is_array = false,
  },
}

function ButtonPress:get_fields()
  return cluster_base.command_get_fields(self)
end

ButtonPress.get_length = utils.length_from_fields
ButtonPress._serialize = utils.serialize_from_fields
ButtonPress.pretty_print = utils.print_from_fields

--- Deserialize this command
---
--- @param buf buf the bytes of the command body
--- @return ButtonPress
function ButtonPress.deserialize(buf)
  return cluster_base.command_deserialize(ButtonPress, buf)
end

function ButtonPress:set_field_names()
  cluster_base.command_set_fields(self)
end

--- Build a version of this message as if it came from the device
---
--- @param device st.zigbee.Device the device to build the message from
--- @return st.zigbee.ZigbeeMessageRx The full Zigbee message containing this command body
function ButtonPress.build_test_rx(device, button_status)
  local args = { button_status }

  return cluster_base.command_build_test_rx(ButtonPress, device, args, "server")
end

--- Initialize the ButtonPress command
---
--- @param self ButtonPress the template class for this command
--- @param device st.zigbee.Device the device to build this message to
--- @return st.zigbee.ZigbeeMessageTx the full command addressed to the device
function ButtonPress:init(device, button_status)
  local args = { button_status }

  return cluster_base.command_init(self, device, args, "server")
end

function ButtonPress:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(ButtonPress, {__call = ButtonPress.init})

return ButtonPress
