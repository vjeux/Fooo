unit FSelection;

interface
uses
  Classes, FGroup;

var
  Selection : TUnitGroup;

const
  MAXSELECTION = 18;
  NearSelectDistance = 40;

function OwnerPlayerUnitExists() : boolean;


implementation
uses
  FCursor, FInterfaceDraw, Flogs, FLuaFunctions,
  FSound, MyMath, FUnit, Math, OpenGL, FData;

function OwnerPlayerUnitExists() : boolean;
var
  i : integer;
  len : integer;
begin
  if not Mouse.Hover then
    Result := False
  else begin
    i := 0;
    len := length(Mouse.HoverList);
    while (i < len)
    and (Mouse.HoverList[i] >= UnitList.Count)
    and (TUnit(UnitList[Mouse.HoverList[i]]).Player <> Player) do
      Inc(i);
    Result := (i <> len);
  end;
end;

end.
