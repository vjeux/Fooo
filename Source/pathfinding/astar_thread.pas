unit astar_thread;

interface

uses
  Classes, pathfinder, myQueue, Funit;

const
  PATHFINDER_PRIORITY = tpLower;

type

  PPathResult = ^TPathResult;
  TPathResult = record
    path  : PMyQueue;
    id    : integer;
  end;


  TastarThread = class(TThread)
    public
      constructor create(mapw, maph : integer);
      function path_request(u : Punit) : integer; //retourne un ticket (entier)
    private
      _busy       : boolean;      //permet de savoir s'il faut relancer le thread ou pas
      requests    : TMyQueue;     //file de Punits
      results     : Tlist;        //Tlist de TpathResult
      pathfinder  : Tastar;       //le pathfinder ;)
      next_ticket : integer;      //le prochain ticket, comme chez le boucher
    protected
      procedure Execute(); override;
  end;


//var
  //Pathfind : TastarThread;

implementation



constructor TastarThread.create(mapw: Integer; maph: Integer);
begin
  inherited Create(true); //suspended = true : il commence pas dès qu'on l'init
  Self.Priority     := PATHFINDER_PRIORITY;
  pathfinder        := Tastar.Create(mapw, maph);
  Self._busy        := false;
  Self.requests     := TMyQueue.Create();
  Self.results      := TList.Create;
  Self.next_ticket  := 0;
end;


function TastarThread.path_request(u : Punit) : integer;
begin
  if Self.requests.push(u) then
  begin
    if not Self._busy then
    begin
      Self._busy := true;
      Self.Execute;
    end;
    Result := Self.next_ticket;
    inc(Self.next_ticket);
  end
  else
    result := -1;
end;


procedure TastarThread.execute;
var
  u : Punit;
  res : PPathResult;
begin
  while not Self.requests.is_empty do
  begin
    u := Punit(Self.requests.pop);
    new(res);
    res^.path := Self.pathfinder.Astar(u);
    res^.id := u^.path_ticket;
  end;
end;

end.
