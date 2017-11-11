--[[
  Copyright 2017 Stefano Mazzucco

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

  **NOTE**: connman objects do **not** implement
  `org.freedesktop.DBus.Properties.PropertiesChanged`.

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2017 Stefano Mazzucco
  @module connman_dbus
]]
local table = table

local proxy = require("dbus_proxy")

local function _update_property(self, params)
  local prop_name, prop_value = table.unpack(params)
  self[prop_name] = prop_value
end

--[[--
  The Connman Manager singleton. This table is returned when the module is loaded with `require`.

  You **must** use `Manager:SetProperty` to set the writeable properties (you
  will need to wrap the value of the properti in an `lgi.GLib.Variant`), then
  update them with `Manager:update_properties`.

  Manager's properties:

  - State: string. One of "offline", "idle", "ready" or "online".
  - OfflineMode: boolean
  - SessionMode: boolean (deprecated, always false)

  For more information, see the [connman manager API
  documentation](https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/manager-api.txt)

  @table Manager
]]
local Manager = proxy.Proxy:new(
  {
    bus = proxy.Bus.SYSTEM,
    interface = "net.connman.Manager",
    name = "net.connman",
    path = "/"
  }
)

--[[--

  Available Services.

  Table containing Service objects. They can be accessed either using a numeric
  index (e.g. `Manager.services[1]`) or using their object path
  (e.g. `Manager.services["/net/connman/service/wifi_123_managed_psk"]`). The
  lower its numeric index, the higher the priority the service has.

  For more information, see the [connman Service API
  documentation](https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/service-api.txt).

  Manager and  Services proxy obejcts are  updated in real time  (provided that
  the code runs in a GLib main loop, such as the Awesome Window Manager).

]]
Manager.services = {}

setmetatable(
  Manager.services,
  {
    __index = function (t, k)
      if type(k) == "number" then
        for _, v in pairs(t) do
          if v.n == k then
            return v
          end
        end
        return rawget(t, k)
      end
    end,
    __newindex = function (t, k, v)
      if type(k) == "number" then
        for k1, v1 in pairs(t) do
          if v1.n == k then
            v.n = k
            t[k1] = v
            return
          end
        end
      end
      rawset(t, k, v)
    end
  }
)

local function _get_service(path)
  local service = proxy.Proxy:new(
    {
      bus = proxy.Bus.SYSTEM,
      interface = "net.connman.Service",
      name = "net.connman",
      path = path
    }
  )
  if service then
    service:connect_signal(_update_property, "PropertyChanged")
  end
  return service
end

--- Refresh the @{Manager.services} table.
function Manager:refresh_services()
  local pair_list = self:GetServices()

  for idx, pair in ipairs(pair_list) do
    local path = pair[1]
    local service = self.services[path] or _get_service(path)
    if service then
      service.n = idx
      local properties = pair[2]
      for k, v in pairs(properties) do
        service[k] = v
      end
    end
    self.services[path] = service
  end

end

local function _update_services(self, params)
  self:refresh_services()

  local changed, removed = table.unpack(params)

  for _, path in ipairs(removed) do
    self.services[path] = nil
  end

  for idx, pair in ipairs(changed) do
    local path, props = table.unpack(pair)
    local service = self.services[path]
    if service then
      service.n = idx
      for k, v in pairs(props) do
        service[k] = v
      end
      self.services[path] = service
    end
  end
end

if Manager then
  for k, v in pairs(Manager:GetProperties()) do
    Manager[k] = v
  end

  Manager:refresh_services()

  Manager:connect_signal(_update_property, "PropertyChanged")

  Manager:connect_signal(_update_services, "ServicesChanged")
end

return Manager
