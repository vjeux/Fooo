unit myQueue;


interface

const MAXI_MAX_SIZE = 5000;

type

PMyQueue = ^TMyQueue;

TMyQueue = class(Tobject)
  public
    constructor Create(max : integer = MAXI_MAX_SIZE);
    function pop(): Pointer;
    function is_empty(): boolean;
    function push(p : Pointer): boolean;
    function top(): Pointer;
  private
    tab : array of Pointer;
	  MaxSize : integer;
    size    : integer;
    first   : integer;
end;


implementation

constructor TMyQueue.Create(max : integer = MAXI_MAX_SIZE);
begin
  setlength(Self.tab, max);
  Self.MaxSize := max;
  Self.size	:= 0;
  Self.first  := 0;
end;



function TMyQueue.is_empty(): boolean;
begin
  Result := Self.size = 0;
end;


function TMyQueue.push(p : Pointer): boolean;
begin
  if Self.size <> Self.MaxSize then
  begin
    Self.tab[(first + size) mod Self.MaxSize] := p;
    inc(Self.size);
    Result := true;
  end
  else
    Result := false;
end;


function TMyQueue.pop(): Pointer;
begin
  Result := nil;
  if Self.Size > 0 then
  begin
    Result := Self.top;
    dec(Self.size);
    if Self.first = Self.MaxSize - 1 then
      Self.first := 0
    else
      inc(Self.first);
  end;
end;


function TMyQueue.top(): Pointer;
begin
  Result := Self.tab[Self.first];
end;
end.
