local data_types = require "st.zigbee.data_types"
local zb_const = require "st.zigbee.constants"
local zcl_clusters = require "st.zigbee.zcl.clusters"

zb_const.ZGP_PROFILE_ID = 0xA1E0

zcl_clusters.bind_request_id = 0x0021
zcl_clusters.id_to_name_map[zcl_clusters.bind_request_id] = "BindRequest"

zcl_clusters.bind_request_response_id = 0x8021
zcl_clusters.id_to_name_map[zcl_clusters.bind_request_response_id] = "BindRequestResponse"

zcl_clusters.mgmt_bind_request_id = 0x0033
zcl_clusters.id_to_name_map[zcl_clusters.mgmt_bind_request_id] = "MgmtBindRequest"

zcl_clusters.binding_table_list_record_id = 0x8033
zcl_clusters.id_to_name_map[zcl_clusters.binding_table_list_record_id] = "BindingTableListRecord"

zcl_clusters.tuya_e000_id = 0xE000
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e000_id] = "TuyaE000"
data_types.id_to_name_map[0x48] = "CharString"  -- overrides Array data type (0xE000 attributes)

zcl_clusters.tuya_e001_id = 0xE001
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e001_id] = "TuyaE001"

zcl_clusters.tuya_ef00_id = 0xEF00
zcl_clusters.id_to_name_map[zcl_clusters.tuya_ef00_id] = "TuyaEF00"

-- local ColorControl = zcl_clusters.ColorControl

-- ColorControl.command_direction_map.TuyaMoveToColor = "client"
-- ColorControl.command_direction_map.TuyaMoveToColorTemperature = "client"
-- ColorControl.command_direction_map.TuyaSetMode = "client"

-- ColorControl.server_id_map = {
--   [0x00] = "MoveToHue",
--   [0x01] = "MoveHue",
--   [0x02] = "StepHue",
--   [0x03] = "MoveToSaturation",
--   [0x04] = "MoveSaturation",
--   [0x05] = "StepSaturation",
--   [0x06] = "MoveToHueAndSaturation",
--   [0x07] = "MoveToColor",
--   [0x08] = "MoveColor",
--   [0x09] = "StepColor",
--   [0x0A] = "MoveToColorTemperature",
--   [0x40] = "EnhancedMoveToHue",
--   [0x41] = "EnhancedMoveHue",
--   [0x42] = "EnhancedStepHue",
--   [0x43] = "EnhancedMoveToHueAndSaturation",
--   [0x44] = "ColorLoopSet",
--   [0x47] = "StopMoveStep",
--   [0x4B] = "MoveColorTemperature",
--   [0x4C] = "StepColorTemperature",

--   [0xE0] = "TuyaMoveToColorTemperature",
--   [0xE1] = "TuyaMoveToColor",
--   [0xF0] = "TuyaSetMode",
-- }

-- function ColorControl:get_server_command_by_id(command_id)
--   if ColorControl.server_id_map[command_id] then
--     return self.server.commands[ColorControl.server_id_map[command_id]]
--   end
--   return nil
-- end
