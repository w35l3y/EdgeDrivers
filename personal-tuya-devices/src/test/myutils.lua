local test = require "integration_test"

local myutils = require "utils"

test.register_coroutine_test("profiles", function ()
  assert(not myutils.is_same_profile({}), "False - Sem preferências")

  assert(not myutils.is_same_profile({preferences={profile="other"}}, "profile"), "0 False - No manufacturer")
  assert(myutils.is_same_profile({preferences={profile="profile"}}, "profile"), "0 True - Same profile, no manufacturer")

  assert(not myutils.is_same_profile({preferences={profile="other"}}, "profile", "manufacturer"), "1 False - No manufacturer")
  assert(not myutils.is_same_profile({preferences={profile="other", manufacturer="_"}}, "profile", "manufacturer"), "1 False - Manufacturer=auto")
  assert(not myutils.is_same_profile({preferences={profile="other", manufacturer="other"}}, "profile", "manufacturer"), "1 False - Other manufacturer")
  assert(myutils.is_same_profile({preferences={profile="other", manufacturer="manufacturer"}}, "profile", "manufacturer"), "1 True - Same manufacturer")

  assert(myutils.is_same_profile({preferences={profile="profile"}}, "profile", "manufacturer"), "2 True - Same profile, no manufacturer")
  assert(myutils.is_same_profile({preferences={profile="profile", manufacturer="_"}}, "profile", "manufacturer"), "2 True - Same profile, manufacturer=auto")
  assert(not myutils.is_same_profile({preferences={profile="profile", manufacturer="other"}}, "profile", "manufacturer"), "2 False - Other manufacturer")
  assert(myutils.is_same_profile({preferences={profile="profile", manufacturer="manufacturer"}}, "profile", "manufacturer"), "2 True - Same manufacturer")

  assert(myutils.is_same_profile({preferences={profile="other"}}, "profile") == myutils.is_same_profile({preferences={profile="other", manufacturer="_"}}, "profile"), "3 No manufacturer")
  assert(myutils.is_same_profile({preferences={profile="other"}}, "profile", "manufacturer") == myutils.is_same_profile({preferences={profile="other", manufacturer="_"}}, "profile", "manufacturer"), "3 Manufacturer=auto")

  assert(myutils.is_same_profile({preferences={profile="profile"}}, "profile") == myutils.is_same_profile({preferences={profile="profile", manufacturer="_"}}, "profile"), "4 No manufacturer")
  assert(myutils.is_same_profile({preferences={profile="profile"}}, "profile", "manufacturer") == myutils.is_same_profile({preferences={profile="profile", manufacturer="_"}}, "profile", "manufacturer"), "4 Manufacturer=auto")
end, {
  test_init = function() end
})