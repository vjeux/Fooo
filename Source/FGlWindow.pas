unit FGlWindow;

interface

uses
  Windows, OpenGL, Forms, Sysutils,
  Classes, StdCtrls, ExtCtrls, Controls, Messages, Graphics, Menus, Buttons,
	FLua, FLuaFunctions, FOpenGL, FLoader, FLogs, FFonts,
	FTerrain, FView, FTextures, FKeys, FBase, FCursor, FFPS,
	FXMLLoader, FData, xmldom, XMLIntf, msxmldom, XMLDoc, FTransmit,
  FResolution, FModel, FRedirect, FEditorModelView;

type
	TGlWindow = class(TForm)
    ModelFrame: TPanel;
    Document: TXMLDocument;

		procedure FormCreate(Sender: TObject);
		procedure FormResize(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ModelFrameMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ModelFrameMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ModelFrameMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
  private
    procedure OnUpdate(Sender: TObject; var Done: Boolean);
    procedure OnActivate(Sender : TObject);
    procedure OnDeActivate(Sender : TObject);

    // Hack pour recup la touche TAB
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;

  public
    { Déclarations publiques }
	end;

var
	GlWindow: TGlWindow;

implementation
{$R *.dfm}

uses
  FInterfaceDraw, Fsound, FMouseClick;


procedure TGlWindow.WMGetDlgCode(var Message: TWMGetDlgCode);
Begin
  Inherited;
  Message.Result := Message.Result or DLGC_WANTTAB;
End;
                   

procedure TGlWindow.FormShow(Sender: TObject);
begin
  Screen_Launch(SCREEN_MENU);
end;

procedure TGlWindow.ModelFrameMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Screen_OnMouseDown(Button);
end;

procedure TGlWindow.ModelFrameMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Screen_OnMouseMove(X, Y);
end;

procedure TGlWindow.ModelFrameMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Screen_OnMouseUp(Button);
end;

procedure TGlWindow.OnUpdate(Sender: TObject; var Done: Boolean);
begin
 	Done := False;
  Screen_OnUpdate();
end;

procedure TGlWindow.OnActivate(Sender: TObject);
begin
  ChangeResolution();
end;

procedure TGlWindow.OnDeactivate(Sender: TObject);
begin
  ResetResolution();   
end;

procedure TGlWindow.FormCreate(Sender: TObject);
begin
  Randomize;

	InterfaceLoaded := false;

  Application.OnIdle := GlWindow.OnUpdate;
  Application.OnDeactivate := GlWindow.OnDeactivate;
  Application.OnActivate := GlWindow.OnActivate;
end;

procedure TGlWindow.FormDestroy(Sender: TObject);
begin
  lua_close(L);
end;

procedure TGlWindow.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Screen_OnKeyDown(Key);
end;

procedure TGlWindow.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Screen_OnKeyPress(Key);
end;

procedure TGlWindow.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  Screen_OnMouseWheel(WheelDelta);
end;

procedure TGlWindow.FormResize(Sender: TObject);
begin
	Window.X := GlWindow.ModelFrame.Width;
	Window.Y := GlWindow.ModelFrame.Height;
end;

end.
