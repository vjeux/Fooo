unit FBase;

interface
uses
	Windows, OpenGl, FOpenGL, SysUtils, FFonts, FData;

type
	TWindow = record
		X : Integer;
		Y : Integer;
	end;
  PPos = array[1..4] of Double;

  GlFrame = record
    rc : HGLRC;
    dc : HDC;
  end;

var
  GLFrames : array of GLFrame;
	Window : TWindow;
	glNameCount : GLUInt;

procedure InitGLFrame(handle : Cardinal; id : integer);
procedure SetGLFrame(id : integer);
procedure glDraw(id : integer);

implementation
uses
	FInterfaceDraw, FText, FTerrain, FCursor, FTextures, FServer, FPlayer,
  FView, FModel, FFrustum, FLogs, FRedirect, Funit, FMap, FXMLLoader;

procedure InitGLFrame(handle : Cardinal; id : integer);
var
	pfd : TPixelFormatDescriptor;
	pf  : Integer;
begin
	GLFrames[id].dc := GetDC(handle);
	pfd.nSize := sizeof(pfd);
	pfd.nVersion := 1;
	pfd.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER or 0;
	pfd.iPixelType := PFD_TYPE_RGBA;
	pfd.cColorBits := 32;
	pf := ChoosePixelFormat(GLFrames[id].dc, @pfd);
	SetPixelFormat(GLFrames[id].dc, pf, @pfd);
	GLFrames[id].rc := wglCreateContext(GLFrames[id].dc);
end;

procedure SetGLFrame(id : integer);
begin
  wglMakeCurrent(GLFrames[id].dc, GLFrames[id].rc);
end;

procedure Draw(select : boolean = false);
begin
  if CurrentScreen = SCREEN_GAME then begin
    glNameCount := 0;

    if not select and (CurrentScreen = SCREEN_GAME) then
      DrawTerrain();
    DrawModel(select);
  end;
	if not select then
    DrawInterface();

	glLoadName(glNameCount);
end;

function GetRectangleCoords(x1, y1, x2, y2 : double) : PPos;
begin
  Result[1] := (x1 + x2) / 2;
  Result[2] := (y1 + y2) / 2;
  Result[3] := abs(x2 - x1) + 1;
  Result[4] := abs(y2 - y1) + 1;
end;

procedure DrawMinimap(x, y, w : integer);
var
  i : integer;
  u : TUnit;
const
  cstBotX = 1200;
  cstTopX = 600;
  cstBotY = 1200;      
  cstTopY = 600;
begin
  if UnitList = nil then
    exit;

  for i := 0 to UnitList.Count - 1 do begin
    u := TUnit(UnitList[i]);
    if u.Active then begin
      glColor3f(
        u.TeamColor.X,
        u.TeamColor.Y,
        u.TeamColor.Z
      );

      if not u.Stats.IsBuilding then begin
        DrawCarre(
          CircleGLID,
          x + ((u.RealPos.X - UNITSIZE * u.Stats.Size div 2) / (MAP_SIZE * UNITSIZE) * w),
          y + w - ((u.RealPos.Y + UNITSIZE * u.Stats.Size div 2) / (MAP_SIZE * UNITSIZE) * w),
          (u.Stats.Size / MAP_SIZE) * w
        );
      end else begin
        DrawCarre(
          BlankGLID,
          x + ((u.RealPos.X - UNITSIZE * u.Stats.Size div 2) / (MAP_SIZE * UNITSIZE) * w),
          y + w - ((u.RealPos.Y + UNITSIZE * u.Stats.Size div 2) / (MAP_SIZE * UNITSIZE) * w),
          (u.Stats.Size / MAP_SIZE) * w
        );
      end;
    end;
  end;

  glcolor3f(1, 1, 1);
	glBegin(GL_LINE_STRIP);
    glVertex2f(
      x +     ((View.tarx - cstTopX) / (MAP_SIZE * UNITSIZE) * w),
      y + w - ((View.tary - cstTopY) / (MAP_SIZE * UNITSIZE) * w)
    );
    glVertex2f(
      x +     ((View.tarx + cstTopX) / (MAP_SIZE * UNITSIZE) * w),
      y + w - ((View.tary - cstTopY) / (MAP_SIZE * UNITSIZE) * w)
    );
    glVertex2f(
      x +     ((View.tarx + cstBotX) / (MAP_SIZE * UNITSIZE) * w),
      y + w - ((View.tary + cstBotY) / (MAP_SIZE * UNITSIZE) * w)
    );
    glVertex2f(
      x +     ((View.tarx - cstBotX) / (MAP_SIZE * UNITSIZE) * w),
      y + w - ((View.tary + cstBotY) / (MAP_SIZE * UNITSIZE) * w)
    );           
    glVertex2f(
      x +     ((View.tarx - cstTopX) / (MAP_SIZE * UNITSIZE) * w),
      y + w - ((View.tary - cstTopY) / (MAP_SIZE * UNITSIZE) * w)
    );
  glEnd();

//	glBegin(GL_POINTS);
//    glVertex2f(
//      x +     ((View.tarx) / (MAP_SIZE * UNITSIZE) * w),
//      y + w - ((View.tary) / (MAP_SIZE * UNITSIZE) * w)
//    );
//  glEnd();

  glColor3f(1, 1, 1);
end;

procedure GetPicking();
var
	selectBuff : array[0..1023] of GLuint;
	viewport : array[1..4] of GLuint;
	hits : TGLint;
  Pos : PPos;
  i : integer;
  issel : boolean;
  eq : array[0..3] of double;
begin
  if (Mouse.Mode <> nil) and (Mouse.Mode.Action = REPAIR) then begin
    Mouse.Hover := False;
    exit;
  end;

	glGetIntegerv(GL_VIEWPORT, @viewport);
	glSelectBuffer(1024, @selectBuff);

	glMatrixMode(GL_PROJECTION);

	glPushMatrix();
    glRenderMode(GL_SELECT);
    glInitNames();
    glPushName(0);
    glLoadIdentity();

    if not Mouse.OnSelection then
      gluPickMatrix(Mouse.X, viewport[4] - Mouse.Y, 1, 1, @viewport)
    else begin
      Pos := GetRectangleCoords(Mouse.SelectionX, Mouse.SelectionY, Mouse.X, Mouse.Y);
      gluPickMatrix(Pos[1], viewport[4] - Pos[2], Pos[3], Pos[4], @viewport);
    end;
    gluPerspective(30, Window.X / Window.Y, 0.0001, 10000);
    gluLookAt(View.camx, View.camy, View.camz, View.tarx, View.tary, View.tarz, 0, 1, 0); //1650
    glMatrixMode(GL_MODELVIEW);
    ExtractFrustum();


    eq[0] := 0;
    eq[1] := 0;
    eq[2] := 1;
    eq[3] := 0;
    glClipPlane(GL_CLIP_PLANE0, PGLDouble(@eq));
    glEnable(GL_CLIP_PLANE0);

    Draw(true);           
    glDisable(GL_CLIP_PLANE0);


    hits := glRenderMode(GL_RENDER);

    issel := Mouse.OnSelection and ((abs(Mouse.X - Mouse.SelectionX) >= 5)
        or (abs(Mouse.Y - Mouse.SelectionY) >= 5));

    if (hits > 0) and (UnitList.Count > 0) then begin
      Mouse.Hover := True;
      if issel then
        SetLength(Mouse.HoverList, hits)
      else
        SetLength(Mouse.HoverList, 1);

      for i := 0 to hits - 1 do begin
        if issel then begin
          Mouse.HoverList[i] := selectBuff[3 + 4 * i];
        end else if (i = 0)
        or (TUnit(UnitList[Mouse.HoverList[0]]).RealPos.Y > TUnit(UnitList[selectBuff[3 + 4 * i]]).RealPos.Y) then begin
          Mouse.HoverList[0] := selectBuff[3 + 4 * i];
        end;
      end;
    end else begin
      Mouse.Hover := False;
    end;

	glPopMatrix();
end;

procedure glDraw(id : integer);
begin
  SetGLFrame(id);
	glClear(GL_DEPTH_BUFFER_BIT);

  if CurrentScreen = SCREEN_GAME then begin
	  OnUpdateView();

	  GetPicking();
  end;
  UpdateView();
  if CurrentScreen = SCREEN_GAME then
    GetTerrainCursor();

  glEnable(GL_DEPTH_TEST);
	Draw();

  glPushMatrix();
    glScalef(Window.X / FrameList[0].width, Window.Y / FrameList[0].height, 1);
    DrawMinimap(25, 920, 260);
  glPopMatrix();

 	DisplayCursor();
  
	glFlush();
	SwapBuffers(GLFrames[id].dc);
end;

end.

