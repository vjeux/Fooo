unit FLoadMap;

interface
procedure LoadMap(path : string);

implementation
uses
  SysUtils, Windows, FTransmit, FData, FUnit, FLogs, FPlayer, FReceive
  , FServer;

procedure LoadMap(path : string);
var
  F : TextFile;
  id : integer;
  pos : TPoint;
  u : TUnit;
  temppos : array of TPoint;
begin
  AssignFile(F, path);
  Reset(F);

  while not EOF(F) do begin
    ReadLn(F, id, pos.X, pos.Y);
    pos.X := pos.X * UNITSIZE;
    pos.Y := pos.Y * UNITSIZE;
    if id < 10 then begin
      SetLength(TempPos, Length(TempPos) + 1);
      TempPos[Length(TempPos) - 1] := pos;
      // pos depart
    end else begin
      u := CreateUnit2(pos, id, 1, id, -1); //-1 : noOne created that unit
      u.TeamColor.X := 139 / 255;
      u.TeamColor.Y := 69 / 255;
      u.TeamColor.Z := 19 / 255;
    end;
  end;

  if clienttab.tab[0].is_server then begin // Treants
    Dec(TempPos[0].X, 300);
    sendServerCreateUnit(TempPos[0], 1, GlobalClientRank+1, -1);
    Inc(TempPos[0].X, 300);
    sendServerCreateUnit(TempPos[0], 1, GlobalClientRank+1, -1);
    Inc(TempPos[0].X, 300);
    sendServerCreateUnit(TempPos[0], 1, GlobalClientRank+1, -1);
  end else begin                                // Rats
    Dec(TempPos[1].X, 300);
    sendServerCreateUnit(TempPos[1], 10, GlobalClientRank+1, -1);
    Inc(TempPos[1].X, 300);
    sendServerCreateUnit(TempPos[1], 10, GlobalClientRank+1, -1);
    Inc(TempPos[1].X, 300);
    sendServerCreateUnit(TempPos[1], 10, GlobalClientRank+1, -1);
  end;
end;

end.
