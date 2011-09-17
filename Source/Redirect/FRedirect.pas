unit FRedirect;

interface
uses
  Windows, SysUtils, Controls;

type
  ScreenType = (SCREEN_MENU, SCREEN_LOAD, SCREEN_GAME, SCREEN_EDIT);

var
  CurrentScreen : ScreenType;
       
const
  UIPATH_MENU = 'Interface/Menu/Interface.xml';
  UIPATH_LOAD = 'Interface/Load/Interface.xml';
  UIPATH_GAME = 'Interface/Game/Interface.xml';
  UIPATH_EDIT = 'Interface/Edit/Interface.xml';

procedure Screen_Launch(screen : ScreenType);
procedure Screen_OnUpdate();
procedure Screen_OnKeyDown(Key: Word);
procedure Screen_OnKeyPress(Key: Char);
procedure Screen_OnMouseWheel(WheelDelta: Integer);
procedure Screen_OnMouseDown(Button: TMouseButton);
procedure Screen_OnMouseUp(Button: TMouseButton);
procedure Screen_OnMouseMove(X, Y: Integer);
procedure Screen_Quit();

implementation
uses
  FInterfaceUtils, FView, FTerrain, FFPS, FTransmit, FBase, FData, FInterfaceDraw,
  FEditorModelView, FCursor, FGlWindow, FResolution, FLogs, Fsound, FServer, forms,
  FText, FModelPreview, FKeys, FFonts, FTextures, FLoader, FOpenGL, FMouseClick,
  FLuaFunctions, FLua, FUpdateData, Dialogs, FLoadMap;


procedure Screen_Launch(screen : ScreenType);
begin
  CurrentScreen := screen;

  case screen of
    SCREEN_MENU: begin
      InitLog();
      InitResolution();
      ChangeResolution();
      InitFPS();
      InitKeys();
      InitOpenGL();
      SetLength(GLFrames, 1);
      InitGLFrame(GLWindow.ModelFrame.Handle, 0);
      SetGLFrame(0);
      InitTextures();
      InitCursor(GlWindow.ModelFrame);
      InitFonts();
      Sound_Init();
      Sound_Init_sample();
      Sound_Init_stream();
      Play_Sound_stream(0, 100, 0, 0, 0);
      InitNetwork();
      CleanupInterface();
      LoadInterface(UIPATH_MENU);
    end;

    SCREEN_EDIT: begin
      InitLog();
      InitResolution();
      Resolution.FullScreen := false;
      InitFPS();
      InitKeys();
      InitOpenGL();
      SetLength(GLFrames, 1);
      SetLength(GLFrames, 2);
      InitGLFrame(GLWindow.ModelFrame.Handle, 0);
      InitGLFrame(EditorModelView.EditorModelFrame.Handle, 1);
      SetGLFrame(1);
      InitTextures();
      InitFonts();
      Sound_Init();
      Sound_Init_sample();
      Sound_Init_stream();
      InitModels();
      InitData();
      EditorModelView.Show();

      CleanupInterface();
      LoadInterface(UIPATH_EDIT);
    end;

    SCREEN_GAME: begin
//      FreeTextures();
      InitData();
      InitView();
      InitModels();
      InitTerrain();
      Stop_Sound_stream(0);
      Play_Sound_stream(1, 100, 0, 0, 0);

      CleanupInterface();
      LoadInterface(UIPATH_GAME);

      LoadMap('Maps/Welcome.fooo');
    end;
  end;
end;

procedure Screen_OnUpdate();
begin
	OnUpdateFPS();

  case CurrentScreen of
    SCREEN_MENU: begin
      receiveNetwork();
      while executeNetwork() do begin end;
      glDraw(0);
    end;

    SCREEN_EDIT: begin
      glDraw(0);
      ModelPreview_Draw(1);
    end;

    SCREEN_GAME: begin
      receiveNetwork();
      while executeNetwork() do begin end;

      NetUpdateUnits();

      glDraw(0);
      OnUpdateData();
    end;
  end;
end;

procedure Screen_OnKeyDown(Key: Word);
begin
  HandleKey(Key);
end;

procedure Screen_OnKeyPress(Key: Char);
begin
  HandleKeyDown(Key);
end;

procedure Screen_OnMouseWheel(WheelDelta: Integer);
begin
  OnMouseWheelUpdate(WheelDelta);
end;

procedure Screen_OnMouseDown(Button: TMouseButton);
begin
  if Button = mbLeft then begin
    OnLeftMouseDown();
    FCursor.Mouse.ClickingState := 1;
  end else if Button = mbRight then begin
    OnRightMouseDown();
    FCursor.Mouse.ClickingState := 2;
  end else begin
    FCursor.Mouse.ClickingState := 3;
  end;
end;

procedure Screen_OnMouseUp(Button: TMouseButton);
begin
  if Button = mbLeft then begin
    OnLeftMouseUp();
    FCursor.Mouse.ClickingState := -1;
  end else if Button = mbRight then begin
    OnRightMouseUp();
    FCursor.Mouse.ClickingState := -2;
  end else begin
    FCursor.Mouse.ClickingState := -3;
  end;
end;

procedure Screen_OnMouseMove(X, Y: Integer);
begin
  OnMouseMoveView(X, Y);
end;

procedure Screen_Quit();
begin
  case CurrentScreen of
    SCREEN_MENU: begin
      sendDisconnectClient(GlobalServerIP, GlobalClientIP);
      TerminateNetwork();
    end;

    SCREEN_EDIT: begin
      glDraw(0);
      ModelPreview_Draw(1);
    end;

    SCREEN_GAME: begin
      sendDisconnectClient(GlobalServerIP, GlobalClientIP);
      TerminateNetwork();
    end;
  end;

  Sound_Close_stream();
  Sound_Close_sample();
  Sound_Close();
  wglMakeCurrent(0,0);
//  wglDeleteContext(rc);

  ResetResolution();
	ShowCursor(true);
  Application.Terminate();
end;


//  AddLine('Welcome to Project HGF - Fooo');
//  AddLine('');
//  AddLine('Here are some controls to start with:');
//
//  AddLine('Misc:');
//  AddLine('  - Escape to quit');
//  AddLine('  - F2 to create a zerg under the cursor');
//
//  AddLine('Selection:');
//  AddLine('  - Left Click to select a unit');
//  AddLine('  - Ctrl Left Click to select all nearby units of the same type');
//  AddLine('  - Shift Left Click to add/remove unit from selection');
//  AddLine('  - Left Drag to select multiple units');
//  AddLine('  - 0..9 to select a unit group');
//  AddLine('  - Ctrl + 0..9 to set a unit group');
//  AddLine('  - Shift + 0..9 to add selected units to the group');
//
//  AddLine('Control:');
//  AddLine('  - Right click on the map to move selected units');
//  AddLine('  - Shift Right click on the map to make a movement path');
//  AddLine('  - Right click to follow a friendly unit');
//  AddLine('  - Right click to attack an hostile unit');
//  AddLine('  - Zerg: ''A'' to use Speed ability on a friendly unit');
//  AddLine('  - Zerg: ''S'' to build an Altar');
//
//  AddLine('Chat:');
//  AddLine('  - Enter to display the chatbox and send a message');
//  AddLine('  - /connect <ip_server> <ip_self> to connect to a server');
//
//  AddLine('');
//  AddLine('Enjoy !');

end.
