unit FKeys;


interface
uses
	Windows, Forms, FStructure, FLoader, Classes, FLogs, FFps, FLuafunctions, FLua,
  SysUtils, FData, FTerrain, FCursor, FTransmit, FXMLLoader, FSelection,
  Funit, Fmap, FInterfaceUtils, FBallistic, FRedirect, FSound;

var
	KeyList : array[0..400] of Integer;
const
	FO_LEFT = 0;
	FO_RIGHT = 1;
	FO_UP = 2;
	FO_DOWN = 3;

procedure InitKeys();
function isKeyDown(key : Integer) : boolean;
function isWinKeyDown(key : Integer) : boolean;
procedure HandleKey(key : Word);

implementation
uses
  FGLWindow, FInterfaceDraw, FServer, FReceive, fmoddyn;

function isKeyDown(key : Integer) : boolean;
begin
	Result := (GetKeyState(KeyList[key]) AND 128) = 128;
end;

function isWinKeyDown(key : Integer) : boolean;
begin
	Result := (GetKeyState(key) AND 128) = 128;
end;

// http://delphi.about.com/od/objectpascalide/l/blvkc.htm
procedure InitKeys();
begin
	KeyList[FO_LEFT] 		:= VK_LEFT;
	KeyList[FO_RIGHT] 	:= VK_RIGHT;
	KeyList[FO_UP] 			:= VK_UP;
	KeyList[FO_DOWN] 		:= VK_DOWN;
end;


procedure HandleKey(key : Word);
var
  x, y, i, j, k, Index : integer;
  o : POrder;
  z : integer;
  p : PAbility;
//  iF6 : integer;
  F : TextFile;
begin
//  if (Key = VK_DOWN) or (Key = VK_LEFT) or (Key = VK_RIGHT) or (Key = VK_UP) then begin
    lua_pushnumber(L, -Key);
    lua_setglobal(L, 'arg1');
    HandleKeyDownLoop(0);
//  end;


  if (Key >= 48) and (Key <= 57) then  //0123456789
  begin
    i := Key - 48;
    if isWinKeyDown(VK_LCONTROL) and (Selection.Count > 0) then
    begin
      if TUnit(Selection[0]).Player = Player then
      begin
        SelectionGroups[i].Clear;
        for j := 0 to Selection.Count - 1 do
          SelectionGroups[i].Add(Selection[j]);
      end;
    end
    else
    if not(isWinKeyDown(VK_LCONTROL)) and not(isWinKeyDown(VK_SHIFT)) and (SelectionGroups[i].Count > 0) then
    begin
      CancelMouseAction();
      for j := 0 to Selection.Count - 1 do
        TUnit(Selection[j]).Selected := false;
      Selection.Clear;
      for j := 0 to SelectionGroups[i].Count - 1 do
      begin
        Selection.Add(SelectionGroups[i][j]);
        TUnit(Selection[j]).Selected := true;
      end;
    end
    else
    if isWinKeyDown(VK_SHIFT) and (Selection.Count > 0) then
    begin
      if TUnit(Selection[0]).Player = Player then
      begin
        for j := 0 to Selection.Count - 1 do
        begin
          if ValidAddInGroup(TUnit(Selection[j]), i) then
            SelectionGroups[i].Add(Selection[j]);
        end;
      end;
    end;
    if isWinKeyDown(VK_LCONTROL) and (Selection.Count = 0) then
    begin
      Warning.SetMsg('No unit selected.');
    end;
  end;


  if (Key = 83) and isWinKeyDown(VK_LCONTROL) then
  begin
    if wav_volume = 0 then
      wav_volume := DEFAULT_WAV_VOL
    else
      wav_volume := 0;
  end;


  if CurrentScreen = SCREEN_GAME then begin

  if (Selection.Count > 0) and not(TUnit(Selection[0]).Stats.IsBuilding) then
  begin
    if (Key = 65) and (Selection.Count > 0) then //touche a : Attaquer
    begin
      CancelMouseAction();
      SetMouseMode(ATTACK);
    end;

    if (Key = 86) and (Selection.Count > 0) then //touche v : Deplacement
    begin
      CancelMouseAction();
      SetMouseMode(MOVETO);
    end;

  if (Key = 83) and (Selection.Count > 0) then //touche s : Stop
  begin
    CancelMouseAction();
    New(o);
    o^.action := STOP;
    selection.issueOrder(o);
  end;

    if (Key = 84) and (Selection.Count > 0) then //touche t : Tenir Position
    begin
      CancelMouseAction();
      New(o);
      o^.action := HOLDPOS;
      selection.issueOrder(o);
    end;

    if (Key = 80) and (Selection.Count > 0) then //touche p : Patrouiller
    begin
      CancelMouseAction();
      SetMouseMode(PATROL);
    end;
  end;

  if (Key = 82) and (Selection.Count > 0) and TUnit(Selection[0]).Stats.Repairer then //touche r : Reparer
  begin
    CancelMouseAction();
    if TUnit(Selection[0]).Stats.Repairer then
      SetMouseMode(REPAIR);
  end;

  if (Key = 68) and (Selection.Count > 0) then //touche d
  begin
    p := @Abilities[6];
    if TUnit(Selection[0]).AlreadyAffected(p) then
      TUnit(Selection[0]).CancelEffect(p)
    else
      TUnit(Selection[0]).AbilityCast(TUnit(Selection[0]), 6);
  end;

  if (Key = 66) and (Selection.Count > 0) and (Length(TUnit(Selection[0]).Stats.Buildings) > 0) then //touche b
  begin
    if TUnit(Selection[0]).Stats.IsBuilding then
      TUnit(Selection[0]).AddBuildingQueue(TUnit(Selection[0]).Stats.Buildings[0])
    else
      SetBuildingMode(TUnit(Selection[0]).Stats.Buildings[0]);
  end;

  if (Key = VK_DELETE) and (Selection.Count > 0) then
    TUnit(Selection[0]).Wound(Round(TUnit(Selection[0]).Hp+1));

  if Selection.Count > 0 then
  begin
    Index := 0;
    j := Length(TUnit(Selection[Index]).Abilities) - 1;
    for i := 0 to j do
    begin
      if TUnit(Selection[Index]).Abilities[i].Ability^.shortcut = char(Key) then
      begin
        if TUnit(Selection[Index]).Abilities[i].Ability^.Target = MYSELF then
          TUnit(Selection[Index]).AbilityCast(TUnit(Selection[Index]), i)
        else
          SetCastMode(i);
        break
      end;
    end;
  end;
  end;

  if Key = VK_ESCAPE then begin
    Screen_Quit();
    exit;
  end;


  exit;





































  if Key = VK_F9 then begin
    CreateServer('ServerCreatedWithF9', 'MapF9');
    LaunchGame(0);
  end;



  if Key = VK_F1 then begin
    CleanupInterface();
    if CurrentScreen = SCREEN_MENU then
      LoadInterface(UIPATH_MENU);
    if CurrentScreen = SCREEN_GAME then
      LoadInterface(UIPATH_GAME);
  end;

  if CurrentScreen = SCREEN_MENU then
    exit;

  if (Key = VK_F2) and (CurrentScreen = SCREEN_GAME) then begin
    x := Round(Mouse.Terrain.x);
    y := Round(Mouse.Terrain.y);
    if (x >= 0) and (y >= 0) and (x div UnitSize + Attributes[0].Size <= MAP_SIZE) and (y div UnitSize + Attributes[0].Size <= MAP_SIZE)
    and CheckMap(Attributes[0].Size, x div UnitSize, y div UnitSize) then
    //on ne cree pas une unite sur une case occupee ou invalide
    begin
      sendServerCreateUnit(Mouse.Terrain, 1, GlobalClientRank+1, -1); //-1 : noOne created that unit
      //CreateUnit(Mouse.Terrain, @Attributes[0], GlobalClientRank+1,1);
      Log('Unit ' + IntToStr(UnitList.Count) + ' Created at position : ' + IntToStr(x div UnitSize) + ' ' + IntToStr(y div UnitSize));
    end;
  end;
  if (Key = VK_F3) and (CurrentScreen = SCREEN_GAME) then begin
    x := Round(Mouse.Terrain.x);
    y := Round(Mouse.Terrain.y);
    if (x >= 0) and (y >= 0) and (x div UnitSize + Attributes[0].Size <= MAP_SIZE) and (y div UnitSize + Attributes[0].Size <= MAP_SIZE)
    and CheckMap(Attributes[0].Size, x div UnitSize, y div UnitSize) then
    //on ne cree pas une unite sur une case occupee ou invalide
    begin
      sendServerCreateUnit(Mouse.Terrain, 10, GlobalClientRank+1, -1); //-1 : noOne created that unit
      //CreateUnit(Mouse.Terrain, @Attributes[0], GlobalClientRank+1,1);
      Log('Unit ' + IntToStr(UnitList.Count) + ' Created at position : ' + IntToStr(x div UnitSize) + ' ' + IntToStr(y div UnitSize));
    end;
  end;
  if (Key = VK_F4) and (CurrentScreen = SCREEN_GAME) then begin
    x := Round(Mouse.Terrain.x);
    y := Round(Mouse.Terrain.y);
    if (x >= 0) and (y >= 0) and (x div UnitSize + Attributes[0].Size <= MAP_SIZE) and (y div UnitSize + Attributes[0].Size <= MAP_SIZE)
    and CheckMap(Attributes[0].Size, x div UnitSize, y div UnitSize) then
    //on ne cree pas une unite sur une case occupee ou invalide
    begin
      sendServerCreateUnit(Mouse.Terrain, 13, GlobalClientRank+1, -1); //-1 : noOne created that unit
      //CreateUnit(Mouse.Terrain, @Attributes[0], GlobalClientRank+1,1);
      Log('Unit ' + IntToStr(UnitList.Count) + ' Created at position : ' + IntToStr(x div UnitSize) + ' ' + IntToStr(y div UnitSize));
    end;
  end;

  if (Key = VK_F5) and (CurrentScreen = SCREEN_GAME) then begin
    k := random(3);
    x := Round(Mouse.Terrain.x);
    y := Round(Mouse.Terrain.y);
    if (x >= 0) and (y >= 0) and (x div UnitSize + Attributes[18 + k].Size <= MAP_SIZE) and (y div UnitSize + Attributes[18 + k].Size <= MAP_SIZE)
    and CheckMap(Attributes[18 + k].Size, x div UnitSize, y div UnitSize) then
    //on ne cree pas une unite sur une case occupee ou invalide
    begin
      sendServerCreateUnit(Mouse.Terrain, 18 + k, GlobalClientRank+1, -1); //-1 : noOne created that unit
      //CreateUnit(Mouse.Terrain, @Attributes[0], GlobalClientRank+1,1);
      Log('Unit ' + IntToStr(UnitList.Count) + ' Created at position : ' + IntToStr(x div UnitSize) + ' ' + IntToStr(y div UnitSize));
    end;
  end;

  if (Key = VK_F6) and (CurrentScreen = SCREEN_GAME) then begin
    AssignFile(F, 'CurrentMap.fooo');
    Rewrite(F);
    for i := 0 to UnitList.Count - 1 do
      WriteLn(F, TUnit(UnitList[i]).Stats.ID, ' ', TUnit(UnitList[i]).pos.X, ' ', TUnit(UnitList[i]).pos.Y);
    CloseFile(F);
    AddLine('Map Saved to CurrentMap.fooo');
    Addline('Unit2 : ' + IntToStr(TUnit(UnitList[2]).Player));
  end;



  if Key = VK_F11 then begin
    // F10 buggée en mode fenêtré :s
    AddLine('lol');
  end;
  if Key = VK_F11 then begin
    Addline('Count.now : ' + IntToStr(Count.Now));
    z := 0;
    while (z < ClientTab.size) and (ClientTab.tab[z] <> NIL) do begin
      Addline('Synchro client ' + IntToStr(z) + ' : ' + IntToStr(ClientTab.tab[z].synchroPing) + 'ms');
      ping(ClientTab.tab[z].ip);
      inc(z);
    end;
  end;

end;
end.
