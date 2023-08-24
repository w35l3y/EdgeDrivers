require "test.carbonmonoxide"   -- dni 0x0001
require "test.colordimmer"      -- dni 0x0002
require "test.dimmer"           -- dni 0x0003
require "test.switch"           -- dni 0x0004
require "test.contact"          -- dni 0x0005
require "test.motion"           -- dni 0x0006
require "test.smoke"            -- dni 0x0007
require "test.sound"            -- dni 0x0008
require "test.water"            -- dni 0x0009

local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local profile = t_utils.get_profile_definition("default_v1.yaml")

test.load_all_caps_from_profile(profile)

zigbee_test_utils.prepare_zigbee_env_info()

test.set_test_init_function(function()
  error("You must use your own test_init")
end)

local result = test.run_registered_tests()
if result == nil or result.failed > 0 then
  error("Unable to proceed")
end