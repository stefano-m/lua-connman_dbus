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
    license = "Apache v2.0"
 }
 dependencies = {
    "lua >= 5.1",
    "dbus_proxy"
 }
 supported_platforms = { "linux" }
 build = {
    type = "builtin",
    modules = { ["connman_dbus.init"] = "src/connman_dbus/init.lua" },
    copy_directories = { "docs" }
}
