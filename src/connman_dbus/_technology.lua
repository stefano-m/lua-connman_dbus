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

--- @submodule connman_dbus

local GVariant = require("lgi").GLib.Variant

local Technology = {}

--[[-- Set whether the Technology should be powered.

  @bool is_powered Whether the Technology should be powered.

]]
function Technology:enable_power(is_powered)
  self:SetProperty("Powered", GVariant("b", is_powered))
end

--- Toggle the power state.
-- @see Technology:enable_power
function Technology:toggle_power()
  self:enable_power(not self.Powered)
end

--[[-- Whether tethering should be enabled.

  This method allows one to enable or disable the support for tethering. When
  tethering is enabled then the default service is bridged to all clients
  connected through the technology.

  @bool is_tethered Whether tethering is enabled.

]]
function Technology:enable_tethering(is_tethered)
  self:SetProperty("Tethering", GVariant("b", is_tethered))
end

--- Toggle the tethering state.
-- @see Technology:enable_tethering
function Technology:toggle_tethering()
  self:enable_tethering(not self.Tethering)
end

--[[-- Set the tethering broadcasted identifier.

  This method is only valid for the WiFi technology, and is then mapped to the
  WiFi AP SSID clients will have to join in order to gain internet
  connectivity.

  @string id The tethering identifier.

]]
function Technology:set_tethering_identifier(id)
  self:SetProperty("TetheringIdentifier", GVariant("s", id))
end

--[[-- Set the tethering connection passphrase (**sensitive!**).

  This method is only valid for the WiFi technology, and is then mapped to
  the WPA pre-shared key clients will have to use in order to establish a
  connection.

**IMPORTANT SECURITY NOTE**

  Take extra care when using this method and the corresponding
`TetheringPassphrase` field as connman does not make any security guarantee in
regard!!!

  @string secret The tethering passphrase.

]]
function Technology:set_tethering_passphrase(secret)
  self:SetProperty("TetheringPassphrase", GVariant("s", secret))
end

return Technology
