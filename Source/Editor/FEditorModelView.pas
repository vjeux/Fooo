unit FEditorModelView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TEditorModelView = class(TForm)
    EditorModelFrame: TPanel;
    ModelListBox: TComboBox;
    Label1: TLabel;
    AnimationListBox: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure ModelListBoxChange(Sender: TObject);
    procedure AnimationListBoxChange(Sender: TObject);
    procedure EditorModelFrameMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure EditorModelFrameMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EditorModelFrameMouseEnter(Sender: TObject);
    procedure EditorModelFrameMouseLeave(Sender: TObject);
    procedure EditorModelFrameMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TEditorView = record
    x, y : integer;
    zoom, transx, transy, rotat : single;
    current : integer;
  end;

var
  EditorModelView: TEditorModelView;
  EditorView : TEditorView;

procedure glModelViewDraw(id : Integer);

implementation
uses
  FLogs, FData, FUnit, FBase, FOpenGl, FModelPreview, FStructure;

{$R *.dfm}

procedure ModelPreview_Init();
begin
  EditorView.x := 0;
  EditorView.y := 0;
  EditorView.zoom := 1;
  EditorView.transx := 0;
  EditorView.transy := 0;
  EditorView.rotat := 0;
  EditorView.current := 0;
end;

procedure ModelPreview_UpdateAnimation();
begin
  ModelPreview_Model.SetAnim(EditorModelView.AnimationListBox.Items.Strings[EditorModelView.AnimationListBox.ItemIndex], true, true);
end;

procedure ModelPreview_UpdateModel();
var
  i : integer;
begin
  ModelPreview_SetModel(@Attributes[EditorModelView.ModelListBox.ItemIndex]);
  EditorModelView.AnimationListBox.Clear();
  for i := 0 to Length(LoadedModels[ModelPreview_Model.ModelID].Sequence) - 1 do
    EditorModelView.AnimationListBox.Items.Add(LoadedModels[ModelPreview_Model.ModelID].Sequence[i].Name);
  EditorModelView.AnimationListBox.ItemIndex := 0;
  ModelPreview_UpdateAnimation();
end;

procedure TEditorModelView.AnimationListBoxChange(Sender: TObject);
begin
  ModelPreview_UpdateAnimation();
end;

procedure TEditorModelView.EditorModelFrameMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    EditorView.current := 1
  else if Button = mbRight then
    EditorView.current := 2;
end;

procedure TEditorModelView.EditorModelFrameMouseEnter(Sender: TObject);
begin
  EditorView.current := 0;
end;

procedure TEditorModelView.EditorModelFrameMouseLeave(Sender: TObject);
begin
  EditorView.current := 0;
end;

procedure TEditorModelView.EditorModelFrameMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if ((ssCtrl in Shift) or (ssAlt in Shift)) and (EditorView.current > 0) then begin
		EditorView.zoom := EditorView.zoom - (Y - EditorView.y) / 100;
  end else if EditorView.current = 1 then begin
		EditorView.rotat := EditorView.rotat + (X - EditorView.x) div 2;
  end else if EditorView.current = 2 then begin
		EditorView.transx := EditorView.transx + (X - EditorView.x) div 2;
		EditorView.transy := EditorView.transy - (Y - EditorView.y) div 2;
  end;

  EditorView.x := X;
  EditorView.y := Y;
end;

procedure TEditorModelView.EditorModelFrameMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  EditorView.current := 0;
end;

procedure TEditorModelView.FormShow(Sender: TObject);
var
  i : integer;
begin
  ModelPreview_Init();
  if Length(Attributes) > 0 then begin
    for i := 0 to Length(Attributes) - 1 do
      ModelListBox.Items.Add(Attributes[i].Name);
    ModelListBox.ItemIndex := 0;
    ModelPreview_UpdateModel();
  end;
end;

procedure glModelViewDraw(id : Integer);
begin
  SetGLFrame(id);

  glClearColor(1, 0, 0, 1);
  glClear(GL_DEPTH_BUFFER_BIT);

	glFlush();
	SwapBuffers(GLFrames[id].dc);
end;

procedure TEditorModelView.ModelListBoxChange(Sender: TObject);
begin             
  ModelPreview_UpdateModel();
end;
end.
