unit FLuaFunctions;
interface

uses
	SysUtils, FLua, FLogs;

var
  L : lua_State;
  loaded : boolean;
  procedure InitInterface();

implementation
uses
	FGlWindow;

function printr(L: lua_State) : Integer; cdecl;
var text: PChar;
begin
  text := lua_tostring(L, 1);
	Log(text);
  Result := 1;
end;

function SendChatMessage(L: lua_State) : Integer; cdecl;
var text: PChar;
begin
  text := lua_tostring(L, 1);
  Log(PChar('Vjeux: ' + string(text)));
 // Form1.TcpClient1.Sendln(text);
  Result := 1;
end;

function RunScript(L: lua_State) : Integer; cdecl;
var text: PChar;
begin
  text := lua_tostring(L, 1);
    if (luaL_loadbuffer(L, PChar(text), strlen(PChar(text)), 'line') <> 0 or
                lua_pcall(L, 0, 0, 0)) then begin
			Log(lua_tostring(L,-1));
			lua_pop(L, 1);
		end;
		Result := 1;
end;

procedure LoadLuaFile(path: PChar);
begin
	if (luaL_loadfile(L, PChar('Interface/' + string(path))) or lua_pcall(L, 0, 0, 0)<>0) then begin
    Log(lua_tostring(L,-1));
    lua_pop(L, 1);
  end;
end;

function IncludeFile(L: lua_State) : Integer; cdecl;
var text: PChar;
begin
  text := lua_tostring(L, 1);
  LoadLuaFile(text);
  Result := 1;
end;

procedure LoadLuaModules(); cdecl;
begin
  lua_pushcfunction(L, printr);
  lua_setglobal(L, 'print');
  lua_pushcfunction(L, RunScript);
  lua_setglobal(L, 'RunScript');
  lua_pushcfunction(L, IncludeFile);
  lua_setglobal(L, 'include');
  lua_pushcfunction(L, SendChatMessage);
  lua_setglobal(L, 'SendChatMessage');
end;

procedure LoadBaseUI();
begin
  L := lua_open();
  luaopen_base(L);
  luaopen_table(L);
  luaopen_io(L);
  luaopen_string(L);
  luaopen_math(L);
  luaopen_loadlib(L);
end;

procedure InitInterface();
begin
	if loaded then
		lua_close(L);
	loaded := true;
	LoadBaseUI();
	LoadLuaModules();

	LoadLuaFile('Interface.lua');
	Log('Interface Loaded');
end;

end.
