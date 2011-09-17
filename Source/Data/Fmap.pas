unit Fmap;

interface

uses
  Funit, Fdata, Fterrain, Windows;

const
  MAP_SIZE    = TerrainSize * TileSize div UNITSIZE;

type
  TMapTile = record
    Texture   : string;
    Cost      : integer;
    nb_units  : integer;
    Walkable  : boolean;
    Unite : TUnit;
  end;

  Tmap = array of array of TMapTile;

    //initialise la map
  procedure initMap();

    //retourne TRUE si un block de taille size peut aller en (x, y)
  function InBoundsMap(size, x, y : integer) : boolean;

    //remplit la map selon la taille de l'unite
  procedure OccupyMap(U : TUnit; a : integer=1);

    //libère la map selon la taille de l'unite
  procedure ClearMap(U : TUnit);

    //retourne TRUE si on peut placer une unité de taille size en case (x, y)
  function CheckMap(size : integer; x, y : integer) : boolean;

    //retourne TRUE si l'unité U peut se déplacer en case (x, y)
  function CheckMovementMap(U : TUnit; x, y : integer) : boolean;

    //retourne TRUE si l'unité U occupe la case (x, y)
  function unitStepsOn(U : Tunit; x, y : integer): boolean; overload;
  function unitStepsOn(U : Tunit; p    : Tpoint ): boolean; overload;

    //fonction de debug : dump un coin de la map dans un fichier
  procedure dumpMap(from, dest: Tpoint; filename : string);

var
  map : Tmap;

implementation

uses
  MyMath,
  //DEBUG
  SysUtils, my_swap, FInterfaceDraw, Point, FLogs;

  
function InBoundsMap(size, x, y : integer) : boolean;
var
  hsize : integer;
begin
  hsize := half(size);
  Result := (x >= hsize)
        and (x - hsize < Map_Size)
        and (y >= hsize)
        and (y - hsize < Map_Size);
end;


procedure initMap();
var
  i, j : integer;
begin
  SetLength(Map, MAP_SIZE, MAP_SIZE);
  for i := 0 to MAP_SIZE - 1 do begin
    for j := 0 to MAP_SIZE - 1 do begin
      Map[i,j].Texture := 'grass';  //valeurs par defaut pour le test
      Map[i,j].Cost := 1;          
      Map[i,j].Walkable := true;
      Map[i,j].nb_units := 0;
    end;
  end;
end;


procedure OccupyMap(U : TUnit; a : integer=1);
var
  i, j, hsize : integer;
  len1, len2 : integer;
begin
  if U.Stats.Size > 0 then begin
    len1 := Length(Map);
    len2 := Length(Map[0]); // Hope map is declared ...
    hsize := half(U.Stats.Size);
    for i := 0 to U.Stats.Size - 1 do begin //on remplit toutes les cases
      for j := 0 to U.Stats.Size - 1 do begin
        if   (U.pos.x - hsize + i < 0)
          or (U.pos.x - hsize + i >= len1)
          or (U.pos.y - hsize + j < 0)
          or (U.pos.y - hsize + j >= len2) then
          Log(u.name + ' is going outside the map ! ('
          + IntToStr(U.pos.x - hsize + i) + ' / '
          + IntToStr(U.pos.y - hsize + j) + ')')
        else
        begin
          inc(Map[U.pos.x - hsize + i, U.pos.y - hsize + j].nb_units, a);
          if a = -1 then
            Map[U.pos.x - hsize + i, U.pos.y - hsize + j].Unite := nil
          else
            Map[U.pos.x - hsize + i, U.pos.y - hsize + j].Unite := U;
        end;
      end;
    end;
  end;
end;


procedure ClearMap(U : TUnit);
begin
  OccupyMap(U, -1);
end;


function unitStepsOn(U : Tunit; x, y : integer) :boolean;
var
  hsize : integer;
begin
  hsize := half(U.Stats.Size);
  Result := (x >= U.pos.x - hsize)
        and (x <= U.pos.x + hsize)
        and (y >= U.pos.y - hsize)
        and (y <= U.pos.y + hsize);
end;


function unitStepsOn(U: Tunit; p: Tpoint): boolean;
var
  hsize : integer;
begin
  hsize := half(U.Stats.Size);
  Result := (p.x >= U.pos.x - hsize)
        and (p.x <= U.pos.x + hsize)
        and (p.y >= U.pos.y - hsize)
        and (p.y <= U.pos.y + hsize);
end;


function CheckMap(size : integer; x, y : integer) : boolean;
var
  i, j, hsize : integer;
begin
  Result := InBoundsMap(size, x, y);
  hsize := half(size);
  for i := 0 to size - 1 do begin
    for j := 0 to size - 1 do
    begin
      result := (Map[x - hsize + i, y - hsize + j].nb_units = 0);
      if not(result) then
        exit;
    end;
  end;
end;


function CheckMovementMap(U : TUnit; x, y : integer) : boolean;
var
  i, j, hsize : integer;
begin
  result := InBoundsMap(U.Stats.Size, x, y);
  hsize := half(U.Stats.Size);
  for i := 0 to U.Stats.Size - 1 do
    for j := 0 to U.Stats.Size - 1 do
    begin
      Result := (Map[x - hsize + i, y - hsize + j].nb_units = 0)
                or unitStepsOn(U, x, y);
      if not Result then
        break;
    end;
end;


//DEBUG
procedure dumpMap(from, dest: Tpoint; filename : string);
var
  i, j : integer;
  t : Textfile;
begin
  if from.x > dest.x then
    my_swap.swap(from.x, dest.x);
  if from.y < dest.y then //les y inversés
    my_swap.swap(from.y, dest.y);
    
  AssignFile(t, filename);
  ReWrite(t);
  for i := from.y downto dest.y do
  begin
    for j := from.x to dest.x do
      write(t, inttostr(map[j, i].nb_units), ' ');
    writeln(t, '');
    writeln(t, '');
  end;
  CloseFile(t);
end;


end.
