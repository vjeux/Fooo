unit FModel;

interface
uses
	Windows, Classes, OpenGl, FStructure, FDisplay, FFPS, FTerrain, FFrustum, FSelection,
  FLogs, FCursor, FLoader, FTextures, SysUtils;

procedure DrawModel(select : boolean);

const
  BuildingSize = 64;

var
  VisibleUnits : array of integer;

implementation
uses
	FBase, FUnit, Fdata, Fmap, FFonts, FInterfaceDraw, FBallistic;

function IsMouseHover(u : integer) : boolean;
var
  i : integer;
begin
  i := 0;
  while i < Length(Mouse.HoverList) do begin
    if Mouse.HoverList[i] = u then
      break;
    Inc(i);
  end;
  Result := Mouse.Hover and not (i = Length(Mouse.HoverList));
end;


procedure GetCoords(var x, y : Double);
var
  viewport:   array [1..4]  of Integer;
	modelview:  array [1..16] of Double;
	projection: array [1..16] of Double;
  z : Double;
begin
	glGetDoublev(GL_MODELVIEW_MATRIX, @modelview );
	glGetDoublev(GL_PROJECTION_MATRIX, @projection );
	glGetIntegerv(GL_VIEWPORT, @viewport );

	gluProject(2000, 2000, 150, @modelview, @projection, @viewport, x, y, z);
end;

procedure DrawModel(select : boolean);
var
  i, j, k, l, size, sizediv, a, b, nb_VisibleUnits: integer;
  OnePlayerUnit : Boolean;
  occupied : Boolean;
  u : TUnit;
  proj : TProjectile;
  m : TModel;
begin
  if select then begin
    for i := 0 to UnitList.Count - 1 do begin
      glLoadName(glNameCount);
      Inc(glNameCount);
      u := TUnit(UnitList[i]);

      if u.inFrustum() and u.Visible then begin
        glPushMatrix();
          glTranslatef(u.RealPos.X, u.RealPos.Y, u.RealPos.Z);
          glRotatef(u.Angle*(180/PI), 0, 0, 1);
          // Should update anim now and not after but well ... doesnt matter
          u.Display(select);
        glPopMatrix();
      end;
    end;
    exit;
  end;

  // Units
                              
  nb_VisibleUnits := 0;
  SetLength(VisibleUnits, nb_VisibleUnits);
  OnePlayerUnit := OwnerPlayerUnitExists();    
  for i := 0 to UnitList.Count - 1 do begin
    u := TUnit(UnitList[i]);
    if u.inFrustum() and u.Visible then begin
      glPushMatrix();
        Inc(nb_VisibleUnits);
        SetLength(VisibleUnits, nb_VisibleUnits);
        VisibleUnits[nb_VisibleUnits - 1] := i;
        u.InterfacePos := Get3DPosTo2D(u.RealPos.X, u.RealPos.Y, u.RealPos.Z + 200);

        glTranslatef(u.RealPos.X, u.RealPos.Y, u.RealPos.Z);
        glPushMatrix();
          glRotatef((u.Angle*180)/PI, 0, 0, 1);
          if u.AnimCurrent = 'birth' then
            u.UpdateAnim(Round(u.ConstructionPercent * 60000))
          else
            u.UpdateAnim();
          u.Display(select);
        glPopMatrix();

        if u.Active and (u.Selected or (IsMouseHover(i) and not (OnePlayerUnit and (u.Player <> Player)))) then begin
          if u.Player = Player then
            glColorMask(FALSE, TRUE, TRUE, TRUE)
          else
            glColorMask(TRUE, FALSE, FALSE, TRUE);

//            glTranslatef(0, 0, -u.Stats.ModelSize + 5);
            m := TModel.Create();
            if u.Selected then
              m.SetPath('Models/Misc/SelectionCircle.mdx')
            else
              m.SetPath('Models/Misc/SelectionCircleLight.mdx');
            m.ModelScale := (u.Stats.ModelSize*u.ModelScale) div (u.Stats.ModelScale);
            m.RealPos := u.RealPos;
            m.SetAnim('Stand');
            m.Display();
            m.Destroy();

          glColorMask(TRUE, TRUE, TRUE, TRUE);
        end;
      glPopMatrix();
    end;
  end;

  // Projectiles

  for i := 0 to ProjectileList.Count - 1 do begin
    proj := TProjectile(ProjectileList[i]);
    if proj.inFrustum() then begin
      glPushMatrix();
        glTranslatef(proj.RealPos.X, proj.RealPos.Y, proj.RealPos.Z);
        glRotatef(proj.Angle * ( 180 / PI ), 0, 0, 1); 
        glRotatef(proj.rand + Count.Now, 1, 0, 0);
        proj.Display(select);
      glPopMatrix();
    end;
  end;

  // Buildings hover
  
  if (Mouse.Mode <> nil) and ((Mouse.Mode.Action = REPAIR) and (Mouse.Mode.Building <> nil)) then begin
    size := Mouse.Mode.Building.Size div (BUILDINGSIZE div UNITSIZE);
    sizediv := size div 2;
    for i := 0 to size - 1 do begin
      for j := 0 to size - 1 do begin
        occupied := False;
        k := 0;
        while not occupied and (k < (BUILDINGSIZE div UNITSIZE)) do begin
          l := 0;
          while not occupied and (l < (BUILDINGSIZE div UNITSIZE)) do begin
            a := ((Mouse.terrain.x div BUILDINGSIZE - (i - sizediv + 1)) * BUILDINGSIZE) div UNITSIZE + k;
            b := ((Mouse.terrain.y div BUILDINGSIZE - (j - sizediv + 1)) * BUILDINGSIZE) div UNITSIZE + l;
            occupied := InBoundsMap(Mouse.Mode.Building.Size, a, b) and (Map[a, b].nb_units <> 0);
            Inc(l);
          end;
          Inc(k);
        end;

        glColorMask(occupied, not occupied, FALSE, TRUE);

        glBegin(GL_QUADS);
          glColor4f(0.5, 0.5, 0.5, 0.5);
          glVertex3f(
            (Mouse.terrain.x div BUILDINGSIZE - (i - sizediv)) * BUILDINGSIZE,
            (Mouse.terrain.y div BUILDINGSIZE - (j - sizediv)) * BUILDINGSIZE,
            2
          );
          glColor4f(0.5, 0.5, 0.5, 0.5);
          glVertex3f(
            (Mouse.terrain.x div BUILDINGSIZE - (i - sizediv)) * BUILDINGSIZE,
            (Mouse.terrain.y div BUILDINGSIZE - (j - sizediv + 1)) * BUILDINGSIZE,
            2
          );
          glColor4f(0.5, 0.5, 0.5, 0.5);
          glVertex3f(
            (Mouse.terrain.x div BUILDINGSIZE - (i - sizediv + 1)) * BUILDINGSIZE,
            (Mouse.terrain.y div BUILDINGSIZE - (j - sizediv + 1)) * BUILDINGSIZE,
            2
          );
          glColor4f(0.5, 0.5, 0.5, 0.5);
          glVertex3f(
            (Mouse.terrain.x div BUILDINGSIZE - (i - sizediv + 1)) * BUILDINGSIZE,
            (Mouse.terrain.y div BUILDINGSIZE - (j - sizediv)) * BUILDINGSIZE,
            2
          );
        glEnd();
      end;
    end;

    glColorMask(TRUE, TRUE, TRUE, TRUE);

    glPushMatrix();
    glTranslatef(
      Mouse.terrain.x div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2,
      Mouse.terrain.y div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2, 0);

    m := TModel.Create();
    m.SetPath(Mouse.Mode.Building.Model);
    glrotatef(-90, 0, 0, 1);
    m.ModelScale := Mouse.Mode.Building.ModelScale;
    m.RealPos.X := Mouse.terrain.x div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2;
    m.RealPos.Y := Mouse.terrain.y div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2;
    m.RealPos.Z := 0;
    m.SetAnim('Stand');
    m.Display();
    m.Destroy();

    glPopMatrix();
  end;
end;


end.

