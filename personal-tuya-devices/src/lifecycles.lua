local log = require "log"
local utils = require "st.utils"

-- https://community.smartthings.com/t/st-edge-change-driver-tool-in-the-st-app/230956/23?u=w35l3y
local base_device = require "st.device"
local device_management = require "st.zigbee.device_management"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local data_types = require "st.zigbee.data_types"
local device_lib = require "st.device"

local myutils = require "utils"

local cluster_base = require "st.zigbee.cluster_base"
local read_attribute = require "st.zigbee.zcl.global_commands.read_attribute"
local zcl_messages = require "st.zigbee.zcl"
local messages = require "st.zigbee.messages"
local zb_const = require "st.zigbee.constants"

function cluster_base.read_attributes(device, cluster_id, attr_ids)
  local read_body = read_attribute.ReadAttribute(attr_ids)
  local zclh = zcl_messages.ZclHeader({
    cmd = data_types.ZCLCommandId(read_attribute.ReadAttribute.ID)
  })
  local addrh = messages.AddressHeader(
      zb_const.HUB.ADDR,
      zb_const.HUB.ENDPOINT,
      device:get_short_address(),
      device:get_endpoint(cluster_id.value),
      zb_const.HA_PROFILE_ID,
      cluster_id.value
  )
  local message_body = zcl_messages.ZclMessageBody({
    zcl_header = zclh,
    zcl_body = read_body
  })
  return messages.ZigbeeMessageTx({
    address_header = addrh,
    body = message_body
  })
end

-- set_component_to_endpoint_fn
-- get_endpoint_for_component_id
-- utilizado quando enviado comando device:send_to_component
-- este comando acima é comumento utilizado quando clicamos numa ação do app
local function component_to_endpoint(device, component_id)
  if component_id == "main" and myutils.is_normal(device) then
    return device.fingerprinted_endpoint_id
  else
    local group = component_id:match("main(%x+)")
    return group and tonumber(group, 16) or device.fingerprinted_endpoint_id
  end
end

-- set_endpoint_to_component_fn
-- get_component_id_for_endpoint
-- utilizado quando enviado comando device:emit_event_for_endpoint
-- este comando acima é comumente utilizado quando clicamos num botão físico (recepção de attributo)
-- @TODO pode ser que eu precise atualizar o handler global para emitir este evento
local function endpoint_to_component(device, group)
  if group == device.fingerprinted_endpoint_id and myutils.is_normal(device) then
    return "main"
  else
    return string.format("main%02X", group)
  end
end

local function find_child_fn(device, group)
  return device:get_child_by_parent_assigned_key(string.format("%02X", group))
end

local lifecycles = {}

function lifecycles.init(driver, device, event, ...)
  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    device:set_component_to_endpoint_fn(component_to_endpoint)
    device:set_endpoint_to_component_fn(endpoint_to_component)
    device:set_find_child(find_child_fn)

    driver:call_with_delay(0, function ()
      myutils.spell_magic_trick(device)
    end)
  end
end

function lifecycles.added(driver, device, event, ...)
end

function lifecycles.removed(driver, device, event, ...)
end

function lifecycles.driverSwitched(driver, device, event, ...)
end

--function lifecycles.doConfigure(driver, device, event, args)
--  device_management.configure(driver, device)
--end

return lifecycles
