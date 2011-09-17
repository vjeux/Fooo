//*********************************************************
//GLFONT.CPP -- glFont routines
//Copyright (c) 1998 Brad Fish
//*********************************************************

unit FFonts;

interface
uses
	Windows, FOpenGL, OpenGl, FLogs, SysUtils, Math, Classes, FTerrain;

type
  PGLFontChar = ^TGLFontChar;
  TGLFontChar = record
  	dx, dy : Single;
  	tx1, ty1 : Single;
	  tx2, ty2 : Single;
  end;

  PGLFont = ^TGLFont;
  TGLFont = record
  	tex : Integer;
  	texWidth, texHeight : Integer;
  	intStart, intEnd : Integer;
    character : PGLFontChar;
  end;
           
  PFont = ^TFont;
  TFont = record
    Path : string;
    GLID : GLuint;
    FontID : integer;
  end;


var
	LoadedFonts : TList;
	GLFonts: array of TGLFont;

  FontSquares : TSquares;
  FontSquaresIndices : array of Integer;

procedure glPrint(text : string; fontID : integer);
procedure glFontCreate(var tex : GLuint; pFont : PGLFont; fileName : string);
procedure glFontDestroy(pFont : PGLFont);
procedure SetFontSquares(pFont : PGLFont; str : string);
procedure SetStringSize(var x, y : integer; id : integer; str : string);      
function LoadFont(path: string) : integer;
procedure InitFonts();                 
procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;

implementation
uses
  FXMLLoader, FBase;


procedure InitFonts();
begin
  LoadedFonts := TList.Create();
end;

function LoadFont(path: string) : integer;
var
  index, len : integer;
  t : PFont;
begin
	if path <> '' then begin
    path := 'Fonts/' + path + '.glf';
    index := 0;
    len := LoadedFonts.Count;
    while (index < len) and (PFont(LoadedFonts.Items[index])^.Path <> path) do
      Inc(index);

		if (index = len) then begin
      New(t);
      t^.Path := path;
      len := Length(GLFonts);
      SetLength(GLFonts, len + 1);
      t^.FontID := len;
      glFontCreate(t^.GLID, @GLFonts[len], t^.Path);
      Result := LoadedFonts.Add(t);
		end else begin
      Result := index;
    end;
	end else
    Result := 0;
end;


procedure glPrint(text : string; fontID : integer);
var
	color : array[1..4] of GLFloat;
  pFont : PGLFont;
begin
  pFont := @GLFonts[fontID];

  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindTexture(GL_TEXTURE_2D, pFont^.tex);

  // Shadow
  GlGetFloatv(GL_CURRENT_COLOR, @color);
 
  SetFontSquares(pFont, text);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glVertexPointer(2, GL_FLOAT, 0, FontSquares.vertex);
  glTexCoordPointer(2, GL_FLOAT, 0, FontSquares.texture);

  glColor3f(0, 0, 0);
  glPushMatrix();
    glTranslatef(2, 2, 0);
    glDrawElements(GL_QUADS, Length(text)*4, GL_UNSIGNED_INT, FontSquaresIndices);
    glcolor3f(color[1], color[2], color[3]);
    glTranslatef(-1.5, -1.5, 0);
    glDrawElements(GL_QUADS, Length(text)*4, GL_UNSIGNED_INT, FontSquaresIndices);
    glTranslatef(-0.5, 0, 0);
    glDrawElements(GL_QUADS, Length(text)*4, GL_UNSIGNED_INT, FontSquaresIndices);
  glPopMatrix();

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
end;


procedure glFontCreate(var tex : GLuint; pFont : PGLFont; fileName : string);
var
	input : file;
	pTexBytes : PChar;
	num : integer;
begin
  AssignFile(input, fileName);
  Reset(input, 1);
  BlockRead(input, pFont^, SizeOf(TGLFont));

	glGenTextures(1, tex);
  pFont^.tex := tex;
  num := pFont^.intEnd - pFont^.intStart + 1;
  GetMem(pFont.character, SizeOf(TGLFontChar) * num);
  BlockRead(input, pFont^.character^, SizeOf(TGLFontChar) * num);
  num := pFont^.texWidth * pFont^.texHeight * 2;
  GetMem(pTexBytes, num);
  BlockRead(input, pTexBytes^, num);

  glBindTexture(GL_TEXTURE_2D, pFont^.tex);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  glTexImage2D(GL_TEXTURE_2D, 0, 2, pFont^.texWidth, pFont^.texHeight, 0,
                GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, pTexBytes);
  CloseFile(input);

  num := pFont^.texWidth * pFont^.texHeight * 2;
  FreeMem(pTexBytes, num);
end;

procedure glFontDestroy(pFont : PGLFont);
var
  num : Integer;
begin
  num := pFont^.intEnd - pFont^.intStart + 1;
  FreeMem(pFont^.character, SizeOf(TGLFontChar) * num);
  pFont^.character := nil;
end;

procedure SetStringSize(var x, y : integer; id : integer; str : string);
var
  i : integer;
  font : PGLFont;
  pCharacter : PGLFontChar;
  dx, dy : Double;
begin
  dx := 0;
  dy := 0;
  font := @GLFonts[id];

  for i := 0 to Length(str) - 1 do begin
    pCharacter := font^.character;
    Inc(pCharacter,  Integer(str[i + 1]) - font^.intStart);
    dx := dx + pCharacter^.dx * font^.texWidth;
    dy := Max(dy, pCharacter^.dy * font^.texHeight);
  end;

  x := Round(dx);
  y := Round(dy);
end;

procedure SetFontSquares(pFont : PGLFont; str : string);
var
  i : Integer;
  pCharacter : PGLFontChar;
  x, dx, dy : Single;
begin
  SetLength(FontSquares.texture, Length(str) * 8);
  SetLength(FontSquares.vertex, Length(str) * 8);
  SetLength(FontSquaresIndices, Length(str) * 4);

  x := 0;
  for i := 0 to Length(str) - 1 do begin
    pCharacter := pFont^.character;
    Inc(pCharacter,  Integer(str[i + 1]) - pFont^.intStart);

    dx := pCharacter^.dx * pFont^.texWidth;
    dy := pCharacter^.dy * pFont^.texHeight;

    FontSquares.texture[i*8 + 0] := pCharacter^.tx1;
    FontSquares.texture[i*8 + 1] := pCharacter^.ty1;

    FontSquares.texture[i*8 + 2] := pCharacter^.tx1;
    FontSquares.texture[i*8 + 3] := pCharacter^.ty2;

    FontSquares.texture[i*8 + 4] := pCharacter^.tx2;
    FontSquares.texture[i*8 + 5] := pCharacter^.ty2;

    FontSquares.texture[i*8 + 6] := pCharacter^.tx2;
    FontSquares.texture[i*8 + 7] := pCharacter^.ty1;

    FontSquares.vertex[i*8 + 0] := x;
    FontSquares.vertex[i*8 + 1] := 0;

    FontSquares.vertex[i*8 + 2] := x;
    FontSquares.vertex[i*8 + 3] := dy;

    FontSquares.vertex[i*8 + 4] := x + dx;
    FontSquares.vertex[i*8 + 5] := dy;

    FontSquares.vertex[i*8 + 6] := x + dx;
    FontSquares.vertex[i*8 + 7] := 0;

    FontSquaresIndices[i*4 + 0] := i*4 + 0;
    FontSquaresIndices[i*4 + 1] := i*4 + 1;
    FontSquaresIndices[i*4 + 2] := i*4 + 2;
    FontSquaresIndices[i*4 + 3] := i*4 + 3;

		x := x + dx;
  end;        

end;

end.

