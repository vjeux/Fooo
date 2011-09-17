unit FDisplay;

interface
uses
  Windows, FOpenGl, FStructure, FMath3d;
type
  int2 = array[0..1] of integer;

  TCoords3c = record
    X : currency;
    Y : currency;
    Z : currency;
  end;
  
  MatrixSaveType = record
    Time : Integer;
    Matrix : PGLFLoat;
  end;
  
  TModel = class
    private
      _angle : Currency;
      procedure setAngle(a : Currency);
    public
      ModelPath : string;
      ModelID : integer;
      _ModelScale : Integer;

      MatrixSave : array of MatrixSaveType;

      RealPos : TCoords3c;
      InterfacePos : TPoint;

      Animated : Boolean;
      AnimRepeat : Boolean;
      AnimID : Integer;
      AnimTime : Integer;
      AnimPlayAfter : string;
      AnimDoAfter : string;
      AnimCurrent : string;
      TeamColor : TCoords3c;

      procedure set_ModelScale(effect : integer);
      property ModelScale : integer read _ModelScale write set_ModelScale;

      property Angle : Currency read _angle write setAngle;
      procedure SetAnim(name : string; AnimRepeat : boolean = true; forceUpdate : boolean = false);
      procedure SetPath(path : string);
      procedure UpdateAnim(time : integer = -1);
      procedure Display(select : boolean = false);
      procedure ApplyTexture(i : integer);
      function ApplyTransformation(i, j : integer) : Float3;
      function inFrustum() : boolean;
      function GetGeosetAlpha(GeosetID : integer; select: boolean) : Float;  
      function GetTransformation(ObjectId, time : integer) : PGLFloat;
      procedure ClearSavedMatrix();
      constructor Create();
  end;

const
  NOPARENT = 4294967295;

implementation
uses
	FBase, FTextures, FFrustum, Flogs, SysUtils, FFPS, Math, FLoader, FInterfaceDraw;

constructor TModel.Create();
begin
  self.AnimPlayAfter := '';
  self.AnimDoAfter := 'Ready';
end;

procedure TModel.ClearSavedMatrix();
var
  i : integer;
begin
   for i := 0 to Length(self.MatrixSave) - 1 do
    self.MatrixSave[i].Time := -1;
end;

function TModel.inFrustum() : boolean;
begin
  Result := ModelInFrustum(@LoadedModels[self.ModelID], self.AnimID, self.RealPos.X,  self.RealPos.Y,  self.RealPos.Z);
end;

procedure TModel.SetPath(path: string);
begin
  self.ModelPath := path;
  Self.ModelID := GetModel(path);

  SetLength(self.MatrixSave, LoadedModels[self.ModelID].ObjectMaxId + 1);
  self.ClearSavedMatrix();
end;

procedure TModel.setAngle(a : Currency);
begin
  self._angle := a;
//  if self._angle < 0 then
//    self._angle := 2*PI + self._angle
//  else if self._angle > 2*PI then
//    self._angle := -2*PI + self._angle;
end;

procedure TModel.SetAnim(name : string; AnimRepeat : boolean = true; forceUpdate : boolean = false);
var
  i, k, len : integer;
  Model : PMdxModel;
begin
  name := LowerCase(name);

  if (self.AnimCurrent = name) and not forceUpdate then
    exit;

  if name = '' then begin
    self.Animated := False;
    exit;
  end else
    self.Animated := True;

  Model := @LoadedModels[self.ModelID];
  len := Length(Model^.Sequence);

  i := 0;
  while (i < len) and (LowerCase(Model^.Sequence[i].Name) <> name) do
    Inc(i);

  if (i = len) then begin
    AddLine('Animation `' + name + '` not found on `' + Model^.Model.Name + '`');
    exit;
  end;

  k := 0;
  while (i + k + 1 < len) and (Model^.Sequence[i + k + 1].Rarity > 0)
    and (Random() > 1 / Model^.Sequence[i + k + 1].Rarity) do
    Inc(k);
                           
  if (i + k + 1 = len) or (Model^.Sequence[i + k + 1].Rarity = 0) then
    k := -1;

  self.AnimID := i + k + 1;
  self.AnimTime := Model^.Sequence[self.AnimID].IntervalStart;
  self.AnimCurrent := name;
  self.AnimRepeat := AnimRepeat;
  self.ClearSavedMatrix();
end;

procedure TModel.UpdateAnim(time : integer = -1);
var
  Model : PMdxModel;
begin
  if not Self.Animated then
    exit;
  Model := @LoadedModels[self.ModelID];
  if time = -1 then
    if (self.AnimTime + Count.Elapsed > Integer(Model^.Sequence[self.AnimID].IntervalEnd)) then
      if self.AnimRepeat then begin
        if self.AnimPlayAfter <> '' then begin
          self.AnimCurrent := self.AnimPlayAfter;
          self.AnimPlayAfter := '';
        end;
        if self.AnimDoAfter = '' then
          self.AnimDoAfter := 'Ready';
        self.SetAnim(self.AnimCurrent, true, true);
      end else begin
        self.AnimTime := Model^.Sequence[self.AnimID].IntervalEnd;
        self.SetAnim('');
      end
    else
      self.AnimTime := (self.AnimTime
                      + Count.Elapsed
                      - Integer(Model^.Sequence[self.AnimID].IntervalStart))
                    mod
                      (Integer(Model^.Sequence[self.AnimID].IntervalEnd)
                      - Integer(Model^.Sequence[self.AnimID].IntervalStart))
                    + Integer(Model^.Sequence[self.AnimID].IntervalStart)

  else
    self.AnimTime := Integer(Model^.Sequence[self.AnimID].IntervalStart) + time;
end;


function FindKey(Transfo : Transformation1; t : Cardinal; Sequence : PSequenceChunk; var k : int2) : integer; overload;
var
	i, len : integer;
begin
	len := Length(Transfo.Scaling);
  k[0] := -1;
  i := 0;
  while (i < len) and (Transfo.Scaling[i].Time <= t) and (Transfo.Scaling[i].Time <= Sequence^.IntervalEnd) do begin
    k[0] := i;
    Inc(i);
  end;
  if (k[0] = -1) or (k[0] >= len) or (Transfo.Scaling[k[0]].Time < Sequence^.IntervalStart)
    or (Transfo.Scaling[k[0]].Time > Sequence.IntervalEnd) then
    Result := 0
  else begin
    k[1] := k[0] + 1;
    if (k[1] >= len) or (Transfo.Scaling[k[1]].Time < Sequence.IntervalStart) then
      Result := 1
    else
      Result := 2;
  end;
end;

function FindKey(Transfo : Transformation3; t : Cardinal; Sequence : PSequenceChunk; var k : int2) : integer; overload;
var
	i, len : integer;
begin
	len := Length(Transfo.Scaling);
  k[0] := -1;
  i := 0;
  while (i < len) and (Transfo.Scaling[i].Time <= t) and (Transfo.Scaling[i].Time <= Sequence^.IntervalEnd) do begin
    k[0] := i;
    Inc(i);
  end;
  if (k[0] = -1) or (k[0] >= len) or (Transfo.Scaling[k[0]].Time < Sequence^.IntervalStart)
    or (Transfo.Scaling[k[0]].Time > Sequence.IntervalEnd) then
    Result := 0
  else begin
    k[1] := k[0] + 1;
    if (k[1] >= len) or (Transfo.Scaling[k[1]].Time < Sequence.IntervalStart) then
      Result := 1
    else
      Result := 2;
  end;
end;

function FindKey(Transfo : Transformation4; t : Cardinal; Sequence : PSequenceChunk; var k : int2) : integer; overload;
var
	i, len : integer;
begin
	len := Length(Transfo.Scaling);
  k[0] := -1;
  i := 0;
  while (i < len) and (Transfo.Scaling[i].Time <= t) and (Transfo.Scaling[i].Time <= Sequence^.IntervalEnd) do begin
    k[0] := i;
    Inc(i);
  end;
  if (k[0] = -1) or (k[0] >= len) or (Transfo.Scaling[k[0]].Time < Sequence^.IntervalStart)
    or (Transfo.Scaling[k[0]].Time > Sequence.IntervalEnd) then
    Result := 0
  else begin
    k[1] := k[0] + 1;
    if (k[1] >= len) or (Transfo.Scaling[k[1]].Time < Sequence.IntervalStart) then
      Result := 1
    else
      Result := 2;
  end;
end;

function CalculatePos(Transfo : Transformation1; time: integer; Sequence : PSequenceChunk; Default : Float; var IsChanged : Boolean) : Float; overload;
var
  k : int2;
  found : integer;
begin
  found := FindKey(Transfo, time, Sequence, k);
  if (found = 0) or ((found = 1) and (Transfo.InterpolationType > 0)) then begin
    Result := Default;
    IsChanged := false;
  end else begin
    IsChanged := true;
    if Transfo.InterpolationType = 0 then
      Result := Transfo.Scaling[k[0]].Value
    else
      Result :=
        Interpolate(time,
          Transfo.Scaling[k[0]].Time,
          Transfo.Scaling[k[1]].Time,
          Transfo.Scaling[k[0]].Value,
          Transfo.Scaling[k[1]].Value,
          Transfo.InterpolationType
        );
  end;
end;

function CalculatePos(Transfo : Transformation3; time: integer; Sequence : PSequenceChunk; Default : Float3; var IsChanged : Boolean) : Float3; overload;
var
  k : int2;
  found : integer;
begin
  found := FindKey(Transfo, time, Sequence, k);
  if (found = 0) or ((found = 1) and (Transfo.InterpolationType > 0)) then begin
    Result := Default;
    IsChanged := false;
  end else begin
    IsChanged := true;
    if Transfo.InterpolationType = 0 then
      Result := Transfo.Scaling[k[0]].Value
    else begin
      Result[0] :=
        Interpolate(time,
          Transfo.Scaling[k[0]].Time,
          Transfo.Scaling[k[1]].Time,
          Transfo.Scaling[k[0]].Value[0],
          Transfo.Scaling[k[1]].Value[0],
          Transfo.InterpolationType
        );
      Result[1] :=
        Interpolate(time,
          Transfo.Scaling[k[0]].Time,
          Transfo.Scaling[k[1]].Time,
          Transfo.Scaling[k[0]].Value[1],
          Transfo.Scaling[k[1]].Value[1],
          Transfo.InterpolationType
        );
      Result[2] :=
        Interpolate(time,
          Transfo.Scaling[k[0]].Time,
          Transfo.Scaling[k[1]].Time,
          Transfo.Scaling[k[0]].Value[2],
          Transfo.Scaling[k[1]].Value[2],
          Transfo.InterpolationType
        );
    end;
  end;
end;

function CalculatePos(Transfo : Transformation4; time: integer; Sequence : PSequenceChunk; Default : Float4; var IsChanged : Boolean) : Float4; overload;
var
  k : int2;
  found : integer;
begin
  found := FindKey(Transfo, time, Sequence, k);
  if (found = 0) or ((found = 1) and (Transfo.InterpolationType > 0)) then begin
    Result := Default;
    IsChanged := false;
  end else begin
    IsChanged := true;
    if Transfo.InterpolationType = 0 then
      Result := Transfo.Scaling[k[0]].Value
    else
      Result :=
        QuaternionSlerp(
          Transfo.Scaling[k[0]].Value,
          Transfo.Scaling[k[1]].Value,
          (Cardinal(time) - Transfo.Scaling[k[0]].Time) / (Transfo.Scaling[k[1]].Time - Transfo.Scaling[k[0]].Time)
        );
  end;
end;

function TModel.GetGeosetAlpha(GeosetID : integer; select: boolean) : Float;
var
  i, len : integer;
  Model : pMdxModel;
  t : boolean;
begin
  Model := @LoadedModels[self.ModelID];
  i := 0;
  len := Length(Model^.GeosetAnimation);

  if select and (Model^.Geoset[GeosetID].SelectionFlags = 4) then begin
    Result := 0;
    exit;
  end;

  // Hack
  if (Length(Model^.Material[Model^.Geoset[GeosetID].MaterialId].Layer) > 0)
  and (Model^.Texture[Model^.Material[Model^.Geoset[GeosetID].MaterialId].Layer[0].TextureId].ReplaceableId = 2) then begin
    Result := 0;
    exit;
  end;
  


  if len = 0 then begin
    Result := 1;
    exit;
  end;
  
  while (i < len - 1) and (Integer(Model^.GeosetAnimation[i].GeosetId) <> GeosetID) do
    Inc(i);

  if (Integer(Model^.GeosetAnimation[i].GeosetId) <> GeosetID) then
    Result := 1
  else begin
    Result := CalculatePos(
      Model^.GeosetAnimation[i].GeosetAlpha,
      self.AnimTime, @Model^.Sequence[self.AnimID], 1, t
    );
  end;
end;

function FindNode(Model : pMDXModel; ObjectId : integer) : PNodeChunk;
var
  i : integer;
begin
  // Search the good node
  i := 0;
  while (i < Length(Model^.Bone)) and (Integer(Model^.Bone[i].Node.ObjectId) <> ObjectId) do
    Inc(i);
  if (i = Length(Model^.Bone)) then begin
    i := 0;
    while (i < Length(Model^.Helper)) and (Integer(Model^.Helper[i].ObjectId) <> ObjectId) do
      Inc(i);
    if (i = Length(Model^.Helper)) then begin
      Result := nil;
      Log('Model Error: ' + Model^.Model.Name + ' can''t find the Node ' + IntToStr(ObjectId));
      exit;
    end else
      Result := @Model^.Helper[i];
  end else
    Result := @Model^.Bone[i].Node;
end;

function TModel.GetTransformation(ObjectId, time : integer) : PGLFloat;
var
  Node : PNodeChunk;
  Translation, Pivot, Scaling : Float3;
  Rotation : Float4;
  isTranslation, isRotation, isScaling : Boolean;
  Model : pMDXModel;
begin
  Model := @LoadedModels[self.ModelID];
  // Find the node
  Node := FindNode(Model, ObjectId);
  if Node = nil then begin
    Result := IdentityMatrix;
    exit;
  end;

  // if already calculated
  if time = self.MatrixSave[ObjectId].Time then begin
    Result := self.MatrixSave[ObjectId].Matrix;
    exit;
  end;

  // Calculate
  glPushMatrix();
    // Base Matrix
    if Node^.ParentId <> NOPARENT then begin
      glLoadMatrixf(self.GetTransformation(Node^.ParentId, time));
    end else
      glLoadIdentity();


    // Getting transformations
    Translation := CalculatePos(Node^.NodeTranslation, time, @Model^.Sequence[self.AnimID], DefaultTranslation, isTranslation);
    Rotation := CalculatePos(Node^.NodeRotation, time, @Model^.Sequence[self.AnimID], DefaultQuaternion, isRotation);
    Scaling := CalculatePos(Node^.NodeScaling, time, @Model^.Sequence[self.AnimID], DefaultScaling, isScaling);
    Pivot := Model^.PivotPoint[ObjectId];

    // Apply transformations
    if isTranslation and (isRotation or isScaling) then
      glTranslatef(Translation[0] + Pivot[0], Translation[1] + Pivot[1], Translation[2] + Pivot[2])
    else if isTranslation then
      glTranslatef(Translation[0], Translation[1], Translation[2])
    else if isRotation or isScaling then
      glTranslatef(Pivot[0], Pivot[1], Pivot[2]);

    if isRotation then
      glMultMatrixf(QuaternionToMatrix(Rotation));
    if isScaling then
      glScalef(Scaling[0], Scaling[1], Scaling[2]);

    if isRotation or isScaling then
      glTranslatef(-Pivot[0], -Pivot[1], -Pivot[2]);

    glGetFloatv(GL_MODELVIEW_MATRIX, Result);

    // Storing it
    self.MatrixSave[ObjectId].Matrix := Result;
    self.MatrixSave[ObjectId].Time := time;
  glPopMatrix();
end;

function TModel.ApplyTransformation(i, j : integer) : Float3;
var
  l, len : integer;
  Matrix : PGLFloat;
  Model : pMDXModel;
begin
  Model := @LoadedModels[self.ModelID];
  len := Length(Model^.Geoset[i].Matrix[Model^.Geoset[i].VertexGroup[j]]);
  Matrix := NullMatrix;
  for l := 0 to len - 1 do
    AddMatrix(Matrix, self.GetTransformation(Model^.Geoset[i].Matrix[Model^.Geoset[i].VertexGroup[j]][l], self.AnimTime));
  MultMatrix(Matrix, 0.1 * self.ModelScale / len);
  Result := TransformVector(Model^.Geoset[i].VertexPosition[j], Matrix);
end;

procedure TModel.ApplyTexture(i : integer);
var
	j : integer;
  Model : pMdxModel;
  Layer : ^LayerChunk;
  Texture : ^TextureChunk;
begin
  Model := @LoadedModels[self.ModelID];
	for j := 0 to Length(Model^.Material[Model^.Geoset[i].MaterialId].Layer) - 1 do begin
    glClientActiveTexture(GL_TEXTURE0_ARB + j);
    glActiveTexture(GL_TEXTURE0_ARB + j);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);

    Layer := @Model^.Material[Model^.Geoset[i].MaterialId].Layer[j];
    Texture := @Model^.Texture[Layer^.TextureId];

    case Layer^.FilterMode of
      0 : begin
      end;
      1 : begin // transparent
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glEnable(GL_ALPHA_TEST);
        glAlphaFunc(GL_GREATER, 0.8);
      end;
      2 : begin // blend
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        if j > 0 then
          glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL );
      end;
      3 : begin // additive
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);
      end;
    end;

    case Texture^.ReplaceableId of
      0 : begin // Texture
        BindTexture(Texture^.GLID);
      end;
      1 : begin // Team Color
        glColor3f(self.TeamColor.X, self.TeamColor.Y, self.TeamColor.Z);
        BindTexture(BlankGLID);
      end;
      2 : begin // Team Glow
        BindTexture(TransparentGLID); // Hack en attendant le vrai code !
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        AddLine(inttoStr(Length(Model^.Material[Model^.Geoset[i].MaterialId].Layer)));
      end;
    end;

    glTexCoordPointer(2, GL_FLOAT, 0, Model^.Geoset[i].TexturePosition)
  end;
end;

procedure TModel.Display(select : boolean=false);
var
  i, j, k : integer;
  geo : array of Float3;
  Model : pMDXModel;
begin
  Model := @LoadedModels[self.ModelID];

	for i := 0 to length(Model^.Geoset) - 1 do begin
    if GeosetInFrustum(@Model^.Geoset[i], self.RealPos) and (self.GetGeosetAlpha(i, select) > 0) then begin
      glEnableClientState(GL_VERTEX_ARRAY);

      // Texture
      if not select then
        self.ApplyTexture(i);

      // Vertex
      SetLength(geo, Length(Model^.Geoset[i].VertexPosition));
      for j := 0 to Length(geo) - 1 do
        geo[j] := self.ApplyTransformation(i, j);
      glVertexPointer(3, GL_FLOAT, 0, geo);

      // Draw
      glDrawElements(GL_TRIANGLES, Length(Model^.Geoset[i].Face) * 3, GL_UNSIGNED_SHORT, Model^.Geoset[i].Face);

      // Cleaning Up
      if not select then begin
        glColor3f(1, 1, 1);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_BLEND);

        for k := Length(Model^.Material[Model^.Geoset[i].MaterialId].Layer) - 1 downto 0 do begin
          glClientActiveTexture(GL_TEXTURE0_ARB + k);
          glActiveTexture(GL_TEXTURE0_ARB + k);
          glDisable(GL_TEXTURE_2D);
          glDisableClientState(GL_TEXTURE_COORD_ARRAY);
          glDisableClientState(GL_VERTEX_ARRAY);
          glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE );
        end;
      end;
    end;
  end;
end;

procedure TModel.set_ModelScale(effect : integer);
begin
  self._ModelScale := effect;
end;


end.

