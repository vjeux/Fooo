unit FInterfaceDraw;

interface
uses
  FOpenGl;

procedure DrawInterface();        
procedure AddLine2(str : string);
procedure AddLine(str : string);
procedure drawFrame(f : integer);
procedure DrawCarre(GLID : GLuint; x, y, w : single);

var
  LaunchGameAfter : Boolean = False;


implementation
uses
	Windows, FLua, FBase, FTextures, Flogs, FFonts, FInterfaceUtils,
  FLuaFunctions, SysUtils, FGlWindow, FFPS, FCursor, FData, FTerrain,
  FSelection, FUnit, FXMLLoader, FRedirect;


procedure AddLine2(str : string);
begin
  Log('Addline : ' + str);
  if InterfaceLoaded then begin
    lua_getglobal(L, 'AddLine');
    lua_pushstring(L, PChar(str));
    lua_call(L, 1, 0);
  end;
end;
procedure AddLine(str : string);
begin
  Log('Addline : ' + str);  
  exit;
  if InterfaceLoaded then begin
    lua_getglobal(L, 'AddLine');
    lua_pushstring(L, PChar(str));
    lua_call(L, 1, 0);
  end;
end;

procedure DrawCarre(GLID : GLuint; x, y, w : single);
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(GLID);

	glBegin(GL_QUAD_STRIP);
		glTexCoord2f(0, 1);
		glVertex2f(x, y);

		glTexCoord2f(1, 1);
		glVertex2f(x+w, y);

		glTexCoord2f(0, 0);
		glVertex2f(x, y+w);

		glTexCoord2f(1, 0);
		glVertex2f(x+w, y+w);
	glEnd();

	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);
end;

procedure DrawImage(GLID : GLuint; partX, partY, partW, partH, imageW, imageH, NewW, NewH : extended);
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(GLID);

	glBegin(GL_QUAD_STRIP);
		glTexCoord2f(partX / imageW, partY / imageH);
		glVertex2f(0, 0);

		glTexCoord2f((partX + partW) / imageW, partY / imageH);
		glVertex2f(NewW, 0);

		glTexCoord2f(partX / imageW, (partY + partH) / imageH);
		glVertex2f(0, NewH);

		glTexCoord2f((partX + partW) / imageW, (partY + partH) / imageH);
		glVertex2f(NewW, NewH);
	glEnd();

	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);
end;


procedure drawTexture(Texture : TextureType);
begin
  if Texture.Path = '' then
    exit;

	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(Texture.GLID);
                                    
  glColor3f(Texture.Color.r / 255, Texture.Color.g / 255, Texture.Color.b / 255);
  
	glBegin(GL_QUADS);
		glTexCoord2f(Texture.TexCoord.left, 1 - Texture.TexCoord.top);
		glVertex2f(Texture.left, Texture.top);

		glTexCoord2f(Texture.TexCoord.right, 1 - Texture.TexCoord.top);
		glVertex2f(Texture.left + Texture.w, Texture.top);

		glTexCoord2f(Texture.TexCoord.right, 1 - Texture.TexCoord.bottom);
		glVertex2f(Texture.left + Texture.w, Texture.top + Texture.h);

		glTexCoord2f(Texture.TexCoord.left, 1 - Texture.TexCoord.bottom);
		glVertex2f(Texture.left, Texture.top + Texture.h);
	glEnd();

  glColor3f(1, 1, 1);

  glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
end;

procedure drawFontString(FontString : FontStringType);
begin
  glPushMatrix();                                      
    glColor3f(FontString.Color.r / 255, FontString.Color.g / 255, FontString.Color.b / 255);
    glTranslatef(FontString.left, FontString.top, 0);
    glPrint(FontString.Text, FontString.FontID);        
    glColor3f(1, 1, 1);
  glPopMatrix();
end;

procedure drawSquare(iT, iL, iH, iW, pT, pL, pW, pH : Single);
begin
  glBegin(GL_QUADS);
    glTexCoord2f(iL   , iT+iH);
    glVertex2f  (pL   , pT);
    glTexCoord2f(iL+iW, iT+iH);
    glVertex2f  (pL+pW, pT);
    glTexCoord2f(iL+iW, iT);
    glVertex2f  (pL+pW, pT+pH);
    glTexCoord2f(iL   , iT);
    glVertex2f  (pL   , pT+pH);
  glEnd();
end;

procedure drawSquareRotated(iT, iL, iH, iW, pT, pL, pW, pH : Single);
begin
  glBegin(GL_QUADS);
    glTexCoord2f(iL+iW, iT+iH);
    glVertex2f  (pL   , pT);

    glTexCoord2f(iL+iW, iT);
    glVertex2f  (pL+pW, pT);

    glTexCoord2f(iL   , iT);
    glVertex2f  (pL+pW, pT+pH);

    glTexCoord2f(iL   , iT+iH);
    glVertex2f  (pL   , pT+pH);
  glEnd();
end;

procedure drawBackground(Frame : FrameType);
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  BindTexture(Frame.BackgroundGLID);

  drawSquare(0, 0,
    (Frame.h - Frame.BorderSize) / Frame.BorderSize / 10,
    (Frame.w - Frame.BorderSize) / Frame.BorderSize / 10,
    Frame.top + Frame.BorderSize / 2 - 2,
    Frame.left + Frame.BorderSize / 2 - 2,
    Frame.w - Frame.BorderSize + 5,
    Frame.h - Frame.BorderSize + 5
  );

  glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
end;

procedure drawBorder(Frame : FrameType);
var
  tmpborderSize : Tpoint;
  tmpbordersize2 : Tpoint;
  _2bordersize : integer;
  wtfoptimvar  : integer;
  wtfoptimvar2  : integer;
begin
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  BindTexture(Frame.BorderGLID);

  tmpborderSize.x := (Frame.w div Frame.BorderSize) - 2;
  tmpborderSize.y := (Frame.h div Frame.BorderSize) - 2;
  _2bordersize := Frame.BorderSize shl 1;
  tmpbordersize2.x := Frame.w - _2bordersize;
  tmpbordersize2.y := Frame.h - _2bordersize;
  wtfoptimvar := Frame.left + Frame.w - Frame.BorderSize;
  wtfoptimvar2 := Frame.top + Frame.h - Frame.BorderSize;
  _2bordersize := Frame.left + Frame.BorderSize;

  drawSquareRotated(0, 0.25, TmpborderSize.x , 0.125, Frame.top, _2bordersize, tmpbordersize2.x, Frame.BorderSize);
  drawSquareRotated(0, 0.375, TmpborderSize.x , 0.125, wtfoptimvar2 , _2bordersize, tmpbordersize2.x, Frame.BorderSize);

  _2bordersize := Frame.top + Frame.BorderSize;
  drawSquare(0, 0,TmpborderSize.y , 0.125, _2bordersize, Frame.left, Frame.BorderSize, tmpbordersize2.y);
  drawSquare(0, 0.125, TmpborderSize.y, 0.125, _2bordersize, wtfoptimvar, Frame.BorderSize, tmpbordersize2.y);

  drawSquare(0, 0.5, 1, 0.125, Frame.top, Frame.left, Frame.BorderSize, Frame.BorderSize);
  drawSquare(0, 0.625, 1, 0.125, Frame.top, wtfoptimvar, Frame.BorderSize, Frame.BorderSize);
  drawSquare(0, 0.75, 1, 0.125, wtfoptimvar2, Frame.left, Frame.BorderSize, Frame.BorderSize);
  drawSquare(0, 0.875, 1, 0.125, wtfoptimvar2, wtfoptimvar, Frame.BorderSize, Frame.BorderSize);
//  drawSquareRotated(0, 2/8, (Frame.w - 2 * Frame.BorderSize) / Frame.BorderSize, 1/8, Frame.top, Frame.left + Frame.BorderSize, Frame.w - 2 * Frame.BorderSize, Frame.BorderSize);
//  drawSquareRotated(0, 3/8, (Frame.w - 2 * Frame.BorderSize) / Frame.BorderSize, 1/8, Frame.top + Frame.h - Frame.BorderSize, Frame.left + Frame.BorderSize, Frame.w - 2 * Frame.BorderSize, Frame.BorderSize);
//  drawSquare(0, 0/8, (Frame.h - 2 * Frame.BorderSize) / Frame.BorderSize, 1/8, Frame.top + Frame.BorderSize, Frame.left, Frame.BorderSize, Frame.h - 2 * Frame.BorderSize);
//  drawSquare(0, 1/8, (Frame.h - 2 * Frame.BorderSize) / Frame.BorderSize, 1/8, Frame.top + Frame.BorderSize, Frame.left + Frame.w - Frame.BorderSize, Frame.BorderSize, Frame.h - 2 * Frame.BorderSize);
//
//  drawSquare(0, 4/8, 1, 1/8, Frame.top, Frame.left, Frame.BorderSize, Frame.BorderSize);
//  drawSquare(0, 5/8, 1, 1/8, Frame.top, Frame.left + Frame.w - Frame.BorderSize, Frame.BorderSize, Frame.BorderSize);
//  drawSquare(0, 6/8, 1, 1/8, Frame.top + Frame.h - Frame.BorderSize, Frame.left, Frame.BorderSize, Frame.BorderSize);
//  drawSquare(0, 7/8, 1, 1/8, Frame.top + Frame.h - Frame.BorderSize, Frame.left + Frame.w - Frame.BorderSize, Frame.BorderSize, Frame.BorderSize);

  glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
end;

procedure drawFrame(f : integer);
var
  i : integer;
  Frame : FrameType;
  FontString : FontStringType;
begin
  Frame := FrameList[f];
  if Frame.Hidden or Frame.Virtual then
    exit;

  if Frame.Scripts.OnUpdate <> '' then begin
    lua_pushstring(L, PChar(Frame.Name));
    lua_setglobal(L, 'self');
    RunScript(Frame.Scripts.OnUpdate);
  end;

  if f <> 0 then
    SetPosition(@Frame);

  if Frame.EnableMouse then begin
    if (Mouse.InterfaceX >= Frame.left) and (Mouse.InterfaceX <= Frame.left + Frame.w)
    and (Mouse.InterfaceY >= Frame.top) and (Mouse.InterfaceY <= Frame.top + Frame.h) then begin
      if not Frame.MouseHover then begin  
        lua_pushstring(L, PChar(Frame.Name));
        lua_setglobal(L, 'self');
        RunScript(Frame.Scripts.OnEnter);
        Frame.MouseHover := True;
        lua_pushstring(L, PChar(Frame.Name));
        lua_setglobal(L, 'self');
      end;

      if (Mouse.ClickingState <> 0) then begin
        lua_pushstring(L, PChar(Frame.Name));
        lua_setglobal(L, 'self');
        lua_pushnumber(L, Abs(Mouse.ClickingState));
        lua_setglobal(L, 'arg1');
        if Mouse.ClickingState > 0 then
          RunScript(Frame.Scripts.OnMouseDown)
        else
          RunScript(Frame.Scripts.OnMouseUp);
      end;

    end else begin
      if Frame.MouseHover and (Frame.Scripts.OnLeave <> '') then begin
        lua_pushstring(L, PChar(Frame.Name));
        lua_setglobal(L, 'self');             
        RunScript(Frame.Scripts.OnLeave);
      end;
      Frame.MouseHover := False;
    end;
  end;

  if Frame.Background <> '' then
    drawBackground(Frame);
  if Frame.Border <> '' then
    drawBorder(Frame);

  for i := 0 to Frame.TexturesCount - 1 do begin   
    if not TextureList[Frame.Textures[i]].Hidden then begin
      SetPosition(@TextureList[Frame.Textures[i]]);
      drawTexture(TextureList[Frame.Textures[i]]);
    end;
  end;

  for i := 0 to Frame.FontStringsCount - 1 do begin
    if not FontStringList[Frame.FontStrings[i]].Hidden then begin
      FontString := FontStringList[Frame.FontStrings[i]];
      SetStringSize(FontString.width, FontString.height, FontString.FontID, FontString.Text);
      SetPosition(@FontString);
      drawFontString(FontString);
    end;
  end;

  for i := 0 to Frame.FramesCount - 1 do
    drawFrame(Frame.Frames[i]);
end;

procedure DrawInterface();
begin
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, Window.X, Window.Y, 0);
	glMatrixMode(GL_MODELVIEW);
	glDisable(GL_DEPTH_TEST);

  if Mouse.OnSelection then
    DrawSelectionRectangle(Mouse.SelectionX, Mouse.SelectionY, Mouse.X, Mouse.Y);

  if Length(FrameList) >= 1 then begin
    glPushMatrix();
      glScalef(Window.X / FrameList[0].width, Window.Y / FrameList[0].height, 1);
      drawFrame(0);
    glPopMatrix();

    if (Mouse.ClickingState <> 0) then begin
      lua_pushnumber(L, Abs(Mouse.ClickingState));
      lua_setglobal(L, 'arg1');
      if Mouse.ClickingState > 0 then
        TriggerEvent(EVENT_ONMOUSEDOWN)
      else
        TriggerEvent(EVENT_ONMOUSEUP);
      Mouse.ClickingState := 0;
    end;

    if LaunchGameAfter then begin
      LaunchGameAfter := False;
      Screen_Launch(SCREEN_GAME);
    end;
  end;

end;

end.

