local os = os
local string = string

print("Test STARTED")
print("Attempting to require connman_dbus")
local _, value = pcall(require, "connman_dbus")

if os.getenv("INSIDE_NIX") then
  print("Inside nix build")
  local expected_error = "Gio.DBusConnection expected, got nil"
  assert(
    string.match(value, expected_error),
    "Expected '" .. expected_error .. "' in error '" .. value .. "'"
  )
  print("Got expected error: " .. value)
  print("Test PASSED")
else
  print("Outside nix build")
  local connman = value

  assert(connman:GetProperties().State ~= nil, "State property should not be nil")

  local service = connman:GetServices()[1]

  assert(service ~= nil, "There should be at least one service")

  assert(#service == 2, "The service should have exactly 2 elements")

  local prefix = "/net/connman/service/"
  assert(
    string.match(service[1], prefix),
    "Service path should start with '" .. prefix .. "'"
  )

  assert(service[2].State ~= nil, "Service state should not be nil")

  local service_proxy = connman.services[1]

  assert(service_proxy ~= nil, "There should be at least one service proxy object")

  assert(type(service_proxy.connect_signal) == "function",
         "service proxy object should have a connect_signal function")

  local tech = connman.technologies["/net/connman/technology/wifi"]

  assert(tech ~= nil, "WiFi technology should be present")

  assert(type(tech.connect_signal) == "function", "technology object should have a connect_signal function")

  print("Test PASSED")
end
