unit my_swap;

interface

uses Windows;


procedure swap(var a, b : Pointer);  overload;
procedure swap(var a, b : Integer);  overload;
procedure swap(var a, b : Real);     overload;
procedure swap(var a, b : Tpoint);   overload;


implementation


procedure swap(var a, b : Pointer);
var tmp : Pointer;
begin
  tmp := a;
  a   := b;
  b   := tmp;
end;

procedure swap(var a, b : Integer);
var tmp : Integer;
begin
  tmp := a;
  a   := b;
  b   := tmp;
end;


procedure swap(var a, b : Real);
var tmp : Real;
begin
  tmp := a;
  a   := b;
  b   := tmp;
end;


procedure swap(var a, b : Tpoint);
var tmp : Tpoint;
begin
  tmp := a;
  a   := b;
  b   := tmp;
end;

end.
