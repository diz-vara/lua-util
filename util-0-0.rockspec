package = 'util'
version = '0-0'

source = {
   url = 'git://github.com/akfidjeland/lua-util',
   branch = 'master'
}

description = {
  summary = "Random utilities for Lua and Torch.",
  homepage = "https://github.com/akfidjeland/lua-util"
}

dependencies = { 'torch >= 7.0'}
build = {
   type = "command",
   build_command = [[
cmake -E make_directory build;
cd build;
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(LUA_BINDIR)/.." -DCMAKE_INSTALL_PREFIX="$(PREFIX)"; 
$(MAKE)
   ]],
   install_command = "cd build && $(MAKE) install"
}
