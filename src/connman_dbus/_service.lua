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

local DbusProxy = require('dbus_proxy').Proxy

local GVariant = require("lgi").GLib.Variant

local Service = {}
setmetatable(Service, {__index = DbusProxy})

--[[-- Set whether the service should connect automatically.

  If set to true, this service will auto-connect when no other connection is
available.

  The service won't auto-connect while roaming.

  For favorite services it is possible to change this value to prevent or
permit automatic connection attempts.

  @bool should_autoconnect whether the service should connect automatically.

]]
function Service:enable_autoconnect(should_autoconnect)
  self:SetProperty(
    "AutoConnect",
    GVariant("b", should_autoconnect))
end

--- Toggle the AutoConnect property.
-- @see Service:set_autoconnect
function Service:toggle_autoconnect()
  self:enable_autoconnect(not self.AutoConnect)
end

--[[-- Manually configure the domain name (DNS) servers.

Some cellular networks don't provide correct name servers and this allows for
an override.

When using manual configuration and no global nameservers are configured, then
it is useful to configure this setting.

Changes to the domain name servers can be done at any time. It will not cause a
disconnect of the service. However there might be small window where name
resolution might fail.

  @tparam {string,...} nameservers Array of strings. This array is sorted by priority
and the first entry in the list represents the nameserver with the highest
priority.


]]
function Service:configure_nameservers(nameservers)
  self:SetProperty(
    "Nameservers.Configuration",
    GVariant("as", nameservers))
end

--[[-- Manually configure the time servers.

  When using manual configuration this setting is useful to override all the
other timeserver settings. This is service specific, hence only the values for
the default service are used.

  Calling this method will result in restart of NTP query.

  @tparam {string,...} timeservers Array of strings. The first entry in the
list represents the timeserver with the highest priority.


]]
function Service:configure_timeservers(timeservers)
  self:SetProperty("Timeservers.Configuration", GVariant("as", timeservers))
end

--[[-- Manually configure the search domains (instead of using DHCP or VPN).

  @tparam {string,...} searchdomains Array of strings.

]]
function Service:configure_search_domains(searchdomains)
  self:SetProperty("Domains.Configuration", GVariant("as", searchdomains))
end


--[[-- Configure IPv4.

Calling this method will cause a state change of the service. The service
will become unavailable until the new configuration has been successfully
installed.

  @tparam table config table with the following fields:

  - `Method` (string) Possible values are `dhcp`, `manual`, `auto` and `off`.
  - `Address` (string) The IPv4 address.
  - `Netmask` (string) The IPv4 netmask.
  - `Gateway` (string) The IPv4 gateway.
]]
function Service:configure_ipv4(config)
  local cfg = GVariant(
    "a{sv}",
    {
      Method = GVariant("s",
                        config.Method),
      Address = GVariant("s",
                         config.Method == "manual" and config.Address or ""),
      Netmask = GVariant("s",
                         config.Method == "manual" and config.Netmask or ""),
      Gateway = GVariant("s",
                         config.Method == "manual" and config.Gateway or "")
    }
  )
  self:SetProperty("IPv4.Configuration", cfg)
end

--[[-- Configure IPv6.

Calling this method will cause a state change of the service. The service
will become unavailable until the new configuration has been successfully
installed.

  @tparam table config table with the following fields:

  - `Method` (string) Possible values are `auto`, `manual`, and `off`.
  - `Address` (string) The IPv6 address.
  - `PrefixLength` (number) The prefix length of the IPv6 address.
  - `Gateway` (string) The IPv6 gateway.
  - `Privacy` (string) Set the IPv6 privacy extension as described in
    [RFC4941](https://tools.ietf.org/html/rfc4941). The value has only meaning
    if `Method` is set to `auto`. Possible values are `disabled`, `enabled` and
    `preferred`.
]]
function Service:configure_ipv6 (config)
  local cfg = GVariant(
    "a{sv}",
    {
      Method = GVariant("s",
                        config.Method),
      Address = GVariant("s",
                         config.Method == "manual" and config.Address or ""),
      PrefixLength = GVariant("y",
                              config.Prefixlength),
      Gateway = GVariant("s",
                         config.Method == "manual" and config.Gateway or ""),
      Privacy = GVariant("s",
                         config.Method == "auto" and config.Privacy or "")
    }
  )
  self:SetProperty("IPv6.Configuration", cfg)
end

--[[-- Configure the proxy server.

  @tparam table config table with the following fields:

  - `Method` (string) Possible values are `direct`, `auto` and `manual`. In
    case of `auto` method, the URL file can be provided by the `URL` field
    (unless you want to let DHCP/WPAD auto-discover to be tried). For the
    `manual` method the `Servers` field **must** be set, the `Excludes` field
    is optional.
  - `URL` (string) Automatic proxy configuration URL. Needed when `Method` is
    set to `auto`.
  - `Servers` ({string,...}) List of proxy URIs. The URI without a protocol
    will be interpreted as the generic proxy URI.  All others will target a
    specific protocol and only once. This field **must** be set if `Method` is
    set to `manual`. For example, a generic proxy URI may look like
    `server.example.com:911`.
  - `Excludes` ({string,...}) List of hosts which can be accessed without the
    need of a proxy. This field is optionally used when `Method` is set to `auto`.

]]
function Service:configure_proxy(config)
  local cfg = GVariant(
    "a{sv}",
    {
      Method = GVariant("s",
                        config.Method),
      URL = GVariant("s",
                     config.Method == "auto" and config.URL or ""),
      Servers = GVariant("as",
                         config.Method == "manual" and config.Servers or {}),
      Excludes = GVariant("as",
                          config.Excludes or {})
    }
  )
  self:SetProperty("Proxy.Configuration", cfg)
end

--[[--

  Set whether [Multicast DNS (mDNS)](https://en.wikipedia.org/wiki/MDNS) should
  be enabled for this service.

  **Note**: mDNS requires a DNS backend which supports it. Currently the only
  DNS backend which supports mDNS is `systemd-resolved`.

  @bool use_mdns Whether mDNS should be used.

]]
function Service:enable_mdns(use_mdns)
  self:SetProperty("mDNS.Configuration", GVariant("b", use_mdns))
end

return Service
