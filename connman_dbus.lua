--[[
  Copyright 2016 Stefano Mazzucco

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]

--[[--
  Get information about your network devices using
  [Connman](https://01.org/connman) and DBus.

  Requiring this module will return the Connman Manager singleton.

  Example:

      local Manager = require("connman_dbus"):init()
      print(Manager.current_service.Type, Manager.current_service.Name)

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2016 Stefano Mazzucco
]]

--- @alias Manager

local ldbus = require("ldbus_api")

local function call(opts, method, args)
  args = args or {}
  if type(method) ~= "string" then
    error("method type must be a string, got " .. type(method), 2)
  end
  local t = {method = method, args = args}
  for k, v in pairs(opts) do
    t[k] = v
  end
  local status, data = pcall(ldbus.api.call, t)
  if status then
    return data
  else
    local msg = string.format("Error calling %s:\n%s", method, data)
    error(msg, 2)
  end
end

--[[- Connman service (exposed via `Manager.services` and `Manager.current_service`).

  @field dbus table containing the DBus information for the service:

  * `path`: the service's object path (string)
  * `dest`: "net.connman"
  * `interface`: "net.connman.Service"
  * `bus`: "system"

  @field Name the SSID (like "MyWireless"), absent for ethernet and hidden Wifi
  @field Type the service type, like  "wifi" or "ethernet"
  @field State one of "idle", "failure", "association", "configuration", "ready", "disconnect" or "online"
  @field Strength WiFi signal strength between 0 and 100
  @field Favorite bool, will be true if a cable is plugged in or the user selected and successfully connected to this service.
  @field AutoConnect bool
  @field Immutable bool

  @field Ethernet table

  * `Interface`: like "wlo1", "eth0", etc.
  * `Address`: the MAC address
  * `MTU`: like 1500
  * `Method`: like "auto"

  @field Security array of supported security, the elements can be: "none", "wep", "psk", "ieee8021x" or "wps"

  @field Provider table

  @field Domains array
  @field Domains.Configuration table

  @field Nameservers array
  @field Nameservers.Configuration table

  @field IPv4 table

  * `Netmask`
  * `Gateway`
  * `Address`

  @field IPv4.Configuration table

  * `Method`

  @field IPv6 table

  * `Netmask`
  * `Gateway`
  * `Address`

  @field IPv6.Configuration table

  * `Method`

  @field Proxy table
  @field Proxy.Configuration table

  @field Timeservers array
  @field Timeservers.Configuration table

  @field Error one of "out-of-range", "pin-missing", "dhcp-failed", "connect-failed", "login-failed", "auth-failed" or "invalid-key"

  @table Service
--]]
local Service = {}

function Service:new(opts)
  local service = {
    dbus = {
      bus = "system",
      dest = "net.connman",
      interface = "net.connman.Service"}
  }
  setmetatable(service, self)
  self.__index = self

  opts = opts or {object_path = "/invalid", properties = {}}

  service.dbus.path = opts.object_path

  for k, v in pairs(opts.properties) do
    local first, _, second = k:match("(.*)(%.)(.*)")
    if first and second then
      if not service[first] then
        service[first] = {}
      end
      -- e.g. service.IPv4.Configuration = <value>
      service[first][second] = v
    else
      if type(service[k]) == "table" and type(v) == "table" then
        -- Update the existing table rather than overriding it.
        for vk, vv in pairs(v) do
          service[k][vk] = vv
        end
      else
        service[k] = v
      end
    end
  end

  return service
end

--[[-
  The Connman Manager singleton. This table is returned when the module is loaded with `require`.
  Call `Manager:init()` to initialize it.

  E.g.

      Manager = require("connman_dbus"):init()

  @field State "offline", "idle", "ready" or "online"
  @field OfflineMode bool
  @field SessionMode bool (deprecated, always false)
  @field techs table of technologies. Each
  key is the object path and each value is
  the table containing the tech's properties:

  * `Powered`: bool
  * `Connected`: bool
  * `Name`: str
  * `Type`: str ("ethernet", "wifi", etc.)

  @field services array of services (sorted by Connman in order of preference)
  @field current_service the currently active service
  @field dbus table with DBus information

  @see Service
  @see Manager:init

  @table Manager
]]
local Manager = {
  dbus = {
    bus = "system",
    dest = "net.connman",
    interface = "net.connman.Manager",
    path = "/"}
}

local function make_table(pairs_array)
  local t = {}
  for _, pair in ipairs(pairs_array) do
    t[pair[1]] = pair[2]
  end
  return t
end

--- Update the Manager's own properties.
function Manager:update_properties()
  local props = ldbus.api.get_value(call(self.dbus, "GetProperties")[1])
  for k, v in pairs(props) do
    self[k] = v
  end
end

--- Update the available technologies stored in the `techs` table.
-- @see Manager
function Manager:update_techs()
  local techs = ldbus.api.get_value(call(self.dbus, "GetTechnologies")[1])
  self.techs = make_table(techs)
end

--- Update the Manager's `service` and `current_service` fields.
function Manager:update_services()
  self.services = {}
  for i, s in ipairs(ldbus.api.get_value(
                       call(self.dbus, "GetServices")[1])) do
    self.services[i] = Service:new({object_path = s[1],
                                    properties = s[2]})
  end
  self.current_service = self.services[1] or Service:new()
end


--- Initialize the connman Manager singleton.
-- Update own properties, services and technologies.
-- @return self
-- @see Manager:update_properties
-- @see Manager:update_services
-- @see Manager:update_techs
function Manager:init()
  self:update_properties()
  self:update_services()
  self:update_techs()
  return self
end

return Manager
