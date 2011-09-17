unit FInterface;

interface
uses
	Windows, FOpenGl, FBase, FTextures, Flogs, FFonts,
  SysUtils, FGlWindow, FFPS, FCursor, FData, FTerrain, FSelection, FUnit, FXMLLoader;

var
  Chat : array[0..36] of string;

procedure DrawInterface(select : boolean);
procedure AddLine(str : string);
procedure drawFrame(f : integer);

implementation

procedure AddLine(str : string);
var
  i : integer;
begin
  for i := 34 downto 0 do
    Chat[i+1] := Chat[i];
  Chat[0] := str;
end;

procedure DrawImage(path : string; partX, partY, partW, partH, imageW, imageH, NewW, NewH : extended);
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(path);
	glBegin(GL_QUAD_STRIP);
		glTexCoord2f(partX / imageW, partY / imageH);
		glVertex3f(0, 0, 0);

		glTexCoord2f((partX + partW) / imageW, partY / imageH);
		glVertex3f(NewW, 0, 0);

		glTexCoord2f(partX / imageW, (partY + partH) / imageH);
		glVertex3f(0, NewH, 0);

		glTexCoord2f((partX + partW) / imageW, (partY + partH) / imageH);
		glVertex3f(NewW, NewH, 0);
	glEnd();
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);
end;

function GetSelection(Ref : PComponent; point : pointType) : TPoint;
begin
  case point of
    TOPLEFT : begin
      Result.X := 0;
      Result.Y := 0;
    end;
    TOP : begin
      Result.X := Ref^.width div 2;
      Result.Y := 0;
    end;
    TOPRIGHT : begin
      Result.X := Ref^.width;
      Result.Y := 0;
    end;
    LEFT : begin
      Result.X := 0;
      Result.Y := Ref.height div 2;
    end;
    RIGHT : begin
      Result.X := Ref^.width;
      Result.Y := Ref^.height div 2;
    end;
    CENTER : begin
      Result.X := Ref^.width div 2;
      Result.Y := Ref^.height div 2;
    end;
    BOTTOMLEFT : begin
      Result.X := 0;
      Result.Y := Ref^.height;
    end;
    BOTTOM : begin
      Result.X := Ref^.width div 2;
      Result.Y := Ref^.height;
    end;
    BOTTOMRIGHT : begin
      Result.X := Ref^.width;
      Result.Y := Ref^.height;
    end;
  end;
end;

procedure SetPosition(Compo : PComponent);
var
  point : TPoint;
  Ref : FrameType;
begin
  Ref := FrameList[Compo^.Anchor.RelativeTo];

  Compo.left := Compo^.Anchor.x + Ref.left;
  Compo.top := Compo^.Anchor.y + Ref.top;

  point := GetSelection(@Ref, Compo.Anchor.RelativePoint);
  Inc(Compo^.left, point.X);
  Inc(Compo^.top, point.Y);

  point := GetSelection(Compo, Compo.Anchor.Point);
  Dec(Compo^.left, point.X);
  Dec(Compo^.top, point.Y);
end;

procedure drawTexture(Texture : TextureType);
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(Texture.Path);

	glBegin(GL_QUADS);
		glTexCoord2f(Texture.TexCoord.left, Texture.TexCoord.top);
		glVertex3f(Texture.left, Texture.top, 0);

		glTexCoord2f(Texture.TexCoord.right, Texture.TexCoord.top);
		glVertex3f(Texture.left + Texture.width, Texture.top, 0);

		glTexCoord2f(Texture.TexCoord.right, Texture.TexCoord.bottom);
		glVertex3f(Texture.left + Texture.width, Texture.top + Texture.height, 0);

		glTexCoord2f(Texture.TexCoord.left, Texture.TexCoord.bottom);
		glVertex3f(Texture.left, Texture.top + Texture.height, 0);
	glEnd();
  glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
end;

procedure drawFontString(FontString : FontStringType);
begin
  glPushMatrix();
    glTranslatef(FontString.left, FontString.top, 0);
    glPrint(FontString.Text);
  glPopMatrix();
end;

procedure drawFrame(f : integer);
var
  i : integer;
  Frame : FrameType;
  FontString : FontStringType;
begin
  Randomize();

  Frame := FrameList[f];
  if Frame.Hidden or Frame.Virtual then
    exit;
  if f <> 0 then
    SetPosition(@Frame);

//  glColor3f(Random(100)/100, Random(100)/100, Random(100)/100);
//  glBegin(GL_QUAD_STRIP);
//    glVertex3f(Frame.left              , Frame.top, 0);
//    glVertex3f(Frame.left + Frame.width, Frame.top, 0);
//    glVertex3f(Frame.left              , Frame.top + Frame.height, 0);
//    glVertex3f(Frame.left + Frame.width, Frame.top + Frame.height, 0);
//  glEnd();
//  glColor3f(1, 1, 1);

  for i := 0 to Frame.TexturesCount - 1 do begin
    SetPosition(@TextureList[Frame.Textures[i]]);
    drawTexture(TextureList[Frame.Textures[i]]);
  end;

  for i := 0 to Frame.FontStringsCount - 1 do begin
    FontString := FontStringList[Frame.FontStrings[i]];
    SetStringSize(FontString.width, FontString.height, @GLFont, FontString.Text);
    SetPosition(@FontString);
    drawFontString(FontString);
  end;

  for i := 0 to Frame.FramesCount - 1 do
    drawFrame(Frame.Frames[i]);
end;

procedure DrawInterface(select : boolean);
var
  i, l : integer;
begin
  if select then
    exit;

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, Window.X, Window.Y, 0);
	glMatrixMode(GL_MODELVIEW);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_TEXTURE_2D);

  if Mouse.OnSelection then
    DrawSelectionRectangle(Mouse.SelectionX, Mouse.SelectionY, Mouse.X, Mouse.Y);

  glPushMatrix();
    glScalef(Window.X / FrameList[0].width, Window.Y / FrameList[0].height, 1);
    drawFrame(0);
  glPopMatrix();

//  exit;

	glPushMatrix();
    DrawImage('Textures/Interface/Tile1.tga', 0, 0, 512, 128, 512, 512, 512/1600*Window.X, 128/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile2.tga', 0, 0, 512, 128, 512, 512, 512/1600*Window.X, 128/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile3.tga', 0, 0, 512, 128, 512, 512, 512/1600*Window.X, 128/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile4.tga', 0, 0, 64, 128, 64, 512, 64/1600*Window.X, 128/1200*Window.Y);
	glPopMatrix();

	glPushMatrix();
    glTranslatef(0, Window.Y - 384/1200*Window.Y, 0);

    DrawImage('Textures/Interface/Tile1.tga', 0, 128, 512, 384, 512, 512, 512/1600*Window.X, 384/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile2.tga', 0, 128, 512, 384, 512, 512, 512/1600*Window.X, 384/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile3.tga', 0, 128, 512, 384, 512, 512, 512/1600*Window.X, 384/1200*Window.Y);
    glTranslatef(512/1600*Window.X, 0, 0);
    DrawImage('Textures/Interface/Tile4.tga', 0, 128, 64, 384, 64, 512, 64/1600*Window.X, 384/1200*Window.Y);
	glPopMatrix();

	glPushMatrix();
    glTranslatef(Window.X - 60, 10, 1);
    glPrint('500');
	glPopMatrix();

	glPushMatrix();
    glTranslatef(Window.X - 135, 3, 0.1);
    DrawImage('Textures/Interface/Icons/ResourceUndead.tga', 0, 0, 32, 32, 32, 32, 32, 32);
    glTranslatef(50,0,-1);
	glPopMatrix();

  if Selection.Count >= 1 then
  begin
    glPushMatrix();
      glTranslatef(Window.X div 2 - 50, Window.Y - 200, 1);
      glPrint(PChar(TUnit(Selection[0]).Stats.Name));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2 - 140, Window.Y - 150, 1);
      glPrint(PChar('HP : '+ FloatToStr(Round(TUnit(Selection[0]).HP)) +  '/' + IntToStr(TUnit(Selection[0]).MaxHP)));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2, Window.Y - 150, 1);
      glPrint(PChar('MP : '+ FloatToStr(Round(TUnit(Selection[0]).MP)) +  '/' + IntToStr(TUnit(Selection[0]).MaxMP)));
    glPopMatrix();


    glPushMatrix();
      glTranslatef(Window.X div 2 - 140, Window.Y - 120, 1);
      glPrint(PChar('Position : '+ FloatToStr(TUnit(Selection[0]).RealPos.X) + ' ' + FloatToStr(TUnit(Selection[0]).RealPos.y)));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2 - 140, Window.Y - 90, 1);
      glPrint(PChar('Damage: '+ IntToStr(TUnit(Selection[0]).Damage)));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2, Window.Y - 90, 1);
      glPrint(PChar('Defense: '+ IntToStr(TUnit(Selection[0]).Defense)));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2 - 140, Window.Y - 60, 1);
      glPrint(PChar('Vitesse: '+ IntToStr(TUnit(Selection[0]).Speed)));
    glPopMatrix();

    glPushMatrix();
      glTranslatef(Window.X div 2, Window.Y - 60, 1);
      glPrint(PChar('Joueur: '+ IntToStr(TUnit(Selection[0]).Player)));
    glPopMatrix();
  end;

	glPushMatrix();
		glColor3f(1, 0, 1);
		glTranslatef(Window.X div 2 - 55, Window.Y - 260, 1);
		glPrint(PChar('FPS : ' + IntToStr(Count.FPS)));
		glColor3f(1, 1, 1);
	glPopMatrix();

	glPushMatrix();
		glTranslatef(Window.X div 2 - 300, Window.Y - 360, 1);
    if Mouse.Hover then begin
  		glPrint(PChar(IntToStr(Length(Mouse.HoverList)) + ' Targets :'));
      glTranslatef(100, 0, 0);
      for i := 0 to Length(Mouse.HoverList) - 1 do begin
        glPrint(PChar(IntToStr(Mouse.HoverList[i]) + ', '));
        glTranslatef(15, 0, 0);
      end;
    end else
      glPrint('No Target');
	glPopMatrix();

	glPushMatrix();
		glTranslatef(Window.X div 2 - 300, Window.Y - 260, 1);
		glPrint(PChar('Unit Count : ' + IntToStr(UnitList.Count)));
	glPopMatrix();

	glPushMatrix();
		glTranslatef(Window.X div 2 - 300, Window.Y - 330, 1);
		glPrint(PChar('X : ' + FloatToStr(Round(Mouse.terrain.x)) + ' : '
      + IntToStr(Trunc(Mouse.terrain.x) div UnitSize)));
	glPopMatrix();

	glPushMatrix();
		glTranslatef(Window.X div 2 - 300, Window.Y - 300, 1);
		glPrint(PChar('Y : ' + FloatToStr(Round(Mouse.terrain.y)) + ' : '
      + IntToStr(Trunc(Mouse.terrain.y) div UnitSize)));
	glPopMatrix();

  	glPushMatrix();
		glTranslatef(Window.X div 2 - 120, Window.Y - 285, 1);
		glPrint(PChar('Number of selected units : ' + IntToStr(Selection.Count)));
	glPopMatrix();

  glPushMatrix();
 		glColor3f(1, 0, 0);
    l := Length(Warning.Text);
		glTranslatef(Window.X div 2 - 5*l, Window.Y - 350, 1);
		glPrint(PChar(Warning.Text));
		glColor3f(1, 1, 1);
	glPopMatrix();


  for i := 0 to 34 do begin
    glPushMatrix();
      glTranslatef(20, Window.Y -50 - 20*i, 1);
      glPrint(PChar(Chat[i]));
    glPopMatrix();
  end;


end;

end.

