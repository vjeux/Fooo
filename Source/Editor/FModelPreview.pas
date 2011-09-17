unit FModelPreview;

interface
uses
  FDisplay, FUnit;

procedure ModelPreview_SetModel(attr : PUnitAttributes);
procedure ModelPreview_UpdateView();
procedure ModelPreview_Draw(id : integer);


var
  ModelPreview_Model : TModel = nil;

implementation
uses
  Windows, FOpenGl, FBase, FRedirect, FEditorModelView, FPlayer;

procedure ModelPreview_SetModel(attr : PUnitAttributes);
begin
  if ModelPreview_Model = nil then begin
    ModelPreview_Model := TModel.Create();
    ModelPreview_Model.RealPos.X := 0;
    ModelPreview_Model.RealPos.Y := 0;
    ModelPreview_Model.RealPos.Z := 0;
    ModelPreview_Model.ModelScale := attr.ModelScale;
    ModelPreview_Model.TeamColor := TeamColor[2];
  end;
  ModelPreview_Model.SetPath(attr.Model);
end;

procedure ModelPreview_UpdateView();
begin
	glViewport(0, 0, EditorModelView.Width, EditorModelView.Height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(40, EditorModelView.Width / EditorModelView.Height, 1, 10000);
	gluLookAt(0, -1000, 250,
            0, 0, 250,
            0, 0, 1);
	glMatrixMode(GL_MODELVIEW);
end;

procedure ModelPreview_Draw(id : integer);
begin
  SetGLFrame(id);
	glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
  glEnable(GL_DEPTH_TEST);
  ModelPreview_UpdateView();
  glClearColor(0, 0, 0, 0);

  if ModelPreview_Model <> nil then begin
    glPushMatrix();
      glTranslatef(EditorView.transx, 0, EditorView.transy);         
      glrotatef(EditorView.rotat, 0, 0, 1);
      glscalef(EditorView.zoom, EditorView.zoom, EditorView.zoom);
      ModelPreview_Model.UpdateAnim();
      ModelPreview_Model.Display();
    glPopMatrix();
  end;

	glFlush();
	SwapBuffers(GLFrames[id].dc);
end;

end.
