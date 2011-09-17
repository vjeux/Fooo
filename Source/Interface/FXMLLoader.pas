unit FXMLLoader;

{
  Restrictions :
    - No more than 512 * subframes    per frame
                       * textures
                       * fontstrings
    - No more than 512 levels of subframes

}

interface
uses
	XMLIntf, XMLDoc, FLogs, SysUtils, FFonts, FLua, FOpenGL, FTextures;

type
  // Global
	pointType = (TOP, BOTTOM, LEFT, RIGHT, CENTER, TOPLEFT, BOTTOMLEFT, TOPRIGHT, BOTTOMRIGHT);

  ComponentType = (FRAME, TEXTURE, FONTSTRING);
  RecordComponent = record
    t : ComponentType;
    id : integer;
  end;

	AnchorType = Record
		Point : pointType;
		RelativePoint : pointType;
		RelativeTo : RecordComponent;
    RelativeToString : string[255];
    x : integer;
    y : integer;
	end;

  ColorType = record
    r, g, b : Integer;
  end;
                         
  PComponent = ^Component;
  Component = class
    public
      width : integer;
      height : integer;
      left : integer;
      top : integer;
      w : integer;
      h : integer;
      Hidden : boolean;
      Virtual : boolean;
      Name : string;
      Anchor : AnchorType;   
      Parent : integer;    
      Color : ColorType;
  end;

  // Fonts

	FontStringType = class(Component)
		Size : integer;
		Font : string;
    FontID : integer;
		Text : string;
	end;

  // Textures

 	TexCoordType = record
		top : Single;
  	right : Single;
		bottom : Single;
		left : Single;
	end;

	TextureType = class(Component)
    public
      Path : string;
      GLID : GLuint;
      TexCoord : TexCoordType;
	end;

  // Frames

	ScriptsType = Record
		OnLoad : string;
		OnUpdate : string;
		OnMouseUp : string;
		OnMouseDown : string;
    OnEvent : string;
		OnEnter : string;
		OnLeave : string;
		OnKeyDown : string;
	end;

	FrameType = class(Component)
    public
      EnableMouse : boolean;
      MouseHover : boolean;
      EnableKeyboard : boolean;
      Background : string[255];
      BackgroundGLID : GLuint;
      Border : string[255];
      BorderGLID : GLuint;
      BorderSize : integer;
      Scripts : ScriptsType;

      FramesCount : integer;
      Frames : array[0..511] of integer;
      TexturesCount : integer;
      Textures : array[0..511] of integer;
      FontStringsCount : integer;
      FontStrings : array[0..511] of integer;
	end;

	PNode = ^IXMLNode;

var
  FrameList : array of FrameType;
  TextureList : array of TextureType;
  FontStringList : array of FontStringType;
	FrameStack : array[0..511] of integer;
  FrameStackCount : integer;

	XMLFunctionList : array[0..100] of procedure (Node : PNode);
	XMLTypeList : array[0..100] of string;

procedure initXMLLoader();
procedure LoadXMLFile(path : string);    
procedure ParseChild(Node : PNode);

implementation
uses
	FGlWindow, FInterfaceDraw, FLuaFunctions, FInterfaceUtils;

function Inc(var i : integer) : integer; overload; begin i := i + 1; Result := i; end;

// --
// -- HERITAGE --
// --

procedure CopyComponent(Dest, Source : PComponent);
var
  Temp : PComponent;
begin
  Dest^.width := Source^.width;
  Dest^.height := Source^.height;
  Dest^.Hidden := Source^.Hidden; 
  Dest^.Color := Source^.Color;
  Dest^.Virtual := False;

  Temp := Dest;
  while (Temp^.Parent <> 0) and not Temp^.Virtual do
    Temp := @FrameList[Temp.Parent];
                           
  Dest^.Anchor := Source^.Anchor;
  if not Temp^.Virtual and (Dest^.Parent <> 0) then begin
    Dest^.Name := StringReplace(Source^.Name, '$parent', FrameList[Dest^.Parent].Name, [rfReplaceAll]);
    Dest^.Anchor.RelativeToString := StringReplace(Source^.Anchor.RelativeToString, '$parent', FrameList[Dest^.Parent].Name, [rfReplaceAll]);
  end else begin
    Dest^.Name := Source^.Name;
    Dest^.Anchor.RelativeToString := Source^.Anchor.RelativeToString;
  end;   
end;

procedure CopyTexture(DestID, SourceID : Integer);
var
  Dest, Source : TextureType;
begin
  Dest := TextureList[DestID];
  Source := TextureList[SourceID];

  CopyComponent(@Dest, @Source);

  Dest.Path := Source.Path;
  Dest.GLID := Source.GLID;
  Dest.TexCoord := Source.TexCoord;
end;

procedure CopyFontString(DestID, SourceID : Integer);
var
  Dest, Source : FontStringType;
begin
  Dest := FontStringList[DestID];
  Source := FontStringList[SourceID];
                                  
  CopyComponent(@Dest, @Source);

  Dest.Size := Source.Size;
  Dest.Font := Source.Font;
  Dest.FontID := Source.FontID;
  Dest.Text := Source.Text;
  SetStringSize(Dest.width, Dest.height, Dest.FontID, Dest.Text);
end;

procedure CopyFrame(DestID, SourceID : Integer);
var
  i, l : integer;
  Dest, Source : FrameType;
begin
  Dest := FrameList[DestID];
  Source := FrameList[SourceID];

  Dest.EnableMouse := Source.EnableMouse;
  Dest.MouseHover :=  Source.MouseHover;
  Dest.EnableKeyboard := Source.EnableKeyboard;
  Dest.Background := Source.Background;
  Dest.BackgroundGLID := Source.BackgroundGLID;
  Dest.Border := Source.Border;
  Dest.BorderGLID := Source.BorderGLID;
  Dest.BorderSize := Source.BorderSize;
  Dest.Scripts := Source.Scripts;

  if not Source.Virtual then
    Dest.Name := StringReplace(Source.Name, '$parent', FrameList[Dest.Parent].Name, [rfReplaceAll]);

  Dest.FramesCount := Source.FramesCount;
  for i := 0 to Dest.FramesCount - 1 do begin
    l := Length(FrameList);
    SetLength(FrameList, l + 1);
    FrameList[l] := FrameType.Create();
    FrameList[l].Parent := DestID;
    Dest.Frames[i] := l;
    CopyFrame(l, Source.Frames[i]);
  end;

  Dest.TexturesCount := Source.TexturesCount;
  for i := 0 to Dest.TexturesCount - 1 do begin
    l := Length(TextureList);
    SetLength(TextureList, l + 1);
    TextureList[l] := TextureType.Create();
    TextureList[l].Parent := DestID;
    Dest.Textures[i] := l;
    CopyTexture(l, Source.Textures[i]);
  end;

  Dest.FontStringsCount := Source.FontStringsCount;
  for i := 0 to Dest.FontStringsCount - 1 do begin
    l := Length(FontStringList);
    SetLength(FontStringList, l + 1);
    FontStringList[l] := FontStringType.Create();
    FontStringList[l].Parent := DestID;
    Dest.FontStrings[i] := l;
    CopyFontString(l, Source.FontStrings[i]);
  end;

  CopyComponent(@Dest, @Source);
end;

// --
// -- INIT --
// --

procedure InitComponentVariables(Compo : PComponent);
begin
  Compo^.Anchor.x := 0;
  Compo^.Anchor.y := 0;
  Compo^.Anchor.RelativePoint := TOPLEFT;
  Compo^.Anchor.Point := TOPLEFT;
  Compo^.Anchor.RelativeTo.t := FRAME;
  Compo^.Anchor.RelativeTo.id := Compo^.Parent;
  Compo^.Anchor.RelativeToString := '';
  Compo^.Name := '';
  Compo^.width := -1;
  Compo^.height := -1;
  Compo^.Hidden := False;
  Compo^.Virtual := False;
  Compo^.Color.r := 255;
  Compo^.Color.g := 255;
  Compo^.Color.b := 255;
end;

procedure InitFrameVariables(var Frame : FrameType);
begin
  Frame.EnableMouse := False;
  Frame.MouseHover := False;
  Frame.EnableKeyboard := False;     
  Frame.Background := '';  
  Frame.BackgroundGLID := 0;
  Frame.Border := '';
  Frame.BorderGLID := 0;
  Frame.BorderSize := 64;
  Frame.Scripts.OnLoad := '';
  Frame.Scripts.OnUpdate := '';
  Frame.Scripts.OnMouseUp := '';
  Frame.Scripts.OnMouseDown := '';
  Frame.Scripts.OnEnter := '';
  Frame.Scripts.OnLeave := '';
  Frame.Scripts.OnEvent := '';
  Frame.Scripts.OnKeyDown := '';
  Frame.FramesCount := 0;
  Frame.TexturesCount := 0;
  Frame.FontStringsCount := 0;
end;

procedure InitTextureVariables(var Texture : TextureType);
begin
  Texture.Path := '';
  Texture.GLID := 0;
  Texture.TexCoord.top := 0;
  Texture.TexCoord.right := 1;
  Texture.TexCoord.bottom := 1;
  Texture.TexCoord.left := 0;
end;

procedure InitFontStringVariables(var FontString : FontStringType);
begin
  FontString.Size:= 0;
  FontString.Font := 'Thorndale14';
  FontString.FontID := LoadFont(FontString.Font);
  FontString.Text := '';
end;         

// --
// -- FILL --
// --

procedure FillFontStringVariables(Node : PNode; var FontString : FontStringType);
begin
  if Node^.HasAttribute('size') then
    FontString.Size := Node^.GetAttribute('size');
  if Node^.HasAttribute('font') then begin
    FontString.Font := Node^.GetAttribute('font');
    FontString.FontID := LoadFont(FontString.Font);
  end;
  if Node^.HasAttribute('text') then
    FontString.Text := Node^.GetAttribute('text');
  SetStringSize(FontString.width, FontString.height, FontString.FontID, FontString.Text);
end;

procedure FillFrameVariables(Node : PNode; var Frame : FrameType);
begin
  if Node^.HasAttribute('EnableMouse') and Node^.GetAttribute('EnableMouse') = 'true' then
    Frame.EnableMouse := true;

  if Node^.HasAttribute('EnableKeyboard') and Node^.GetAttribute('EnableKeyboard') = 'true' then
    Frame.EnableKeyboard := true;
                                                 
  if Node^.HasAttribute('Background') then begin
    Frame.Background := Node^.GetAttribute('Background');
    Frame.BackgroundGLID := LoadTexture(Frame.Background);
  end;

  if Node^.HasAttribute('Border') then begin
    Frame.Border := Node^.GetAttribute('Border');
    Frame.BorderGLID := LoadTexture(Frame.Border);
  end;

  if Node^.HasAttribute('BorderSize') then
    Frame.BorderSize := Node^.GetAttribute('BorderSize');
end;

procedure FillComponentVariables(Node : PNode; Compo : PComponent);
var
	ChildNode : IXMLNode;
begin
  if Node^.HasAttribute('name') then
    Compo^.Name := Node^.GetAttribute('name');

  if Node^.HasAttribute('width') then
    Compo^.width := Node^.GetAttribute('width');

  if Node^.HasAttribute('height') then
    Compo^.height := Node^.GetAttribute('height');

  if Node^.HasAttribute('hidden') and (Node^.GetAttribute('hidden') = 'true') then
    Compo^.Hidden := true;

  if Node^.HasAttribute('virtual') and (Node^.GetAttribute('virtual') = 'true') then
    Compo^.Virtual := true;

  if Node^.HasAttribute('r') then
    Compo^.Color.r := Node^.GetAttribute('r');
  if Node^.HasAttribute('g') then
    Compo^.Color.g := Node^.GetAttribute('g');
  if Node^.HasAttribute('b') then
    Compo^.Color.b := Node^.GetAttribute('b');

  if Node^.HasChildNodes then begin
		ChildNode := Node^.ChildNodes.First;
		repeat
			if (ChildNode.NodeName = 'Anchor') then begin
        if ChildNode.HasAttribute('x') then
          Compo^.Anchor.x := ChildNode.GetAttribute('x');
        if ChildNode.HasAttribute('y') then
          Compo^.Anchor.y := ChildNode.GetAttribute('y');
         if ChildNode.HasAttribute('relativePoint') then
          FillPointType(Compo^.Anchor.RelativePoint, ChildNode.GetAttribute('relativePoint'));
        if ChildNode.HasAttribute('point') then
          FillPointType(Compo^.Anchor.Point, ChildNode.GetAttribute('point'));
        if ChildNode.HasAttribute('relativeTo') then
            Compo^.Anchor.RelativeToString := ChildNode.GetAttribute('relativeTo');
      end;
			ChildNode := ChildNode.NextSibling;
		until ChildNode = nil;
  end;
end;

procedure FillTextureVariables(Node : PNode; var Texture : TextureType);
begin
  if Node^.HasAttribute('path') then begin
    Texture.Path := Node^.GetAttribute('path');
    Texture.GLID := LoadTexture(Texture.Path);
  end;
  if Node^.HasAttribute('top') then
    Texture.TexCoord.top := Node^.GetAttribute('top') / 100;
  if Node^.HasAttribute('left') then
    Texture.TexCoord.left := Node^.GetAttribute('left') / 100;
  if Node^.HasAttribute('bottom') then
    Texture.TexCoord.bottom := Node^.GetAttribute('bottom') / 100;
  if Node^.HasAttribute('right') then
    Texture.TexCoord.right := Node^.GetAttribute('right') / 100;
end;

// --
// -- HANDLE --
// --


procedure HandleNode(Node : PNode);
var
	i : integer;
begin
	for i := 0 to Length(XMLTypeList) - 1 do begin
		if Node.NodeName = XMLTypeList[i] then begin
			XMLFunctionList[i](Node);
      break;
    end;
  end;
end;

procedure HandleOnLoad(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnLoad := Node^.Text;  
end;

procedure HandleOnUpdate(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnUpdate := Node^.Text;
end;

procedure HandleOnMouseUp(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnMouseUp := Node^.Text;
end;

procedure HandleOnMouseDown(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnMouseDown := Node^.Text;
end;

procedure HandleOnEnter(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnEnter := Node^.Text;
end;

procedure HandleOnLeave(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnLeave := Node^.Text;
end;

procedure HandleOnEvent(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnEvent := Node^.Text;
end;

procedure HandleOnKeyDown(Node : PNode);
begin
	FrameList[FrameStack[FrameStackCount - 1]].Scripts.OnKeyDown := Node^.Text;
end;

procedure HandleTexture(Node : PNode);
var
  l, i, j, textureID : integer;
begin
  l := Length(TextureList);
  SetLength(TextureList, l + 1);
  TextureList[l] := TextureType.Create();

  i := FrameStackCount;
  TextureList[l].Parent := FrameStack[i-1];
  
  InitComponentVariables(@TextureList[l]);
  InitTextureVariables(TextureList[l]);

  if Node^.HasAttribute('name') then
    TextureList[l].Name := Node^.GetAttribute('name');

  // Inheritage
  if Node^.HasAttribute('inherit') then begin
    if FindTextureByName(textureID, Node^.GetAttribute('inherit')) then
      CopyTexture(l, textureID);
  end;

  FillComponentVariables(Node, @TextureList[l]);
  FillTextureVariables(Node, TextureList[l]);

  j := FrameList[FrameStack[i-1]].TexturesCount;
  Inc(FrameList[FrameStack[i-1]].TexturesCount);
  FrameList[FrameStack[i-1]].Textures[j] := l;
end;

procedure HandleFontString(Node : PNode);
var
  l, i, j, fontID : integer;
begin
  l := Length(FontStringList);
  SetLength(FontStringList, l + 1);
  FontStringList[l] := FontStringType.Create();

  i := FrameStackCount;     
  FontStringList[l].Parent := FrameStack[i-1];

  InitComponentVariables(@FontStringList[l]);
  InitFontStringVariables(FontStringList[l]);

  if Node^.HasAttribute('name') then
    FontStringList[l].Name := Node^.GetAttribute('name');

  // Inheritage
  if Node^.HasAttribute('inherit') then begin
    if FindFontStringByName(fontID, Node^.GetAttribute('inherit')) then
      CopyFontString(l, fontID);
  end;

  FillComponentVariables(Node, @FontStringList[l]);
  FillFontStringVariables(Node, FontStringList[l]);

  j := FrameList[FrameStack[i-1]].FontStringsCount;
  Inc(FrameList[FrameStack[i-1]].FontStringsCount);
  FrameList[FrameStack[i-1]].FontStrings[j] := l;
end;

procedure HandleFrame(Node : PNode);
var
	i, j, k, frameID : integer;
begin
  k := Length(FrameList);
  SetLength(FrameList, k + 1);
  FrameList[k] := FrameType.Create();

  i := FrameStackCount;
  Inc(FrameStackCount);

  // Parent Check
  FrameList[k].Parent := -1;
  if Node^.HasAttribute('parent') and FindFrameByName(frameID, Node^.GetAttribute('parent')) then
      FrameList[k].Parent := frameID;
  if (FrameList[k].Parent = -1) and (i-1 > 0) then
    FrameList[k].Parent := FrameStack[i-1]
  else
    FrameList[k].Parent := 0;

  InitComponentVariables(@FrameList[k]);
  if Node^.HasAttribute('name') then
    FrameList[k].Name := Node^.GetAttribute('name');

  // Inheritage
  if Node^.HasAttribute('inherit') then begin
    if FindFrameByName(frameID, Node^.GetAttribute('inherit')) then
      CopyFrame(k, frameID);
  end;

  FillComponentVariables(Node, @FrameList[k]);
  FillFrameVariables(Node, FrameList[k]);

	FrameStack[i] := k;

  j := FrameList[FrameStack[i-1]].FramesCount;
  Inc(FrameList[FrameStack[i-1]].FramesCount);
  FrameList[FrameStack[i-1]].Frames[j] := k;

	ParseChild(Node);

  if (FrameList[k].Scripts.OnLoad <> '') and (FrameList[k].Virtual = False) then begin
    lua_pushstring(L, PChar(FrameList[k].Name));
    lua_setglobal(L, 'self');
    RunScript(FrameList[k].Scripts.OnLoad);
  end;

  Dec(FrameStackCount);
end;

procedure HandleScript(Node : PNode);
begin
	if Node.HasAttribute('file') then
		AddLine(Node.Attributes['file']);
	if length(Node.Text) > 0 then
		AddLine(Node.Text);
end;

procedure HandleInclude(Node : PNode);
begin                                   
	if Node.HasAttribute('lua') then
		LoadLuaFile(Node.Attributes['lua']);
	if Node.HasAttribute('xml') then
		LoadXMLFile(Node.Attributes['xml']);
end;

// --
// -- PARSING --
// --

procedure SetInterfaceValues();
begin
  FrameList[0].Name := 'Interface';    
  FrameList[0].left := 0;
  FrameList[0].top := 0;
  FrameList[0].width := 1600;
  FrameList[0].height := 1200;
  FrameList[0].Anchor.point := TOPLEFT;
  FrameList[0].Anchor.RelativePoint := TOPLEFT;
//  FrameList[0].Anchor.RelativeTo := 0;
  FrameList[0].Anchor.RelativeToString := '';
  FrameList[0].FramesCount := 0;
  FrameList[0].TexturesCount := 0;
  FrameList[0].FontStringsCount := 0;
  FrameList[0].Parent := -1;
end;

procedure ParseChild(Node : PNode);
var
	ChildNode : IXMLNode;
begin
	if Node.HasChildNodes then begin
		ChildNode := Node.ChildNodes.First;
		repeat
			HandleNode(@ChildNode);
			ChildNode := ChildNode.NextSibling;
		until ChildNode = nil;
	end;
end;

procedure LoadXMLFile(path : string);
var
	Node : IXMLNode;
begin
  Log('Loading ' + path);
  if not FileExists(path) then begin
    Log('Error: File `' + path + '` does not exist');
    exit;
  end;

	try
		GlWindow.Document.LoadFromFile(path);
		Node := GlWindow.Document.DocumentElement;
  except
		on E : Exception do begin
			AddLine('Error loading ' + path + ': ' + E.Message);
			exit;
		end;
	end;

	HandleNode(@Node);
end;

procedure InitXMLLoader();
var
	i : integer;
begin
  SetLength(FrameList, 1);
  FrameList[0] := FrameType.Create();
  FrameStackCount := 1;

	FrameStack[0] := 0;
  SetInterfaceValues();

	i := -1;
	XMLTypeList[Inc(i)] := 'Ui';
	XMLFunctionList[i] := ParseChild;
	XMLTypeList[Inc(i)] := 'Frames';
	XMLFunctionList[i] := ParseChild;
	XMLTypeList[Inc(i)] := 'Scripts';
	XMLFunctionList[i] := ParseChild;

	XMLTypeList[Inc(i)] := 'Script';
	XMLFunctionList[i] := HandleScript;

	XMLTypeList[Inc(i)] := 'Include';
	XMLFunctionList[i] := HandleInclude;

	XMLTypeList[Inc(i)] := 'OnLoad';
	XMLFunctionList[i] := HandleOnLoad;
	XMLTypeList[Inc(i)] := 'OnUpdate';
	XMLFunctionList[i] := HandleOnUpdate;
	XMLTypeList[Inc(i)] := 'OnMouseUp';
	XMLFunctionList[i] := HandleOnMouseUp;
	XMLTypeList[Inc(i)] := 'OnMouseDown';
	XMLFunctionList[i] := HandleOnMouseDown;
	XMLTypeList[Inc(i)] := 'OnEnter';
	XMLFunctionList[i] := HandleOnEnter;
	XMLTypeList[Inc(i)] := 'OnLeave';
	XMLFunctionList[i] := HandleOnLeave;
  XMLTypeList[Inc(i)] := 'OnEvent';
	XMLFunctionList[i] := HandleOnEvent;
	XMLTypeList[Inc(i)] := 'OnKeyDown';
	XMLFunctionList[i] := HandleOnKeyDown;

	XMLTypeList[Inc(i)] := 'Frame';
	XMLFunctionList[i] := HandleFrame;
	XMLTypeList[Inc(i)] := 'Texture';
	XMLFunctionList[i] := HandleTexture;
	XMLTypeList[Inc(i)] := 'FontString';
	XMLFunctionList[i] := HandleFontString;

end;

end.

