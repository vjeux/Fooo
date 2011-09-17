//*********************************************************
//GLFONT.CPP -- glFont routines
//Copyright (c) 1998 Brad Fish
//See glFont.txt for terms of use
//November 10, 1998
//
//Conversion to Delphi: Daniel Klepel
//November 26, 2001
//*********************************************************

unit FGLFont;

interface
uses
	FOpenGL, OpenGl, FLogs, SysUtils;

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

var
	GLFont: TGLFont;
                    
procedure glPrint(text : pchar);

procedure glFontCreate(pFont : PGLFont; fileName : string);
procedure glFontDestroy(pFont : PGLFont);
procedure glPrintFontText(pFont : PGLFont; str : string);

implementation

procedure glPrint(text : pchar);
var
	color : array[1..4] of GLFloat;
begin
  // Shadow
  GlGetFloatv(GL_CURRENT_COLOR, @color);
  glColor3f(0, 0, 0);
  glTranslatef(1, 1, 0);
  glPrintFontText(@GLFont, text);
  glColor3f(color[1], color[2], color[3]);
  glTranslatef(-1, -1, 0);

  glPrintFontText(@GLFont, text);
end;


procedure glFontCreate(pFont : PGLFont; fileName : string);
var
	input : file;
	pTexBytes : PChar;
	num, tex : integer;
begin
  AssignFile(input, fileName);
  Reset(input, 1);
  BlockRead(input, pFont^, SizeOf(TGLFont));

  tex := 0;
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

procedure glGetStringSize(var x, y : integer; font: PGLFont; str : string);
var
  i : integer;    
  pCharacter : PGLFontChar;
begin
  x := 0;
  y := 0;

  for i := 0 to Length(str) - 1 do begin     
    pCharacter := font^.character;
    Inc(pCharacter,  Integer(str[i + 1]) - font^.intStart);
    Inc(x, Round(pCharacter^.dx * font^.texWidth));
    Inc(y, Round(pCharacter^.dy * font^.texHeight));
  end;
end;

procedure glPrintFontText(pFont : PGLFont; str : string);
var
  i : Integer;
  pCharacter : PGLFontChar;
  x, dx, dy : Single;
begin
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindTexture(GL_TEXTURE_2D, pFont^.tex);
	glBegin(GL_QUADS);

  x := 0;
  for i := 0 to Length(str) - 1 do begin
    pCharacter := pFont^.character;
    Inc(pCharacter,  Integer(str[i + 1]) - pFont^.intStart);

    dx := pCharacter^.dx * pFont^.texWidth;
    dy := pCharacter^.dy * pFont^.texHeight;

		glTexCoord2f(pCharacter^.tx1, pCharacter^.ty1);
		glVertex3f(x, 0, 0);

		glTexCoord2f(pCharacter^.tx1, pCharacter^.ty2);
		glVertex3f(x, dy, 0);

		glTexCoord2f(pCharacter^.tx2, pCharacter^.ty2);
		glVertex3f(x + dx, dy, 0);

		glTexCoord2f(pCharacter^.tx2, pCharacter^.ty1);
		glVertex3f(x + dx, 0, 0);

		x := x + dx;
  end;
  
	glEnd();
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
end;

end.

