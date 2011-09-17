unit FEffects;

interface

uses
  FData, FUnit, FBallistic, FFPS;

procedure Whirlwind(UnitID : TUnit); stdcall;
procedure WhirlwindCancel(UnitID : TUnit); stdcall;
procedure Miniaturize(UnitID : TUnit); stdcall;

implementation

procedure Whirlwind(UnitID : TUnit); stdcall;
begin
  UnitID.Angle := UnitID.Angle + Count.Elapsed*0.015;
  UnitID.RealPos.Z := 100;
  UnitID.stop_unit(true);
end;

procedure WhirlwindCancel(UnitID : TUnit); stdcall;
begin
  UnitID.RealPos.Z := 0;
  UnitID.get_moving;
end;

procedure Miniaturize(UnitID : TUnit); stdcall;
begin
  UnitID.ModelScale := UnitID.ModelScale div 2;
end;

end.
