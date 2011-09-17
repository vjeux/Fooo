unit FReceive;

interface

uses
  windows, FSelection, FUnit;

type
  string255 = string[255];
  PInteger = ^Integer;

procedure displayChat(senderIP, senderNick, data : string);
procedure doDamages(targetID, HP : integer);
procedure netSetClientAs(rank : integer);
procedure CheckServer(ip : string);
procedure CreateClient_(ip, nick : string255 ; race, team, color : integer);
procedure ExecuteOrder(selfID : integer ; OrderType : TorderType ; pos : TPoint ; TargetID : integer ; orderTime : Int64 ; add : boolean);
function createUnit2(pos : Tpoint ; Attri, Team, unitID, creatorID : integer) : TUnit;
function FindUnitByID(var id : integer; unitID : integer) : boolean;
procedure CalculatePing(senderIP : string255 ; PingTime, PongTime : int64);
procedure LaunchGame(synchronisationTime : integer);
procedure serverConnectionLost();
procedure UpdatePublicInfoNBroadcast(id, color, race, team : integer ; nick, ip : string);
procedure UpdateRessources(res1, res2 : double);

implementation

uses
  FServer, FInterfaceDraw, FData, sysutils, FTransmit, FLogs,
  FLuaFunctions, Flua, FFPS;

// 1
procedure displayChat(senderIP, senderNick, data : string);
var
  displayed_ip : string;
begin
// IP = 127.0.0.1 means it's the server's : it must be replaced by the real ip
  if SenderIP = '127.0.0.1' then begin
    displayed_ip := GlobalServerIP;
  end else begin
    displayed_ip := SenderIP;
  end;
  Addline2(displayed_ip + ' - ' + SenderNick + ' says : ' + data);
end;

// 2
procedure doDamages(targetID, HP : integer);
var
  i : integer;
begin
  i := 0;
  while TUnit(UnitList[i]).UnitID <> targetID do begin
    Inc(i);
  end;
  TUnit(UnitList[i]).Wound(Hp);
  Addline('Unit ' + IntToStr(targetID) + ' has lost ' + IntToStr(Hp) + ' HP');
end;

// 8
procedure netSetClientAs(rank : integer);
begin
  GlobalClientRank := rank;
  Player := GlobalClientRank+1;
end;

procedure CheckServer(ip : string);
begin
  if (ClientTab.tab[0].is_server) and (not(ClientTab.tab[0].serverIsRunning)) then begin
    BroadcastAnswer(ip);
  end;
end;

procedure CreateClient_(ip, nick : string255 ; race, team, color : integer);
begin
  if ClientTab.tab[0]^.is_server then begin
    CreateClient(ip, nick, {race}1, {color}2, false);
    ReturnClientIP(ip);
  end;
end;

procedure ExecuteOrder(selfID : integer ; OrderType : TorderType ; pos : TPoint ; TargetID : integer ; orderTime : Int64 ; add : boolean);
var
  i, j : integer;
  order : Porder;
begin
  new(order);
  order^.action := OrderType;
  order^.target.time := (orderTime div TURN_LENGTH) + TURN_DELAY; // Temps auquel cet ordre a été éxécuté. Il faut maintenant prévoir à quel temps l'ordre doit être achevé.
  case OrderType of
    MOVETO, ATTACKTO, PATROL : begin
      order^.target.TType := T_pos;
      order^.target.pos := pos;
      Addline('Executing MOVETO, ATTACKTO OR PATROL');
    end;
    FOLLOW, ATTACK, REPAIR, TRAIN, UNTRAIN : begin
      j := 0;
      while (UnitList.Count > j) and (TUnit(UnitList[j]).UnitID <> TargetID) do begin
        inc(j);
      end;
      Addline('Executing FOLLOW, ATTACK OR REPAIR');
      if UnitList.Count <= j then begin
        Addline('Error FReceive line 116');
        Log('Error FReceive line 116');
        exit;
      end;
      order^.target.TType := T_Unit;
      order^.target.unit_ := UnitList[j];

    end;
    HOLDPOS : Log('HOLDPOS order');
    STOP : Log('STOP order');
//    CAST : Addline('');
//      (SpellTarget : pointer ; spell : TAbility ; SpellPos : TPoint);
    else Log('Unknown order !');

  end;
  i := 0;
  while (UnitList.Count > i) and (TUnit(UnitList[i]).UnitID <> selfID) do begin
    inc(i);
  end;
  if UnitList.Count < i then begin
    Log('Error FReceive line 123');
    Log('Error FReceive line 124');
    exit;
  end;
  if add then
    TUnit(UnitList[i]).add_order(order)
  else
    TUnit(UnitList[i]).issue_order(order);
end;

function createUnit2(pos : Tpoint ; Attri, Team, unitID, creatorID : integer) : TUnit;
var
  order : Porder;
  target, i : integer;
  u : TUnit;
begin
//    ClientTab.tab[0]^.info.add_res1(-Attributes[Attri].Res1Cost);      moved in FTransmit
//    ClientTab.tab[0]^.info.add_res2(-Attributes[Attri].Res2Cost);
  ClientTab.tab[0]^.info.add_unit();
  u := createUnit(pos, @Attributes[Attri], Team, unitID);
  for i := 0 to CurrentUpgrades.Count - 1 do
  if PUpgrade(CurrentUpgrades[i])^.TargetsID = u.Stats^.ID then
    u.UpgradeEffect(CurrentUpgrades[i]);

// For orders through network :
  if creatorID <> -1 then begin
    New(order);
    order^.action := REPAIR;
    order^.target.ttype := t_unit;
  //  order^.target := TUnit(UnitList[unitID]);
    if FindUnitByID(target, unitID) then begin
      order^.target.unit_ := UnitList[target];
      sendServerOrder(creatorID, order, false);
    end;
    dispose(order);
  end;
  Result := u;
end;

function FindUnitByID(var id : integer; unitID : integer) : boolean;
var
  i, len : integer;
begin
  len := UnitList.count - 1;
  i := 0;
  while i <= len do begin
    if TUnit(UnitList[i]).UnitId = unitID then
      break;
    Inc(i);
  end;
  if i <= len then begin
    Result := true;
    id := i;
  end else begin
    Log('Error: UnitID `' + intToStr(unitID) + '` does not exist');
    Result := false;
  end;
end;

function TListSortGrowing(a, b : pointer) : integer;
begin
  if integer(a^) > integer(b^) then
      result := 1
  else if integer(a^) < integer(b^) then
    result := -1
  else
    result := 0;
end;

(* On calcule le ping.
    Quand la partie n'est pas lancéze, on remplit une liste de 10 pings et on en
    tire la médiane (voir FLuaFunctions.pas) : elle est utilisée pour
    initialiser le Count.Now...
    Une fois ceci fait 1 fois, on stocke simplement le ping dans le .ping du
    client (voir FServer.pas)                                                 *)
procedure CalculatePing(senderIP : string255 ; PingTime, PongTime : int64);
var
  i : integer;
  ping : PInteger;
begin
  if ClientTab.tab[0].is_server then begin
    new(ping);
    ping^ := pongTime - pingTime;
    i := 0;
    while ClientTab.tab[i].ip <> senderIP do begin
      inc(i);
    end;
    ClientTab.tab[i].ping := ping^;
    if (ClientTab.Tab[i]^.synchroPing = -1) then begin
      if (ClientTab.tab[i].pings.Count < 10) then begin
        ClientTab.tab[i].pings.add(ping);
        Log('Client ' + intToStr(i) + ' : Adding ping ' + IntToStr(ping^) + ' to table in pos ' + IntToStr(ClientTab.tab[i].pings.Count));
      end else begin
        dispose(ping);
        ClientTab.tab[i].pings.Sort(TListSortGrowing);
        ClientTab.tab[i].synchroPing := integer(ClientTab.tab[i].pings[4]^); // mediane
        Log('Mediane des pings (utilisée pour la synchro) : ' + IntToStr(ClientTab.tab[i].synchroPing));
//        ClientTab.tab[i].pings.Destroy;
      end;
    end else begin
      Addline('Pinging client #' + IntToStr(i) + ' : ' + IntToStr(ping^) + 'ms');
      dispose(ping);
    end;
  end;
end;


(*
    Count.Now is set to
                      - 0 for the server
                      - median of ping for each client
*)
procedure LaunchGame(synchronisationTime : integer);
begin
  Count.Now := synchronisationTime;
  LaunchGameAfter := True;
end;

procedure serverConnectionLost();
begin
  TriggerEvent(EVENT_ONSERVERDISCONNECT);
  GlobalServerIP := '127.0.0.1';
end;

procedure UpdatePublicInfoNBroadcast(id, color, race, team : integer ; nick, ip : string);
begin
  ClientTab.tab[0].publicPlayerList.tab[id].refresh(color,
                                                    team,
                                                    race,
                                                    nick,
                                                    ip    );
  BroadcastPublicListRefresh(id, color, race, team, nick);
end;

procedure UpdateRessources(res1, res2 : double);
begin
  ClientTab.tab[0]^.info.res1 := res1;
  ClientTab.tab[0]^.info.res2 := res2;
end;

end.

