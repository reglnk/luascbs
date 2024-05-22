#include <luascbs/platform.h> // IWYU pragma: keep

#include <lua.hpp>

#include <cstdio>
#include <cstdlib>
#include <cstdint> // IWYU pragma: keep
#include <cassert> // IWYU pragma: keep
#include <cstring> // IWYU pragma: keep

#include <new> // IWYU pragma: keep
#include <vector> // IWYU pragma: keep
#include <iostream> // IWYU pragma: keep
#include <string> // IWYU pragma: keep
#include <filesystem>
#include <stdexcept>

#ifndef _WIN32
#  include <unistd.h>
#else
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#endif

#define LUASCBS_PATH_MAX 4096

namespace stdfs = std::filesystem;

extern "C" {
	void somefunc() {
		std::cout << "somefunc is called!\n";
	}
}

stdfs::path getSelfExecPath()
{
	char buffer[LUASCBS_PATH_MAX];
	
#ifndef _WIN32
    int len = (int)readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
    if (len == -1)
        throw new std::runtime_error("failed to get process executable path");

    // Null-terminate the string
    buffer[len] = '\0';
#else
	GetModuleFileNameA(NULL, buffer, LUASCBS_PATH_MAX);
#endif

	return stdfs::path(buffer);
}

static int report_err(lua_State *L) {
	fprintf(stderr, "Lua error stack traceback:\n%s\n", lua_tostring(L, -1));
	lua_pop(L, 1);
	lua_close(L);
	return 1;
}

static inline void exit_err(lua_State *L) {
	lua_close(L);
	exit(1);
}

static inline void check_stack(lua_State *L, int required) {
	int newtop = lua_gettop(L);
	if (newtop > required)
		lua_settop(L, required);
	else if (newtop != required) {
		puts("Wrong stack size");
		exit_err(L);
	}
}

int main(int argc, char **argv)
{
	stdfs::path mainpath = argc > 2 ? argv[--argc] : ".";

	if (stdfs::is_directory(mainpath))
		mainpath /= "project.lua";
	
	if (!stdfs::is_regular_file(mainpath)) {
		fprintf(stderr, "%s: not a regular file\n", mainpath.c_str());
		return 1;
	}

	lua_State* L = luaL_newstate();
	luaopen_base(L);
	luaL_openlibs(L);
	lua_settop(L, 0);
	
	luaL_dostring (L,
		"table.__index = table;"
		"setmetatable(table, {__call = function(self, t) return setmetatable(t, self) end})"
	);
	lua_settop(L, 0);

	stdfs::path cInsPath = getSelfExecPath().parent_path();
	auto pkgPath =
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?" / "init.lua").string() +
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?.lua").string();

	lua_getglobal(L, "package");
    lua_getfield(L, 1, "path");
    lua_pushstring(L, pkgPath.c_str());
    lua_concat(L, 2);
    lua_setfield(L, 1, "path");

	lua_pushstring(L, LUASCBS_SOURCE_OS);
	lua_setglobal(L, "SOURCE_OS");

	lua_pushstring(L, LUASCBS_SOURCE_ARCH);
	lua_setglobal(L, "SOURCE_ARCH");

	lua_settop(L, 0);

	if (luaL_dostring(L, "require \"scbs\"")) {
		puts("Failed to load core module");
		return report_err(L);
	}

	int top = lua_gettop(L);
	
	// some compilers have mainpath.c_str() of type wchar_t *
	if (luaL_dofile(L, mainpath.string().c_str()))
		return report_err(L);

	// the main file should have returned one value
	check_stack(L, ++top);
	
	lua_getglobal(L, "scbsmain");
	if (lua_isnil(L, -1) || !lua_isfunction(L, -1)) {
		fprintf(stderr, "main function is missing\n");
		lua_close(L);
		return 1;
	}

	// move the table after function value
	lua_insert(L, top);

	// make array from args
	lua_newtable(L);
	for (int i = 1; i < argc; ++i)
	{
		lua_pushstring(L, argv[i]);
		lua_rawseti(L, -2, i);
	}
	assert(lua_gettop(L) == top + 2);

	if (lua_pcall(L, 2, 1, 0) != LUA_OK)
		return report_err(L);

	int result = 0;
	if (!lua_isnil(L, -1))
		result = lua_tointeger(L, -1);

	lua_close(L);
	return result;
}
