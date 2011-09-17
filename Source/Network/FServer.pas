unit FServer;

interface

uses
  sysutils, FInterfaceDraw, FLuaFunctions, classes, FPlayer;

const
  MAX_CLIENTS = 8;

type

  PClient = ^TClient;
  TClient = record
    ip : string;
    info : TPlayer;
    ping : integer; // ping up to date
    synchroPing : integer;
    pings : TList;
    is_server, serverIsRunning : boolean;
    serverName : string;
    map : string;
    publicPlayerList : TPublicPlayerList;
  end;

  TClientTab = record
    size : integer;
    tab : array[0..MAX_CLIENTS-1] of PClient;
  end;

var
  ClientTab : TClientTab; //!\\ Global !!!
  GlobalServerIP : string;
  GlobalClientIP : string;
  GlobalClientRank : integer;

procedure InitClientTab();
procedure CreateServer(Servername, map : string);
procedure CreateClient(ip, nick : string255 ; race, color : integer ; isServer : boolean);
procedure DestroyClient(ip : string);


implementation

uses
  FTransmit, FData, FLogs, FConfig;

procedure InitClientTab();
var
  i : integer;
  cfgFile : TConfig;
  nick : string;
begin
  for i := 0 to MAX_CLIENTS - 1 do begin
    ClientTab.tab[i] := NIL;
  end;
  ClientTab.size := 0;
  GlobalServerIP := '127.0.0.1';
  GlobalClientIP := '127.0.0.1';
  if FileExists('Fooo.cfg') then begin
    cfgFile := TConfig.create;
    nick := cfgFile.get_nick;
  end else begin
    Log('Missing Fooo.cfg !!');
    nick := 'Erreur dans le fichier de config';
  end;
  CreateClient('127.0.0.1', nick, 0, 5, false);
end;

procedure CreateServer(Servername, map : string);
begin
  ClientTab.tab[0].is_server := true;
  ClientTab.tab[0].serverName := serverName;
  Clienttab.tab[0].map := map;
  Clienttab.tab[0].synchroPing := -1;
end;

procedure CreateClient(ip, nick : string255 ; race, color : integer ; isServer : boolean);
var
  i, j : integer;
begin
  i := 0;
  while (i < MAX_CLIENTS - 1) AND (ClientTab.tab[i] <> NIL) do begin
    inc(i);
  end;
  if ClientTab.tab[i] = NIL then begin
    new(ClientTab.tab[i]);
    ClientTab.tab[i]^.serverIsRunning := false;
    if ClientTab.tab[0].serverIsRunning then begin
      Log('A new client is trying to connect (' + ip + ', ' + nick+ ') but server is running !');
      dispose(ClientTab.tab[i]);
      exit;
    end;
    ClientTab.tab[i]^.pings := TList.Create;
    ClientTab.tab[i]^.synchroPing := -1;
    ClientTab.tab[i]^.ip := ip;
    ClientTab.tab[i]^.info := TPlayer.Create;
    ClientTab.tab[i]^.info.nick := nick;
    ClientTab.tab[i]^.info.race := race;
    ClientTab.tab[i]^.info.team := i;
    ClientTab.tab[i]^.info.color := color;
    ClientTab.tab[i]^.is_server := isServer;
    Inc(ClientTab.size);
    Addline('New client : ip = ' + ClientTab.tab[i]^.ip + ' nick = '
                                   + ClientTab.tab[i]^.info.nick + ' race = '
                                   + IntToStr(ClientTab.tab[i]^.info.race) + ' team = '
                                   + IntToStr(ClientTab.tab[i]^.info.team) + ' color = '
                                   + IntToStr(ClientTab.tab[i]^.info.color));
    Addline('Client added to cell ' + IntToStr(i));
    if i = 0 then begin
      ClientTab.tab[0]^.PublicPlayerList := TPublicPlayerList.create;
    end;
    // Upadate server's public info --
    ClientTab.tab[0]^.PublicPlayerList.add(i, color, i, race, nick, ip, i = 0);
    // --
    if GlobalClientRank = -42 then begin
      GlobalClientRank := i;
      FData.Player := GlobalClientRank+1;
    end else begin
      SetClientAs(ip, i);
    end;
    if i <> 0 then begin
      //If new player is not the server, tell everybody that there's a new player
      //so other clients can refresh their list.
      broadcastNewPlayer(i);
    end;
    // Send public list to the new client exept if it's the server --
    j := 0;
    while j + 1 <= ClientTab.tab[0]^.publicPlayerList.count do begin
      if i <> 0 then begin
        log('Sending to player ' + IntToStr(i) + ' infos about player ' + IntToStr(j)); 
        AddPublicPlayerInfo(i, // Id of the receiver
                            j, // Id of the client described by all the following info :
                            ClientTab.tab[0]^.publicPlayerList.tab[j].color,
                            ClientTab.tab[0]^.publicPlayerList.tab[j].race,
                            ClientTab.tab[0]^.publicPlayerList.tab[j].team,
                            ClientTab.tab[0]^.publicPlayerList.tab[j].nick,
                            ClientTab.tab[0]^.publicPlayerList.tab[j].ip,
                            i = j (* isYou  *)                                );
      end;
        inc(j);
    end;
    // --
    // Broadcast public infos to everybody exept server and new client --
    BroadcastPublicPlayerInfo(i, color, race, i, nick); //isYou : false
    // --
    // Broadcast to
  end else begin
    Addline('Array is full !');
  end;
end;


procedure DestroyClient(ip : string);
var
  i : integer;
begin
  i := 0;
  while (CLientTab.tab[i] <> NIL) and (ClientTab.tab[i].ip <> ip) do begin
    inc(i);
  end;
  if ClientTab.tab[i] <> NIL then begin
    Addline(ClientTab.tab[i]^.info.nick + ' (' + ClientTab.tab[i]^.ip + ') has left the game');
    dispose(ClientTab.tab[i]);
    ClientTab.tab[i] := NIL;
    dec(ClientTab.size);
    inc(i);
    // Filling the hole made by the destruction
    while (i <> MAX_CLIENTS) and (ClientTab.tab[i] <> NIL) do begin
      ClientTab.tab[i - 1] := ClientTab.tab[i];
      AddLine('Client ' + IntToStr(i) + ' moved to ' + IntToStr(i - 1));
      inc(i);
    end;
  end;
end;
end.

