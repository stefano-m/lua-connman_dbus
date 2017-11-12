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

  Requiring this module will return the Connman @{Manager} singleton.

  Proxy obejcts are updated in real time, provided that the code runs in a GLib
  main loop (such as the Awesome Window Manager).

  **NOTE**: connman objects do **not** implement
  `org.freedesktop.DBus.Properties.PropertiesChanged`.

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2017 Stefano Mazzucco
  @module connman_dbus
]]
local table = table

local GVariant = require("lgi").GLib.Variant
local proxy = require("dbus_proxy")

local _Service = require("connman_dbus._service")
local _Technology = require("connman_dbus._technology")

local _prototypes = {
  Service = {__index = _Service},
  Technology = {__index = _Technology}
}

local function _update_property(self, prop_name, prop_value)
  self[prop_name] = prop_value
end

local function _get(what, path)
  local obj = proxy.Proxy:new(
    {
      bus = proxy.Bus.SYSTEM,
      interface = "net.connman." .. what,
      name = "net.connman",
      path = path
    }
  )
  if obj then
    obj:connect_signal(_update_property, "PropertyChanged")
    local meta = _prototypes[what]
    if meta then
      setmetatable(obj, meta)
    end
  end
  return obj
end

local function _refresh(self, what, what_one)
  local field = what:lower()
  what_one = what_one or what:sub(1, -2)
  local pair_list = self["Get" .. what](self)

  for idx, pair in ipairs(pair_list) do
    local path = pair[1]
    local obj = self[field][path] or _get(what_one, path)
    if obj then
      obj.n = idx
      local properties = pair[2]
      for k, v in pairs(properties) do
        obj[k] = v
      end
    end
    self[field][path] = obj
  end
end

local function _update_services(self, changed, removed)
  self:refresh_services()

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

local function _add_technology(self, path, properties)
  local new_tech = _get("Technology", path)
  for k, v in pairs(properties) do
    new_tech[k] = v
  end

  local old_tech = self.technologies[path]
  if old_tech then
    new_tech.n = old_tech.n
  else
    new_tech.n = #self.technologies + 1
  end

  self.technologies[path] = new_tech
end

local function _remove_technology(self, path)
  self.technologies[path] = nil
end

--- Metatable that delegates searching by index.
local _delegate_index_mt = {
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
  end,
  __len = function (t)
    local count = 0
    for k, _ in pairs(t) do
      if type(k) == "string" then
        count = count +1
      end
    end
    return count
  end
}

--[[--
  The Connman Manager singleton. This table is returned when the module is loaded with `require`.

  You **must** use `Manager:SetProperty` to set the writeable properties (you
  will need to wrap the value of the properti in an `lgi.GLib.Variant`), then
  update them with `Manager:update_properties`.

  Manager's properties:

  - State: string. One of "offline", "idle", "ready" or "online".
  - OfflineMode: boolean
  - SessionMode: boolean (deprecated, always false)

  For more information, see the [connman Manager API
  documentation](https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/manager-api.txt)

  @table Manager
]]
local Manager = _get("Manager", "/")

--[[-- Set the global offline mode.

The offline mode indicates the global setting for switching all radios on or
off. Changing offline mode to true results in powering down all devices. When
leaving offline mode the individual policy of each device decides to switch the
radio back on or not.

During offline mode, it is still possible to switch certain technologies
manually back on. For example the limited usage of WiFi or Bluetooth devices
might be allowed in some situations.

@bool is_offline whether offline mode should be turned on
]]
function Manager:enable_offline_mode(is_offline)
  self:SetProperty("OfflineMode", GVariant("b", is_offline))
end

--- Toggle the global offline mode.
-- @see Manager:set_offline_mode
function Manager:toggle_offline_mode()
  self:enable_offline_mode(not self.OfflineMode)
end

local function _init()
  for k, v in pairs(Manager:GetProperties()) do
    Manager[k] = v
  end
  Manager:refresh_services()
  Manager:connect_signal(_update_services, "ServicesChanged")
  Manager:refresh_technologies()
  Manager:connect_signal(_add_technology, "TechnologyAdded")
  Manager:connect_signal(_remove_technology, "TechnologyRemoved")
end

--[[--

  Available Services.

  Table containing Service objects. They can be accessed either using a numeric
  index (e.g. `Manager.services[1]`) or using their object path
  (e.g. `Manager.services["/net/connman/service/wifi_123_managed_psk"]`). The
  lower its numeric index, the higher the priority the service has.

  For more information, see the [connman Service API
  documentation](https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/service-api.txt).

]]
Manager.services = {}
setmetatable(Manager.services, _delegate_index_mt)

--[[--

  Available Technologies.

  Table containing Technology objects. They can be accessed either using a
  numeric index (e.g. `Manager.technologies[1]`) or using their object path
  (e.g. `Manager.technologies["/net/connman/technology/wifi"]`).

  For more information, see the [connman Technology API
  documentation](https://git.kernel.org/pub/scm/network/connman/connman.git/tree/doc/technology-api.txt).

]]
Manager.technologies = {}
setmetatable(Manager.technologies, _delegate_index_mt)

--- Refresh the @{Manager.services} table.
function Manager:refresh_services()
  _refresh(self, "Services")
end

--- Refresh the @{Manager.technologies} table.
function Manager:refresh_technologies()
  _refresh(self, "Technologies", "Technology")
end

_init()

return Manager
