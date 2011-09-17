unit FBallistic;

interface

uses
  Windows, FData, FUnit, FFPS, FLogs, FDisplay, FLoader, SysUtils, MyMath;

const
  PROJECTILE_SPEED = 0.5;
type
  Projectile = (NORMAL, MAGIC, OTHER);
  TTrajectory = (LINEAR, PARABOLIC);
  PEffectCallBack = ^TEffectCallBack;
  PProjectile = ^TProjectile;
  TProjectile = class(TModel)
    public
      ProjectileType : projectile;
      Trajectory : TTrajectory;
      TargetPos, IniPos, IniSpeed : TCoords3c;
      Caster, Target : TUnit;
      dist : Currency;
      rand : integer;
      time : integer;
      ToDelete : boolean;
      Effect : procedure(proj : TProjectile); stdcall;
      constructor Create(UnitID, Target : TUnit; Effect : pointer);
      procedure Update;
      function CheckEnd : boolean;
      procedure UpdateAngle;
      procedure ProjectileEffect;
    private

  end;
  TEffectCallBack = procedure(proj : TProjectile); stdcall;
  procedure testcallback(proj : TProjectile); stdcall;
  procedure projectiledamage(proj : TProjectile); stdcall;
  procedure UpdateAllProjectiles;
  procedure CreateProjectile(UnitID, Target : TUnit; Effect : PEffectCallBack);
implementation
uses
  FEffects;

procedure CreateProjectile(UnitID, Target : TUnit; Effect : PEffectCallBack);
begin
  ProjectileList.Add(TProjectile.Create(UnitID, Target, Effect));
  TProjectile(ProjectileList.Last).SetAnim('Stand');
end;

constructor TProjectile.Create(UnitID, Target : TUnit; Effect : pointer);
var
  dist, time : currency;
begin
  self.SetPath('Models/Missiles/ArrowMissile.mdx');
  self.ModelScale := 10;
  self.ProjectileType := NORMAL;
  self.Trajectory := LINEAR;
  self.ToDelete := false;
  self.RealPos := UnitID.RealPos;
  self.IniPos := UnitID.RealPos;
  self.RealPos.Z := self.RealPos.Z + 30;
  self.time := Count.Now;
  self.rand := Random(10000);
  dist := distance(UnitID.RealPos, Target.RealPos);
  self.dist := 2/3*dist;
  self.Target := Target;
  if self.Trajectory = Parabolic then
    self.IniSpeed.Z := 5 * (self.dist+Target.RealPos.Z)
  else
    self.IniSpeed.Z := 0;
  time := 1/10*(sqrt(self.IniSpeed.Z*self.IniSpeed.Z+20*Self.RealPos.Z-20*self.TargetPos.Z)+self.IniSpeed.Z);
  if self.Target.State = STATE_MOVING then
  begin
    self.TargetPos.X := Self.Target.RealPos.X + BaseSpeed * Self.Target.Speed * time * cos(Self.Target.AimedAngle);
    self.TargetPos.Y := Self.Target.RealPos.Y + BaseSpeed * Self.Target.Speed * time * sin(Self.Target.AimedAngle);
  end
  else
    self.TargetPos := Target.RealPos;
  {en cas de changement de position cible}
  self.IniSpeed.X := ((self.TargetPos.X - UnitID.RealPos.X) / self.dist);
  self.IniSpeed.Y := ((self.TargetPos.Y - UnitID.RealPos.Y) / self.dist);


  self.Caster := UnitID;
  self.Effect := TEffectCallBack(Effect);
  self.UpdateAngle();
end;

procedure testcallback(proj : TProjectile); stdcall;
begin
//  proj.Target.Wound(50);
  proj.Caster.AbilityCast(proj.Target, 0);
end;

procedure projectiledamage(proj : TProjectile); stdcall;
begin
  proj.Target.Wound(Round(randpercent(proj.Caster.Damage,10)*(1-proj.target.Defense/10)));
end;

procedure TProjectile.ProjectileEffect;
begin
  TEffectCallBack(self.Effect)(self);
end;

procedure TProjectile.Update();
var
  dista, t : currency;
begin
  t := Count.Now - self.time;
  self.RealPos.x := self.IniPos.x + t*self.IniSpeed.X;
  self.RealPos.y := self.IniPos.y + t*self.IniSpeed.Y;
  if self.Trajectory = Parabolic then
    self.RealPos.Z := (-5*t*t + self.IniSpeed.Z*t) / (8 * self.dist) + self.IniPos.Z;

  if self.CheckEnd() then
  begin
    self.ToDelete := true;
    dista := distance(self.RealPos, self.Target.RealPos);
    if (self.ProjectileType = MAGIC) or (dista < 100) then //dist : si la target n'a pas bougee
      ProjectileEffect;
  end;

  if self.ProjectileType = MAGIC then //les missiles magiques sont a tete chercheuse
    self.UpdateAngle();
end;

function TProjectile.CheckEnd() : boolean;
var
  Pos : TCoords3c;
  sine, cosine : Currency;
begin
    if self.ProjectileType = MAGIC then
      Pos := self.Target.RealPos
    else
      Pos := self.TargetPos;
    cosine := Cos(self.Angle);
    sine := Sin(self.Angle);
    if cosine > 0 then
    begin
      if sine > 0 then
        Result := (Pos.X - self.RealPos.X <= 0)
              and (Pos.Y - self.RealPos.Y <= 0)
      else
        Result := (Pos.X - self.RealPos.X <= 0)
              and (Pos.Y - self.RealPos.Y >= 0);
    end
    else
    begin
      if sine > 0 then
        result := (Pos.X - self.RealPos.X >= 0)
              and (Pos.Y - self.RealPos.Y <= 0)
      else
        Result := (Pos.X - self.RealPos.X >= 0)
              and (Pos.Y - self.RealPos.Y >= 0);
    end;
end;

procedure TProjectile.UpdateAngle;
begin
  self.Angle := ArcTan((self.Target.RealPos.y - self.RealPos.y) / (self.Target.RealPos.x - self.RealPos.x));
  if self.Target.RealPos.x < self.RealPos.x then
    self.Angle := PI + self.Angle;
  if self.Angle < 0 then
    self.Angle := 2*PI + self.Angle;
end;

procedure UpdateAllProjectiles;
var
  i : integer;
begin
  for i := 0 to ProjectileList.Count - 1 do
      TProjectile(ProjectileList[i]).Update;
  for i := ProjectileList.Count - 1 downto 0 do
  begin
    if TProjectile(ProjectileList[i]).ToDelete then
    begin
      TProjectile(ProjectileList[i]).Destroy;
      ProjectileList.Delete(i);
    end;
  end;
end;
end.
