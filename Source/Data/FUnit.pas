unit FUnit;

interface

uses
  Windows, Math, MyQueue, classes, point, FLoader, FDisplay, FStructure;

const
    //nombre d'ordre max dans la file d'ordres (SHIFT)
  MAX_ORDERS  = 20;
  MAX_PATH    = 5000;
    //vitesse de rotation
  ANGULAR_SPEED = 0.0005;
  MAX_BUILDING_QUEUE = 6;
    //temps en ms entre chaque mise à jour de la position de l'autre
  FOLLOW_MOVE_TIME  = 20000;
  SOUNDTYPE_COUNT = 12;

type
  TSoundType = (SOUND_BUILDING, SOUND_GOLD, SOUND_SEARCH, SOUND_UNDER, SOUND_WOOD,
    SOUND_ATTACK, SOUND_DEATH, SOUND_LISTEN, SOUND_MANA, SOUND_MOVE, SOUND_OK, SOUND_READY);
  string255 = string[255];

  TCurrencyPoint = packed record
    X, Y, Z : Currency
  end;

  PUnit = ^TUnit;
  Porder = ^Torder;

  TUnitType = (Hero, Infantry, Ranged, Caster);
  TSpellTarget = (ENEMY, FRIENDLY, MYSELF);

  {------------  TTarget ----------------}

  TTargetType = (T_NONE, T_POS, T_UNIT);

  TTarget = record
    time : Int64;
    case ttype : TTargetType of
      T_NONE :
        ();
      T_POS :
        (pos  : Tpoint);
      T_UNIT :
        (unit_ : Pointer);
  end;

  {------------  TEffects ----------------}
  PEffects = ^TEffects;
  TEffects = packed record
    Hp, Attack, Defense, Damage, Speed, Size : integer;
//    Special : pointer;
  end;

  {------------  UPGRADES ----------------}
  PUpgrade = ^TUpgrade;
  TUpgrade = record
      Name, Icon, ToolTip : string;
      Res1Cost, Res2Cost, ID, TargetsID : integer;
      Effects : PEffects;
  end;


  {------------  ABILITIES ---------------}
  PAbility = ^TAbility;
  TAbility = packed record
    Name, icon, ToolTip : string;
    shortcut : char;
    Target, AreaEffectTarget : TSpellTarget;
    AreaEffect : boolean;
    Range, Duration, Cost, ID, tick, cooldown : integer;
    Instant, Periodic : PEffects;
   // CancelSpecial : pointer;
  end;

  TUnitAttributesAbility = record
    Innate : boolean;
    Ability : PAbility;
  end;

  TUnitAbility = record
    cooldown : integer;
    Ability : PAbility;
  end;


  {------------  UNIT ATTRIBUTES ---------------}
  TAggressivity = (AGGRESSIVE, DEFENSIVE, PASSIVE);
  PUnitAttributes = ^TUnitAttributes;
  TUnitAttributes = packed record
    Name, Model, Icon, ToolTip : string;
    UnitType : TUnitType;
    HP, MP, Atk_speed, Atk_range, Defense, Damage, Speed, BuildingTime,
    Size, ID, ModelScale, ModelSize, Res1Cost, Res2Cost, race : integer;
    Aggressivity : TAggressivity;
    HPRegen, MPRegen, Training : double;
    Buildings : array of PUnitAttributes;
    Abilities : array of TUnitAttributesAbility;
    Upgrades : array of PUpgrade;
    IsBuilding, Repairer : boolean;  
    SoundCount : array[0..SOUNDTYPE_COUNT-1] of integer;
    SoundFolder : string;
  end;

  TUnitState = (STATE_MOVING, STATE_STAND, STATE_ATTACKING, STATE_BUILDING,
                STATE_DYING);

  {------------   ORDERS ---------------}

  TorderType = (STOP,
                MOVETO, ATTACKTO, HOLDPOS, PATROL,
                FOLLOW, ATTACK, REPAIR,
                CAST, TRAIN, UNTRAIN);

  Torder = record
    target : TTarget;
    action : TorderType;
    spell : TAbility;
  end;

  {------------  MOVE_STATE --------------}

  TMoveState = (IDLE, WAITING_PATH, MOVING);

  {------------  GOAL ---------------}

  Tgoal = record
    order     : Torder;  //what to accomplish
    path      : TMyQueue; //calculated path to get there
    state     : TMoveState; //current moving state
    path_id   : integer;    //path line waiting ticket
  end;

  {------------  TIMER EFFECT  ---------------}

  PTimerEffect = ^TTimerEffect;
  TTimerEffect = record
      TurnsRemaining, Last_tick : integer;
      Temporary : boolean;
      ticks : integer;
      Ability : PAbility;
  end;

  {------------  UNIT  ---------------}

  TUnit = class(TModel)
    public
      Name : string;
      Stats : PUnitAttributes;
      Player, UnitId, TargetID, last_hit : integer;
      _MaxHp, _MaxMp, _Atk_speed, _Atk_range, _Defense, _Damage, _Speed : integer;
      pos: Tpoint;
      destPos : TCurrencyPoint;
      State : TUnitState;
      Abilities : array of TUnitAbility;
      Aggressivity : TAggressivity;
//      MP, HPRegen, MPRegen : double;
      _ConstructionPercent, Progression : double;
      AimedAngle : Currency;
      Moving, Selected, ToDelete, _InConstruction, RotatingClockWise, Rotating, Active, Visible : boolean;
      Effects : TList;
      last_up_move : int64;
      BuildingQueue, TrainingList : TList;
      goal : Tgoal;
      _HP, _MP, _HPRegen, _MPRegen : double;
      procedure set_HP(HP : double);
      procedure set_MP(MP : double);
      procedure set_HPRegen(HPRegen : double);
      procedure set_MPRegen(MPRegen : double);
      property HP : double read _HP write set_HP;
      property MP : double read _MP write set_MP;
      property HPRegen : double read _HPRegen write set_HPRegen;
      property MPRegen : double read _MPRegen write set_MPRegen;

      procedure set_MaxHp(effect : integer);
      procedure set_MaxMp(effect : integer);
      procedure set_Atk_speed(effect : integer);
      procedure set_Atk_range(effect : integer);
      procedure set_Damage(effect : integer);
      procedure set_Defense(effect : integer);
      procedure set_Speed(effect : integer);
      property MaxHp : integer read _MaxHp write set_MaxHp;
      property MaxMp : integer read _MaxMp write set_MaxMp;
      property Atk_speed : integer read _Atk_speed write set_Atk_speed;
      property Atk_range : integer read _Atk_range write set_Atk_range;
      property Damage : integer read _Damage write set_Damage;
      property Defense : integer read _Defense write set_Defense;
      property Speed : integer read _Speed write set_Speed;

      procedure set_constrPerc(a : double);
      procedure set_inConstr(a : boolean);
      property InConstruction : boolean read _InConstruction write set_inConstr;
      property ConstructionPercent : double read _ConstructionPercent write set_constrPerc;


      constructor Create(pos : Tpoint; attr : PUnitAttributes; Player, ID : integer);
      function alreadyAffected(ability : PAbility): boolean;
      function checkMovement(Pos: TCoords3c): boolean;
      function distanceMovement(): extended;
      function get_action_dist(): integer;
      function get_action_range(): integer;
      function get_dest(): Tpoint;
      function get_mode(): TorderType;
      function get_nearest_enemy(): TUnit;
      function get_next_chckpnt(): Tpoint;
      function get_target(): Pointer;
      function hard_unit_distance(): integer;
      function IsAbilityAvailable(ability : PAbility) : boolean;
      function is_too_far(): boolean;
      function path_ticket(): integer;
      function ValidTarget(UnitID : TUnit; ability : PAbility) : boolean;
      procedure AbilityAreaEffect(abilityID : PAbility; Instant : boolean);
      procedure AbilityCast(target : TUnit; UnitAbilityID : integer);
      procedure AbilityEffect(target : TUnit; ability : PAbility; Temp, instant : boolean);
      procedure AbilityTickEffect(abilityID : PTimerEffect);
      procedure AddBuildingQueue(u : PUnitAttributes);
      procedure add_order(o : Porder);
      procedure BackToNormal(index : integer);
      procedure ButtonEnable(order : TOrderType; enable : boolean);
      procedure CancelEffect(ability : PAbility);
      procedure ClearEffects();
      procedure execute_next_order();
      procedure get_moving();
      procedure HandleBuildingQueue;
      procedure hit();
      procedure issue_order(o : Porder);
      procedure kill();
      procedure new_path(dest : Tpoint);
      procedure next_move();
      procedure Repair_building();
      procedure request_new_path();
      procedure stop_unit(stopAnim : boolean);
      procedure UpdateActions();
      procedure UpdateAngle();
      procedure UpdateAttacks();
      procedure UpdateMovement();
      procedure UpdateRotWay();
      procedure UpdateStats();
      procedure EnterTraining(building : TUnit);
      procedure ExitTraining(building : TUnit);
      procedure UpgradeEffect(Upgrade : PUpgrade);
      procedure wound(x : integer);
      procedure PlaySound(soundtype : TSoundType);
      procedure broadcastEffects();
    private
      Orders            : TMyQueue;
  end;

  TAbilityCallBack = procedure(UnitID : TUnit); stdcall;

  function need_target(action : TorderType): boolean;


var
  Attributes  : array of TUnitAttributes;
  Abilities   : array of TAbility;
  Upgrades    : array of TUpgrade;
  LastEffectUpdate : int64 = 0;
  LastHPUpdate : int64 = 0;


implementation

uses
  SysUtils, Fdata, Fselection, Fcursor, FFPS, Fmap, FTransmit, FServer, MyMath,
  FLogs, pathfinder, FInterfaceDraw, FBallistic, FLuaFunctions, FLua, FKeys,
  FUpdateData, FNetworkTypes, FSound, FView;



constructor TUnit.Create(pos : Tpoint; attr : PUnitAttributes; Player, ID : integer);
var
  i, l : integer;
begin
  Orders          := TmyQueue.create(MAX_ORDERS);
  Self.goal.path  := TmyQueue.create;
  if attr.IsBuilding then
  begin
    self.BuildingQueue :=  TList.Create;
    self.BuildingQueue.Capacity := MAX_BUILDING_QUEUE;
    self.TrainingList:= TList.Create;
    self.Progression := 0;
  end
  else
  begin
    self.BuildingQueue :=  nil;
    self.TrainingList := nil;
    self.Progression := 0;
  end;
  last_up_move    := 0;
  last_hit        := 0;
  self.Angle      := -PI/2;
  self.AnimID     := 0;
  self.Player     := Player;
  self.UnitID     := ID;
  self._ModelScale := attr.ModelScale;
  self.State      := STATE_STAND;
  self.Selected   := false;
  self.ToDelete   := false;
  self.Rotating   := false;
  self.Active     := true;
  self.Visible    := true;
  self.Aggressivity   := attr^.Aggressivity;
  self._MP            := attr^.MP * 1/2;
  self._MaxHp          := attr^.HP;
  self._MaxMp          := attr^.MP;
  self._HPregen       := attr^.HPregen;
  self._MPregen       := attr^.MPRegen;
  self._Atk_speed      := attr^.Atk_speed;
  self._Atk_range      := attr^.Atk_range;
  self.TargetID       := -1;
  self._Defense        := attr^.Defense;
  self._Damage         := attr^.Damage;
  self._Speed          := attr^.Speed;
  if attr^.IsBuilding then
  begin
    self._InConstruction := true;
    self._Hp := 1;
    self._ConstructionPercent := self.Hp/self.MaxHp;
  end
  else
  begin
    self._InConstruction := false;
    self._ConstructionPercent := 1;
    self._HP := attr^.HP;
  end;
  self.SetPath(attr.Model);
//  if attr.IsBuilding then
    self.SetAnim('Birth');
//  else
//    self.SetAnim('Stand');
  self.pos.x          := pos.x div UnitSize;
  self.pos.y          := pos.y div UnitSize;
  self.RealPos.X      := pos.x div UnitSize * UnitSize + UnitSize div 2;
  self.RealPos.Y      := pos.y div UnitSize * UnitSize + UnitSize div 2;
  self.RealPos.Z      := 0;
  self.Effects        := TList.Create;
  self.Stats          := attr;
  l := Length(self.Stats.Abilities);
  SetLength(self.Abilities, l);
  for i := 0 to l - 1 do
  begin
    self.Abilities[i].Ability := self.stats.Abilities[i].Ability;
    self.Abilities[i].cooldown := 0;
    if self.Stats.Abilities[i].innate then
      self.AbilityCast(self, i);
  end;
end;

procedure TUnit.wound(x : integer);
var
  i, j      : integer;
  tmp_unit  : Tunit;
begin
  self.Hp := self.Hp - x;
  if self.Hp <= 0 then
  begin
    Self.kill;
    CancelMouseAction();
    if self.Selected then //on retire de la liste de selection
    begin
      i := Selection.IndexOf(Self);
      if (i > -1) and (i < Selection.Count) then
        Selection.Delete(i);
    end;
    for i := 0 to 9 do //on retire des groupes de selection
    begin
      j := SelectionGroups[i].IndexOf(self);
      if j <> -1 then      
        SelectionGroups[i].Delete(j);
    end;
    for i := 0 to UnitList.Count - 1 do
    begin
      tmp_unit := TUnit(UnitList[i]);
      while TUnit(tmp_unit.get_target) = Self do
        tmp_unit.execute_next_order;
    end;
    TriggerEvent(EVENT_SELECTIONCHANGE);
  end else if self.Hp > self.Stats.Hp then
    self.Hp := self.Stats.Hp;
end;


procedure TUnit.hit();
var
  i : integer;
  p : TPacketTUnit;
  you : integer;
begin
  i := 0;
  while TUnit(UnitList[i]).Name <> self.Name do begin
    inc(i);
  end;
  broadcastUpdateTUnit(i, TUNIT_ATTACK, p);

  self.AnimPlayAfter := 'Stand Ready';
  self.SetAnim('Attack');
  self.Rotating := true;
  Self.AimedAngle := ArcTan((TUnit(Self.get_target).pos.y - Self.pos.y) / (TUnit(Self.get_target).pos.x - Self.pos.x));
  if TUnit(Self.get_target).pos.x < Self.pos.x then
    Self.AimedAngle := PI + Self.AimedAngle;
  if self.AimedAngle < 0 then
    Self.AimedAngle := 2*PI + Self.AimedAngle;
  if self.Stats.UnitType = Ranged then
    self.AnimDoAfter := ''
  else
    if Self.Damage < 0 then
      Tunit(Self.get_target).Wound(Self.Damage)
    else
    begin
        //nous sommes attaqués
      you := 0;
      while not CLientTab.tab[0]^.publicPlayerList.tab[you].isYou do begin
        inc(you)
      end;

      if (Tunit(Self.get_target).Player = you)
      and (Self.Player <> you)
      and (Count.Now >= (lastAttackWArning + (1000 * ATTACK_WARNING_DELAY))) then
      begin
        Adviser_voice(SOUND_UNDER);
        lastAttackWArning := Count.Now;
      end;
      Tunit(Self.get_target).Wound(Round( randpercent(Self.Damage,10)
                                          * (1 - TUnit(self.get_target).Defense
                                          / 10)));
    end;
end;


procedure Tunit.Repair_building();
begin
  if Self.stats.IsBuilding then begin
    Self.HP := Min(Self.MaxHp, Self.HP + Self.MaxHP * (1/Self.Stats.BuildingTime));
    Self.ConstructionPercent := Min(1, Self.ConstructionPercent + (1/Self.Stats.BuildingTime));
    if self.InConstruction and (Self.ConstructionPercent = 1) then begin
      TriggerEvent(EVENT_SELECTIONCHANGE); //pour afficher les tooltips
      Self.InConstruction := false;
      self.SetAnim('Stand');
      Adviser_voice(SOUND_BUILDING);
      self.broadcastEffects();
    end;
  end;
end;


procedure TUnit.UpdateAttacks();
begin
  if (CurrentTurn - Self.last_hit) >= Self.Atk_speed then
  begin
    Self.hit;
    Self.last_hit := CurrentTurn;
  end
  else
  if (self.Stats.UnitType = RANGED) and (self.AnimDoAfter = 'Ready') then
  begin
    CreateProjectile(self, Tunit(self.get_target), @projectiledamage);
    self.AnimDoAfter := '';
  end;

end;


procedure TUnit.issue_order(o : Porder);
var
  tmp : Porder;
begin
  //DEBUG
   if {(o.action = FOLLOW) or (o.action = REPAIR) or} (o.action = ATTACKTO) then
    exit;

  case o^.action of
    MOVETO    : self.PlaySound(SOUND_MOVE);
    ATTACKTO  : self.PlaySound(SOUND_ATTACK);
    HOLDPOS   : self.PlaySound(SOUND_OK);
    PATROL    : self.PlaySound(SOUND_MOVE);
    FOLLOW    : self.PlaySound(SOUND_MOVE);
    ATTACK    : self.PlaySound(SOUND_ATTACK);
    REPAIR    : self.PlaySound(SOUND_OK);
    CAST      : self.PlaySound(SOUND_OK);
    TRAIN     : self.PlaySound(SOUND_OK);
    UNTRAIN   : self.PlaySound(SOUND_OK);
  end;

    //empty orders queue
  while not(Self.orders.is_empty) do
  begin
    tmp := Self.orders.pop;
    if tmp <> nil then
      dispose(tmp);
  end;
  Self.orders.push(o);
  Self.execute_next_order;
end;


procedure Tunit.request_new_path;
begin
  addline('-- new pathfinding request');
end;


procedure Tunit.get_moving();
begin
  if Self.State <> STATE_MOVING then
  begin
    Self.new_path(Self.get_dest);
    Self.state := STATE_MOVING;
    self.SetAnim('Walk');
    ClearMap(Self);
    self.Rotating := true;
    Self.AimedAngle := ArcTan((Self.get_next_chckpnt.y - Self.pos.y) / (Self.get_next_chckpnt.x - Self.pos.x));
//    Self.AimedAngle := ArcTan((Self.goal.order.target.pos.Y - Self.pos.y) / (Self.goal.order.target.pos.X - Self.pos.x));
    if Self.get_next_chckpnt.X < Self.pos.x then
      Self.AimedAngle := PI + Self.AimedAngle;
    if self.AimedAngle < 0 then
      Self.AimedAngle := 2*PI + Self.AimedAngle;
    //Self.UpdateRotWay;
  end;
end;


procedure Tunit.stop_unit(stopAnim : boolean);
begin
  if Self.state = STATE_MOVING then
  begin
//    addline('STOP ! ' + self.Name);
    Self.state := STATE_STAND;
    self.Rotating := false;
    OccupyMap(Self);
    if stopAnim then
      Self.SetAnim('Stand');
  end;
end;


procedure Tunit.kill();
var
  i : integer;
begin
  self.HP := -10;
  if (Self.state <> STATE_MOVING)
  or Self.Stats.isBuilding then
    ClearMap(Self)
  else
    Self.state := STATE_STAND;
  for i := self.Effects.Count - 1 downto 0 do
  begin
    Dispose(self.Effects[i]);
    self.Effects.Delete(i);
  end;
  self.Effects.Clear;
  SetLength(self.abilities, 0);
  self.SetAnim('Death', false);
  self.PlaySound(SOUND_DEATH);
  self.InConstruction := false;
  self.Active := false;
  ClientTab.tab[0]^.info.kill_unit;
end;


procedure TUnit.add_order(o : Porder);
begin
  if not Self.orders.push(o) then
    Warning.SetMsg('Can''t memorize a new order.');
end;


procedure TUnit.execute_next_order();
var
  next_order : Porder;
  i : integer;
  p : TPacketTUnit;
begin
  ButtonEnable(self.get_mode, false);

  next_order := Porder(Self.orders.pop);
  if next_order = nil then
  begin
    new(next_order);
    next_order^.action := STOP;
    i := 0;
    while TUnit(UnitList[i]).Name <> self.Name do begin
      inc(i)
    end;
    p.realPosX := self.RealPos.X;
    p.realPosY := self.RealPos.Y;
    p.realPosZ := self.RealPos.Z;
    p.posX := self.pos.X;
    p.posY := self.pos.Y;
    p.speed := self.Speed;
    broadcastUpdateTUnit(i, TUNIT_STOP, p);
    Self.issue_order(next_order);
//    sendServerOrder(self.UnitId, next_order);
  end
  else begin //set next order as goal
    Self.goal.order := next_order^;
  end;
  Self.stop_unit(next_order^.action <> MOVETO);
  //on active le bouton de l'action suivante
  ButtonEnable(self.get_mode, true);
end;


function TUnit.get_mode() : TorderType;
begin
  Result := Self.goal.order.action;
end;


function TUnit.get_target(): Pointer;
begin
  if need_target(Self.get_mode) then
    Result := Self.goal.order.target.unit_
  else
    Result := nil;
end;


function Tunit.path_ticket() : integer;
begin
  Result := Self.goal.path_id;
end;


procedure TUnit.new_path(dest : Tpoint);
var
  tmp   : ^Tpoint;
  tmp_Q : PMyQueue;
  t     : PPoint;
  p     : TPacketTUnit;
  i     : integer;
begin

//    empty previous path
  while not(Self.goal.path.is_empty) do
  begin
    tmp := Self.goal.path.pop;
    if tmp <> nil then
      dispose(tmp);
  end;

  //------
  if not ClientTab.tab[0].is_server then begin
    new(tmp);
    tmp^ := dest;
    Self.goal.path.push(tmp); //used for direct path instead of Astar
  end else begin
    tmp_Q := pathfind.Astar(@(Self));
//    if isWinKeyDown(VK_LCONTROL) then
//        dumpMap(Self.pos, dest, 'map_dump.txt');

    if tmp_Q^.is_empty then
      Self.execute_next_order
    else
    begin
      while not(tmp_Q^.is_empty) do
      begin
        tmp := tmp_Q^.pop;
        Self.goal.path.push(tmp);
      end;
      dispose(tmp_Q);
    end;
    if Self.goal.path.top <> NIL then begin
      t := PPoint(Self.goal.path.top);
      p.posX     := self.pos.X;
      p.posY     := self.pos.Y;
      p.posZ     := self.pos.Y;
      p.realPosX := self.realPos.X;
      p.realPosY := self.realPos.Y;
      p.realPosZ := self.realPos.Z;
      p.destPosX := t^.X;
      p.destPosY := t^.Y;
      p.speed := self.Speed;
//    p.destPosY := t^.Z;
      i := 0;
      while TUnit(UnitList[i]).Name <> self.Name do begin
        inc(i);
      end;

      broadcastUpdateTUnit(i, TUNIT_MOVE_ORDER, p);
    end;
  end;
  //------
  //switch comments above to toggle pathfinding

end;


procedure TUnit.UpdateRotWay();
begin
  //if not self.goal.path.is_empty then
  //and not pointCmp(Self.get_next_chckpnt, Self.pos) then
    self.RotatingClockWise := sin(self.AimedAngle - self.Angle) < 0;
end;


procedure TUnit.UpdateAngle();
var
  wasClockWise : boolean;
begin
  if Self.Rotating then
  begin
    self.UpdateRotWay;
    wasClockWise := self.RotatingClockWise;
    if wasClockWise then
      self.Angle := self.Angle - self.Speed*ANGULAR_SPEED*Count.Elapsed
    else
      self.Angle := self.Angle + self.Speed*ANGULAR_SPEED*Count.Elapsed;
    self.UpdateRotWay;
    if self.RotatingClockWise <> wasClockWise then
    begin
      self.Angle := self.AimedAngle;
      self.Rotating := false;
    end;
  end;
end;


procedure TUnit.UpdateMovement();
var
  p1, p2 : Tpoint;
  coeff : extended;
  NewPos : TCoords3c;
  cosine, sine : Currency;
begin
  {if self.state = STATE_MOVING then begin
    if temps_actuel < temps_vise then begin
      NewPos.X := Pos.X + (temps_vise - temps_actuel) * Target.X
      NewPos.Y := Pos.Y + (temps_vise - temps_actuel) * Target.Y
    end else begin
      if server then
        Broadcast(next_movement)

    end;

  end;}


  if (Count.Elapsed > 0) and (Self.state = STATE_MOVING) then
  begin
    p1 := Self.pos;
    coeff := BaseSpeed * Self.Speed * Count.Elapsed; //pour pas que ca bouge entre les 2 :)
    cosine := cos(self.AimedAngle);
    sine := sin(self.AimedAngle);
    NewPos.X := Self.RealPos.X + coeff * cosine;
    NewPos.Y := Self.RealPos.Y + coeff * sine;
    NewPos.Z := 0;
    p2.x := Round(NewPos.X) div UnitSize;
    p2.y := Round(NewPos.Y) div UnitSize;
      //reached a checkpoint
    if Self.checkMovement(NewPos) then
    begin
        Self.RealPos.X := Self.get_next_chckpnt.X * UnitSize + UnitSize / 2;
        Self.RealPos.Y := Self.get_next_chckpnt.Y * UnitSize + UnitSize / 2;
        Self.pos := p2;
        Self.RealPos.X := Self.pos.x * UnitSize + UnitSize / 2;
        Self.RealPos.Y := Self.pos.y * UnitSize + UnitSize / 2;
        Self.next_move;
    end
    else
    begin
        Self.RealPos  := NewPos;
        Self. pos      := p2;
    end;
  end;
end;

procedure Tunit.UpdateActions;
var
  order   : Porder;
  target  : Tunit;
begin
  target := Self.get_target();
  if Self.state = STATE_MOVING then
  begin
    if not Self.is_too_far then
    begin
      //addline('CLOSE ENOUGH');
      Self.stop_unit(true);
    end;
  end
  else
//    Log(IntToStr(Integer(self.get_mode)));
    if Self.is_too_far then
    begin
      //addline('TOO FAR!');
      if Self.get_mode = PATROL then
      begin
        //addline('adding patrol to ' + TpointToStr(Self.pos));
        new(order);
        order^.action := PATROL;
        order^.target.ttype := T_POS;
        order^.target.pos := Self.pos;
        Self.add_order(order);
      end;
      Self.get_moving;
    end
    else
    case Self.get_mode of
      ATTACK :
        begin
          Self.UpdateAttacks;
        end;
      MOVETO, PATROL :
        Self.execute_next_order;
      REPAIR :
        begin
          target.Repair_building;
          if not target.InConstruction then
            Self.execute_next_order
          else if not Self.Rotating then
          begin
            Self.Rotating := true;
            Self.AimedAngle := ArcTan((target.pos.y - Self.pos.y)
                                        / (target.pos.x - Self.pos.x));
            if target.pos.x < Self.pos.x then
              Self.AimedAngle := PI + Self.AimedAngle;
            if Self.AimedAngle < 0 then
              Self.AimedAngle := 2*PI + Self.AimedAngle;
          end;
        end;
      TRAIN :
        begin
          self.EnterTraining(target);
          Self.execute_next_order;
        end;
      UNTRAIN :
        begin
          self.ExitTraining(target);
          self.execute_next_order;
        end;
      STOP :
        begin
          Self.rotating := false;
          if Self.Aggressivity = AGGRESSIVE then
          begin
            target := Self.get_nearest_enemy();
            if target <> nil then
            begin
              New(order);
              order^.target.unit_ := target;
              order^.action := ATTACK;
              Self.issue_order(order);
//            sendServerOrder(Self.UnitId, order);
            end;
          end;
        end;
    end;
end;


procedure TUnit.ClearEffects;
var
  i, l : integer;
  curability : PTimerEffect;
begin
    //spell effects
  l := Length(self.Abilities) - 1;
  for i := 0 to l do
    if self.Abilities[i].cooldown > 0 then
      Dec(self.Abilities[i].cooldown);
  if Self.Effects.Count > 0 then
  begin
    for i := Self.Effects.Count - 1 downto 0 do
    begin
      if self.HP <= 0 then
        break;
      curability := PTimerEffect(Self.Effects[i]);
      {duration = -1 => effet permanent}
      if curability^.temporary then
      begin
        Self.BackToNormal(i);
        Dispose(curability);
        Self.Effects.Delete(i);
      end
      else
        if ((curability^.TurnsRemaining = 0) and (curability^.Ability.duration <> -1)) then
        begin
          if (curability^.Ability.tick > 0) and (curability^.ticks <> curability^.Ability.tick) then
            AbilityTickEffect(curability);
          Self.BackToNormal(i);
          Dispose(curability);
          Self.Effects.Delete(i);
          TriggerEvent(EVENT_SELECTIONCHANGE);
        end
        else
        if (curability^.TurnsRemaining = 0) then
        begin
          Dispose(curability);
          Self.Effects.Delete(i);
        end
    end;
  end;
end;

procedure TUnit.UpdateStats;
var
  i : integer;
begin
    //spell effects
  if Self.Effects.Count > 0 then
    for i := 0 to Self.Effects.Count - 1 do
      begin
        dec(PTimerEffect(Self.Effects[i])^.TurnsRemaining);
        if not(PTimerEffect(Self.Effects[i])^.temporary) then
        begin
          if (CurrentTurn - PTimerEffect(Self.Effects[i])^.last_tick >= PTimerEffect(Self.Effects[i])^.ability.tick) then
            AbilityTickEffect(PTimerEffect(Self.Effects[i]));
        end;
      end;
    //HP
  if (Self.HPregen > 0) and not(Self.InConstruction)
  and (Self.HP < Self.MaxHP) then
  begin
    Self.HP :=  Self.HP + Self.HPRegen;
    if Self.HP > Self.MaxHP then
      Self.HP := Self.MaxHP;
  end;
    //MP
  if (Self.MPregen > 0) and not(Self.InConstruction)
  and (Self.MP < Self.MaxMP) then
  begin
    Self.MP :=  Self.MP + Self.MPregen;
    if Self.MP > Self.MaxMP then
      Self.MP := Self.MaxMP;
  end;
end;


function TUnit.hard_unit_distance(): integer;
begin
  if need_target(Self.get_mode) then
    Result := ceil(sqrt2*half(Self.Stats.Size)
              + (sqrt2*half(Tunit(Self.get_target).Stats.size)))
  else
    Result := 0;
end;


function TUnit.get_action_range(): integer;
begin
  case Self.get_mode of
    FOLLOW :
      Result := FOLLOW_RANGE;
    REPAIR, TRAIN : 
      Result := MELEE_RANGE;
    ATTACK :
      begin
        if self.Stats.UnitType = Ranged then
          result := self.Atk_range
        else
          Result := MELEE_RANGE;
      end;
    CAST :
      Result := Self.goal.order.spell.Range;
    else 
      Result := 0;
  end;
end;


function TUnit.get_action_dist(): integer;
begin
  result := Self.get_action_range + Self.hard_unit_distance;
end;


function TUnit.is_too_far() : boolean;
begin
  case Self.get_mode of
    STOP, HOLDPOS :
      Result := false;
    else
      if Self.state = STATE_MOVING then
        Result := (Distance2(Self.pos, Self.get_dest) > pow2(Self.get_action_dist))
      else
        Result := (Distance2(Self.pos, Self.get_dest) > pow2(Self.get_action_dist + ORDERS_TOLERANCE));
  end;
end;


procedure TUnit.next_move;
var
  p : TPacketTUnit;
  i : integer;
  t : PPoint;
begin
    //delete current checkpoint
  if Self.goal.path.top <> nil then
    dispose(Self.goal.path.top);

  Self.goal.path.pop;
  if not Self.goal.path.is_empty then
  begin
    self.Rotating := true;
    self.state := STATE_MOVING;
    Self.AimedAngle := ArcTan((Self.get_next_chckpnt.y - Self.pos.y) / (Self.get_next_chckpnt.x - Self.pos.x));
    if Self.get_next_chckpnt.x < Self.pos.x then
      Self.AimedAngle := PI + Self.AimedAngle;
    if self.AimedAngle < 0 then
      Self.AimedAngle := 2*PI + Self.AimedAngle;

    if Clienttab.tab[0].is_server then begin
      t := PPoint(Self.goal.path.top);
      p.posX     := self.pos.X;
      p.posY     := self.pos.Y;
      p.posZ     := self.pos.Y;
      p.realPosX := self.realPos.X;
      p.realPosY := self.realPos.Y;
      p.realPosZ := self.realPos.Z;
  //  P.destPosX := self.goal.order.target.pos.X;
  //  P.destPosY := self.goal.order.target.pos.Y;
  //  p.destPosZ := self.goal.order.target.pos.Z;
      p.destPosX := t^.X;
      p.destPosY := t^.Y;
  //  p.destPosZ := self.get_next_chckpnt.Z;
      p.speed := self.Speed;
      i := 0;
      while TUnit(UnitList[i]).Name <> self.Name do begin
        inc(i);
      end;

      broadcastUpdateTUnit(i, TUNIT_MOVE_ORDER, p);
    end;
  end
  else
    Self.stop_unit(true);
end;


function Tunit.get_next_chckpnt(): Tpoint;
begin
  if Self.goal.path.top <> nil then
    Result := Tpoint(Self.goal.path.top^)
  else
    Result := Self.pos;
end;


function  Tunit.get_dest(): Tpoint;
begin
  if Self.get_mode = STOP then
    Result := Self.pos
  else if need_target(Self.get_mode) then
    Result := Tunit(Self.get_target).pos
  else
    Result := Self.goal.order.target.pos;
end;


function TUnit.distanceMovement() : extended;
var
  chkpnt : Pointer;
begin
  chkpnt := Self.goal.path.top;
  if chkpnt = nil then
    Result := 0
  else
    Result := sqrt(pow2(abs(Self.pos.x -Tunit(Self.get_target).pos.x))
                  + pow2(abs(Self.pos.y - Tunit(Self.get_target).pos.y)));
end;

function TUnit.checkMovement(Pos : TCoords3c) : boolean;
var
  range, sine, cosine : Currency;
begin
  if self.goal.path.is_empty then
    Result := true
  else begin
    range := 0;
    cosine := cos(self.AimedAngle);
    sine := sin(self.AimedAngle);
    if cosine > 0 then
    begin
      if sine > 0 then
        Result := (Self.get_next_chckpnt.X - Round(pos.X) div UnitSize <= range)
              and (Self.get_next_chckpnt.Y - Round(pos.Y) div UnitSize <= range)
      else
        Result := (Self.get_next_chckpnt.X - Round(pos.X) div UnitSize <= range)
              and (Self.get_next_chckpnt.Y - Round(pos.Y) div UnitSize >= -range);
    end
    else
    begin
      if sine > 0 then
        result := (Self.get_next_chckpnt.X - Round(pos.X) div UnitSize >= -range)
              and (Self.get_next_chckpnt.Y - Round(pos.Y) div UnitSize <= range)
      else
        Result := (Self.get_next_chckpnt.X - Round(pos.X) div UnitSize >= -range)
              and (Self.get_next_chckpnt.Y - Round(pos.Y) div UnitSize >= -range);
    end;
  end;
end;

procedure TUnit.AbilityCast(target : TUnit; UnitAbilityID : integer);
var
  ability : PAbility;
begin
  ability := self.Abilities[UnitAbilityID].Ability;
  if ValidTarget(target, ability) and (self.Abilities[UnitAbilityID].cooldown = 0) then
  begin
    self.MP := self.MP - ability^.Cost;
    self.Abilities[UnitAbilityID].cooldown := ability^.cooldown;
    self.AbilityEffect(target, ability, false, true);
  end;
end;

procedure TUnit.AbilityEffect(target : TUnit; ability : PAbility; Temp, instant : boolean);
var
  effect : PTimerEffect;
  attr : PEffects;
begin
  if ability.Instant.damage <> 0 then
    target.Wound(ability^.Instant^.Damage);
  if instant then
    attr := ability^.Instant
  else
    attr := ability^.Periodic;
  target.ModelScale := target.ModelScale + attr^.Size;
  target.MaxHp    := target.MaxHp + attr^.Hp;
  target.Damage   := target.Damage + attr^.Attack;
  target.Defense  := target.Defense + attr^.Defense;
  target.Speed    := target.Speed + attr^.Speed;
  if (ability^.AreaEffect) and not(Temp) then
    AbilityAreaEffect(ability, true);
  if (ability^.Duration > 0) or (ability^.Duration = -1) then
  begin
    New(effect);
    effect^.TurnsRemaining := ability^.Duration;
    effect^.Ability := ability;
    effect^.last_tick := CurrentTurn;
    effect^.temporary := Temp;
    if ability^.tick > 0 then
      effect^.ticks := 0
    else
      effect^.ticks := -1;
    if temp then
      effect^.ticks := 1;
    target.Effects.Add(effect);
  end;
  TriggerEvent(EVENT_SELECTIONCHANGE);
end;

procedure TUnit.AbilityTickEffect(AbilityID : PTimerEffect);
var
  ability : PAbility;
begin
  ability := abilityID^.ability;
  inc(abilityID^.ticks);
  if ability^.AreaEffect then
    AbilityAreaEffect(abilityID^.ability, false);
  if ability^.Periodic^.damage <> 0 then
    self.Wound(ability^.Periodic^.Damage);
  self.ModelScale := self.ModelScale + ability^.Periodic^.Size;
  self.MaxHp    := self.MaxHp + ability^.Periodic^.Hp;
  self.Damage   := self.Damage + ability^.Periodic^.Attack;
  self.Defense  := self.Defense + ability^.Periodic^.Defense;
  self.Speed    := self.Speed + ability^.Periodic^.Speed;
  AbilityID.last_tick := CurrentTurn;
end;

procedure TUnit.AbilityAreaEffect(AbilityID : PAbility; Instant : boolean);
var
  i : integer;
begin
  if abilityID^.AreaEffectTarget = Enemy then
  begin
    for i := 0 to UnitList.Count - 1 do
    begin
      if (self.Player <> TUnit(UnitList[i]).Player)
      and (Distance2(self, TUnit(UnitList[i])) < pow2(AbilityID^.Range))
      and (self <> TUnit(UnitList[i])) then
      begin
        AbilityEffect(TUnit(UnitList[i]), abilityID, true, Instant);
      end;
    end;
  end
  else
  for i := 0 to UnitList.Count - 1 do
  begin
    if (self.Player = TUnit(UnitList[i]).Player)
    and (Distance2(self, TUnit(UnitList[i])) < pow2(AbilityID^.Range))
    and (self <> TUnit(UnitList[i])) then
    begin
      AbilityEffect(TUnit(UnitList[i]), abilityID, true, Instant);
    end;
  end;
end;

procedure TUnit.BackToNormal(index : integer);
var
  ability : PAbility;
  ticks : integer;
begin
  ability := PTimerEffect(self.Effects[index])^.Ability;
  if PTimerEffect(self.Effects[index])^.temporary then
  begin
    self.ModelScale := self.ModelScale - ability^.Periodic^.Size;
    self.MaxHp    := self.MaxHp - ability^.Periodic^.Hp;
    self.Damage   := self.Damage - ability^.Periodic^.Attack;
    self.Defense  := self.Defense - ability^.Periodic^.Defense;
    self.Speed    := self.Speed - ability^.Periodic^.Speed;
  end
  else
  begin
    if ability^.Tick > 0 then
    begin
      ticks := PTimerEffect(self.Effects[index])^.ticks;
      self.ModelScale := self.ModelScale - (ability^.Instant.Size + ability^.Periodic^.Size*ticks);
      self.MaxHp    := self.MaxHp - (ability^.Instant.Hp + ability^.Periodic^.Hp*ticks);
      self.Damage   := self.Damage - (ability^.Instant.Attack + ability^.Periodic^.Attack*ticks);
      self.Defense  := self.Defense - (ability^.Instant.Defense + ability^.Periodic^.Defense*ticks);
      self.Speed    := self.Speed - (ability^.Instant.Speed + ability^.Periodic^.Speed*ticks);
    end
    else
    begin
      self.ModelScale := self.ModelScale - ability^.Instant^.Size;
      self.MaxHp    := self.MaxHp - ability^.Instant^.Hp;
      self.Damage   := self.Damage - ability^.Instant^.Attack;
      self.Defense  := self.Defense - ability^.Instant^.Defense;
      self.Speed    := self.Speed - ability^.Instant^.Speed;
    end;
  end;
end;

{ ------------------------------------------- }


function TUnit.ValidTarget(UnitID : TUnit; ability : PAbility) : boolean;
begin
  if ((ability^.Target = Enemy) and (UnitID.Player = self.Player))
  or ((ability^.Target = Friendly) and (UnitID.Player <> self.Player))
  or ((ability^.Target = Myself) and (UnitID <> self)) then
  begin
    Warning.SetMsg('Invalid target.');
    result := false;
  end
  else
    result := true;
  result :=  result and not(UnitID.alreadyAffected(ability))
  and (Distance2(UnitID, self) <= pow2(ability^.Range)) and (self.MP >= ability^.Cost);
  if not(result) then //on affiche pourquoi ca ne marche pas
  begin
    if (Distance2(UnitID, self) > pow2(ability^.Range)) then
      Warning.SetMsg('Out of range.')
    else
      if (self.MP >= ability^.Cost) then
        Warning.SetMsg('Not enough mana.')
      else
        Warning.SetMsg('Target already affected by this spell.');
  end;
end;


function need_target(action : TorderType): boolean;
begin
  Result :=     (action = FOLLOW)
            or  (action = ATTACK)
            or  (action = REPAIR)
            or  (action = CAST) or (action = TRAIN) or (action = UNTRAIN);
end;


function TUnit.alreadyAffected(ability : PAbility) : boolean;
var
  i : integer;
begin
  i := 0;
  while ((i < self.Effects.Count) and
  ((PTimerEffect(self.Effects[i])^.Ability^.ID <> ability^.ID) or (PTimerEffect(self.Effects[i])^.temporary))) do
    inc(i);
  result := i < self.Effects.Count;
end;


procedure TUnit.CancelEffect(ability : PAbility);
var
  i : integer;
begin
  i := 0;
  while (i < self.Effects.Count) and
  ((PTimerEffect(self.Effects[i])^.Ability^.Name <> ability^.Name) or (PTimerEffect(self.Effects[i])^.temporary)) do
    inc(i);
  self.BackToNormal(i);
  self.Effects.Delete(i);
end;


procedure TUnit.UpgradeEffect(upgrade : PUpgrade);
begin
  self.ModelScale := self.ModelScale + upgrade^.effects^.size;
  self.MaxHp    := self.MaxHp + upgrade^.effects^.Hp;
  self.Damage   := self.Damage + upgrade^.effects^.Attack;
  self.Defense  := self.Defense + upgrade^.effects^.Defense;
  self.Speed    := self.Speed + upgrade^.effects^.Speed;
end;


function TUnit.get_nearest_enemy(): TUnit;
var
  i, min, dist : integer;
begin
  result := nil;
  min := pow2(AGGRO_RANGE);
  for i := 0 to UnitList.Count - 1 do
  begin
    if (self.Player <> TUnit(UnitList[i]).Player)
    and (self <> TUnit(UnitList[i])) and (TUnit(UnitList[i]).Active) then
    begin
      dist := Distance2(self, TUnit(UnitList[i]));
      if (dist < min) then
      begin
        min := dist;
        result := TUnit(UnitList[i]);
      end;
    end;
  end;
end;


procedure TUnit.ButtonEnable(order : TOrderType; enable : boolean);
begin
  lua_pushnumber(L, get_buttonID(order));
  lua_setglobal(L, 'arg1');
  if enable then
    TriggerEvent(EVENT_UNITACTION)
  else
    TriggerEvent(EVENT_UNITSTOPACTION);
end;


procedure TUnit.AddBuildingQueue(u : PUnitAttributes);
begin
  if (ClientTab.tab[0]^.info.res1 >= u.Res1Cost) then
    if (ClientTab.tab[0]^.info.res2 >= u.Res2Cost) then
    begin
      if Self.BuildingQueue.Count = 6 then
        Warning.SetMsg('Building queue is full.')
      else
      begin
        Self.BuildingQueue.Add(u);
        TriggerEvent(EVENT_BUILDINGQUEUE);
      end;
    end
    else
    begin
      Adviser_voice(SOUND_WOOD);
      Warning.SetMsg('Not enough Wood.');
    end
  else
  begin
      Adviser_voice(SOUND_GOLD);
      Warning.SetMsg('Not enough Gold.');
  end;
end;


procedure TUnit.HandleBuildingQueue;
var
  u : PUnitAttributes;
  i : integer;
  loc : TPoint;
begin
  if (self.BuildingQueue.Count <> 0) then
  begin
    u := self.BuildingQueue.First;
    if (ClientTab.tab[0]^.info.res1 >= u.Res1Cost)
      and (ClientTab.tab[0]^.info.res2 >= u.Res2Cost) then
    begin
      if u.BuildingTime <> 0 then
        self.Progression := self.Progression + (100)/u^.BuildingTime;
      if (self.Progression >= 100) or (u.BuildingTime = 0) then
      begin
        i := 0;
        while TUnitAttributes(Attributes[i]).Name <> u^.Name do
          inc(i);
        loc := GetNearestFreeSpace(self.stats.size, u.size, self.pos.x, self.pos.y);
        loc.x := loc.x * UnitSize;
        loc.y := loc.y * UnitSize;
        sendServerCreateUnit(loc, i, GlobalClientRank+1, -1);
        //CreateUnit(loc, @Attributes[i], GlobalClientRank+1, -1);
        self.BuildingQueue.Delete(0);
        self.Progression := 0;
        TriggerEvent(EVENT_BUILDINGQUEUE);
      end;
    end;
  end;
end;

function TUnit.IsAbilityAvailable(ability : PAbility) : boolean;
var
  i, l : integer;
begin
  i := 0;
  l := Length(Self.Abilities);
  while (i < length(Self.Abilities)) and (self.Abilities[i].Ability <> Ability) do
    inc(i);
  if i < l then
    result := (0 = self.Abilities[i].cooldown)
  else
    result := false;
end;

procedure TUnit.EnterTraining(building : TUnit);
begin
  if building.Stats.IsBuilding and (building.Stats.Training = -1) and (building.TrainingList.Count < 6) then
  begin  //batiment d'extraction
    self.Visible := false;
    building.TrainingList.Add(self);
    TriggerEvent(EVENT_TRAINING);
    Selection.removeUnit(UnitList.IndexOf(Self));
    ClearMap(self);
  end;
end;

procedure TUnit.ExitTraining(building : TUnit);
var
  loc : TPoint;
begin
  if building.Stats.IsBuilding and (building.Stats.Training = -1) then
  begin
    self.Visible := true;
    building.TrainingList.Delete(building.TrainingList.IndexOf(self));
    loc := GetNearestFreeSpace(building.stats.size, self.stats.size, building.pos.x, building.pos.y);
    self.pos := loc;
    TriggerEvent(EVENT_TRAINING);
    OccupyMap(self);
  end
end;

procedure TUnit.set_HP(HP : double);
var
  p : TPacketTUnit;
  i: integer;
begin


    if ClientTab.tab[0]^.is_server then begin
      if round(self._HP) <> round(HP) then begin
        self._HP := HP;
        i := 0;
        while TUnit(UnitList[i]).Name <> self.Name do begin
          inc(i)
        end;
        p.HP := HP;
        if ClientTab.tab[0]^.is_server and (Count.Now > LastHPUpdate + TURN_LENGTH*10)then begin
          LastHPUpdate := Count.Now;
          broadcastUpdateTUnit(i, TUNIT_HP, p);
        end;
      end else begin
        self._HP := HP;
      end;
    end else begin
      self._HP := HP;
    end;

end;

procedure TUnit.set_MP(MP : double);
var
  p : TPacketTUnit;
  i: integer;
begin
  if ClientTab.tab[0]^.is_server then begin
    if round(self._MP) <> round(MP) then begin
      self._MP := MP;
      i := 0;
      while TUnit(UnitList[i]).Name <> self.Name do begin
        inc(i)
      end;
      p.MP := MP;
      broadcastUpdateTUnit(i, TUNIT_MP, p);
    end else begin
      self._MP := MP;
    end;
  end else begin
    self._MP := MP;
  end;
end;

procedure TUnit.set_HPRegen(HPRegen : double);
var
  p : TPacketTUnit;
  i: integer;
begin
  if ClientTab.tab[0].is_server then begin
    if round(self._HPRegen) <> round(HPRegen) then begin
      self._HPRegen := HPRegen;
      i := 0;
      while TUnit(UnitList[i]).Name <> self.Name do begin
        inc(i)
      end;
      p.HPRegen := HPRegen;
      broadcastUpdateTUnit(i, TUNIT_HP_REGEN, p);
    end else begin
      self._HPRegen := HPRegen;
    end;
  end else begin
    self._HPRegen := HPRegen;
  end;
end;

procedure TUnit.set_MPRegen(MPRegen : double);
var
  p : TPacketTUnit;
  i: integer;
begin
  if ClientTab.tab[0].is_server then begin
    if round(self._MPRegen) <> round(MPRegen) then begin
      self._MPRegen := MPRegen;
      i := 0;
      while TUnit(UnitList[i]).Name <> self.Name do begin
        inc(i)
      end;
      p.MPRegen := MPRegen;
      broadcastUpdateTUnit(i, TUNIT_MP_REGEN, p);
    end else begin
      self._MPRegen := MPRegen;
    end;
  end else begin
    self._MPRegen := MPRegen;
  end;
end;

procedure TUnit.broadcastEffects();
var
  i : integer;
  p : TPacketTUnit;
begin
  if ClientTab.tab[0]^.is_server and (Count.Now > LastEffectUpdate + TURN_LENGTH*10)then begin
    LastEffectUpdate := Count.Now;
    i := 0;
    while TUnit(UnitList[i]).name <> self.Name do begin
      inc(i)
    end;
    p.ModelScale := self.ModelScale;
    p.MaxHp := self.maxHP;
    p.MaxMp := self.maxMP;
    p.Damage := self.Damage;
    p.Defense := self.Defense;
    p.Speed := self.speed;
    p.Atk_speed := self.Atk_speed;
    p.Atk_range := self.Atk_range;
    p.InConstruction := self.InConstruction;
    p.constructionPercent := self.ConstructionPercent;
    broadcastUpdateTUnit(i, TUNIT_EFFECTS, p);
    Addline('Effects broadcasted !');
  end;
end;

procedure TUnit.set_MaxHp(effect : integer);

begin
  self._maxHp := effect;
  self.broadcastEffects();
end;

procedure TUnit.set_MaxMp(effect : integer);
begin
  self._maxMp := effect;
  self.broadcastEffects();
  Addline('Debug : Max MP set to ' + IntToStr(effect));
end;

procedure TUnit.set_Atk_speed(effect : integer);
begin
  self._Atk_speed := effect;
  self.broadcastEffects();
end;

procedure TUnit.set_Atk_range(effect : integer);
begin
  self._Atk_range := effect;
  self.broadcastEffects();
end;

procedure TUnit.set_Damage(effect : integer);
begin
  self._Damage := effect;
  self.broadcastEffects();
end;

procedure TUnit.set_Defense(effect : integer);
begin
  self._Defense := effect;
  self.broadcastEffects();
end;

procedure TUnit.set_Speed(effect : integer);
begin
  self._Speed := effect;
  self.broadcastEffects();
end;

procedure TUnit.PlaySound(soundtype : TSoundType);
var
  you : integer;
begin
  you := 0;
  while not ClientTab.tab[0]^.publicPlayerList.tab[you].isYou do begin
    inc(you);
  end;
  if (self.Player - 1 = you)
  or (soundType = SOUND_BUILDING)
  or (soundType = SOUND_GOLD)
  or (soundType = SOUND_SEARCH)
  or (soundType = SOUND_UNDER)
  or (soundType = SOUND_WOOD) then begin
    PlayStatSound(self.Stats, soundtype);
  end;
end;

procedure TUnit.set_constrPerc(a : double);
begin
  self._constructionPercent := a;
  self.broadcastEffects();

  if self.InConstruction and (Self.ConstructionPercent = 1) then begin
      if not ClientTab.tab[0].is_server then begin
        TriggerEvent(EVENT_SELECTIONCHANGE); //pour afficher les tooltips
        Self.InConstruction := false;
        self.SetAnim('Stand');
        Adviser_voice(SOUND_BUILDING);
      end;
  end;
end;

procedure TUnit.set_inConstr(a : boolean);
begin
  self._inConstruction := a;
  self.broadcastEffects();
end;

end.
