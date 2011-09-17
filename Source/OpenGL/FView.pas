unit FView;

interface
uses
	Windows, OpenGl, FOpenGl, FBase, Math, FKeys, FXMLLoader,
  FCursor, FFPS, FLogs, SysUtils, FTerrain, FFrustum;

type
	TView = Record
		camx : Extended;
		camy : Extended;
		camz : Extended;

		tarx : Extended;
		tary : Extended;
		tarz : Extended;

		angle : Extended;
    Hangle : Extended;
	end;

var
	View : TView;

const
	BorderOffset = 10;
	MoveFactor = 2;

  FactorAngle = 0.00025;
  FactorCamY  = -0.005;
  FactorCamZ  = -1.1;

  MinAngle    = -7.5 / 10 * PI;
  MinCamY     = TileSize * 40;
  MinCamZ     = 1500;

  MaxAngle    = -6.7 / 10 * PI;
  MaxCamY     = MinCamY + ( MaxAngle - MinAngle) / FactorAngle * FactorCamY;
  MaxCamZ     = MinCamZ + ( MaxAngle - MinAngle) / FactorAngle * FactorCamZ;

procedure InitView();
procedure UpdateView();
procedure OnUpdateView();
procedure OnMouseMoveView(X : integer; Y : integer);  
procedure OnMouseWheelUpdate(Intensity : Integer);

implementation

procedure CalculateView();
begin
  // Bordures - A changer car ne gere pas le changement de camera !
	if View.tarx < TileSize * 16 then
		View.tarx := TileSize * 16;
	if View.tarx > TileSize * TerrainSize - TileSize * 16 then
		View.tarx := TileSize * TerrainSize - TileSize * 16;

	if View.tary < TileSize * 13 then
		View.tary := TileSize * 13;
	if View.tary > TileSize * TerrainSize - TileSize * 13 then
		View.tary := TileSize * TerrainSize - TileSize * 13;

	View.camx := View.tarx + cos(View.Hangle) * View.camz * tan(View.angle);
	View.camy := View.tary - sin(View.Hangle) * View.camz * tan(View.angle);
end;

procedure UpdateView();
begin
	glViewport(0, 0, Window.X, Window.Y);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(30, Window.X / Window.Y, 1, 10000);
	gluLookAt(View.camx, View.camy, View.camz,
            View.tarx, View.tary, View.tarz,
            View.tarx - View.camx, View.tary - View.camy, 1);    //1650
	glMatrixMode(GL_MODELVIEW);
	ExtractFrustum();
end;

procedure InitView();
begin
	View.tarx := TileSize * 40;
	View.tary := MinCamY;
	View.camz := MinCamZ;

	View.tarz := 0;
	View.angle := MinAngle;
  View.Hangle := -3*PI/2;

	CalculateView();
	UpdateView();
end;

procedure OnMouseWheelUpdate(Intensity : Integer);
begin
  View.angle := View.angle + Intensity * FactorAngle;
  View.camy  := View.tary  + Intensity * FactorCamY;
  View.camz  := View.camz  + Intensity * FactorCamZ;

  if View.angle >= MaxAngle then begin
    View.angle := MaxAngle;
    View.camy := MaxCamY;
    View.camz := MaxCamZ;
  end;

  if View.angle <= MinAngle then begin
    View.angle := MinAngle;
    View.camy := MinCamY;
    View.camz := MinCamZ;
  end;

  CalculateView();
end;

procedure OnMouseMoveView(X : integer; Y : integer);
begin
	if isWinKeyDown(VK_MBUTTON) then begin
		View.tarx := View.tarx - (X - Mouse.X)/2;
		View.tary := View.tary + (Y - Mouse.Y)/2;
		UpdateView();
	end;
	CalculateView();

	Mouse.X := X;
	Mouse.Y := Y;
  Mouse.InterfaceX := Round(FrameList[0].width / Window.X * X);
  Mouse.InterfaceY := Round(FrameList[0].height / Window.Y * Y);
end;

procedure OnUpdateView();
begin
  if Mouse.OnSelection then
    exit;
  SetCursor(Mouse.Cursor);

//  View.Hangle := View.Hangle + 0.001;

	if not isWinKeyDown(VK_MBUTTON) then begin
		if isKeyDown(FO_LEFT) or (Mouse.X < BorderOffset) then begin
			View.tarx := View.tarx - (MoveFactor * Count.Elapsed);
			if not isKeyDown(FO_LEFT) then
				SetCursor(Mouse.Cursor, true, false, false, false);
			CalculateView();
		end;

		if isKeyDown(FO_RIGHT) or (Mouse.X > Window.X - BorderOffset) then begin
			View.tarx := View.tarx + (MoveFactor * Count.Elapsed);
			if not isKeyDown(FO_RIGHT) then
				SetCursor(Mouse.Cursor, false, true, false, false);
			CalculateView();
		end;

		if isKeyDown(FO_UP) or (Mouse.Y < BorderOffset) then begin
			View.tary := View.tary + (MoveFactor * Count.Elapsed);
			if not isKeyDown(FO_UP) then
				SetCursor(Mouse.Cursor, false, false, true, false);
			CalculateView();
    end;

    if isKeyDown(FO_DOWN) or (Mouse.Y > Window.Y - BorderOffset) then begin
      View.tary := View.tary - (MoveFactor * Count.Elapsed);
      if not isKeyDown(FO_DOWN) then
        SetCursor(Mouse.Cursor, false, false, false, true);
      CalculateView();
		end;
  end;
end;

end.

