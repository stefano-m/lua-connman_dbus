# Get network information with Connman and DBus

This module provides a simple API to query
[Connman](https://01.org/connman/)
using [DBus](http://dbus.freedesktop.org/).

# Requirements

In addition to the requirements specified in the rockspec file,
you need Connman and DBus. Note that you may need permissions to access
the Connman DBus interface.

# Installation

This module can be installed with [Luarocks](http://luarocks.org/) by running

    luarocks install connman_dbus

Use the `--local` option in `luarocks` if you don't want or can't install it
system-wide.

# Example

Below is a small example of how to use the module:

```lua
Manager = require("connman_dbus"):init()
print(Manager.OfflineMode) -- e.g. true
print(Manager.techs["/net/connman/technology/p2p"].Powered) -- e.g. false
service = Manager.current_service
print(service.Type) -- e.g. "wifi"
print(service.State) -- e.g. "online"
```

# Documentation

The documentation of this module is built using [LDoc](https://stevedonovan.github.io/ldoc/).
A copy of the documentation is already provided in the `doc` folder,
but you can build it from source by running `ldoc .` in the root of the repository.
