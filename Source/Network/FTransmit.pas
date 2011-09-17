unit FTransmit;

interface

uses
  FUnit, Types, FNetworkTypes;

const
  TURN_LENGTH = 10; // ms
  TURN_DELAY = 3;    // turn

var
  GlobalUnitID : integer; //!\\ Global !

procedure InitNetwork();
procedure broadcast();
procedure broadcastAnswer(ip : string);

// Orders sent to server...
  // ...to be broadcasted
  procedure sendServerOrder(selfID : integer ; order : Porder ; add : boolean);

  procedure sendServerString(str : string);
  procedure sendServerCreateUnit(pos : Tpoint ; UnitType, Team, CreatorID : integer);
  procedure sendServerDamages(id, HP : integer);
  procedure requestUpdatePublicPlayerList(myId, color, race, team : integer ; nick : string);
  // ...to be directly executed
  procedure sendNetworkSetServer(ServerIP, nick : string);
  procedure sendDisconnectClient(ServerIP, ClientIP : string);
  procedure setClientAs(ip : string ; rank : integer);
  procedure pong(pingTime : int64);

// Sent by server to 1 client
procedure ReturnClientIP(ClientIP : string);
procedure AddPublicPlayerInfo(destinationClientId, id, color, race, team : integer ; nick, ip : string ; isYou : boolean);

// Broadcast by server
procedure broadcastString(str, SenderIP, SenderNick : string ; rank : integer);
procedure broadcastCreateUnit(pos : Tpoint ; UnitType, Team, creatorID : integer);
procedure broadcastDamages(id, HP : integer);
procedure broadcastNewPlayer(newplayerID : integer);
procedure BroadCastLaunchGame();
procedure BroadcastOrder(selfID : integer ; OrderType : TorderType; pos : TPoint; TargetID : integer);
procedure ping(ip : string);
procedure disconnectAllClients();
procedure BroadcastPublicPlayerInfo(newPlayerId, color, race, team : integer ; nick : string);
procedure BroadcastPublicListRefresh(id, color, race, team : integer ; nick : string);
procedure broadcastUpdateTUnit(UnitId, InfoToUpdate : integer ; p : TPAcketTUnit);
procedure broadcastUpdateRessources();


// Bigs receiving functions
function executeNetwork() : boolean;
procedure receiveNetwork();

procedure TerminateNetwork();

implementation
uses
  SysUtils, Classes, Windows, FNetwork, FInterfaceDraw, FServer, FLogs,
  FFPS, pqueue, FLuaFunctions, FReceive, FData, FUpdateData, FMap;

var
  Network : TNetwork;
  PacketTas : TpQueue;

function comp_fun (p1, p2: pointer): integer;
var
  n1, n2 : PNetPacket;
begin
  n1 := p1;
  n2 := p2;
  if n1.time < n2.time then begin
    result := 1;
  end else if n1.time > n2.time then begin
    result := -1;
  end else begin
    result := 0;
  end;
end;

procedure free_fun (var p: pointer);
var
  n : PNetPacket;
begin
  n := p;
  dispose(n);
end;

procedure InitNetwork();
begin
  GlobalClientRank := -42;
  Network := TNetwork.connect();
  InitClientTab();
  GlobalUnitID := 1;
  PacketTas := TpQueue.create(4096, comp_fun, free_fun);
end;

procedure broadcast();
var
  buffer : pointer;
  Packet : TPacketBroadcast;
begin
  Packet.id := 10;
  Packet.execTime := 0;
  buffer := @Packet;
  Network.broadcast(buffer, sizeof(Packet));
end;

procedure broadcastAnswer(ip : string);
var
  buffer : pointer;
  Packet : TPacketBroadcastAnswer;
begin
  Packet.id := 11;
  Packet.execTime := 0;
  Packet.serverName := ClientTab.tab[0]^.serverName;
  Packet.player_count := ClientTab.size;
  Packet.map := ClientTab.tab[0]^.map;
  buffer := @Packet;
  AddLine('Sending data');
  Network.sendToIp(PAnsiChar(ip), buffer, sizeof(Packet));
end;

// Broadcast requests ----------------------------------------------------------
procedure sendServerOrder(selfID : integer ; order : Porder ; add : boolean);
var
  Packet : TPacketOrder;
  buffer : pointer;
  i : integer;
begin
  Packet.execTime := Count.Now;
  Packet.selfID := selfID;
  Packet.OrderType := order^.action;
  Packet.add := add;
  case order^.action of
    MOVETO, ATTACKTO, PATROL : begin
      Packet.pos := order^.target.pos;
    end;
    FOLLOW, ATTACK, REPAIR, TRAIN, UNTRAIN : begin
      Packet.TargetID := TUnit(order^.target.unit_).UnitId;
    end;
//    CAST : Addline('');
//      (SpellTarget : pointer ; spell : TAbility ; SpellPos : TPoint);
  end;
  buffer := @Packet;
  AddLine('Sending data');
  if (order^.action = TRAIN) or (order^.action = UNTRAIN) then begin
    Packet.id := 18;
    i := 0;
    while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
      Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
      Inc(i);
    end;
  end else begin
    Packet.id := 12;
    Network.sendToIp(PAnsiChar(GlobalServerIP), buffer, sizeof(Packet));
  end;
end;

procedure sendServerString(str : string);
var
  buffer : pointer;
  Packet : TPacketString;
begin
  Packet.id := 4;
  Packet.execTime := 0;
  Packet.rank := GlobalClientRank;
  Packet.data := str;
  Packet.SenderNick := ClientTab.tab[0].info.nick;
  buffer := @Packet;
  AddLine('Sending data');
  Network.sendToIp(PAnsiChar(GlobalServerIP), buffer, sizeof(Packet));
end;

procedure sendServerCreateUnit(pos : Tpoint ; UnitType, Team, creatorID : integer);
var
  buffer : pointer;
  Packet : TPacketCreateUnit;
begin
  Packet.id := 6;
  Packet.execTime := Count.Now;
  Packet.pos := pos;
  Packet.Attributes := UnitType;
  Packet.Team := Team;
  Packet.creatorID := creatorID;
  buffer := @Packet;
  Network.sendToIp(PAnsiChar(GlobalServerIP), buffer, sizeof(Packet));
end;

procedure sendServerDamages(id, HP : integer);
var
  buffer : pointer;
  Packet : TPacketDamages;
begin
  Packet.id := 9;
  Packet.execTime := 0;
  Packet.targetID := id;
  Packet.HP := HP;
  buffer := @Packet;
  Network.sendToIp(PChar(GlobalServerIP), buffer, sizeof(Packet));
end;

procedure requestUpdatePublicPlayerList(myId, color, race, team : integer ; nick : string);
var
  buffer : pointer;
  Packet : TPacketPublicInfo;
begin
  Packet.id := 23;
  Packet.execTime := 0;
  Packet.infoId := myId;
  Packet.color := color;
  Packet.race := race;
  Packet.team := team;
  Packet.nick := string255(nick);

  buffer := @Packet;

  Network.sendToIp(PChar(GlobalServerIP), buffer, sizeof(Packet));
end;

//-----------------------------------------------------------/broadcast requests

// Sent by server to 1 client
procedure ReturnClientIP(ClientIP : string);
var
  buffer : pointer;
  Packet : TPacketClientIP;
begin
  Packet.id := 13;
  Packet.execTime := 0;
  Packet.ClientIP := ClientIP;
  buffer := @Packet;
  Network.sendToIp(PChar(ClientIP), buffer, sizeof(Packet));
end;

procedure AddPublicPlayerInfo(destinationClientId, id, color, race, team : integer ; nick, ip : string ; isYou : boolean);
var
  buffer : pointer;
  Packet : TPacketPublicInfo;
begin
  Packet.id := 22;
  Packet.execTime := 0;
  Packet.infoId := id;
  Packet.color := color;
  Packet.race := race;
  Packet.team := team;
  Packet.nick := nick;
  Packet.ip := ip;
  Packet.isYou := isYou;

  buffer := @packet;

  Network.sendToIp(PChar(ClientTab.tab[destinationClientId]^.ip), buffer, sizeof(Packet));
end;

// Server orders ---------------------------------------------------------------
procedure broadcastString(str, SenderIP, SenderNick : string ; rank : integer);
var
  buffer : pointer;
  Packet : TPacketString;
  i : integer;
begin
  Packet.id := 1;
  Packet.execTime := 0;
  Packet.rank := rank;
  Packet.SenderIP := SenderIP;
  Packet.data := str;
  Packet.SenderNick := SenderNick;
  buffer := @Packet;
  i := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure broadcastCreateUnit(pos : Tpoint ; UnitType, Team, creatorID : integer);
var
  buffer : pointer;
  Packet : TPacketCreateUnit;
  i : integer;
begin
  // Update ressources
  if (pos.x >= 0) and (pos.y >= 0)
  and (pos.x div UnitSize + Attributes[UnitType].Size <= MAP_SIZE)
  and (pos.y div UnitSize + Attributes[UnitType].Size <= MAP_SIZE)
  and CheckMap(Attributes[UnitType].Size, pos.x div UnitSize, pos.y div UnitSize) then begin
    if (ClientTab.tab[Team - 1]^.info.res1 >= Attributes[UnitType].Res1Cost)
    and (ClientTab.tab[Team - 1]^.info.res2 >= Attributes[UnitType].Res2Cost) then begin
      clientTab.tab[Team - 1]^.info.add_res1(-Attributes[UnitType].Res1Cost);
      clientTab.tab[Team - 1]^.info.add_res2(-Attributes[UnitType].Res2Cost);

      Packet.id := 7;
      Packet.execTime := Count.Now;
      Packet.unitID := GlobalUnitID;
      inc(GlobalUnitID);
      Packet.creatorID := creatorID;
      Packet.pos := pos;
      Packet.Attributes := UnitType;
      Packet.Team := Team;
      buffer := @Packet;
      i := 0;
      while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
        Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
        Inc(i);
      end;
    end else begin
      Warning.SetMsg('Not enough resources.');
    end;
  end;
end;

procedure broadcastDamages(id, HP : integer);
var
  buffer : pointer;
  Packet : TPacketDamages;
  i : integer;
begin
  Packet.id := 2;
  Packet.execTime := 0;
  Packet.targetID := id;
  Packet.HP := HP;
  buffer := @Packet;
  i := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure broadcastNewPlayer(newplayerID : integer);
// Broadcast to everyone exept the new player
// used in connection menu
  var
  buffer : pointer;
  Packet : TPacket;
  i : integer;
begin
  Packet.id := 16;
  Packet.execTime := 0;
  buffer := @Packet;
  i := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    if i <> newPlayerID then begin
      Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    end;
    Inc(i);
  end;
end;

procedure BroadCastLaunchGame();
var
  buffer : pointer;
  Packet : TPacketLaunchGame;
  i : integer;
begin
  Packet.id := 17;
  Packet.execTime := 0;
  buffer := @Packet;
  i := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Packet.synchronisationTime := ClientTab.tab[i]^.synchroPing;
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure BroadcastOrder(selfID : integer ; OrderType : TorderType; pos : TPoint; TargetID : integer);
var
  buffer : pointer;
  Packet : TPacketOrder;
  i : integer;
begin
  Packet.id := 12;
  Packet.execTime := Count.Now;
  Packet.selfID := SelfID;
  Packet.OrderType := OrderType;
  case OrderType of
    MOVETO, ATTACKTO, PATROL : begin
      Packet.pos := pos;
    end;
    FOLLOW, ATTACK, REPAIR, TRAIN, UNTRAIN : begin
      Packet.TargetID := TargetID;
    end;
//    CAST : Addline('');
//      (SpellTarget : pointer ; spell : TAbility ; SpellPos : TPoint);
  end;
  buffer := @Packet;
  i := 0;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure ping(ip : string);
var
  buffer : pointer;
  Packet : TPacketPing;
begin
  Packet.id := 19;
  Packet.execTime := 0;
  Packet.PingTime := Count.Now;
  buffer := @Packet;
  Network.sendToIp(PAnsiChar(ip), buffer, sizeof(Packet));
end;

procedure disconnectAllClients();
var
  buffer : pointer;
  Packet : TPacketDisconnect;
  i : integer;
begin
  Packet.id := 21;
  Packet.execTime := 0;
  buffer := @Packet;
  i := 1;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure BroadcastPublicPlayerInfo(newPlayerId, color, race, team : integer ; nick : string); //isYou : false
var
  buffer : pointer;
  Packet : TPacketPublicInfo;
  i : integer;
begin
  Packet.id := 22;
  Packet.execTime := 0;
  Packet.infoId := newPlayerId;
  Packet.color := color;
  Packet.race := race;
  Packet.team := team;
  Packet.nick := nick;
  Packet.isYou := false;

  buffer := @Packet;

  i := 1;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    if i <> newPlayerId then begin // Not sent to the new player...
      Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    end;
    Inc(i);
  end;
end;

procedure BroadcastPublicListRefresh(id, color, race, team : integer ; nick : string);
var
  buffer : pointer;
  Packet : TPacketPublicInfo;
  i : integer;
begin
  Packet.id := 24;
  Packet.execTime := 0;
  Packet.infoId := id;
  Packet.color := color;
  Packet.race := race;
  Packet.team := team;
  Packet.nick := nick;

  buffer := @Packet;

  i := 1;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    if i <> id then begin // Not sent to the player who requested the update (already refreshed).
      Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    end;
    Inc(i);
  end;
end;

procedure broadcastUpdateTUnit(UnitId, InfoToUpdate : integer ; p : TPAcketTUnit);
// On passe en paramètre le type d'info qu'on update, et dans p on ne rempli que
// le type à mettre à jour.
var
  buffer : pointer;
  i : integer;
begin
  p.id := 100;
  p.unitId := unitId;
  p.infoToUpdate := InfoToUpdate;
  p.execTime := Count.Now + (TURN_LENGTH*TURN_DELAY);  

  buffer := @p;
  i := 1;
  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(p));
    Inc(i);
  end;
end;

procedure broadcastUpdateRessources();
var
  Packet : TPacketUpdateRessources;
  buffer : pointer;
  i : integer;
begin
  Packet.id := 30;
  Packet.execTime := Count.Now;
  i := 1;

  while (i < ClientTab.size) and (ClientTab.tab[i] <> NIL) do begin
    Packet.res1 := ClientTab.tab[i].info.res1;
    Packet.res2 := ClientTab.tab[i].info.res2;
    buffer := @Packet;
    Network.sendToIp(PAnsiChar(ClientTab.tab[i]^.ip), buffer, sizeof(Packet));
    Inc(i);
  end;
end;

procedure sendNetworkSetServer(ServerIP, nick : string);
var
  buffer : pointer;
  Packet : TPacketSetServer;
  nick255 : string255;
begin
  // On supprime ses propores infos de la public list pour que le serveur vienne
  // se placer en premiere position de la liste et ajoute les bonnes infos...
  ClientTab.tab[0].publicPlayerList.remove(0);


  nick255 := nick;
  ClientTab.tab[0].info.nick := nick255;
  Packet.id := 3;
  Packet.execTime := 0;
  Packet.SenderNick := nick255;
  Packet.SenderRace := 1;
  ClientTab.tab[0].info.race := 1;
  Packet.SenderTeam := ClientTab.tab[0].info.team;
  Packet.SenderColor := 1;
  ClientTab.tab[0].info.color := 1;
  buffer := @Packet;
  Network.sendToIp(PChar(ServerIP), buffer, sizeof(Packet));
end;

procedure sendDisconnectClient(ServerIP, ClientIP : string);
var
  buffer : pointer;
  Packet : TPacketDisconnectServer;
begin
  Packet.id := 5;
  Packet.execTime := 0;
  Packet.ClientIP := ClientIP;
  buffer := @Packet;
  Network.sendToIp(PChar(ServerIP), buffer, sizeof(Packet));
end;

procedure setClientAs(ip : string ; rank : integer);
var
  buffer : pointer;
  Packet : TPacketSetClientAs;
begin
  Packet.id := 8;
  Packet.execTime := 0;
  Packet.rank := rank;
  buffer := @Packet;
  Network.sendToIp(PChar(ip), buffer, sizeof(Packet));
end;

procedure pong(pingTime : int64);
var
  buffer : pointer;
  Packet : TPacketPing;
begin
  Packet.id := 20;
  Packet.execTime := 0;
  Packet.pingTime := pingTime;
  buffer := @Packet;
  
  Network.sendToIp(PChar(GlobalServerIP), buffer, sizeof(Packet));
end;

// ---------------------------------------------------------------/Server orders

procedure receiveNetwork();
var
  NetAnswer : integer;
  buffer : pointer;
  SenderIP : string255;
  Packet : PNetPacket;
  warning : integer;
  VistaReady : string;  // WTF variable : DO NOT TOUCH
begin
  getmem(buffer, 1024*50);
  NetAnswer := Network.receiveFrom(buffer, SenderIP);
  if NetAnswer = 1 then begin
    new(Packet);
    Packet^.time := PPacket(buffer)^.execTime;
    Packet^.buffer := buffer;
    Packet^.SenderIP := SenderIP;
    warning := PacketTas.insert(Packet);
    if warning = -1 then begin
      Log('Erreur d''entassage de packet !');
      dispose(Packet);
    end;
  end else begin
    freemem(buffer);
  end;
end;

function executeNetwork() : boolean;
var
  p : TPacket;
  senderIP : string255;
  buffer : pointer;
  Packet : PNetPacket;
begin
  if PacketTas.count = 0 then begin
    result := false;
    exit;
  end;
  Packet := PacketTas.peek;
  if (packet.time div TURN_LENGTH) + TURN_DELAY > Count.Now div TURN_LENGTH then begin
    result := false
  end else begin
    buffer := Packet^.buffer;
    senderIP := Packet^.SenderIP;
    p := Tpacket(buffer^);
//    Log(IntToStr(p.id));
    case p.id of
      //  Received and executed by the client
      1 : displayChat(      PPacketString(buffer)^.SenderIP,
                            PPacketString(buffer)^.SenderNick,
                            PPacketString(buffer)^.data          );

      2 : doDamages(        PPacketDamages(buffer)^.targetID,
                            PPacketDamages(buffer)^.HP           );

      7 : createUnit2(      PPacketCreateUnit(buffer)^.pos,
                            PPacketCreateUnit(buffer)^.Attributes,
                            PPacketCreateUnit(buffer)^.Team,
                            PPacketCreateUnit(buffer)^.unitID,
                            PPacketCreateUnit(buffer)^.creatorID );

      8 : netSetClientAs(   PPacketSetClientAs(buffer)^.rank     );


      11 : AddServerList4(  SenderIP,
                            PPacketBroadcastAnser(buffer)^.serverName,
                            PPacketBroadcastAnser(buffer)^.player_count,
                            PPacketBroadcastAnser(buffer)^.map   );

      19 : pong(            PPacketPing(buffer)^.PingTime        );
      21 : serverConnectionLost();

      //  Received and executed by the server
      3 : CreateClient_(   SenderIP,
                           PPacketSetServer(buffer)^.SenderNick,
                           PPacketSetServer(buffer)^.SenderRace,
                           PPacketSetServer(buffer)^.SenderTeam,
                           PPacketSetServer(buffer)^.SenderColor );
      5 : DestroyClient(   PPacketDisconnectServer(buffer)^.ClientIP);
      10 : CheckServer(    SenderIP                              );
      20 : CalculatePing(  senderIP,
                           PPacketPing(buffer)^.pingTime,
                           Count.Now                         );

      //  Received by the server in order to broadcast it
      4 : broadcastString( PPacketstring(buffer)^.data,
                           SenderIP,
                           PPacketstring(buffer)^.SenderNick,
                           PPacketstring(buffer)^.rank           );

      6 : begin
//        Log(IntToStr(PPacketCreateUnit(buffer)^.Team)); // Attention si un jour on peut changer de team !
//        Log(IntToStr(PPacketCreateUnit(buffer)^.Attributes));
//        if (ClientTab.tab[PPacketCreateUnit(buffer)^.Team -1]^.info.res1 >= Attributes[PPacketCreateUnit(buffer)^.Attributes].Res1Cost)
//        and (ClientTab.tab[PPacketCreateUnit(buffer)^.Team -1]^.info.res2 >= Attributes[PPacketCreateUnit(buffer)^.Attributes].Res2Cost) then

        broadcastCreateUnit(PPacketCreateUnit(buffer)^.pos,
                            PPacketCreateUnit(buffer)^.Attributes,
                            PPacketCreateUnit(buffer)^.Team,
                            PPacketCreateUnit(buffer)^.creatorID  );
      end;

      9 : broadcastDamages(TPacketDamages(buffer^).targetID,
                           TPacketDamages(buffer^).HP            );

      18 : broadcastOrder( TPacketOrder(buffer^).selfID,
                           TPacketOrder(buffer^).OrderType,
                           TPacketOrder(buffer^).pos,
                           TPacketOrder(buffer^).TargetID        );
      23 : UpdatePublicInfoNBroadcast(TPacketPublicInfo(buffer^).infoId,
                                      TPacketPublicInfo(buffer^).color,
                                      TPacketPublicInfo(buffer^).race,
                                      TPacketPublicInfo(buffer^).team,
                                      TPacketPublicInfo(buffer^).nick,
                                      TPacketPublicInfo(buffer^).ip      );

      // Received by the client to be executed
      13 : GlobalClientIP := PPacketClientIP(buffer)^.ClientIP;
      16 : RefreshPlayerList(L);
      17 : LaunchGame(     TPacketLaunchGame(buffer^).synchronisationTime);
      12 : ExecuteOrder(   TPacketOrder(buffer^).selfID,
                           TPacketOrder(buffer^).OrderType,
                           TPacketOrder(buffer^).pos,
                           TPacketOrder(buffer^).TargetID,
                           packet.time,
                           TPacketOrder(buffer^).add                          );
      // ! Packet 22 called by 2 different functions !
      22 : begin
             if TPacketPublicInfo(buffer^).ip <> '127.0.0.1' then begin
               SenderIP := TPacketPublicInfo(buffer^).ip;
             end;
             ClientTab.tab[0].publicPlayerList.add(TPacketPublicInfo(buffer^).infoId,
                                                   TPacketPublicInfo(buffer^).color,
                                                   TPacketPublicInfo(buffer^).team,
                                                   TPacketPublicInfo(buffer^).race,
                                                   TPacketPublicInfo(buffer^).nick,
                                                   SenderIP,
                                                   TPacketPublicInfo(buffer^).isYou       );
           end;
      24 : ClientTab.tab[0].publicPlayerList.refresh(TPacketPublicInfo(buffer^).infoId,
                                                     TPacketPublicInfo(buffer^).color,
                                                     TPacketPublicInfo(buffer^).race,
                                                     TPacketPublicInfo(buffer^).team,
                                                     TPacketPublicInfo(buffer^).nick,
                                                     TPacketPublicInfo(buffer^).ip      );
      100:UpdateUnit(TPacketTUnit(buffer^).unitId,
                     TPacketTUnit(buffer^).InfoToUpdate,
                     TPacketTUnit(buffer^).speed,
                     TPacketTUnit(buffer^).TardetId,
                     TPacketTUnit(buffer^).realPosX,
                     TPacketTUnit(buffer^).realPosY,
                     TPacketTUnit(buffer^).realPosZ,
                     TPacketTUnit(buffer^).posX,
                     TPacketTUnit(buffer^).posY,
                     TPacketTUnit(buffer^).posZ,                     
                     TPacketTUnit(buffer^).destPosX,
                     TPacketTUnit(buffer^).destPosY,
//                     TPacketTUnit(buffer^).destPosZ,
                     TPacketTUnit(buffer^).HP,
                     TPacketTUnit(buffer^).MP,
                     TPacketTUnit(buffer^).HPRegen,
                     TPacketTUnit(buffer^).MPRegen,
                     TPacketTUnit(buffer^).AimedAngle,
                     TPacketTUnit(buffer^).ToDelete,
                     TPacketTUnit(buffer^).InConstruction,
                     TPacketTUnit(buffer^).RotationgClockWise,
                     TPacketTUnit(buffer^).Rotating,
                     TPacketTUnit(buffer^).active,
                     TPacketTUnit(buffer^).state,
                     TPacketTUnit(buffer^).last_up_move,

                     TPacketTUnit(buffer^).modelScale,
                     TPacketTUnit(buffer^).maxHP,
                     TPacketTUnit(buffer^).maxMP,
                     TPacketTUnit(buffer^).Damage,
                     TPacketTUnit(buffer^).Defense,
                     TPacketTUnit(buffer^).Atk_speed,
                     TPacketTUnit(buffer^).Atk_range,

                     TPacketTUnit(buffer^).TurnsRemaining,
                     TPacketTUnit(buffer^).Last_tick,
                     TPacketTUnit(buffer^).ticks,
                     TPacketTUnit(buffer^).Temporary,
                     TPacketTUnit(buffer^).AbilityID,
                     TPacketTUnit(buffer^).uID,
                     TPacketTUnit(buffer^).constructionPercent                );



      30 : UpdateRessources(TPacketUpdateRessources(buffer^).res1,
                            TPacketUpdateRessources(buffer^).res2  );
//      18 : begin
//        if (TPacketOrder(buffer^).OrderType = TRAIN)
//        or (TPacketOrder(buffer^).OrderType = UNTRAIN) then begin
//          ExecuteOrder(TPacketOrder(buffer^).selfID,
//                       TPacketOrder(buffer^).OrderType,
//                       TPacketOrder(buffer^).pos,
//                       TPacketOrder(buffer^).TargetID,
//                       TPacketOrder(buffer^).execTime,
//                       TPacketOrder(buffer^).add );
//        end;
//      end;
    end;
    freemem(buffer);
    PacketTas.extract(Pointer(Packet));
    dispose(packet);
    result := true;
  end;
end;

procedure TerminateNetwork();
begin
  Network.disconnect();
  Network.Destroy();
end;
end.
