local test = require "integration_test"
local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"

local utils = {}

function utils.expect_spell(device)
  return { device.id, zigbee_test_utils.build_attribute_read(device, zcl_clusters.Basic.ID, { 0x0004, 0x0000, 0x0001, 0x0005, 0x0007, 0xFFFE }):to_endpoint(0x01) }
end

function utils.expect_info(device, value)
  return device:generate_test_message("main", capabilities["valleyboard16460.info"].value(value))
end

function utils.expect_settings(device, value)
  return device:generate_test_message("main", capabilities["valleyboard16460.settings"].value(value))
end

function utils.send_spell(device)
  test.socket.zigbee:__expect_send(utils.expect_spell(device))
end

function utils.send_info(device, value)
  test.socket.capability:__expect_send(utils.expect_info(device, value))
end

function utils.send_settings(device, value)
  test.socket.capability:__expect_send(utils.expect_settings(device, value))
end

return utils
