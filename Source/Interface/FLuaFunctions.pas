unit FLuaFunctions;
interface

uses
  FLua;

const
  EVENT_SELECTIONCHANGE = 1;
  EVENT_ONMOUSEDOWN = 2;
  EVENT_ONMOUSEUP = 3;
  EVENT_UNITACTION = 4;
  EVENT_UNITSTOPACTION = 5;
  EVENT_ONEFFECT = 6;
  EVENT_ONSERVERDISCONNECT = 7;
  EVENT_BUILDINGQUEUE = 8;
  EVENT_WARNING = 9;
  EVENT_TRAINING = 10;
  EVENT_POPCHANGE = 11;
type
  string255 = string[255];

var
  L : lua_State = nil;
  InterfaceLoaded : boolean;
  procedure InitInterface();
  procedure LoadLuaFile(path: string);
  procedure RunScript(text : string); overload;
  procedure TriggerEvent(eventID : Integer);
  procedure HandleKeyDownLoop(id : integer);
  procedure HandleKeyDown(key : Char);
  procedure AddServerList4(ip, serverName : string255 ; player_count : integer ; map : string255);
  procedure AddServerList5(nick, ip : string ; race, color, team : integer);
  procedure AddServerList1(map : string255);
  procedure MenuListBoxClear(ListBox : string);
  function RefreshPlayerList(L: lua_State) : Integer; cdecl;

implementation
uses
	Windows, SysUtils, Forms, FLogs, FXMLLoader, FInterfaceUtils,
  FTransmit, FFPS, ClipBrd, FData, FUnit, FSelection, FCursor, FFonts,
  FRedirect, FGlWindow, FKeys, FInterfaceDraw, FServer, FTextures,
  FModel, Math, FConfig;


function LogLua(L: lua_State) : Integer; cdecl; overload;
begin
  Log(lua_tostring(L, 1));
  Result := 1;
end;

function Quit(L: lua_State) : Integer; cdecl; overload;
begin         
  Screen_Quit();
  Result := 1;
end;

function GetElapsed(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Count.Elapsed);
  Result := 1;
end;

function Time(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Count.Now);
  Result := 1;
end;

function Lua_IsWinKeyDown(L : lua_State) : Integer; cdecl;
begin
  lua_pushboolean(L, IsWinKeyDown(Round(lua_tonumber(L, 1))));
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//            NETWORK                //
// - - - - - - - - - - - - - - - - - //

function SendChatMessage(L: lua_State) : Integer; cdecl;
var
  text: PChar;
  s : string;
begin
  text := lua_tostring(L, 1);
  s := string(text);
  sendServerString(s);
  Result := 1;
end;

function SetServer(L: lua_State) : Integer; cdecl;
var
  ServerIP : string;        //   /connect 192.168.0.112
begin
  ServerIP := lua_tostring(L, 1);
  GlobalServerIP := ServerIP;
  sendNetworkSetServer(ServerIP, 'Unknown soldier');
  result := 1;
end;

function SetNick(L: lua_State) : Integer; cdecl;
var
  Nick : string;
begin
  Nick := lua_tostring(L, 1);
  ClientTab.tab[0].info.Nick := Nick;
  Addline('Nick set to ' + Nick);
  result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//              MENU                 //
// - - - - - - - - - - - - - - - - - //

function Refresh(L: lua_State) : Integer; cdecl;
begin
  Log('Broadcasted by menu');
  broadcast();
  result := 1;
end;

procedure AddServerList4(ip, serverName : string255 ; player_count : integer ; map : string255);
var
  ip_str, serverName_str, map_str : string;
begin
  if InterfaceLoaded then begin
    ip_str := ip;
    serverName_str := serverName;
    map_str := map;
    lua_getglobal(L, 'AddServerList4');
    lua_pushstring(L, PChar(ip_str));
    lua_pushstring(L, PChar(serverName_str));
    lua_pushnumber(L, player_count);
    lua_pushstring(L, PChar(map_str));
    lua_call(L, 4, 0);
  end;
end;

function RefreshPlayerList(L: lua_State) : Integer; cdecl;
var
  i : integer;
begin
  MenuListBoxClear('PlayerList');
  i := 0;
  while i <= ClientTab.tab[0].publicPlayerList.count - 1 do begin
    AddserverList5(ClientTab.tab[0].publicPlayerList.tab[i].nick,
                   ClientTab.tab[0].publicPlayerList.tab[i].ip,
                   ClientTab.tab[0].publicPlayerList.tab[i].race,
                   ClientTab.tab[0].publicPlayerList.tab[i].color,
                   ClientTab.tab[0].publicPlayerList.tab[i].team    );
    inc(i);
  end;
  result := 1;
end;

procedure AddServerList5(nick, ip : string ; race, color, team : integer);
begin
  if InterfaceLoaded then begin
    lua_getglobal(L, 'AddServerList5');
    lua_pushstring(L, PChar(nick));
    lua_pushstring(L, PChar(ip));
    lua_pushnumber(L, race);
    lua_pushnumber(L, color);
    lua_pushnumber(L, team);
    lua_call(L, 5, 0);
  end;
end;

procedure AddServerList1(map : string255);
var
  map_str : string;
begin
  if InterfaceLoaded then begin
    map_str := map;
    lua_getglobal(L, 'AddServerList1');
    lua_pushstring(L, PChar(map_str));
    lua_call(L, 1, 0);
  end;
end;

procedure MenuListBoxClear(ListBox : string);
begin
  if InterfaceLoaded then begin
    lua_getglobal(L, 'ListBoxClear');
    lua_pushstring(L, PChar(ListBox));
    lua_call(L, 1, 0);
  end;
end;


function ConnectFromMenu(L: lua_State) : Integer; cdecl;
var
  ip : string;
  nick : string255;
  cfg : TConfig;
begin
  cfg := TCOnfig.Create;
  ip := lua_tostring(L, 1);
  nick := lua_tostring(L, 2);
  cfg.set_nick(nick);
  ClientTab.tab[0].info.nick := nick;
  GlobalServerIP := ip;
  sendNetworkSetServer(ip, nick);
  result := 1;
end;

function DisconnectFromMenu(L: lua_State) : Integer; cdecl;
begin
  if GlobalServerIP <> '127.0.0.1' then begin
    sendDisconnectClient(GlobalServerIP, GlobalClientIP);
    GlobalServerIP := '127.0.0.1';
  end;
  result := 1;
end;

function CreateServerFromMenu(L: lua_State) : Integer; cdecl;
var
  serverName, map : string;
  cfg : TConfig;
begin
  serverName := lua_tostring(L, 1);
  cfg := TConfig.Create;
  cfg.set_serverName(serverName);
  map := lua_tostring(L, 2);
  CreateServer(serverName, map);
  result := 1;
end;

function UndoCreateServerFromMenu(L: lua_State) : Integer; cdecl;
var
  i : integer;
begin
  if GlobalServerIP = '127.0.0.1' then begin
    i := 1;
    while (i < CLientTab.size) and (ClientTab.Tab[i] <> NIL) do begin
      disconnectAllClients();
      DestroyClient(ClientTab.tab[i].ip);
    end;
    ClientTab.tab[0].pings.Clear;
    ClientTab.tab[0].is_server := false;
    Log('Server destroyed');
  end;
  result := 1;
end;

function SetNickFromMenu(L: lua_State) : Integer; cdecl;
var
  cfg : TConfig;
  nick : string;
begin
  nick := lua_tostring(L, 1);
  cfg := TConfig.Create;
  cfg.set_nick(nick);
  ClientTab.tab[0].info.nick := nick;
  ClientTab.tab[0].publicPlayerList.tab[0].refresh(-1,
                                                   -1,
                                                   -1,
                                                   nick,
                                                   ''                         );
  result := 1;
end;

function BroadCastLaunchGame_(L: lua_State) : Integer; cdecl;
begin
  ClientTab.tab[0].serverIsRunning := true;
  BroadCastLaunchGame();
  result := 1;
end;

function SynchroniseClients(L: lua_State) : Integer; cdecl;
var
  i, return : integer;
begin
  i := 0;
  return := 1;
  while CLientTab.tab[i] <> NIL do begin
    ping(ClientTab.tab[i].ip);
    if ClientTab.tab[i]^.synchroPing = -1 then begin
      inc(return);
    end;
  inc(i);
  end;
  lua_pushnumber(L, return);
  result := 1;
end;

function max(a, b : integer) : integer;
begin
  if a >= b then
    result := a
  else
    result := b;
end;

function MaxWaitingTime(L : Lua_State) : integer; cdecl;
var
  i : integer;
  maxi : integer;
begin
  i := 0;
  maxi := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    maxi := max(maxi, 10 - ClientTab.tab[i].pings.Count);
    inc(i);
  end;
  lua_PushNumber(L, maxi);
  result := 1;
end;

function requestUpdatePlayerList(L : Lua_State) : integer; cdecl;
var
  myId, color, race, team : integer;
  nick : string;
begin
  myId := round(lua_tonumber(L, 1));
  color := round(lua_tonumber(L, 2));
  race := round(lua_tonumber(L, 3));
  team := round(lua_tonumber(L, 4));
  nick := lua_tostring(L, 5);

  requestUpdatePublicPlayerList(myId,
                                color,
                                race,
                                team,
                                nick  );
  result := 1;
end;

function getNickFromMenu(L : Lua_State) : integer; cdecl;
begin
  lua_pushstring(L, PChar(ClientTab.tab[0]^.info.nick));
  result := 1;
end;

function getServerNameFromMenu(L : Lua_State) : integer; cdecl;
var
  cfg : TConfig;
begin
  cfg := TConfig.create;
  lua_pushstring(L, PChar(cfg.get_serverName));
  result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//            TEXTURES               //
// - - - - - - - - - - - - - - - - - //

function SetPath(L: lua_State) : Integer; cdecl;
var
  id : integer;
begin
  if FindTextureByName(id, lua_tostring(L, 1)) then begin
    TextureList[id].Path := lua_tostring(L, 2);
    TextureList[id].GLID := LoadTexture(TextureList[id].Path);
  end;
  Result := 1;
end;

function GetPath(L : lua_State) : Integer; cdecl;
var
  id : integer;
begin
  if FindTextureByName(id, lua_tostring(L, 1)) then
    lua_pushstring(L, PChar(TextureList[id].Path))
  else
    lua_pushstring(L, '');
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//          FONT STRINGS             //
// - - - - - - - - - - - - - - - - - //

function SetText(L: lua_State) : Integer; cdecl;
var
  id : integer;
begin
  if FindFontStringByName(id, lua_tostring(L, 1)) then begin
    FontStringList[id].Text := lua_tostring(L, 2);
    SetStringSize(FontStringList[id].width, FontStringList[id].height, FontStringList[id].FontID, FontStringList[id].Text);
  end;
  Result := 1;
end;

function GetText(L : lua_State) : Integer; cdecl;
var
  id : integer;
begin
  if FindFontStringByName(id, lua_tostring(L, 1)) then
    lua_pushstring(L, PChar(FontStringList[id].Text))
  else
    lua_pushstring(L, '');
  Result := 1;
end;

function GetStringWidth(L : lua_State) : Integer; cdecl;
var
  x, y : integer;
begin
  SetStringSize(x, y, Trunc(lua_tonumber(L, 2)), lua_tostring(L, 1));
  lua_pushnumber(L, x);
  Result := 1;
end;

function GetStringHeight(L : lua_State) : Integer; cdecl;
var
  x, y : integer;
begin
  SetStringSize(x, y, Trunc(lua_tonumber(L, 2)), lua_tostring(L, 1));
  lua_pushnumber(L, y);
  Result := 1;
end;

function GetFont(L : lua_State) : Integer; cdecl;
var
  id : integer;
begin
  if FindFontStringByName(id, lua_tostring(L, 1)) then
    lua_pushnumber(L, FontStringList[id].FontID)
  else
    lua_pushnumber(L, 0);
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//            COMPONENT              //
// - - - - - - - - - - - - - - - - - //

         
function GetParent(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    lua_pushstring(L, PChar(FrameList[c.Parent].Name));
  end else begin
    lua_pushstring(L, '');
  end;
  Result := 1;
end;

function GetX(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    lua_pushnumber(L, c.Anchor.x);
  end else begin
    lua_pushnumber(L, 0);
    lua_pushnumber(L, 0);
  end;
  Result := 1;
end;

function GetY(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    lua_pushnumber(L, c.Anchor.y);
  end else begin
    lua_pushnumber(L, 0);
    lua_pushnumber(L, 0);
  end;
  Result := 1;
end;

function SetX(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    c.Anchor.x := Trunc(lua_tonumber(L, 2));
  end;
  Result := 1;
end;

function SetY(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    c.Anchor.y := Trunc(lua_tonumber(L, 2));
  end;
  Result := 1;
end;

function SetColor(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
  begin
    c.Color.r := Round(lua_tonumber(L, 2));
    c.Color.g := Round(lua_tonumber(L, 3));
    c.Color.b := Round(lua_tonumber(L, 4));
  end;
  Result := 1;
end;

function SetSize(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then begin
    c.width := Trunc(lua_tonumber(L, 2));
    c.height := Trunc(lua_tonumber(L, 3));
  end;
  Result := 1;
end;

function SetWidth(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    c.Width := Trunc(lua_tonumber(L, 2));
  Result := 1;
end;

function GetWidth(L : lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    lua_pushnumber(L, GetRealWidth(@c))
  else
    lua_pushnumber(L, 0);
  Result := 1;
end;

function SetHeight(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    c.Height := Trunc(lua_tonumber(L, 2));
  Result := 1;
end;

function GetHeight(L : lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    lua_pushnumber(L, GetRealHeight(@c))
  else
    lua_pushnumber(L, 0);
  Result := 1;
end;

function SetVisible(L: lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    c.Hidden := not lua_toboolean(L, 2);
  Result := 1;
end;

function IsVisible(L : lua_State) : Integer; cdecl;
var
  c : Component;
begin
  if FindComponentByName(c, lua_tostring(L, 1)) then
    lua_pushboolean(L, not c.Hidden)
  else
    lua_pushboolean(L, false);
  Result := 1;
end;
                  
// - - - - - - - - - - - - - - - - - //
//               MISC                //
// - - - - - - - - - - - - - - - - - //

function GetFPS(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Count.FPS);
  Result := 1;
end;

function GetClipBoard(L : lua_State) : Integer; cdecl;
begin
  lua_pushstring(L, PChar(Clipboard.AsText));
  Result := 1;
end;

function GetControlState(L : lua_State) : Integer; cdecl;
begin
  lua_pushboolean(L, isWinKeyDown(VK_CONTROL));
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//              CURSOR               //
// - - - - - - - - - - - - - - - - - //

function SetMode(L : lua_State) : Integer; cdecl;
var
  orderID : integer;
  order : TOrderType;
begin
  CancelMouseAction();
  orderID := Round(lua_tonumber(L, 1));
  case orderID of
    1 : order := MOVETO;
    4 : order := ATTACK;
    5 : order := PATROL;
    6 : order := REPAIR;
    else order := STOP;
  end;
  if order <> STOP then  
    SetMouseMode(order);
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//              UNITS                //
// - - - - - - - - - - - - - - - - - //

function GetUnitRace(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, TUnit(UnitList[UnitID]).Stats.Race)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetRes1(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Round(ClientTab.tab[0].info.res1));
  Result := 1;
end;

function GetRes2(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Round(ClientTab.tab[0].info.res2));
  Result := 1;
end;

function GetPopCount(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Round(ClientTab.tab[0].info.unitcount));
  Result := 1;
end;

function ValidUnit(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  lua_pushboolean(L, (UnitID < UnitList.Count) and (UnitID <> -1) and (TUnit(UnitList[UnitID]).Player = Player));
  Result := 1;
end;

function GetMouseHoverUnit(L : lua_State) : Integer; cdecl;
begin
  if Mouse.Hover then
    lua_pushnumber(L, Mouse.HoverList[0])
  else
    lua_pushnil(L);
  Result := 1;
end;

function Hold(L : lua_State) : Integer; cdecl;
var
  o    : Porder;
begin
  if (Selection.Count > 0) then
  begin
    New(o);
    o^.action := HOLDPOS;
    selection.issueOrder(o);
  end
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function Wound(L : lua_State) : Integer; cdecl;
var
  UnitID, amount : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  amount := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    TUnit(UnitList[UnitID]).Wound(amount)
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function StopUnit(L : lua_State) : Integer; cdecl;
var
  o : Porder;
begin
  if (Selection.Count > 0) then
  begin
    New(o);
    o^.action := STOP;
    selection.issueOrder(o);
  end
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetHP(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).HP))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetMaxHP(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).MaxHP))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetMP(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).MP))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetMaxMP(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).MaxMp))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBaseDamage(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).Stats.Damage))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBaseDefense(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).Stats.Defense))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetNbUnitVisible(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Length(VisibleUnits));
  Result := 1;
end;

function GetUnitVisibleID(L : lua_State) : Integer; cdecl;
var
  id : integer;
begin
  id := Round(lua_tonumber(L, 1));
  if id < Length(VisibleUnits) then
   lua_pushnumber(L, VisibleUnits[id])
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetNbUnitSelect(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Selection.Count);
  Result := 1;
end;

function GetUnitSelectedID(L : lua_State) : Integer; cdecl;
var
  id : integer;
begin
  id := Round(lua_tonumber(L, 1));
  if id < Selection.Count then
   lua_pushnumber(L, UnitList.IndexOf(Selection[id]))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetPlayerID(L : lua_State) : Integer; cdecl;
begin
  lua_pushnumber(L, Player);
  Result := 1;
end;

function GetDefense(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).Defense))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetDamage(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, Round(TUnit(UnitList[UnitID]).Damage))
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function ChangeSelectedUnit(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID <> -1) and (UnitID < UnitList.Count) then
  begin
    Selection.Clear();
    selection.addUnit(UnitID);
  end
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetPosX(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, TUnit(UnitList[UnitID]).pos.X)
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetPosY(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, TUnit(UnitList[UnitID]).pos.Y)
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetInterfacePosX(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, TUnit(UnitList[UnitID]).InterfacePos.X)
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetInterfacePosY(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushnumber(L, TUnit(UnitList[UnitID]).InterfacePos.Y)
  else
   lua_pushnumber(L, -1);
  Result := 1;
end;

function GetName(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));

  if (UnitID > -1) and (UnitID < UnitList.Count) then
   lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Name))
  else
   lua_pushstring(L, '');
  Result := 1;
end;

function GetOrder(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, get_buttonID(TUnit(UnitList[UnitID]).get_mode))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAggressivity(L : lua_State) : Integer; cdecl;
var
  UnitID, order : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  order := 0;
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    case TUnit(UnitList[UnitID]).Aggressivity of
      PASSIVE : order := 1;
      DEFENSIVE : order := 2;
      AGGRESSIVE : order := 3
    end;
    lua_pushnumber(L, order)
  end
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetEffectsCount(L : lua_State) : Integer; cdecl;
var
  UnitID, i, num : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    num := 0;
    for i := 0 to TUnit(UnitList[UnitID]).Effects.Count - 1 do
    begin
      if not PTimerEffect(TUnit(UnitList[UnitID]).Effects[i])^.Temporary then
        inc(num);
    end;
    lua_pushnumber(L, num)
  end
  else
    lua_pushnumber(L, -1);
 Result := 1;
end;

function GetEffectID(L : lua_State) : Integer; cdecl;
var
  UnitID, EffectID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  EffectID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if EffectID < TUnit(UnitList[UnitID]).Effects.Count then
      lua_pushnumber(L, PTimerEffect(TUnit(UnitList[UnitID]).Effects[0])^.Ability.ID)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAbilityCount(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Length(TUnit(UnitList[UnitID]).Abilities))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingsCount(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));;
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Length(TUnit(UnitList[UnitID]).Stats.Buildings))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUpgradesCount(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Length(TUnit(UnitList[UnitID]).Stats.Upgrades))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUpgradeToolTip(L : lua_State) : Integer; cdecl;
var
  UnitID, UpgradeID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  UpgradeID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Upgrades[UpgradeID].ToolTip))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function LaunchUpgrade(L : lua_State) : Integer; cdecl;
var
  UnitID, UpgradeID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  UpgradeID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    ApplyUpgrade(TUnit(UnitList[UnitID]).Stats.Upgrades[UpgradeID]);
  Result := 1;
end;

function GetUpgradeName(L : lua_State) : Integer; cdecl;
var
  UnitID, UpgradeID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  UpgradeID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Upgrades[UpgradeID].Name))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function IsUpgradeAvailable(L : lua_State) : Integer; cdecl;
var
  UnitID, UpgradeID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  UpgradeID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushboolean(L, CurrentUpgrades.IndexOf(TUnit(UnitList[UnitID]).Stats.Upgrades[UpgradeID]) = -1)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUpgradeIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, UpgradeID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  UpgradeID := Round(lua_tonumber(L, 2));
  if UnitID < UnitList.Count then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Upgrades[UpgradeID].Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;


function GetAbilityIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if UnitID < UnitList.Count then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability.Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAbilityShortcut(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
  s : string;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  s := TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability.shortcut;
  if UnitID < UnitList.Count then
    lua_pushstring(L, PChar(s))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAbilityToolTip(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability.ToolTip))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAbilityName(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability.Name))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetAbilityCost(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability.Cost)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetIsAbilityAvailable(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    begin
      if AbilityID < Length(TUnit(UnitList[UnitID]).Abilities) then
        lua_pushboolean(L, TUnit(UnitList[UnitID]).Abilities[AbilityID].cooldown = 0)
      else
        lua_pushboolean(L, false);
    end
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetCooldownRemainingTime(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, Ceil(TUnit(UnitList[UnitID]).Abilities[AbilityID].cooldown*TURN_LENGTH / 1000))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetEffectIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, EffectID, i : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  EffectID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    i := 0;
    while (i < TUnit(UnitList[UnitID]).Effects.Count) and (EffectId > 0) do
    begin
      if not PTimerEffect(TUnit(UnitList[UnitID]).Effects[i])^.Temporary then
        dec(EffectID);
      if EffectID <> 0 then      
        inc(i)
    end;
    if i <> TUnit(UnitList[UnitID]).Effects.Count then
      lua_pushstring(L, PChar(PTimerEffect(TUnit(UnitList[UnitID]).Effects[i])^.Ability.Icon))
    else
      lua_pushnumber(L, -1)
  end
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingToolTip(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]^.ToolTip))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingName(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]^.Name))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]^.Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingRes1Cost(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]^.Res1Cost)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingRes2Cost(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushnumber(L, TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]^.Res2Cost)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUnitIcon(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(UnitList[UnitID]).Stats.Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUnitInQueueIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, QueueID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  QueueID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(PUnitAttributes(TUnit(UnitList[UnitID]).BuildingQueue[QueueID-1]).Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetUnitInTrainingListIcon(L : lua_State) : Integer; cdecl;
var
  UnitID, ListID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  ListID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushstring(L, PChar(TUnit(TUnit(UnitList[UnitID]).TrainingList[ListID-1]).Stats.Icon))
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;


function DeleteFromBuildingQueue(L : lua_State) : Integer; cdecl;
var
  UnitID, QueueID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  QueueID := Round(lua_tonumber(L, 2));
  TUnit(UnitList[UnitID]).BuildingQueue.Delete(QueueID-1);
  if QueueID = 1 then
    TUnit(UnitList[UnitID]).Progression := 0;
  TriggerEvent(EVENT_BUILDINGQUEUE);
  Result := 1;
end;

function DeleteFromTrainingList(L : lua_State) : Integer; cdecl;
var
  UnitID, ListID : integer;
  o : Porder;
begin
  UnitID := Round(lua_tonumber(L, 1));
  ListID := Round(lua_tonumber(L, 2));
  new(o);
  o^.action := UNTRAIN;
  o^.target.unit_ := UnitList[UnitID];
  TUnit(TUnit(UnitList[UnitID]).TrainingList[ListID-1]).issue_order(o);
  TriggerEvent(EVENT_TRAINING);
  Result := 1;
end;

function GetTrainingListLength(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
      lua_pushnumber(L, TUnit(UnitList[UnitID]).TrainingList.count)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function AbilityCast(L : lua_State) : Integer; cdecl;
var
  UnitID, AbilityID : integer;
  ability : PAbility;
begin
  UnitID := Round(lua_tonumber(L, 1));
  AbilityID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    ability := TUnit(UnitList[UnitID]).Abilities[AbilityID].Ability;
    if ability.target = Myself then
      TUnit(UnitList[UnitID]).AbilityCast(TUnit(UnitList[UnitID]), AbilityID)
    else
      SetCastMode(AbilityID)
  end;
  Result := 1;
end;

function SetBuilding(L : lua_State) : Integer; cdecl;
var
  UnitID, BuildingID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  BuildingID := Round(lua_tonumber(L, 2));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
    begin
      TUnit(UnitList[UnitID]).AddBuildingQueue(TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID])
    end
    else
    begin
      SetBuildingMode(TUnit(UnitList[UnitID]).Stats.Buildings[BuildingID]);
    end;
  end;
  Result := 1;
end;

function IsRepairer(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
  begin
    if TUnit(UnitList[UnitID]).Stats.Repairer and TUnit(UnitList[UnitID]).Active then
      lua_pushboolean(L, true)
    else
      lua_pushboolean(L, false)
  end
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function IsBuilding(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    lua_pushboolean(L, TUnit(UnitList[UnitID]).Stats.IsBuilding)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function IsBuildingQueueEmpty(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
      lua_pushboolean(L, TUnit(UnitList[UnitID]).BuildingQueue.Count = 0)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingQueueLength(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
      lua_pushnumber(L, TUnit(UnitList[UnitID]).BuildingQueue.count)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetProgressionPercent(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
      lua_pushnumber(L, TUnit(UnitList[UnitID]).Progression)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetBuildingPercent(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
    if TUnit(UnitList[UnitID]).Stats.IsBuilding then
      lua_pushnumber(L, TUnit(UnitList[UnitID]).ConstructionPercent)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;




function IsInConstruction(L : lua_State) : Integer; cdecl;
var
  UnitID : integer;
begin
  UnitID := Round(lua_tonumber(L, 1));
  if (UnitID > -1) and (UnitID < UnitList.Count) then
      lua_pushboolean(L, TUnit(UnitList[UnitID]).ConstructionPercent < 1)
  else
    lua_pushnumber(L, -1);
  Result := 1;
end;

function GetWarningText(L : lua_State) : Integer; cdecl;
begin
  lua_pushstring(L, PChar(Warning.Text));
  Result := 1;
end;

// - - - - - - - - - - - - - - - - - //
//            CONTROLS               //
// - - - - - - - - - - - - - - - - - //

procedure TriggerEventLoop(id : integer);
var
  i : integer;
begin
  if not FrameList[id].Hidden and not FrameList[id].Virtual then begin
    lua_pushstring(L, PChar(FrameList[id].Name));
    lua_setglobal(L, 'self');
    RunScript(FrameList[id].Scripts.OnEvent);

    for i := 0 to FrameList[id].FramesCount - 1 do
      TriggerEventLoop(FrameList[id].Frames[i]);
  end;
end;

procedure TriggerEvent(eventID : Integer);
begin
  lua_pushnumber(L, eventID);
  lua_setglobal(L, 'event');
  TriggerEventLoop(0);
end;

procedure HandleKeyDownLoop(id : integer);
var
  i : integer;
begin
  if not FrameList[id].Hidden and not FrameList[id].Virtual then begin
    if FrameList[id].EnableKeyboard and (FrameList[id].Scripts.OnKeyDown <> '') then begin
      lua_pushstring(L, PChar(FrameList[id].Name));
      lua_setglobal(L, 'self');
      RunScript(FrameList[id].Scripts.OnKeyDown);
    end;

    for i := 0 to FrameList[id].FramesCount - 1 do
      HandleKeyDownLoop(FrameList[id].Frames[i]);
  end;
end;

procedure HandleKeyDown(key : Char);
begin
  lua_pushnumber(L, Ord(key));
  lua_setglobal(L, 'arg1');
  HandleKeyDownLoop(0);
end;

function RunScript(L: lua_State) : Integer; cdecl; overload;
var
  text: PChar;
begin
  text := lua_tostring(L, 1);
  if (luaL_loadbuffer(L, PChar(text), strlen(PChar(text)), 'line') <> 0
    or lua_pcall(L, 0, 0, 0)) then begin
    Log(lua_tostring(L,-1));
  end;
  Result := 1;
end;

procedure RunScript(text : string); overload;
begin
  if text = '' then
    exit;
  if (luaL_loadbuffer(L, PChar(text), strlen(PChar(text)), 'line') <> 0)
    or (lua_pcall(L, 0, 0, 0) <> 0) then
    Log(lua_tostring(L, -1), LOG_WARNING);
end;

procedure LoadLuaFile(path: string);
begin
  Log('Loading ' + path);
  if not FileExists(path) then begin
    Log('File `' + path + '` does not exist', LOG_WARNING);
    exit;
  end;
  if (luaL_loadfile(L, PChar(path)) <> 0)
      or (lua_pcall(L, 0, 0, 0) <> 0) then
    Log(lua_tostring(L,-1), LOG_WARNING);
end;

function IncludeFile(L: lua_State) : Integer; cdecl;
var text: PChar;
begin
  text := lua_tostring(L, 1);
  LoadLuaFile(text);
  Result := 1;
end;

procedure AddFunction(f : lua_CFunction; s : string);
begin
  lua_pushcfunction(L, f);
  lua_setglobal(L, PChar(s));
end;

procedure LoadLuaModules(); cdecl;
begin
  AddFunction(Lua_IsWinKeyDown, 'IsWinKeyDown');
  AddFunction(RunScript, 'RunScript');
  AddFunction(LogLua, 'Log');
  AddFunction(IncludeFile, 'include');
  AddFunction(SendChatMessage, 'SendChatMessage');
  AddFunction(SetServer, 'SetServer');
  AddFunction(SetNick, 'SetNick');
  AddFunction(Refresh, 'Refresh');
  AddFunction(RefreshPlayerList, 'RefreshPlayerList');
  AddFunction(ConnectFromMenu, 'ConnectFromMenu');
  AddFunction(DisconnectFromMenu, 'DisconnectFromMenu');
  AddFunction(CreateServerFromMenu, 'CreateServerFromMenu');
  AddFunction(UndoCreateServerFromMenu, 'UndoCreateServerFromMenu');
  AddFunction(MaxWaitingTime, 'MaxWaitingTime');
  AddFunction(SetNickFromMenu, 'SetNickFromMenu');
  AddFunction(getNickFromMenu, 'getNickFromMenu');
  AddFunction(getServerNameFromMenu, 'getServerNameFromMenu');
  AddFunction(BroadCastLaunchGame_, 'BroadCastLaunchGame_');
  AddFunction(SynchroniseClients, 'SynchroniseClients');
  AddFunction(GetElapsed, 'GetElapsed');
  AddFunction(GetFPS, 'GetFPS');
  AddFunction(GetParent, 'GetParent');
  AddFunction(GetClipBoard, 'GetClipBoard');
  AddFunction(GetControlState, 'GetControlState');
  AddFunction(SetMode, 'SetMode');
  AddFunction(GetUnitRace, 'GetUnitRace');
  AddFunction(GetRes1, 'GetRes1');
  AddFunction(GetRes2, 'GetRes2');
  AddFunction(GetPopCount, 'GetPopCount');
  AddFunction(Hold, 'Hold');
  AddFunction(Wound, 'Wound');
  AddFunction(StopUnit, 'StopUnit');
  AddFunction(GetHP, 'GetHP');
  AddFunction(GetMP, 'GetMP');
  AddFunction(GetMaxHP, 'GetMaxHP');
  AddFunction(GetMaxMP, 'GetMaxMP');
  AddFunction(GetName, 'GetName');
  AddFunction(GetPosX, 'GetPosX');
  AddFunction(GetPosY, 'GetPosY');
  AddFunction(GetInterfacePosX, 'GetInterfacePosX');
  AddFunction(GetInterfacePosY, 'GetInterfacePosY');    
  AddFunction(GetNbUnitSelect, 'GetNbUnitSelect');
  AddFunction(GetUnitSelectedID, 'GetUnitSelectedID');
  AddFunction(GetNbUnitVisible, 'GetNbUnitVisible');
  AddFunction(GetUnitVisibleID, 'GetUnitVisibleID');
  AddFunction(GetPlayerID, 'GetPlayerID');
  AddFunction(GetDefense, 'GetDefense');
  AddFunction(GetDamage, 'GetDamage');
  AddFunction(GetBaseDefense, 'GetBaseDefense');
  AddFunction(GetBaseDamage, 'GetBaseDamage');
  AddFunction(GetOrder, 'GetOrder');
  AddFunction(GetAggressivity, 'GetAggressivity');
  AddFunction(GetEffectsCount, 'GetEffectsCount');
  AddFunction(GetUnitIcon, 'GetUnitIcon');
  AddFunction(GetEffectID, 'GetEffectID');
  AddFunction(GetAbilityCount, 'GetAbilityCount');
  AddFunction(GetBuildingsCount, 'GetBuildingsCount');
  AddFunction(LaunchUpgrade, 'LaunchUpgrade');
  AddFunction(IsUpgradeAvailable, 'IsUpgradeAvailable');
  AddFunction(GetUpgradesCount, 'GetUpgradesCount');
  AddFunction(GetUpgradeName, 'GetUpgradeName');
  AddFunction(GetUpgradeToolTip, 'GetUpgradeToolTip');
  AddFunction(GetUpgradeIcon, 'GetUpgradeIcon');
  AddFunction(GetAbilityShortcut, 'GetAbilityShortcut');
  AddFunction(GetAbilityToolTip, 'GetAbilityToolTip');
  AddFunction(GetAbilityCost, 'GetAbilityCost');
  AddFunction(GetCooldownRemainingTime, 'GetCooldownRemainingTime');
  AddFunction(GetIsAbilityAvailable, 'GetIsAbilityAvailable');
  AddFunction(GetBuildingToolTip, 'GetBuildingToolTip');
  AddFunction(GetBuildingRes1Cost, 'GetBuildingRes1Cost');
  AddFunction(GetBuildingRes2Cost, 'GetBuildingRes2Cost');
  AddFunction(GetAbilityName, 'GetAbilityName');
  AddFunction(GetBuildingName, 'GetBuildingName');
  AddFunction(GetEffectIcon, 'GetEffectIcon');
  AddFunction(GetAbilityIcon, 'GetAbilityIcon');
  AddFunction(GetBuildingIcon, 'GetBuildingIcon');
  AddFunction(SetBuilding, 'SetBuilding');
  AddFunction(AbilityCast, 'AbilityCast');
  AddFunction(IsRepairer, 'IsRepairer');
  AddFunction(ChangeSelectedUnit, 'ChangeSelectedUnit');
  AddFunction(IsBuilding, 'IsBuilding');
  AddFunction(IsBuildingQueueEmpty, 'IsBuildingQueueEmpty');
  AddFunction(GetBuildingQueueLength, 'GetBuildingQueueLength');
  AddFunction(GetProgressionPercent, 'GetProgressionPercent');
  AddFunction(GetBuildingPercent, 'GetBuildingPercent');
  AddFunction(DeleteFromBuildingQueue, 'DeleteFromBuildingQueue');
  AddFunction(DeleteFromTrainingList, 'DeleteFromTrainingList');
  AddFunction(GetTrainingListLength, 'GetTrainingListLength');
  AddFunction(GetUnitInQueueIcon, 'GetUnitInQueueIcon');
  AddFunction(GetUnitInTrainingListIcon, 'GetUnitInTrainingListIcon');
  AddFunction(IsInConstruction, 'IsInConstruction');
  AddFunction(ValidUnit, 'ValidUnit');
  AddFunction(GetWarningText, 'GetWarningText');
  AddFunction(GetMouseHoverUnit, 'GetMouseHoverUnit');
  AddFunction(SetX, 'SetX');
  AddFunction(SetY, 'SetY');
  AddFunction(GetX, 'GetX');
  AddFunction(GetY, 'GetY');
  AddFunction(GetStringWidth, 'GetStringWidth');
  AddFunction(GetStringHeight, 'GetStringHeight');
  AddFunction(GetFont, 'GetFont');
  AddFunction(SetSize, 'SetSize');
  AddFunction(SetText, 'SetText');
  AddFunction(SetColor, 'SetColor');
  AddFunction(GetText, 'GetText');
  AddFunction(GetPath, 'GetPath');
  AddFunction(SetPath, 'SetPath');
  AddFunction(GetWidth, 'GetWidth');
  AddFunction(SetWidth, 'SetWidth');
  AddFunction(GetHeight, 'GetHeight');
  AddFunction(SetHeight, 'SetHeight');
  AddFunction(SetVisible, 'SetVisible');
  AddFunction(IsVisible, 'IsVisible');
  AddFunction(Quit, 'Quit');
  AddFunction(Time, 'Time');
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
	LoadBaseUI();
	LoadLuaModules();
end;

end.
