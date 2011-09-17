unit FFormation;

interface

uses
  FUnit, windows;

type
  TFormationType = (FORM_STD, FORM_HEART);

function makeDestPos(i, nb, space : integer; dest : Tpoint; form : TFormationType; angle : Extended): TPoint;

implementation

uses
  MyMath;

//HEART SHAPED BOX :
// x = sin( t) ^3
// y = cos(t ) - cos( t)^4
function makeHrtDest(i, nb, sp : integer): Tpoint;
const
  MULT = 1.5;
var
  t     : extended;
  cose  : extended;
  sine  : extended;
begin
  t := ((i + 1) * 2 * Pi) / nb;
  cose := cos(t);
  sine := sin(t);
  Result.x := Round(nb * MULT * (sine * sine * sine));
  Result.y := Round(nb * MULT * (cose - cose * cose * cose * cose));
end;

//STANDARD
function makeStdDest(i, nb, sp : integer): Tpoint;
var
  nbx           : integer; //nb units on this unit's line
  nby           : integer; //nb lines in formation
  UnitsPerLine  : integer;
begin
  if nb <> 1 then
  begin
    UnitsPerLine := 2;
    while nb > (UnitsPerLine * UnitsPerLine) do
      inc(UnitsPerLine);
    if (i div UnitsPerLine) = (nb div UnitsPerLine) then
      nbx := (nb - 1) mod UnitsPerLine + 1
    else
      nbx := UnitsPerLine;
    nby := nb div UnitsPerLine + 1;
    Result.x := - half(nby * sp) + (i div UnitsPerLine) * sp;
    Result.y := half(nbx * sp) - (i mod UnitsPerLine) * sp;
  end;
end;

function makeDestPos(i, nb, space : integer; dest : Tpoint; form : TFormationType; angle : Extended): TPoint;
var
  tp : Tpoint;
begin
  if nb > 1 then
  begin
    //basic formation
    case form of
      FORM_STD :
        tp := makeStdDest(i, nb, space);
      FORM_HEART :
        begin
          angle := angle + (Pi / 2);
          tp := makeHrtDest(i, nb, space);
        end;
    end;
    //rotation
    Result.x := round(tp.x * cos(angle) + tp.y * sin(angle));
    Result.y := round(-tp.x * sin(angle) + tp.y * cos(angle));
  end
  else
  begin
    Result.x := 0;
    Result.y := 0;
  end;
  //move to destination
  Result.x := Result.x + dest.x;
  Result.y := Result.y + dest.y;
end;

end.
