unit FUpdateData;

interface

uses
  FUnit;

procedure NetUpdateUnits();
procedure UpdateUnit(unitId, InfoToUpdate : integer ;
                     speed, TardetId : integer ;
                     realPosX, realPosY, realPosZ : currency ;
                     posX, posY, posZ : integer;
                     destPosX, destPosY : integer;
                     HP, MP, HPRegen, MPRegen : double ;
                     AimedAngle : Currency ;
                     ToDelete, InConstruction, RotationgClockWise,
                     Rotating, active : boolean ;
                     State : TUnitState ;
                     last_up_move : int64 ;
                     modelScale, maxHP, maxMP, Damage, Defense, Atk_speed, Atk_range : integer;
                     TurnsRemaining, Last_tick, ticks : integer;
                     Temporary : boolean ;
                     AbilityID, uID : integer ;
                     constructionPercent : double);

implementation

uses
  FData, FTransmit, FNetworkTypes, FLogs, FDisplay, FFPS, FInterfaceDraw, SysUtils;

var
  LastUpdate : Int64 = 0;

procedure NetUpdateUnits();
var
  i, u : integer;
  p : TPacketTUnit;
begin
  if (LastUpdate div TURN_LENGTH) + TURN_DELAY > Count.Now div TURN_LENGTH then begin
    exit;
  end;
  LastUpdate := Count.Now;

  i := 0;
  while i <= UnitList.Count - 1 do begin
    if TUnit(UnitList[i]).State = STATE_MOVING then begin
      p.realPosX := TUnit(UnitList[i]).realPos.X;
      p.realPosY := TUnit(UnitList[i]).realPos.Y;
      p.realPosZ := TUnit(UnitList[i]).realPos.Z;
      p.posX := TUnit(UnitList[i]).pos.X;
      p.posY := TUnit(UnitList[i]).pos.Y;
//    p.posZ := TUnit(UnitList[i]).pos.Z;
      P.destPosX := TUnit(UnitList[i]).goal.order.target.pos.X;
      P.destPosY := TUnit(UnitList[i]).goal.order.target.pos.Y;
//    p.destPosZ := TUnit(UnitList[i]).goal.order.target.pos.Z;
      p.speed := TUnit(UnitList[i]).Speed;
      broadcastUpdateTUnit(i, TUNIT_POS, p);

//      p.state := TUnit(UnitList[i]).State;
//      broadcastUpdateTUnit(i, TUNIT_STATE, p);
    end;
    for u := 0 to TUnit(UnitList[i]).Effects.Count -1 do begin

      p.TurnsRemaining := PTimerEffect(TUnit(UnitList[i]).Effects[u])^.TurnsRemaining;
      p.Last_tick := PTimerEffect(TUnit(UnitList[i]).Effects[u])^.Last_tick;
      p.Temporary := PTimerEffect(TUnit(UnitList[i]).Effects[u])^.Temporary;
      p.ticks := PTimerEffect(TUnit(UnitList[i]).Effects[u])^.ticks;
      p.AbilityID := PTimerEffect(TUnit(UnitList[i]).Effects[u])^.Ability^.ID;
      p.uID := u;
      broadcastUpdateTUnit(i, TUNIT_TIMER_EFFECTS, p);
    end;

    inc(i);
  end;
end;

procedure UpdateUnit(unitId, InfoToUpdate : integer ;
                     speed, TardetId : integer ;
                     realPosX, realPosY, realPosZ : currency ;
                     posX, posY, posZ : integer;
                     destPosX, destPosY : integer;
                     HP, MP, HPRegen, MPRegen : double ;
                     AimedAngle : Currency ;
                     ToDelete, InConstruction, RotationgClockWise,
                     Rotating, active : boolean ;
                     State : TUnitState ;
                     last_up_move : int64 ;
                     modelScale, maxHP, maxMP, Damage, Defense, Atk_speed, Atk_range : integer;
                     TurnsRemaining, Last_tick, ticks : integer;
                     Temporary : boolean ;
                     AbilityID, uID : integer ;
                     constructionPercent : double);
var
  o : Porder;
  a : PAbility;
  i : integer;
begin
  if unitID >= UnitList.Count then begin
    AddLine('Error, trying to use unitid ' + IntToStr(unitID) + ' not found');
    exit;
  end;

  if (InfoToUpdate = TUNIT_POS)
  or (InfoToUpdate = TUNIT_MOVE_ORDER)
  or (InfoToUpdate = TUNIT_STOP) then begin
      TUnit(UnitList[unitId]).realPos.X := realPosX;
      TUnit(UnitList[unitId]).realPos.Y := realPosY;
      TUnit(UnitList[unitId]).realPos.Z := realPosZ;
      TUnit(UnitList[unitId]).pos.X := posX;
      TUnit(UnitList[unitId]).pos.Y := posY;
      TUnit(UnitList[unitId]).Speed := speed;

  end;
  case InfoToUpdate of
    TUNIT_POS : begin

    end; TUNIT_MOVE_ORDER : begin
      new(o);
      o.target.ttype := T_POS;
      o.action := MOVETO;
      o.target.pos.X := destPosX;
      o.target.pos.Y := destPosY;
      TUnit(UnitList[unitId]).issue_order(o);

    end; TUNIT_STOP : begin
      new(o);
      o.action := STOP;
      TUnit(UnitList[unitId]).issue_order(o);

    end; TUNIT_STATE : begin
      TUnit(UnitList[unitId]).State := State;

    end; TUNIT_HP : begin
      TUnit(UnitList[unitId]).HP := HP;

    end; TUNIT_MP : begin
      TUnit(UnitList[unitId]).MP := MP;

    end; TUNIT_HP_REGEN : begin
      TUnit(UnitList[unitId]).HP := HPRegen;

    end; TUNIT_MP_REGEN : begin
      TUnit(UnitList[unitId]).MP := MPRegen;

    end; TUNIT_EFFECTS : begin
      TUnit(UnitList[unitId])._ModelScale := ModelScale;
      TUnit(UnitList[unitId])._MaxHp := maxHP;
      TUnit(UnitList[unitId])._MaxMp := maxMP;
      TUnit(UnitList[unitId])._Damage := Damage;
      TUnit(UnitList[unitId])._Defense := Defense;
      TUnit(UnitList[unitId])._Speed := speed;
      TUnit(UnitList[unitId])._Atk_speed := Atk_speed;
      TUnit(UnitList[unitId])._Atk_range := Atk_range;
      TUnit(UnitList[unitId])._InConstruction := InConstruction;
      TUnit(UnitList[unitId])._ConstructionPercent := constructionPercent;



    end; TUNIT_TIMER_EFFECTS : begin
      if TUnit(UnitList[unitId]).Effects.Count - 1 >= uID then begin
        PTimerEffect(TUnit(UnitList[unitId]).Effects[uID])^.TurnsRemaining := TurnsRemaining;
        PTimerEffect(TUnit(UnitList[unitId]).Effects[uID])^.Last_tick := Last_tick;
        PTimerEffect(TUnit(UnitList[unitId]).Effects[uID])^.Temporary := Temporary;
        PTimerEffect(TUnit(UnitList[unitId]).Effects[uID])^.ticks := ticks;

        i := 0;
        while Abilities[i].ID <> uID do begin
          inc(i);
        end;
        PTimerEffect(TUnit(UnitList[unitId]).Effects[uID])^.Ability^ := Abilities[i];
      end;
    end; TUNIT_ATTACK : begin
      TUnit(UnitList[unitId]).SetAnim('Attack');
      TUnit(UnitList[unitId]).AnimPlayAfter := 'Stand Ready';

    end;
  end;
end;

end.
