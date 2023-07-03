local log = require("log")

local logs = {}

logs.LOG_LEVEL_PRINT = "print"
logs.LOG_LEVEL_FATAL = "fatal"
logs.LOG_LEVEL_ERROR = "error"
logs.LOG_LEVEL_WARN = "warn"
logs.LOG_LEVEL_INFO = "info"
logs.LOG_LEVEL_DEBUG = "debug"
logs.LOG_LEVEL_TRACE = "trace"

logs._level = logs.LOG_LEVEL_TRACE

logs.levels = {
  [logs.LOG_LEVEL_PRINT] = 700,
  [logs.LOG_LEVEL_FATAL] = 600,
  [logs.LOG_LEVEL_ERROR] = 500,
  [logs.LOG_LEVEL_WARN] = 400,
  [logs.LOG_LEVEL_INFO] = 300,
  [logs.LOG_LEVEL_DEBUG] = 200,
  [logs.LOG_LEVEL_TRACE] = 100,
}

function logs.log(device, level, ...)
  if logs.levels[level] >= logs.levels[device.preferences.logLevel or logs._level] then
    log[level](...)
  end
end

return logs