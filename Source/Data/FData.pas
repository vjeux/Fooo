unit FData;

interface

uses
  Windows, SysUtils, Classes, xmldom, XMLIntf,
  msxmldom, XMLDoc, FLogs, FTerrain, point,
  Funit, FUnitload, FDisplay, MyMath, FTransmit;

const
  BASESPEED     = 0.02;
  UNITSIZE      = 16;
  BUILDINGSIZE  = UNITSIZE * 4;
  MELEE_RANGE   = 1;
  FOLLOW_RANGE  = 5;
  ORDERS_TOLERANCE = 2;
  AGGRO_RANGE = 40; //distance qui declenche l'agressivite
  DECAY_RATE = 30;//pv par sec, sachant que au bout de 100pv perdu, le corps disparait
  WARNING_TIME = 2000; //durée du warning en ms
  WARNING_TURNS = WARNING_TIME div TURN_LENGTH; //durée équivalent en tours de jeux
  NATURAL_RES1_INCOME = 1; //ressources1 par seconde
  NATURAL_RES2_INCOME = 2; //ressources2 par seconde
  RES1_INCOME = (NATURAL_RES1_INCOME/1000)*TURN_LENGTH;//en tours
  RES2_INCOME = (NATURAL_RES2_INCOME/1000)*TURN_LENGTH;//en tours
type

  TWarning = class
    private
      Msg : string;
      EndTurn : integer;
    public
      constructor Create;
      procedure SetMsg(msg : string);
      procedure WipeMsg();
      function IsOver() : boolean;
      property Text : string read Msg;
  end;

  procedure OnUpdateData();
  procedure InitData();
  function CreateUnit(pos : Tpoint; unite : PUnitAttributes; Player, ID : integer): Tunit;
  function Distance2(p1, p2 : Tpoint) : integer; overload;
  function Distance2(x1, y1, x2, y2 : integer) : integer; overload;
  function Distance2(Unit1, Unit2 : TUnit) : integer; overload;
  function Distance(P1, P2 : TCoords3c) : currency;
  function ValidMove(unitemoving : TUnit; x2, y2 : integer) : boolean;
  function compareByType(a : Pointer; b : Pointer) : Integer;
  function CompareByName(Item1 : Pointer; Item2 : Pointer) : Integer;
  procedure ApplyUpgrade(Upgrade : PUpgrade);
  function ValidAddInGroup(UnitID : TUnit; i : integer) : boolean;
  function Distance2(x1, y1, x2, y2 : currency) : currency; overload;
  function get_buttonID(order : TOrderType) : integer;
  function GetNearestFreeSpace(selfsize, size : integer; x, y : integer) : TPoint;
  procedure UpdateResources(killed : integer);

var
  SelectionGroups  : array[0..9] of TList;
  Warning          : TWarning;
  UnitList, ProjectileList, CurrentUpgrades : TList;
  Player, GlobalID, CurrentTurn : Integer;
  LastUpdateRessources : Int64 = 0;
  myRace : integer;

implementation
uses
  FGlWindow, FFPS, FMD5, FInterfaceDraw, FPlayer, FRedirect,
  FCursor, FSelection, pathfinder, astar_thread, FServer,
  FMap, FBallistic, FGroup, FLuaFunctions, FNetworkTypes;


function CreateUnit(pos : Tpoint; unite : PUnitAttributes; Player, ID : integer): Tunit;
begin
  Result := TUnit.Create(pos, unite, Player, ID);
  Result.Name := Result.Stats.Name + ' '+ FormatDateTime('hh:mm:ss:zzz', Now());
  if not Result.Stats.IsBuilding then
    Result.state := STATE_MOVING // petit hack
  else
    OccupyMap(Result);
  Result.TeamColor := TeamColor[ClientTab.tab[0].publicPlayerList.tab[player - 1].color];
  Result.PlaySound(SOUND_READY);
  UnitList.Add(Result);
end;

constructor TWarning.Create;
begin
  self.Msg := '';
  self.EndTurn := -1;
end;
procedure TWarning.SetMsg(msg: string);
begin
  self.Msg := msg;
  self.EndTurn := CurrentTurn + WARNING_TURNS;
  TriggerEvent(EVENT_WARNING);
end;
procedure TWarning.WipeMsg;
begin
  self.Msg := '';
  TriggerEvent(EVENT_WARNING);
end;

function TWarning.IsOver() : boolean;
begin
  result := (self.EndTurn = CurrentTurn)
end;

procedure OnUpdateData();
var
  i, NewTurn, killed : integer;
  cur_unit  : Tunit;
begin
  //les mouvements sont mis a jour a chaque frame
  for i := 0 to UnitList.Count - 1 do
  begin
    cur_unit := TUnit(UnitList[i]);
    if not(cur_unit.Stats.IsBuilding) then
    begin
      cur_unit.UpdateAngle;
      cur_unit.UpdateMovement;
      OccupyMap(cur_unit); //only moved units are considered as obstacles
    end;
  end;
  UpdateAllProjectiles();
  //clear every standing position only after everyone has moved
  for i := 0 to UnitList.Count - 1 do
    if not(TUnit(UnitList[i]).Stats.IsBuilding) then
      ClearMap(TUnit(UnitList[i]));
  //this only works because an unit can occupy/liberate a same place
  //several times, (map occupation uses ints and not bools)


  NewTurn := Count.Now div TURN_LENGTH;
  if NewTurn = CurrentTurn then
    exit
  else
    Inc(CurrentTurn);
  killed := 0;
  for i := 0 to UnitList.Count - 1 do
    if TUnit(UnitList[i]).HP = -10 then //-10 : just killed
      inc(killed);

  UpdateResources(killed);
  for i := 0 to UnitList.Count - 1 do
  begin
    cur_unit := TUnit(UnitList[i]);
    if not(cur_unit.Active) then
    begin
      if cur_unit.HP <= -110 then
        cur_unit.ToDelete := True;; //require corpse deletion
      if cur_unit.HP < 0 then
      begin //decay time
        cur_unit.HP :=  cur_unit.HP - DECAY_RATE*(Count.Elapsed/1000);
      end;
      continue;
    end;
    if cur_unit.Stats.IsBuilding then
      cur_unit.HandleBuildingQueue;
    cur_unit.UpdateActions;
    cur_unit.UpdateStats; //spell effects, HP and MP
//    cur_unit.UpdateAngle;
//    cur_unit.UpdateMovement;
//    cur_unit.UpdateActions;
//    OccupyMap(cur_unit); //only moved units are considered as obstacles
  end;
//    //clear every standing position only after everyone has moved
//  for i := 0 to UnitList.Count - 1 do
//    ClearMap(TUnit(UnitList[i]));
//    //this only works because an unit can occupy/liberate a same place
//    //several times, (map occupation uses ints and not bools)

    //clean corpses
  if UnitList.Count > 0 then
  begin
    for i := UnitList.Count - 1 downto 0 do
    begin
      cur_unit := Tunit(UnitList[i]);
      cur_unit.ClearEffects;
      if cur_unit.ToDelete then
      begin
        cur_unit.Effects.Destroy;
        cur_unit.Destroy;
        UnitList.Delete(i);
      end;
    end;
  end;
  if Warning.IsOver() then
    Warning.WipeMsg;
end;

procedure InitData();
var
  i : integer;
  hash1, hash2 : string;
begin
  LoadAbilities();
  LoadUpgrades();
  LoadUnits();
  GlobalID := 0;
  CurrentTurn := 0;
  UnitList := TList.Create;

  Selection := TUnitGroup.Create;
  ProjectileList := TList.Create;
  CurrentUpgrades := TList.Create;
  Mouse.Mode := nil;
  Warning := TWarning.Create;
  hash1 := MD5FromFile('Data/units.xml');
  hash2 := MD5FromFile('Data/units2.xml');
  if hash1 = hash2 then
    AddLine('MD5 Check : Data Files are identical')
  else
    AddLine('MD5 Check : Data Files are different');

  Mouse.LastDblClick := 0;
  for i := 0 to 9 do
  begin
    SelectionGroups[i] := TList.Create;
    SelectionGroups[i].Capacity := MaxSelection;
  end;
  Selection.Capacity := 20; //on ne selectionne pas plus de 20 unites
  InitMap();
  Player := GlobalClientRank+1;
  //pathfind := TastarThread.create(MAP_SIZE, MAP_SIZE);
  //DEBUG
  pathfind := Tastar.Create(MAP_SIZE, MAP_SIZE);
  if CurrentScreen = SCREEN_GAME then begin
    i := 0;
    while not(Clienttab.tab[0]^.PublicPlayerList.tab[i].isYou) do
      inc(i);
    myRace := ClientTab.tab[0]^.publicPlayerList.tab[i].race;
  end;
end;


function Distance2(p1, p2 : Tpoint) : integer; overload;
begin
   result := pow2(p2.x - p1.x) + pow2(p2.y - p1.y);
end;

function Distance2(x1, y1, x2, y2 : integer) : integer; overload;
begin
  result := pow2(x2 - x1) + pow2(y2 - y1);
end;

function Distance2(x1, y1, x2, y2 : currency) : currency; overload;
begin
  result := (x2-x1)*(x2-x1)+(y2-y1)*(y2-y1);
end;

function Distance(P1, P2 : TCoords3c) : currency; overload;
begin
  result := sqrt((P2.x-P1.x)*(P2.x-P1.x)+(P2.y-P1.y)*(P2.y-P1.y)+(P2.z-P1.z)*(P2.z-P1.z));
end;

function Distance2(Unit1, Unit2 : TUnit) : integer; overload;
begin
  result := pow2(Unit2.pos.x-Unit1.pos.x) + pow2(Unit2.pos.y-Unit1.pos.y);
end;

function ValidMove(unitemoving : TUnit; x2, y2 : integer) : boolean;
var
  x1, y1 : integer;
begin
  x1 := Round(unitemoving.pos.x);
  y1 := Round(unitemoving.pos.y);
  result := false;
if ((x2 = x1 + 1) and (y2 = y1 - 1)) or ((x2 = x1) and (y2 = y1 + 1)) or
   ((x2 = x1) and (y2 = y1 - 1)) or ((x2 = x1 + 1) and (y2 = y1)) or
   ((x2 = x1 + 1) and (y2 = y1 + 1)) or ((x2 = x1 - 1) and (y2 = y1)) or
   ((x2 = x1 - 1) and (y2 = y1 - 1)) or ((x2 = x1 - 1) and (y2 = y1 + 1)) or
   ((x2 = x1) and (y2 = y1)) then
   result := (Map[x2,y2].nb_units = 0) and (Map[x2,y2].Walkable); //la case cible doit etre libre
end;

function compareByType(a : Pointer; b : Pointer) : Integer;
begin
  Result := intComp(ord(TUnit(a).Stats.UnitType), ord(TUnit(b).Stats.UnitType));
end;

function compareByName(Item1 : Pointer; Item2 : Pointer) : Integer;
begin
  if TUnit(Item1).Stats.Name > TUnit(Item2).Stats.Name then
    Result := 1
  else if TUnit(Item1).Stats.Name = TUnit(Item2).Stats.Name then
    Result := 0
  else
    Result := -1;
end;

//procedure TranslateUnit(UnitID : TUnit);
//begin

//    UnitID.pos.x := UnitID.pos.x + BaseSpeed * UnitID.Speed * Count.Elapsed * cos(UnitID.Angle);
//    UnitID.pos.y := UnitID.pos.y + BaseSpeed * UnitID.Speed * Count.Elapsed * sin(UnitID.Angle);
//
////  t := t + 0.01;

////  UnitID.pos.x := UnitID.pos.x + exp(t/50)*cos(t);  //mouvement en spirale

////  UnitID.pos.y := UnitID.pos.y + exp(t/50)*sin(t);

//
//// UnitID.pos.x := UnitID.pos.x + 5*cos(t)*cos(t)*cos(t); //mouvement en carre
//// UnitID.pos.y := UnitID.pos.y + 5*sin(t)*sin(t)*sin(t);
//
////  UnitID.pos.x := UnitID.pos.x + (5*cos(t));  //mouvement aller-retour ovaloide
////  UnitID.pos.y := UnitID.pos.y + (2*sin(t));
//
//// UnitID.pos.x := 2500+ 300*sin(t)*sin(t)*sin(t);  //mouvement en forme de coeur
//// UnitID.pos.y := 2500 + 300*(cos(t)-cos(t)*cos(t)*cos(t)*cos(t));
//
//end;


function ValidAddInGroup(UnitID : TUnit; i : integer) : boolean;
var
  j, l : integer;
begin
  j := 0;
  l := SelectionGroups[i].Count;
  while j < l do
  begin
    if TUnit(SelectionGroups[i][j]) <> UnitID then
      inc(j)
    else
      break
  end;
  result := (j = l);
end;


procedure ApplyUpgrade(Upgrade : PUpgrade); //a placer dans TPlayer
var
  i : integer;
begin
  if CurrentUpgrades.IndexOf(Upgrade) <> -1 then
    exit; //effet deja actif
  CurrentUpgrades.Add(Upgrade);
  for i := 0 to UnitList.Count - 1 do
    if (TUnit(UnitList[i]).Player = Player) and (TUnit(UnitList[i]).Stats.ID = Upgrade.TargetsID) then
      TUnit(UnitList[i]).UpgradeEffect(Upgrade);
  TriggerEvent(EVENT_SELECTIONCHANGE);
end;

function get_buttonID(order : TOrderType) : integer;
begin
  result := 0;
  case order of
    MOVETO, FOLLOW: result := 1;
    STOP: result := 2;
    HOLDPOS: result := 3;
    ATTACKTO, ATTACK: result := 4;
    PATROL: result := 5;
    REPAIR: result := 6;
    CAST: result := 7;
  end;
end;

function GetNearestFreeSpace(selfsize, size : integer; x, y : integer) : TPoint;
var
  space, i, halfsize, halfselfsize : integer;
  found : boolean;
begin
  halfsize := size div 2;
  halfselfsize := selfsize div 2;
  space := halfsize + halfselfsize + 1;
  found := false;
  while not(found) do
  begin
    for i := x - halfselfsize - 1 to x + halfselfsize + 1 do
      if CheckMap(size, i, y - space) then
      begin
        found := true;
        result.x := i;
        result.y := y - space;
        break;
      end;
    if found then
      break;
    for i := y - halfselfsize - 1 to y + halfselfsize + 1 do
      if CheckMap(size, x + space, i) then
      begin
        found := true;
        result.x := x + space;
        result.y := i;
        break;
      end;
    if found then
      break;
    for i := x - halfselfsize - 1 to x + halfselfsize + 1 do
      if CheckMap(size, i, y + space) then
      begin
        found := true;
        result.x := i;
        result.y := y + space;
        break;
      end;
    if found then
      break;
    for i := y - halfselfsize - 1 to y + halfselfsize + 1 do
      if CheckMap(size, x - space, i) then
      begin
        found := true;
        result.x := x - space;
        result.y := i;
        break;
      end;
    if found then
      break;
    inc(space);
  end;
end;

procedure UpdateResources(killed : integer);
var
  i, j : integer;
  z : integer;
  last_res1 : integer;
  updated : boolean;
begin
  updated := false;
  if ClientTab.tab[0].is_server then begin
    for i := 0 to UnitList.Count - 1 do begin
      if (TUnit(UnitList[i]).TrainingList <> nil) and (TUnit(UnitList[i]).TrainingList.Count > 0) then begin
        for j := 0 to TUnit(UnitList[i]).TrainingList.Count - 1 do begin
          ClientTab.tab[TUnit(UnitList[i]).Player - 1]^.info.add_res1(TUnit(TUnit(UnitList[i]).TrainingList[j]).Stats.Training);
          Addline('Updated !' + FloatToStr(TUnit(TUnit(UnitList[i]).TrainingList[j]).Stats.Training));
          updated := true;
        end;
      end;
    end;
    z := 0;
    while ClientTab.tab[z] <> NIL do begin
      last_res1 := round(ClientTab.tab[z]^.info.res1);
      ClientTab.tab[z]^.info.add_res1(RES1_INCOME);
      ClientTab.tab[z]^.info.add_res2(killed);
      if (last_res1 <> round(ClientTab.tab[z]^.info.res1))
      or (killed <> 0)
      then begin
        updated := true;
      end;
      inc(z);
    end;
    if updated then begin
      broadcastUpdateRessources();
      LastUpdateRessources := Count.Now;
    end;
  end;

end;

end.
