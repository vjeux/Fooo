unit Fplayer;

{
 La Classe Tplayer
 créé par vizi le 22/03/2008
 contient les information d'un joueur,
 notamment ses ressources, son ID serveur, son pseudo, équipe etc...
 défini également les classes Tcolor et Trace.
}

interface

uses
  FDisplay;

const
  TeamColor : array[0..7] of TCoords3c = (
    (x : 0.00; y : 1.00; z : 1.00), // Cyan
    (x : 1.00; y : 0.00; z : 1.00), // Magenta
    (x : 1.00; y : 0.00; z : 0.00), // Red
    (x : 0.00; y : 1.00; z : 0.00), // Green
    (x : 0.00; y : 0.00; z : 1.00), // Blue
    (x : 1.00; y : 1.00; z : 0.00), // Yellow
    (x : 1.00; y : 1.00; z : 1.00), // White
    (x : 0.50; y : 0.50; z : 0.50)  // Gray
  );
  DEFAULT_GOLD = 2500;
  DEFAULT_WOOD = 0;

type

  Tplayer = class
    private
      _Res1    : double;
      _Res2    : double;

      _color   : integer;
      _team    : integer;
      _race    : integer;
      _id      : integer;
      _unitcount : integer;
      _nick    : string;
    public
      constructor Create();

        //only allowed before playing
      procedure init_nick(n  : string);
      procedure init_color(c : integer);
      procedure init_race(r  : integer);
      procedure init_team(t  : integer);
      procedure init_id(id  : integer);

        //allowed in game
      procedure add_res1(n : double);
      procedure add_res2(n : double);
      procedure add_unit();
      procedure kill_unit();
      procedure set_team(n : integer);

      property  res1       : double read _res1 write _res1;
      property  res2       : double read _res2 write _res2;
      property  nick       : string  read _nick write _nick;
      property  color      : integer read _color write _color;
      property  team       : integer read _team write _team;
      property  race       : integer read _race write _race;
      property  id         : integer read _id;
      property unitcount   : integer read _unitcount;

      // Les write des fonctions ci dessus sont pas tres secure mais bon
      // on fais avec temporairement...
  end;


  TPublicPlayerInfo = class
    Public
      isYou   : boolean;
      color   : integer;
      team    : integer;
      race    : integer;
      nick    : string;
      ip      : string;
      constructor create;
      procedure refresh(color, team, race : Integer; nick, ip: string);
  end;

  TPublicPlayerList = class
    Public
      tab : array[0..7] of TPublicPlayerInfo;
      count : integer;
      constructor create;
      procedure refresh(id, color, team, race : integer ; nick, ip : string);
      procedure add(id, color, team, race : integer ; nick, ip : string ; isYou : boolean);
      procedure remove(id : integer);
  end;

implementation

uses
  FLogs, sysutils, Fredirect, FLuaFunctions, Fserver, FInterfaceDraw;

constructor Tplayer.Create();
begin
  self._id := 0;
  self._res1 := DEFAULT_GOLD;
  self._res2 := DEFAULT_WOOD;
  self._color := 0;
  self._unitcount := 0;
  self._team := 1;
  self._race := 1;
  self._nick := 'Error_noNick';
end;

procedure TPlayer.init_id(id  : integer);
begin

end;

procedure Tplayer.add_res1(n : double);
begin
  self._res1 := self._res1 + n;
end;


procedure Tplayer.add_res2(n : double);
begin
  self._res2 := self._res2 + n;
end;

procedure Tplayer.add_unit();
begin
  inc(self._unitcount);
  TriggerEvent(EVENT_POPCHANGE);
end;

procedure Tplayer.kill_unit();
begin
  dec(self._unitcount);
  TriggerEvent(EVENT_POPCHANGE);
end;

procedure Tplayer.init_color(c : integer);
begin
  //FIX ME
  {
  Server_request(PLAYER, INIT, COLOR, sizeof(c), c);
  }
end;

procedure Tplayer.init_nick(n : string);
begin
  //FIX ME
  {
  Server_request(PLAYER, INIT, NICK, length(n), format_string(n));
  }
end;

procedure Tplayer.set_team(n : integer);
begin
  //FIX ME
  {
  Server_request(PLAYER, UPDATE, TEAM, length(n), n);
  }
end;


procedure Tplayer.init_race(r : integer);
begin
  //FIX ME
  {
  Server_request(PLAYER, INIT, RACE, sizeof(r), r);
  }
end;

procedure Tplayer.init_team(T : integer);
begin
  //FIX ME
  {
  Server_request(PLAYER, INIT, RACE, sizeof(r), r);
  }
end;


constructor TPublicPlayerInfo.create;
begin
  self.color := -1;
  self.race := -1;
  self.team := -1;
  self.nick := 'Error FPlayer l. 163';
  self.isYou := false;
  self.ip := 'Error IP';
end;

procedure TPublicPlayerInfo.refresh(color, team, race : Integer; nick, ip: string);
begin
//Set value to -1 or '' if you don't want to modify it...
  if color <> -1 then
    self.color := color;
  if race <> -1 then
    self.race := race;
  if team <> -1 then
    self.team := team;
  if nick <> '' then
    self.nick := nick;
  if ip <> '' then
    self.ip := ip;

// If in MENU, reload displayed informations.
  if CurrentScreen = SCREEN_MENU then begin
    RefreshPlayerList(L);
  end;
end;

constructor TPublicPlayerList.create;
begin
  self.count := 0;
end;

procedure TPublicPlayerList.refresh(id, color, team, race : integer ; nick, ip : string);
begin
  self.tab[id].refresh(color, team, race, nick, ip);

  // If you are the server, update your basic ClientTab info too :
  if GlobalServerIP = '127.0.0.1' then begin
    ClientTab.tab[id].info.color := color;
    ClientTab.tab[id].info.team := team;
    ClientTab.tab[id].info.race := race;
    ClientTab.tab[id].info.nick := nick;
  end;
end;

procedure TPublicPlayerList.add(id, color, team, race : integer ; nick, ip : string ; isYou : boolean);
begin
  inc(self.count);
  self.tab[id] := TPublicPlayerInfo.create;
  self.refresh(id, color, team, race, nick, ip);
  self.tab[id].isYou := isYou;
  log('Public player list added' + intToStr(self.count));
end;

procedure TPublicPlayerList.remove(id : integer);
begin
  self.tab[id].Destroy;
  dec(self.count);
end;


end.
