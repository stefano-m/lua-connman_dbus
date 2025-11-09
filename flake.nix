{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    dbusProxyFlake = {
      url = "github:stefano-m/lua-dbus_proxy/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dbusProxyFlake }:
    let

      flakePkgs = import nixpkgs { overlays = [ self.overlays.default ]; inherit system; };
      system = "x86_64-linux";
      currentVersion = builtins.readFile ./VERSION;

      buildPackage = luaPackages: with luaPackages;
        buildLuaPackage rec {
          name = "${pname}-${version}";
          pname = "connman_dbus";
          version = "${currentVersion}-${self.shortRev or "dev"}";

          src = ./.;

          propagatedBuildInputs = [
            dbus_proxy
            flakePkgs.gobject-introspection
          ];

          buildInputs = [
            luacov
            ldoc
            luacheck
            flakePkgs.connman
            flakePkgs.dbus
          ];

          buildPhase = ":";

          installPhase = ''
            mkdir -p "$out/share/lua/${lua.luaversion}"
            cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
          '';

          doCheck = true;

          GI_TYPELIB_PATH = "${flakePkgs.lib.getLib flakePkgs.glib}/lib/girepository-1.0/";
          LUA_PATH = "$LUA_PATH;./src/?.lua;./src/?/init.lua";

          INSIDE_NIX = true;

          checkPhase = ''
            lua -v
            make check
          '';

        };

    in
    {

      packages.${system} = rec {
        default = lua_connman_dbus;
        lua_connman_dbus = buildPackage flakePkgs.luaPackages;
        lua52_connman_dbus = buildPackage flakePkgs.lua52Packages;
        lua53_connman_dbus = buildPackage flakePkgs.lua53Packages;
      };

      devShells.${system}.default = flakePkgs.mkShell {
        LUA_PATH = "./src/?.lua;./src/?/init.lua";
        buildInputs = (with self.packages.${system}.default;
          buildInputs ++ propagatedBuildInputs) ++ (with flakePkgs;
          [ nixpkgs-fmt luarocks ]);
      };

      overlays.default = final: prev:
        let
          thisOverlay = this: previous: with self.packages.${system}; {
            luaPackages = previous.luaPackages // { connman_dbus = lua_connman_dbus; };
            lua52Packages = previous.lua52Packages // { connman_dbus = lua52_connman_dbus; };
            lua53Packages = previous.lua53Packages // { connman_dbus = lua53_connman_dbus; };
            luajitPackages = previous.luajitPackages // { connman_dbus = luajit_connman_dbus; };
          };
        in
        # expose the other lua overlays together with this one.
        (nixpkgs.lib.composeManyExtensions [ thisOverlay dbusProxyFlake.overlays.default ]) final prev;

    };

}
