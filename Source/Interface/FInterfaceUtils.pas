unit FInterfaceUtils;

interface
uses
  Windows, SysUtils, FXMLLoader, FFonts, FLogs, FData, FUnit, FLua;

procedure SetPosition(Compo : PComponent);
procedure FillPointType(var p : pointType; s : string);                     
function FindRecordComponentByName(var c : RecordComponent; const name : string) : boolean;
function FindComponentByName(var c : Component; const name : string) : boolean;
function FindFrameByName(var id : integer; name : string) : boolean;
function FindFontStringByName(var id : integer; name : string) : boolean;
function FindTextureByName(var id : integer; name : string) : boolean;
procedure LogUI(f : integer = 0; s : string = '-');
procedure LoadInterface(path : string);
procedure CleanupInterface();
function FindUnitByID(var id : integer; UnitID : integer) : boolean;
function GetRealWidth(Compo : PComponent) : Integer;
function GetRealHeight(Compo : PComponent) : Integer;

implementation
uses
  FLuaFunctions;


procedure LoadInterface(path : string);
var
  i : integer;
begin
  InitInterface();
  InitXMLLoader();
  LoadXMLFile(path);

  for i := 1 to Length(FrameList) - 1 do begin
    if (FrameList[i].Anchor.RelativeToString = '') or
      not FindRecordComponentByName(FrameList[i].Anchor.RelativeTo, FrameList[i].Anchor.RelativeToString) then begin
        FrameList[i].Anchor.RelativeTo.id := FrameList[i].Parent;
        FrameList[i].Anchor.RelativeTo.t := FRAME;
      end;
  end;

  for i := 0 to Length(FontStringList) - 1 do begin
    if (FontStringList[i].Anchor.RelativeToString = '') or
      not FindRecordComponentByName(FontStringList[i].Anchor.RelativeTo, FontStringList[i].Anchor.RelativeToString) then begin
        FontStringList[i].Anchor.RelativeTo.id := FontStringList[i].Parent;
        FontStringList[i].Anchor.RelativeTo.t := FRAME;
      end;
  end;

  for i := 0 to Length(TextureList) - 1 do begin
    if (TextureList[i].Anchor.RelativeToString = '') or
      not FindRecordComponentByName(TextureList[i].Anchor.RelativeTo, TextureList[i].Anchor.RelativeToString) then begin
        TextureList[i].Anchor.RelativeTo.id := TextureList[i].Parent;
        TextureList[i].Anchor.RelativeTo.t := FRAME;
      end;
  end;


	Log('Interface Loaded');
//  LogUI();
	InterfaceLoaded := true;     
end;

procedure CleanupInterface();
var
  i : integer;
begin
  if L <> nil then
    lua_close(L);
	InterfaceLoaded := false;

  for i := 0 to Length(FrameList) - 1 do
    FrameList[i].Destroy();
  SetLength(FrameList, 0);
  for i := 0 to Length(FontStringList) - 1 do
    FontStringList[i].Destroy();
  SetLength(FontStringList, 0);
  for i := 0 to Length(TextureList) - 1 do
    TextureList[i].Destroy();
  SetLength(TextureList, 0);
end;

procedure LogUI(f : integer = 0; s : string = '-');
var
  i : integer;
  Frame : FrameType;
  FontString : FontStringType;
  virt : string;
begin
  Frame := FrameList[f];

  if Frame.Virtual then
    virt := ' [Virtual]'
  else
    virt := '';

  Log(s + Frame.Name + ' : ' + IntToStr(GetRealWidth(@Frame)) + 'x' + IntToStr(GetRealHeight(@Frame)) + virt);

  for i := 0 to Frame.TexturesCount - 1 do
    Log(s + ' Texture: ' + TextureList[Frame.Textures[i]].Name + ' : ' + IntToStr(GetRealWidth(@TextureList[Frame.Textures[i]])) + 'x' + IntToStr(GetRealHeight(@TextureList[Frame.Textures[i]])));

  for i := 0 to Frame.FontStringsCount - 1 do begin
    FontString := FontStringList[Frame.FontStrings[i]];
    SetStringSize(FontString.width, FontString.height, FontString.FontID, FontString.Text);
    Log(s + ' FontString: ' + FontStringList[Frame.FontStrings[i]].Name + ' : ' + IntToStr(GetRealWidth(@FontStringList[Frame.FontStrings[i]])) + 'x' + IntToStr(GetRealHeight(@FontStringList[Frame.FontStrings[i]])));
  end;

  for i := 0 to Frame.FramesCount - 1 do
    LogUI(Frame.Frames[i], s + ' ');
end;

function GetComponentByRecordComponent(c : RecordComponent) : Component;
begin
  Result := nil;
  case c.t of
    FRAME: Result := FrameList[c.id];
    TEXTURE: Result := TextureList[c.id];
    FONTSTRING: Result := FontStringList[c.id];
  end;
end;

function FindRecordComponentByName(var c : RecordComponent; const name : string) : boolean;
var
  i, len : integer;
begin
  Result := True;

  // FontString
  len := Length(FontStringList) - 1;
  i := 0;
  while (i <= len) and (FontStringList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c.t := FONTSTRING;
    c.id := i;
    exit;
  end;

  // Texture
  len := Length(TextureList) - 1;
  i := 0;
  while (i <= len) and (TextureList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c.t := TEXTURE;
    c.id := i;
    exit;
  end;

  // Frame
  len := Length(FrameList) - 1;
  i := 0;
  while (i <= len) and (FrameList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c.t := FRAME;
    c.id := i;
    exit;
  end;

  Log('Error: Component `' + name + '` does not exist');
  Result := False;
end;

function FindComponentByName(var c : Component; const name : string) : boolean;
var
  i, len : integer;
begin
  Result := True;

  // FontString
  len := Length(FontStringList) - 1;
  i := 0;
  while (i <= len) and (FontStringList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c := FontStringList[i];
    exit;
  end;

  // Texture
  len := Length(TextureList) - 1;
  i := 0;
  while (i <= len) and (TextureList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c := TextureList[i];
    exit;
  end;

  // Frame
  len := Length(FrameList) - 1;
  i := 0;
  while (i <= len) and (FrameList[i].Name <> name) do
    Inc(i);

  if i <= len then begin
    c := FrameList[i];
    exit;
  end;

  Log('Error: Component `' + name + '` does not exist');
  Result := False;
end;

function FindFontStringByName(var id : integer; name : string) : boolean;
var
  i, len : integer;
begin
  len := Length(FontStringList) - 1;
  i := 0;
  while i <= len do begin
    if FontStringList[i].Name = name then
      break;
    Inc(i);
  end;
  if i <= len then begin
    Result := true;
    id := i;
  end else begin
    Log('Error: FontString `' + name + '` does not exist');
    Result := false;
  end;
end;      

function FindTextureByName(var id : integer; name : string) : boolean;
var
  i, len : integer;
begin
  len := Length(TextureList) - 1;
  i := 0;
  while i <= len do begin
    if TextureList[i].Name = name then
      break;
    Inc(i);
  end;
  if i <= len then begin
    Result := true;
    id := i;
  end else begin
    Log('Error: Texture `' + name + '` does not exist');
    Result := false;
  end;
end;

function FindUnitByID(var id : integer; UnitID : integer) : boolean;
var
  i : integer;
begin
  i := 0;
  while i <= UnitList.Count - 1 do begin
    if TUnit(UnitList[i]).UnitID = UnitID then
      break;
    Inc(i);
  end;
  if i <= UnitList.Count - 1 then begin
    Result := true;
    id := i;
  end else begin
    Result := false;
  end;
end;

function FindFrameByName(var id : integer; name : string) : boolean;
var
  i, len : integer;
begin
  len := Length(FrameList) - 1;
  i := 0;
  while i <= len do begin
    if FrameList[i].Name = name then
      break;
    Inc(i);
  end;
  if i <= len then begin
    Result := true;
    id := i;
  end else begin
    Log('Error: Frame `' + name + '` does not exist');
    Result := false;
  end;
end;

procedure FillPointType(var p : pointType; s : string);
begin
  s := UpperCase(s);
  
  if s = 'TOP' then
    p := TOP
  else if s = 'BOTTOM' then
    p := BOTTOM
  else if s = 'LEFT' then
    p := LEFT
  else if s = 'RIGHT' then
    p := RIGHT
  else if s = 'CENTER' then
    p := CENTER
  else if s = 'TOPLEFT' then
    p := TOPLEFT
  else if s = 'BOTTOMLEFT' then
    p := BOTTOMLEFT
  else if s = 'TOPRIGHT' then
    p := TOPRIGHT
  else if s = 'BOTTOMRIGHT' then
    p := BOTTOMRIGHT
  else
    p := TOPLEFT;
end;

function GetSelection(width, height : Integer; point : pointType) : TPoint;
begin
  case point of
    TOPLEFT : begin
      Result.X := 0;
      Result.Y := 0;
    end;
    TOP : begin
      Result.X := width div 2;
      Result.Y := 0;
    end;
    TOPRIGHT : begin
      Result.X := width;
      Result.Y := 0;
    end;
    LEFT : begin
      Result.X := 0;
      Result.Y := height div 2;
    end;
    RIGHT : begin
      Result.X := width;
      Result.Y := height div 2;
    end;
    CENTER : begin
      Result.X := width div 2;
      Result.Y := height div 2;
    end;
    BOTTOMLEFT : begin
      Result.X := 0;
      Result.Y := height;
    end;
    BOTTOM : begin
      Result.X := width div 2;
      Result.Y := height;
    end;
    BOTTOMRIGHT : begin
      Result.X := width;
      Result.Y := height;
    end;
  end;
end;

function GetRealWidth(Compo : PComponent) : Integer;
begin
  while Compo.width = -1 do
    Compo := @FrameList[Compo^.Parent];
  Result := Compo^.width;     
end;

function GetRealHeight(Compo : PComponent) : Integer;
begin
  while Compo.height = -1 do
    Compo := @FrameList[Compo^.Parent];
  Result := Compo^.height;
end;

procedure SetPosition(Compo : PComponent);
var
  point : TPoint;
  Ref : Component;
begin
  Ref := GetComponentByRecordComponent(Compo^.Anchor.RelativeTo);

  Compo^.w := GetRealWidth(Compo);
  Compo^.h := GetRealHeight(Compo);

  Compo^.left := Compo^.Anchor.x + Ref.left;
  Compo^.top := Compo^.Anchor.y + Ref.top;

  point := GetSelection(GetRealWidth(@Ref), GetRealHeight(@Ref), Compo^.Anchor.RelativePoint);
  Inc(Compo^.left, point.X);
  Inc(Compo^.top, point.Y);

  point := GetSelection(Compo^.w, Compo^.h, Compo^.Anchor.Point);
  Dec(Compo^.left, point.X);
  Dec(Compo^.top, point.Y);
end;

end.
