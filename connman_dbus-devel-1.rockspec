package = "connman_dbus"
 version = "devel-1"
 source = {
    url = "git://github.com/stefano-m/lua-connman_dbus",
    tag = "master"
 }
 description = {
    summary = "Get network information with Connman and DBus",
    detailed = "Get network information with Connman and DBus",
    homepage = "https://github.com/stefano-m/lua-connman_dbus",
    license = "GPL v3"
 }
 dependencies = {
    "lua >= 5.1",
    "ldbus_api"
 }
 supported_platforms = { "linux" }
 build = {
    type = "builtin",
    modules = { connman_dbus = "connman_dbus.lua" },
    copy_directories = { "doc" }
 }
