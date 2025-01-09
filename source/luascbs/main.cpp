#include <luascbs/platform.h> // IWYU pragma: keep

#include <lua.hpp>

#include <cstdio>
#include <cstdlib>
#include <cstdint> // IWYU pragma: keep
#include <cassert> // IWYU pragma: keep
#include <cstring> // IWYU pragma: keep
#include <csignal>

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

lua_State *globalL;

namespace stdfs = std::filesystem;

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

/* =============================================================================================== */
// The code taken from luajit.c
// LuaJIT 2.1.1724512491 -- Copyright (C) 2005-2023 Mike Pall. https://luajit.org/

#if !LJ_TARGET_CONSOLE
static void lstop(lua_State *L, lua_Debug *ar)
{
	(void)ar;  /* unused arg. */
	lua_sethook(L, NULL, 0, 0);
	/* Avoid luaL_error -- a C hook doesn't add an extra frame. */
	luaL_where(L, 0);
	lua_pushfstring(L, "%sinterrupted!", lua_tostring(L, -1));
	lua_error(L);
}

static void laction(int i)
{
	signal(i, SIG_DFL); /* if another SIGINT happens before lstop,
	terminate process (default action) */
	lua_sethook(globalL, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1);
}
#endif

static void l_message(const char *msg)
{
  fputs("luascbs", stderr); fputc(':', stderr); fputc(' ', stderr);
  fputs(msg, stderr); fputc('\n', stderr);
  fflush(stderr);
}

static int report(lua_State *L, int status)
{
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(msg);
    lua_pop(L, 1);
  }
  return status;
}

static int traceback(lua_State *L)
{
  if (!lua_isstring(L, 1)) { /* Non-string error object? Try metamethod. */
    if (lua_isnoneornil(L, 1) ||
	!luaL_callmeta(L, 1, "__tostring") ||
	!lua_isstring(L, -1))
      return 1;  /* Return non-string error object. */
    lua_remove(L, 1);  /* Replace object by result of __tostring metamethod. */
  }
  luaL_traceback(L, L, lua_tostring(L, 1), 1);
  return 1;
}

static int docall(lua_State *L, int narg, int nres)
{
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
#if !LJ_TARGET_CONSOLE
  signal(SIGINT, laction);
#endif
  status = lua_pcall(L, narg, nres, base);
#if !LJ_TARGET_CONSOLE
  signal(SIGINT, SIG_DFL);
#endif
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != LUA_OK) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}

static int dofile(lua_State *L, const char *name)
{
	int status = luaL_loadfile(L, name) || docall(L, 0, LUA_MULTRET);
	return report(L, status);
}

static int dostring(lua_State *L, const char *s, const char *name)
{
	int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 0);
	return report(L, status);
}

static int dolibrary(lua_State *L, const char *name)
{
	lua_getglobal(L, "require");
	lua_pushstring(L, name);
	return report(L, docall(L, 1, LUA_MULTRET));
}

/* =============================================================================================== */

int main(int argc, char **argv)
{
	stdfs::path mainpath = argc > 2 ? argv[--argc] : ".";

	if (stdfs::is_directory(mainpath))
		mainpath /= "project.lua";
	
	if (!stdfs::is_regular_file(mainpath)) {
		fprintf(stderr, "%s: not a regular file\n", mainpath.c_str());
		return 1;
	}

	lua_State* L = globalL = luaL_newstate();
	/* Stop collector during library initialization. */
	lua_gc(L, LUA_GCSTOP, 0);
	luaL_openlibs(L);
	lua_gc(L, LUA_GCRESTART, -1);
	lua_settop(L, 0);
	
	// @todo move this to lua code
	luaL_dostring (L,
		"table.__index = table;"
		"setmetatable(table, {__call = function(self, t) return setmetatable(t, self) end})"
	);
	lua_settop(L, 0);

	stdfs::path cInsPath = getSelfExecPath().parent_path();
	auto pkgPath =
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?" / "init.lua").string() +
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?.lua").string();
	auto luarPkgPath =
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?" / "init.luar").string() +
		std::string(";") + (std::filesystem::path(cInsPath) / "lib" / "?.luar").string();

	lua_getglobal(L, "package");
    lua_getfield(L, 1, "path");
    lua_pushstring(L, pkgPath.c_str());
    lua_concat(L, 2);
    lua_setfield(L, 1, "path");
    lua_getfield(L, 1, "lrpath");
    if (lua_isnil(L, 2)) {
		lua_pop(L, 1);
		lua_pushstring(L, "");
	}
    lua_pushstring(L, luarPkgPath.c_str());
    lua_concat(L, 2);
    lua_setfield(L, 1, "lrpath");

	lua_pushstring(L, LUASCBS_SOURCE_OS);
	lua_setglobal(L, "SCBS_OS");

	lua_pushstring(L, LUASCBS_SOURCE_ARCH);
	lua_setglobal(L, "SCBS_ARCH");

	if (dolibrary(L, "scbs")) {
		puts("Failed to load core module");
		return 1;
	}

	lua_settop(L, 0);
	int top = 0;
	
	// some compilers have mainpath.c_str() of type wchar_t *
	if (dofile(L, mainpath.string().c_str()))
		return 1;

	// the main file should have returned one value (proj)
	check_stack(L, ++top);
	
	lua_getglobal(L, "scbsmain");
	if (!lua_isfunction(L, -1)) {
		fprintf(stderr, "scbsmain function is missing\n");
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

	// result = scbsmain(proj, {args...})
	report(L, docall(L, 2, 1));

	int result = 0;
	if (lua_gettop(L) && !lua_isnil(L, -1))
		result = lua_tointeger(L, -1);

	lua_close(L);
	return result;
}
