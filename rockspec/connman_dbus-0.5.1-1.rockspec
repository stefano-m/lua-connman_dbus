package = "connman_dbus"
version = "0.5.1-1"
source = {
   url = "git://github.com/stefano-m/lua-connman_dbus",
   tag = "v0.5.1"
}
description = {
   summary = "Get network information with Connman and DBus",
   detailed = "Get network information with Connman and DBus",
   homepage = "git+https://github.com/stefano-m/lua-connman_dbus",
   license = "Apache v2.0"
}
supported_platforms = {
   "linux"
}
dependencies = {
   "lua >= 5.1",
   "dbus_proxy"
}
build = {
   type = "builtin",
   modules = {
      ["connman_dbus.init"] = "src/connman_dbus/init.lua"
   },
   copy_directories = {
      "docs"
   }
}
