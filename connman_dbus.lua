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
  `org.freedesktop.DBus.Properties.PropertiesChanged`, so there's no way to get
  the cached properties with the DBusProxy object.

  To get the updated properties, use the `update_properties` method.

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2017 Stefano Mazzucco
]]
local string = string

local proxy = require("dbus_proxy")

local function _update_properties(o)
  for k, v in pairs(o:GetProperties()) do
    o[k] = v
  end
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

  @type Manager
]]
local Manager = proxy.Proxy:new(
  {
    bus = proxy.Bus.SYSTEM,
    interface = "net.connman.Manager",
    name = "net.connman",
    path = "/"
  }
)

--- Update the Manager's properties
function Manager:update_properties()
  _update_properties(self)
end

local ok, value = pcall(Manager.update_properties, Manager)
if not ok then
  error(string.format("Could not initialize connman manager: %s",
                      value))
end

return Manager
