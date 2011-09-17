unit point;

interface

uses Windows;


  //tell if a point is between (0, 0) and (w-1, h-1)
function Collision(x, y: integer; w, h : integer; size : integer = 0): boolean; overload;
function Collision(var p: Tpoint; w, h : integer; size : integer = 0): boolean; overload;

function manhattan(var start, finish : Tpoint): integer;

function pointCmp(a, b : Tpoint): boolean;

  //returns the direction from p1 to p2 (ex : (4, 4)->(15, -15) = (1, -1))
  //  (only accurate for horizontal, vertical and diagonal moves) 
function Tpoint_way(var p1, p2 : Tpoint): Tpoint;

function TpointToStr(var p: Tpoint): string;

function TpDist2(var p1, p2 : Tpoint): integer;


implementation

uses
  Sysutils, Mymath;


function Collision(x, y: integer; w, h : integer; size : integer = 0): boolean;
var
  add : integer;
begin
  add := half(size);
  Result := (x >= add) and (y >= add) and (x + add < w) and (y + add < h);
end;


function Collision(var p: Tpoint; w, h : integer; size : integer = 0): boolean;
var
  add : integer;
begin
  add := half(size);
  Result := (p.x >= add) and (p.y >= add) and (p.x + add < w) and (p.y + add < h);
end;


function manhattan(var start, finish : Tpoint): integer;
begin
  Result := int_abs(finish.x - start.x) + int_abs(finish.y - start.y);
end;


function pointCmp(a, b : Tpoint): boolean;
begin
  Result := (a.x = b.x) and (a.y = b.y);
end;


function Tpoint_way(var p1, p2 : Tpoint): Tpoint;
begin
  Result.x := intComp(p2.x, p1.x);
  Result.y := intComp(p2.y, p1.y);
end;


function TpointToStr(var p: Tpoint): string;
begin
  Result := IntToStr(p.x) + ', ' + IntToStr(p.y);
end;


function TpDist2(var p1, p2 : Tpoint): integer;
begin
  Result := pow2(int_abs(p1.x - p2.x)) + pow2(int_abs(p1.y - p2.y));
end;

end.
