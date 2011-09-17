unit FCursor;

interface
uses
	Windows, ExtCtrls, OpenGL, FOpenGl, FTextures, FFPS,
  FLogs, SysUtils, FData, FTerrain, Classes, FSelection, Funit, FServer;

type
  PCursorMode = ^TCursorMode;
  TCursorMode = record
    SpellUnitID : integer;
    Building : PUnitAttributes;
    Action : TOrderType;
  end;

	TMouse = Record
		X : Extended;
		Y : Extended;
    InterfaceX : Integer;
    InterfaceY : Integer;
  	Cursor : Integer;
    GLID : GLuint;
    Terrain : Tpoint;
    LastDblClick : Double;
    Mode : PCursorMode;
		Left : Boolean;
		Right : Boolean;
		Up : Boolean;
		Down : Boolean;
		Hover : Boolean;
    HoverList : array of Integer;
    OnSelection : Boolean;
    SelectionX : Double;
    SelectionY : Double;

    ClickingState : Integer; // Positive : Down       1 : Left Button
                             // Negative : Up         2 : Right Button
                             //                       3 : Middle Button
	end;

const
	CU_NORMAL = 4;
	CU_TARGET = 9;
	CU_NO_TARGET = 3;
	CU_ARROW = 6;
  CU_NONE = -1;

	CursorSize = 32;
	CursorPerRow = 8;
	CursorPerCol = 4;

  CursorAnimationDelay = 75;
  
var
	Mouse : TMouse;
                                
procedure InitCursor(panel : TPanel);
procedure DisplayCursor();              
procedure GetTerrainCursor();
procedure SetCursor( cursor : integer; left : boolean = false; right : boolean = false; up : boolean = false; down : boolean = false );
procedure DrawSelectionRectangle(x1, y1, x2, y2 : double);
procedure CancelMouseAction();
procedure SetMouseMode(Mode : TOrderType);
procedure SetCastMode(SpellUnitID : integer);
procedure SetBuildingMode(Building : PUnitAttributes);     
function Get3DPosTo2D(x, y, z : Double) : TPoint;

implementation
uses
  FInterfaceDraw, FKeys, FXMLLoader, FBase, FSound;

procedure DrawSelectionLine(x1, y1, x2, y2, x3, y3, x4, y4 : double);
begin
  glColor3f(0, 1, 1);
  glBegin(GL_QUADS);
    glVertex3f(x1, y1, -1);
    glVertex3f(x2, y2, -1);
    glVertex3f(x3, y3, -1);
    glVertex3f(x4, y4, -1);
  glEnd();        
  glColor3f(1, 1, 1);
end;

procedure swap(var a, b : double); overload;
var
  t : double;
begin
  t := a;
  a := b;
  b := t;
end;

procedure DrawSelectionRectangle(x1, y1, x2, y2 : double);
begin
  glDisable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glColor4f(0.0, 0.5, 1.0, 0.3); //un bô bleu
  glBegin(GL_QUADS);
    glVertex3f(x1, y1, -1);
    glVertex3f(x2, y1, -1);      //un bô rectangle kikoo
    glVertex3f(x2, y2, -1);
    glVertex3f(x1, y2, -1);
  glEnd();
  glDisable(GL_BLEND);  

  glBegin(GL_LINES);
    glVertex3f(x1, y1, -1);
    glVertex3f(x2, y1, -1);
    glVertex3f(x2 + 1, y1, -1);
    glVertex3f(x2 + 1, y2, -1);
    glVertex3f(x2, y2, -1);
    glVertex3f(x1, y2, -1);
    glVertex3f(x1, y2, -1);
    glVertex3f(x1, y1, -1);
  glEnd();
  glColor3f(1.0, 1.0, 1.0);
end;

procedure InitCursor(panel : TPanel);
begin
	ShowCursor(False);
	panel.Cursor := -1;
	SetCursor(CU_NORMAL);
  Mouse.OnSelection := False;
  Mouse.LastDblClick := 0;
  Mouse.GLID := LoadTexture('Textures\Cursor\HumanCursor.tga');
end;

// Use false as default value !
procedure SetCursor( cursor : integer; left : boolean = false; right : boolean = false; up : boolean = false; down : boolean = false );
begin
	Mouse.Cursor := cursor;

	if (left or right or up or down) then begin
		Mouse.Left := Mouse.Left or left;
		Mouse.Right := Mouse.Right or right;
		Mouse.Up := Mouse.Up or up;
		Mouse.Down := Mouse.Down or down;
	end else begin
		Mouse.Left := false;
		Mouse.Right := false;
		Mouse.Up := false;
		Mouse.Down := false;
  end;
end;

function Get3DPosTo2D(x, y, z : Double) : TPoint;
var                    
  viewport:   array [1..4]  of Integer;
	modelview:  array [1..16] of Double;
	projection: array [1..16] of Double;
  xa, ya, za : Double;
begin
	glGetDoublev(GL_MODELVIEW_MATRIX, @modelview );
	glGetDoublev(GL_PROJECTION_MATRIX, @projection );
	glGetIntegerv(GL_VIEWPORT, @viewport );

	gluProject(x, y, z, @modelview, @projection, @viewport, xa, ya, za);

  Result.X := Round(FrameList[0].width / Window.X * xa);
  Result.Y := Round(FrameList[0].height / Window.Y * (viewport[4] - ya));
end;


procedure GetTerrainCursor();
var
  viewport:   array [1..4]  of Integer;
	modelview:  array [1..16] of Double;
	projection: array [1..16] of Double;
	winY:  Single;
  xa, ya, za, xb, yb, zb : Double;
begin
	glGetDoublev(GL_MODELVIEW_MATRIX, @modelview );
	glGetDoublev(GL_PROJECTION_MATRIX, @projection );
	glGetIntegerv(GL_VIEWPORT, @viewport );

  winY := viewport[4] - Mouse.Y;

	gluUnProject(Mouse.X, winY, 1, @modelview, @projection, @viewport, xa, ya, za);
	gluUnProject(Mouse.X, winY, 0, @modelview, @projection, @viewport, xb, yb, zb);

  // Intersection d'une droite definie par deux points A(xa, ya, za) et B(xb, yb, zb)
  // avec le plan d'equation z = 0
  //
  // Equation parametree de la droite :
  // { x = xa + t(xb - xa)
  // { y = ya + t(yb - ya)
  // { z = za + t(zb - za)
  //
  // Resolution pour z = 0 :
  // { t = - ( za / ( zb - za ) )
  // { x = xa - (za / (zb - za)) * (xb - xa)
  // { y = ya - (za / (zb - za)) * (yb - ya)

  Mouse.terrain.x := round(xa - (za / (zb - za)) * (xb - xa));
  Mouse.terrain.y := round(ya - (za / (zb - za)) * (yb - ya));
end;

procedure DisplayCursor();
var
	position : array[0..3] of array[0..3] of extended;
	angle, i, cursor, CursorX, CursorY, animCount : integer;
begin
  if (Mouse.Mode <> nil) and ((Mouse.Mode.Action = REPAIR) and (Mouse.Mode.Building <> nil)) then
    exit;

  if Mouse.Left or Mouse.Right or Mouse.Up or Mouse.Down then
    cursor := CU_ARROW
  else
    cursor := Mouse.Cursor;

  if Mouse.Hover and not Mouse.OnSelection then begin
    if (cursor = CU_NORMAL) and TUnit(UnitList[Mouse.HoverList[0]]).Active then begin
      if TUnit(UnitList[Mouse.HoverList[0]]).Player = Player then
        glColor3f(0, abs(Count.Now div 10 mod 100 / 100 - 0.5) + 0.5, abs(Count.Now div 10 mod 100 / 100 - 0.5) + 0.5)
      else
        glColor3f(abs(Count.Now div 10 mod 100 / 100 - 0.5) + 0.5, 0, 0);
    end else if cursor = CU_TARGET then begin
      if TUnit(UnitList[Mouse.HoverList[0]]).Player = Player then
        glColor3f(0, 1, 1)
      else
        glColor3f(1, 0, 0);
    end;
  end else if cursor = CU_TARGET then begin
    glColor3f(0, 1, 0);
    cursor := 2;
  end;

  if cursor = CU_ARROW then
    animCount := 3
  else if cursor = CU_TARGET then
    animCount := 8
  else
    animCount := 1;

  CursorX := (cursor + Count.Now div CursorAnimationDelay mod animCount - 1) mod CursorPerRow + 1;
	CursorY := 4 - (cursor + Count.Now div CursorAnimationDelay mod animCount - 1) div CursorPerRow;

  if Mouse.Left or Mouse.Right or Mouse.Up or Mouse.Down then
    cursor := CU_ARROW;

	if Mouse.Up and Mouse.Left then
		angle := -135
	else if Mouse.Up and Mouse.Right then
		angle := -45
	else if Mouse.Up and not(Mouse.Left or Mouse.Right) then
		angle := -90
	else if Mouse.Down and Mouse.Left then
		angle := 135
	else if Mouse.Down and Mouse.Right then
		angle := 45
	else if Mouse.Down and not(Mouse.Left or Mouse.Right) then
		angle := 90
	else if Mouse.Left and not(Mouse.Down or Mouse.Up) then
		angle := 180
	else //if Mouse.Right and not(Mouse.Down and Mouse.Up) then
  	angle := 0;

	position[0][0] := (CursorX - 1) / CursorPerRow;
	position[0][1] := (CursorY - 1) / CursorPerCol;
	position[0][2] := 0;
	position[0][3] := 0;

	position[1][0] := CursorX / CursorPerRow;
	position[1][1] := (CursorY - 1) / CursorPerCol;
	position[1][2] := CursorSize;
	position[1][3] := 0;

	position[2][0] := (CursorX - 1) / CursorPerRow;
	position[2][1] := CursorY / CursorPerCol;
	position[2][2] := 0;
	position[2][3] := CursorSize;

	position[3][0] := CursorX / CursorPerRow;
	position[3][1] := CursorY / CursorPerCol;
	position[3][2] := CursorSize;
	position[3][3] := CursorSize;

	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	BindTexture(Mouse.GLID);

	glPushMatrix();
    glTranslatef(Mouse.X, Mouse.Y, 0);
    if cursor = CU_ARROW then begin
      glRotatef(angle, 0, 0, 1);
      glTranslatef(-CursorSize, -CursorSize/2, 0);
    end else if (cursor = CU_TARGET) or (cursor = 2) then
      glTranslatef(-CursorSize/2, -CursorSize/2, 0);

    glBegin(GL_QUAD_STRIP);
    for i := 0 to 3 do begin
      glTexCoord2f(position[i][0], position[i][1]);
      glVertex3f(  position[i][2], position[i][3], 1);
    end;
    glEnd();
	glPopMatrix();

	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);

  glColor3f(1, 1, 1);

end;

procedure CancelMouseAction();
begin
  if Mouse.Mode <> nil then
  begin
    Dispose(Mouse.Mode);
    Mouse.Mode := nil;
  end;
  SetCursor(CU_NORMAL);
end;

procedure SetMouseMode(Mode : TOrderType);
begin
  New(Mouse.Mode);
  Mouse.Mode.Action := Mode;
  Mouse.Mode.SpellUnitID := -1;
  Mouse.Mode.Building := nil;
  SetCursor(CU_TARGET);
end;

procedure SetCastMode(SpellUnitID : integer);
begin
  if Mouse.Mode = nil then
  begin
    New(Mouse.Mode);
    Mouse.Mode.Action := CAST;
    Mouse.Mode.SpellUnitID := SpellUnitID;
    SetCursor(CU_TARGET);
  end
  else
  begin
    if Mouse.Mode.action = CAST then
    begin
      CancelMouseAction();
    end
    else
    begin
      Mouse.Mode.Action := CAST;
      Mouse.Mode.SpellUnitID := SpellUnitID;
      SetCursor(CU_TARGET);
    end;
  end;
end;

procedure SetBuildingMode(Building : PUnitAttributes);
begin
  if (ClientTab.tab[0]^.info.res1 >= Building.Res1Cost) then
  begin
    SetMouseMode(REPAIR);
    Mouse.Mode.Building := Building;
  end
  else
  begin
    Adviser_voice(SOUND_GOLD);
    Warning.SetMsg('Not enough Gold.');
  end;
end;

end.
