unit FMouseClick;

interface

const
  DoubleClickDelay = 300;

procedure OnLeftMouseDown();
procedure OnLeftMouseUp();
procedure OnRightMouseDown();                            
procedure OnRightMouseUp();

implementation

uses
  FCursor,
  Classes,
  FData,
  FFPS,
  FInterfaceDraw,
  FKeys,
  FMap,
  FTransmit,
  FUnit,
  FSelection,
  FServer,
  Windows,
  MyMath,
  FRedirect,
  Math,
  SysUtils,
  FSound;

function DistanceSort(a, b : TUnit) : integer;
begin
  Result := intComp(Distance2(TUnit(UnitList[Mouse.HoverList[0]]), a),
          Distance2(TUnit(UnitList[Mouse.HoverList[0]]), b));
end;

procedure sortByDistance(var l : TList; u : TUnit);
var
  i : integer;
begin
  for i := 0 to UnitList.Count - 1 do begin
    if (TUnit(UnitList[Mouse.HoverList[0]]).Stats.Name = TUnit(UnitList[i]).Stats.Name)
    and (Distance2(TUnit(UnitList[Mouse.HoverList[0]]), TUnit(UnitList[i])) < pow2(NearSelectDistance))
    and (TUnit(UnitList[i]).Player = Player) then
      l.Add(TUnit(UnitList[i]));
  end;
  l.Sort(@DistanceSort);
end;


procedure OnLeftMouseUp();
var
  i, mini, l    : integer;
  nearestUnits  : TList;
  DoubleClick   : Boolean;
begin
  DoubleClick := (Mouse.LastDblClick <> 0)
                  and (Count.Now < Mouse.LastDblClick + DoubleClickDelay);

  if (Mouse.Hover) and (Mouse.OnSelection) then begin
    if (Mouse.Mode = nil) or not(Mouse.Mode.Action = REPAIR) then begin
      if OwnerPlayerUnitExists() then begin
        if isWinKeyDown(VK_SHIFT) and (isWinKeyDown(VK_LCONTROL) or DoubleClick) then begin
          Mouse.OnSelection := False;
          nearestUnits := TList.Create();
          sortByDistance(NearestUnits, TUnit(Mouse.HoverList[0]));
          mini := Math.Min(MaxSelection - 1, nearestUnits.Count - 1);
          if mini >= 0 then
           selection.addUnit(UnitList.IndexOf(TUnit(nearestUnits[0])));
          for i := 1 to mini do
          begin
            if not(TUnit(NearestUnits[i]).Stats.IsBuilding) then
              selection.addUnit(UnitList.IndexOf(TUnit(nearestUnits[i])));
          end;
          NearestUnits.Destroy();
        end else if isWinKeyDown(VK_SHIFT) then begin
          if (Length(Mouse.HoverList) = 1) and TUnit(UnitList[Mouse.HoverList[0]]).Selected then begin
            selection.removeUnit(Mouse.HoverList[0]);
          end else begin
            if TUnit(Selection[0]).Player = Player then
            begin
              l := Length(Mouse.HoverList) - 1;
              if l >= 0 then
                selection.addUnit(Mouse.HoverList[0]);
              for i := 0 to l do
                if (TUnit(UnitList[Mouse.HoverList[i]]).Player = Player) and (not(TUnit(UnitList[Mouse.HoverList[i]]).Stats.IsBuilding)) then
                  selection.addUnit(Mouse.HoverList[i]);
            end;
          end;
        end else if (isWinKeyDown(VK_LCONTROL) or DoubleClick) then begin
          Selection.Clear();
          Mouse.OnSelection := False;
          NearestUnits := TList.Create();
          sortByDistance(nearestUnits, TUnit(Mouse.HoverList[0]));
          mini := Math.Min(MaxSelection - 1, nearestUnits.Count - 1);
          if mini >= 0 then
            selection.addUnit(UnitList.IndexOf(TUnit(nearestUnits[0])));
          for i := 1 to mini do
            if not(TUnit(nearestUnits[i]).Stats.IsBuilding) then              
              selection.addUnit(UnitList.IndexOf(TUnit(nearestUnits[i])));
          NearestUnits.Destroy();
        end else begin
          selection.Clear();
          l := Length(Mouse.HoverList);
          if l = 1 then
            selection.addUnit(Mouse.HoverList[0])
          else
          begin
            for i := 0 to l - 1 do begin
              if (Mouse.HoverList[i] >= UnitList.Count) then begin
                AddLine('Trying to add unexisting unit to selection ' + IntToStr(Mouse.HoverList[i]));
              end;
              if (TUnit(UnitList[Mouse.HoverList[i]]).Player = Player) and (not(TUnit(UnitList[Mouse.HoverList[i]]).Stats.IsBuilding)) then
                selection.addUnit(Mouse.HoverList[i]);
            end;
          end;
        end;
      end else begin
        if isWinKeyDown(VK_SHIFT) then begin
          if (Selection.IndexOf(TUnit(UnitList[Mouse.HoverList[0]])) = -1) then
          begin
            Selection.Clear();
            if TUnit(UnitList[Mouse.HoverList[0]]).Active then
              selection.addUnit(Mouse.HoverList[0]);
          end
          else
            Selection.Clear();
        end else begin
          Selection.Clear();
          if TUnit(UnitList[Mouse.HoverList[0]]).Active then
            selection.addUnit(Mouse.HoverList[0]);
        end;
      end;
    end;
  end;

  Mouse.OnSelection := False;
  if DoubleClick then
    Mouse.LastDblClick := 0
  else
    Mouse.LastDblClick := Count.Now;
end;

procedure OnLeftMouseDown();
var
  pos       : Tpoint;
  i         : integer;
  order     : Porder;
begin
  order := nil;
  if Mouse.Mode <> nil then
  begin
    if Mouse.Hover then
    begin
      if Mouse.Mode.Action = CAST then 
        TUnit(Selection[0]).AbilityCast(TUnit(UnitList[Mouse.HoverList[0]]), Mouse.Mode.SpellUnitID);
      if Mouse.Mode.Action = MOVETO then
      begin
        New(order);
        order^.action := FOLLOW;
        order^.target.unit_ := TUnit(UnitList[Mouse.HoverList[0]]);
      end;
      if Mouse.Mode.Action = ATTACK then
      begin
        if TUnit(UnitList[Mouse.HoverList[0]]) <> TUnit(Selection[0]) then
        begin
          New(order);
          order^.action := ATTACK;
          order^.target.unit_ := TUnit(UnitList[Mouse.HoverList[0]]);
        end;
      end;
    end
    else
    begin
      if Mouse.Mode.Action = REPAIR then
      begin
        if Mouse.Mode.Building <> nil then
        begin
          pos.x := Mouse.terrain.x div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE;
          pos.y := Mouse.terrain.y div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE;
          if CheckMap(Mouse.Mode^.Building^.Size, pos.x, pos.y) then
          begin
//            New(order);     //Commented for network
//            order^.action := REPAIR; //Commented for network
            i := 0;
            while Mouse.Mode^.Building^.ID <> Attributes[i].ID do
              inc(i);
//            sendServerCreateUnit(pos, i, GlobalClientRank+1, -1); //Commented for network
//            order^.target.ttype := t_Unit;
//            order^.target.unit_ := TUnit(UnitList.Last);           //Commented for network

            pos.X := Mouse.terrain.x div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2;
            pos.Y := Mouse.terrain.y div BUILDINGSIZE * BUILDINGSIZE div UNITSIZE * UNITSIZE + UNITSIZE div 2;
//            selected := CreateUnit(pos, @Attributes[6], Player, 42);                 //Commented for network
            sendServerCreateUnit(pos, i, GlobalClientRank+1, TUnit(selection[0]).UnitID);
//            order^.target.unit_ := selected;                             //Commented for network
          end
          else
            addline('Can''t Build there !');
        end
        else
        begin
          if TUnit(UnitList[Mouse.HoverList[0]]).Stats.IsBuilding then
          begin
            New(order);
            order^.action := REPAIR;
            order^.target.ttype := T_UNIT;
            order^.target.unit_ := TUnit(UnitList[Mouse.HoverList[0]]);
          end;
        end;
      end;
      if Mouse.Mode.Action = MOVETO then
      begin
        pos := Mouse.Terrain;
        New(order);
        order^.action := MOVETO;
        order^.target.ttype := T_POS;
        order^.target.pos.x := pos.x div UnitSize;
        order^.target.pos.y := pos.y div UnitSize;
        // order^.target.time défini dans FTransmit/sendServerOrder
      end else begin                                                            //Banban : j'ai ajouté le else : j'imagine qu'on peut pas MOVETO et PATROL en même temps ?
        if Mouse.Mode.Action = PATROL then
        begin
          pos := Mouse.Terrain;
          New(order);
          order^.action := PATROL;
          order^.target.ttype := T_POS;
          order^.target.pos.x := pos.x div UnitSize;
          order^.target.pos.y := pos.y div UnitSize;
        end;
      end;
    end;
    if (order <> nil) and (order^.action <> REPAIR) then
    begin
      for i := 0 to Selection.Count - 1 do
      begin
        if isWinKeyDown(VK_SHIFT) then
          selection.addOrder(order)
        else
          selection.issueOrder(order);
        end;
    end;
    CancelMouseAction();
  end
  else
  begin
    Mouse.OnSelection := True;
    Mouse.SelectionX := Mouse.X;
    Mouse.SelectionY := Mouse.Y;
    SetCursor(CU_NORMAL);
  end;
end;

procedure OnRightMouseUp();
begin

end;

procedure OnRightMouseDown();
var
  order     : Porder;
  pos       : Tpoint;
  target    : Tunit;
  selected  : Tunit;
begin
  if Mouse.OnSelection or (CurrentScreen = SCREEN_MENU) then
    exit;
  if selection.Count = 0 then
    exit;
  if selection.leader.Player <> Player then
    exit;
  if (Mouse.Mode <> nil) then
  begin
    CancelMouseAction();
    exit;
  end;
  if (Mouse.Terrain.X < 0) or (Mouse.Terrain.Y < 0) then
    exit;

  pos:= Mouse.Terrain;

  if Mouse.Hover then
    target := TUnit(UnitList[Integer(Mouse.HoverList[0])])
  else
    target := map[pos.x div UnitSize, pos.y div UnitSize].Unite;


  selected := selection.leader();
  if not(selected.Stats.IsBuilding) then
  begin
    new(order);

    if target <> nil then
    begin
      if target <> selected then
      begin
        if target.Player <> selected.Player then
        begin
          order^.action := ATTACK;
          order^.target.unit_ := target;
        end
        else //target is from same team
        begin
          if selected.Stats.Repairer and target.Stats.IsBuilding and (target.Hp < target.MaxHP) then
          begin
            order^.action := REPAIR;
            order^.target.unit_ := target;
          end
          else
          if (selected.Stats.Training > 0) and (target.Stats.Training = -1) then
          begin
            order^.action := TRAIN;
            order^.target.unit_ := target;
          end
          else
          begin
            order^.action := FOLLOW;
            order^.target.unit_ := target;
          end;
        end;
      end
      else //clicking on target
      begin
      //  exit; //to remove
        order^.action := MOVETO;
        order^.target.pos.x  := pos.x div UnitSize;
        order^.target.pos.y  := pos.y div UnitSize;
      end;
    end
    else //clicking on the ground
    begin
      order^.action     := MOVETO;
      order^.target.pos.x := pos.x div UnitSize;
      order^.target.pos.y := pos.y div UnitSize;
    end;
    if isWinKeyDown(VK_SHIFT) then
      selection.addOrder(order)
    else
      selection.issueOrder(order);
  end
  else //action for buildings
  begin
    //rally point
  end;

end;

end.
