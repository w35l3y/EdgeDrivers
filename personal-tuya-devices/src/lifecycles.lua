local log = require "log"
local utils = require "st.utils"

-- https://community.smartthings.com/t/st-edge-change-driver-tool-in-the-st-app/230956/23?u=w35l3y
local base_device = require "st.device"
local device_management = require "st.zigbee.device_management"
local myutils = require "utils"

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
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
  device:set_find_child(find_child_fn)
end

function lifecycles.infoChanged(driver, device, event, args)
  if args.old_st_store.preferences.presentation ~= device.preferences.presentation or (not myutils.is_normal(device) and device.profile.components.main == nil) then
    device:try_update_metadata({
      profile = device.preferences.presentation:gsub("_", "-")
    })
  end

  for id, value in pairs(device.preferences) do
    local normalized_id = utils.snake_case(id)
    local match, _length, pref, component, group = string.find(normalized_id, "^child(_?%w*)_(main(%x+))$")
    if match ~= nil and value and args.old_st_store.preferences[id] ~= value then
      local profile = ("child" .. (pref ~= "" and pref or "_switch") .. "-v1"):gsub("_", "-")
      local created = device:get_child_by_parent_assigned_key(group)
      if not created then
        driver:try_create_device({
          type = "EDGE_CHILD",
          device_network_id = nil,
          parent_assigned_child_key = group,
          label = "Child " .. tonumber(group, 16),
          profile = profile,
          parent_device_id = device.id,
          manufacturer = driver.NAME,
          model = profile,
          vendor_provided_label = "Child " .. tonumber(group, 16),
        })
      end
    end
  end
end

function lifecycles.added(driver, device, event, ...)
end

function lifecycles.removed(driver, device, event, ...)
end

--function lifecycles.doConfigure(driver, device, event, args)
--  device_management.configure(driver, device)
--end

return lifecycles
