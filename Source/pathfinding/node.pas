unit node;

interface

uses Windows, contnrs, game_env, point, Mymath;


const
  NODE_DISTANCE = 5;
  DIAGONAL_ADD  = 2;

type

Pnode = ^Tnode;

Tnode = record
    pos     : Tpoint;   //position
    f,                  // weight : g + h
    g,                  // distance from start
    h       : integer;  // estimate distance to finish
    parent  : Pnode;
end;

function Pnode_Create(xi, yi : integer; parent : Pnode; finish : Tpoint): Pnode;

procedure Pnode_display(n : Pnode);

procedure Pnode_make_cost(n : Pnode; finish : Tpoint);

function weight_comp(p1, p2 : Pointer): integer;




implementation



function Pnode_Create(xi, yi : integer; parent : Pnode; finish : Tpoint): Pnode;
begin
  new(Result);
  Result^.pos.x  := xi;
  Result^.pos.y  := yi;
  Result^.parent := parent;
  Pnode_make_cost(Result, finish);
end;


procedure Pnode_make_cost(n : Pnode; finish : Tpoint);
begin
  if n^.parent = nil then
    n^.g := 0
  else
  begin
    n^.g := NODE_DISTANCE + n^.parent^.g;

      //if its diagonal
    if (n^.pos.x <> n^.parent^.pos.x) and (n^.pos.y <> n^.parent^.pos.y) then
      inc(n^.g, DIAGONAL_ADD);
  end;
  n^.h := NODE_DISTANCE * manhattan(n^.pos, finish);
  n^.f := n^.g + n^.h;
end;


procedure Pnode_display(n : Pnode);
begin
  writeln('x : ', n^.pos.x, ', y : ', n^.pos.y);
  writeln('   weight : ', n^.f);
  if n^.parent = nil then
    writeln('   Parent : aucun (depart ?)')
  else
    writeln('   Parent : ', n^.parent^.pos.x, ',', n^.parent^.pos.y);
end;


function weight_comp(p1, p2 : Pointer): integer;
var n1, n2 : Pnode;
begin
  n1 := p1;
  n2 := p2;
  if (n1^.f < n2^.f) then
    Result := 1
  else
    if (n1^.f > n2^.f) then
      Result := -1
    else
      Result := 0;
end;

end.
