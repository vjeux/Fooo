unit Fgroup;

interface

uses
  Classes,
  FUnit,
  windows;

type
  TUnitGroup = class(Tlist)
    public
      constructor Create();
      procedure addOrder(o : Porder);
      procedure addUnit(i : integer);
      procedure Clear(); override;
      procedure issueOrder(o : Porder);
      procedure removeUnit(i : integer);
      function leader(): Tunit;
    private
      spacing : integer;
      function maxSpacing(): integer;
      function midPos(): TPoint;
      function makeDest(i : integer; from, dest : Tpoint) : Tpoint;
  end;

implementation

uses
  FLuaFunctions,
  FData,
  FKeys,
  FFormation,
  FSelection,
  FSound,
  FTransmit,
  FView,
  Math,
  //debug
  SysUtils,
  FInterfaceDraw,
  FServer;

//DEBUG !!
//y'a un vieux bug avec les tailles des persos sinon... :(
const
  MIN_SPACING = 4;

//PUBLIC
//-------------------

constructor TUnitGroup.Create();
begin
  inherited Create();
  Self.spacing := MIN_SPACING;
  Self.Capacity := MAXSELECTION;
end;

procedure TUnitGroup.issueOrder(o : Porder);
var
  i       : integer;
  dest    : TPoint;
  mid     : Tpoint;
begin
  mid := Self.midPos;
  if (o^.action = MOVETO)
  or (o^.action = ATTACKTO)
  or (o^.action = PATROL) then
    dest := o^.target.pos;
  for i := 0 to Self.Count - 1 do
  begin
    if (o^.action = MOVETO)
    or (o^.action = ATTACKTO)
    or (o^.action = PATROL) then
      o^.target.pos := Self.makeDest(i, mid, dest);

    if ClientTab.Tab[0].is_server then begin
      TUnit(self[i]).issue_order(o);
    end else begin
      sendServerOrder(TUnit(Self[i]).UnitId, o, false);
      dispose(o);
    end;
  end;
end;

procedure TUnitGroup.addOrder(o : Porder);
var
  i : integer;
begin
  for i := 0 to Self.Count - 1 do begin
    if TUnit(Self[i]).get_mode = STOP then begin
      if ClientTab.Tab[0].is_server then begin
        TUnit(self[i]).issue_order(o);
      end else begin
        sendServerOrder(TUnit(Self[i]).UnitId, o, false); //false <=> issue order
        dispose(o);
      end;
    end else begin
      if ClientTab.Tab[0].is_server then begin
        TUnit(Self[i]).add_order(o);
      end else begin
        sendServerOrder(TUnit(Self[i]).UnitId, o, true); //true <=> add order
        dispose(o);
      end;
    end;
  end;
end;

procedure TUnitGroup.clear();
var
  i : integer;
begin
  for i := 0 to Self.Count - 1 do
    TUnit(Self[i]).Selected := false;
  inherited Clear();
  Self.spacing := MIN_SPACING;
  TriggerEvent(EVENT_SELECTIONCHANGE);
end;

procedure TUnitGroup.addUnit(i : integer);
begin
  if  (TUnit(UnitList[i])).Active
  and (Self.Count < MaxSelection)
  and (Self.IndexOf(TUnit(UnitList[i])) = -1) then
  begin
  (TUnit(UnitList[i])).PlaySound(SOUND_LISTEN);
//    if Self.Count = 0 then
//      Play_Sound_sample(0,
//                        200,
//                        (TUnit(UnitList[i]).RealPos.X - View.tarx) / 100,
//                        (TUnit(UnitList[i]).RealPos.Y - View.tary) / 100,
//                        3);
    TUnit(UnitList[i]).Selected := true;
    inherited Add(TUnit(UnitList[i]));
    Self.spacing := Max(Self.spacing, TUnit(UnitList[i]).Stats.Size + 1);
    TriggerEvent(EVENT_SELECTIONCHANGE);
    Self.Sort(ComparebyType); //trie la liste par type d'unite
  end;
end;

procedure TUnitGroup.removeUnit(i : integer);
begin
  TUnit(UnitList[i]).Selected := false;
  Self.Remove(TUnit(UnitList[i]));
  Self.spacing := Self.maxSpacing();
  TriggerEvent(EVENT_SELECTIONCHANGE);
  Selection.Sort(ComparebyType); //trie la liste par type d'unite
end;

//just picks any guy in the group
function TUnitGroup.leader(): Tunit;
begin
  if Self.Count > 0 then
    Result := TUnit(Self[0])
  else
    Result := TUnit(nil);
end;

//PRIVATE
//--------------------

  //simple max search ;)
function TUnitGroup.maxSpacing(): integer;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to Self.Count - 1 do
    if TUnit(Self[i]).Stats.Size + MELEE_RANGE > Result then
      Result := TUnit(Self[i]).Stats.Size + MELEE_RANGE;
end;

//puts avg x and avg y in Self.midpos
function TUnitGroup.midPos() : Tpoint;
var
  i : integer;
begin
  Result.x := 0;
  Result.y := 0;
  if Self.Count > 0 then
  begin
    for i := 0 to Self.Count - 1 do
    begin
      Result.x := Result.x + TUnit(Self[i]).pos.x;
      Result.y := Result.y + TUnit(Self[i]).pos.y;
    end;
      Result.x := Result.x div Self.count;
      Result.y := Result.y div Self.count;
  end;
end;

function TUnitGroup.makeDest(i : integer; from, dest : Tpoint) : Tpoint;
var
  angle : extended;
begin
  angle := ArcTan((from.y - dest.y) / (dest.x - from.x));
  if dest.X >= from.x then
      angle := PI + angle;
  if angle < 0 then
    angle := 2*PI + angle;
  if isWinKeyDown(VK_LCONTROL) then
    Result := makeDestPos(i, Self.count, Self.spacing, dest, FORM_HEART, angle)
  else
    Result := makeDestPos(i, Self.count, Self.spacing, dest, FORM_STD, angle);
end;


end.
