unit FText;

interface
                        
procedure LoadFont(font : string; h: integer);    
procedure PrintText(id : integer; text : string);

implementation
uses
  FOpenGL, FFreeType, FLogs, SysUtils;

var
  LoadedFonts : array of record
    list : GLUint;
    chars : array[0..255] of GLuint;
  end;

function CeilPow2( a : integer ) : integer;
begin
  Result := 2;
  while Result < a do
    Result := Result shl 1;
end;

procedure LoadChar(face : FT_Face_ptr; ch, id : integer);
type
  PAInt = ^AInt;
  AInt = array of GLUInt;
var
  error, w, h, i, j, index, temp : integer;
  x, y : Single;
  glyph : FT_Glyph;
  bitmap : ^FT_Bitmap;
  data : array of GluByte;
  origin : FT_Vector;
begin
  index := FT_Get_Char_Index(face, ch);
  if index = 0 then
    exit;

  error := FT_Load_Glyph(face, index, FT_LOAD_DEFAULT);
  if error <> 0 then begin Log('FT_Load_Glyph ' + IntToStr(error)); exit; end;
  error := FT_Get_Glyph(face.glyph, glyph);
  if error <> 0 then begin Log('FT_Get_Glyph ' + IntToStr(error)); exit; end;
  origin.x := 0;
  origin.y := 0;
  error := FT_Glyph_To_Bitmap(@glyph, FT_RENDER_MODE_NORMAL, @origin, 1);
  if error <> 0 then begin Log('FT_Glyph_To_Bitmap ' + IntToStr(error)); exit; end;

  bitmap := @FT_BitmapGlyph(glyph).bitmap;
  
	w := CeilPow2(bitmap^.width);
	h := CeilPow2(bitmap^.rows);

  SetLength(data, 2 * h * w);

	for j := 0 to h - 1 do begin
		for i := 0 to w - 1 do begin
      temp := 2 * (i + j * w);
			data[temp] := 255;
      if (i >= bitmap^.width) or (j >= bitmap^.rows) then
        data[temp + 1] := 0
      else
        data[temp + 1] := AInt(bitmap^.buffer)[i + bitmap^.width * j];
//        data[temp + 1] := GLUint(Pointer(Cardinal(bitmap^.buffer) + (i + bitmap^.width * j) * SizeOf(GLUint)));
    end;
  end;

  glBindTexture(GL_TEXTURE_2D, LoadedFonts[id].chars[ch]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, w, h,
		  0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, data );

  SetLength(data, 0);

	glNewList(LoadedFonts[id].list + Cardinal(ch), GL_COMPILE);
    glBindTexture(GL_TEXTURE_2D, LoadedFonts[id].chars[ch]);
    glPushMatrix();
      glTranslatef(FT_BitmapGlyph(glyph).left, FT_BitmapGlyph(glyph).top - bitmap.rows, 0);

      x := bitmap^.width / w;
      y := bitmap^.rows / h;

      glBegin(GL_QUADS);
        glTexCoord2d(0, 0); glVertex2f(0,             bitmap^.rows);
        glTexCoord2d(0, y); glVertex2f(0,             0);
        glTexCoord2d(x, y); glVertex2f(bitmap^.width, 0);
        glTexCoord2d(x, 0); glVertex2f(bitmap^.width, bitmap^.rows);
      glEnd();
    glPopMatrix();
    glTranslatef(face.glyph.advance.x shr 6, 0, 0);
	glEndList();
end;

procedure LoadFont(font : string; h: integer);
var
  lib : FT_Library_ptr;
  face : FT_Face_ptr;
  len, i : integer;
begin
  len := Length(LoadedFonts);
  SetLength(LoadedFonts, len + 1);

	FT_Init_FreeType(@lib);
	FT_New_Face(lib, PChar(font), 0, face);
	FT_Set_Char_Size(face, h shl 6, h shl 6, 512, 512);

	LoadedFonts[len].list := glGenLists(256);
	glGenTextures(256, @LoadedFonts[len].chars[0]);

	for i := 0 to 255 do
		LoadChar(face, i, len);

	FT_Done_Face(face);
	FT_Done_FreeType(lib);
end;

procedure PrintText(id : integer; text : string);
begin
	glPushAttrib(GL_LIST_BIT or GL_CURRENT_BIT or GL_ENABLE_BIT or GL_TRANSFORM_BIT);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glListBase(LoadedFonts[id].list);
  glCallLists(Length(text), GL_UNSIGNED_BYTE, PChar(text));
end;




end.
