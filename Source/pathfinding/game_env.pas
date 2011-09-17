unit game_env;


interface


uses Windows, point, Funit;


type


TileSet = (Empty, Block);


Tenv = class(Tobject)
  private
    w, h    : integer;
    minSize : integer;
    uni     : PUnit;
  public
    Constructor Create(wi, hi : integer);

    procedure init(u : PUnit);

    Property height : integer read h;
    Property width  : integer read w;

    function is_empty(p: Tpoint)      : boolean; overload;
    function is_empty(x, y : integer) : boolean; overload;

    function can_access(from, dest : Tpoint): boolean;
end;


function horz_check(x1, x2, y : integer) : boolean;
function vert_check(x, y1, y2 : integer) : boolean;



implementation

uses
  FData, Fmap, my_swap, MyMath;

  
function horz_check(x1, x2, y : integer) : boolean;
begin
  if x1 > x2 then
    swap(x1, x2);
  Result := true;
  while (x1 <= x2) and Result do
  begin
    Result := (Map[x1, y].nb_units = 0);
    inc(x1);
  end;
end;


function vert_check(x, y1, y2 : integer) : boolean;
begin
  if y1 > y2 then
    swap(y1, y2);
  Result := true;
  while (y1 <= y2) and Result do
  begin
    Result := (Map[x, y1].nb_units = 0);
    inc(y1);
  end;
end;


Constructor Tenv.Create(wi, hi : integer);
begin
  Self.w := wi;
  Self.h := hi;
end;


procedure Tenv.init(u : PUnit);
begin
  Self.MinSize := u^.Stats.Size;
  Self.uni := u;
end;


function Tenv.is_empty(p: Tpoint): boolean;
begin
  Result := CheckMovementMap(Self.uni^, p.x, p.y);
end;

function Tenv.is_empty(x, y : integer): boolean;
begin
  Result := CheckMovementMap(Self.uni^, x, y);
end;


function Tenv.can_access(from, dest : Tpoint): boolean;
var
  dir : Tpoint;
  newlim : Tpoint;
  hsize : integer;
begin
  hsize := half(Self.minSize);
  dir := Tpoint_way(from, dest);
  newlim.x := from.x + dir.x * (hsize + 1);
  newlim.y := from.y + dir.y * (hsize + 1);
    //dans la map
  Result := Collision(newlim, Self.w, Self.h);
    //on peut s'y déplacer
  if dir.x <> 0 then
    Result := result and vert_check(newlim.x, from.y - hsize, from.y + hsize);
  if dir.y <> 0 then
    Result := result and horz_check(from.x - hsize, from.x + hsize, newlim.y);
  if (dir.x <> 0) and (dir.y <> 0) then
    Result := result and (map[newlim.x, newlim.y].nb_units = 0);
end;

end.
