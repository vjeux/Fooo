unit FUnitLoad;

interface


procedure LoadUnits();
procedure LoadAbilities();
procedure LoadUpgrades();
implementation

uses
  FGlWindow, FUnit, xmldom, XMLIntf, msxmldom, XMLDoc, FData,
  FEffects, FTransmit, FLogs, SysUtils;


type
  PIXMLNode = ^IXMLNode;


procedure LoadUnits();
var
  TempNode, CurrentNode : IXMLNode;
  i, j, k, len : integer;
begin
	GlWindow.Document.LoadFromFile('Data/units.xml');
  i := 0;
  if GlWindow.Document.DocumentElement.HasChildNodes then begin
    CurrentNode := GlWindow.Document.DocumentElement.ChildNodes.First;
    repeat
      if CurrentNode.NodeName = 'unit' then begin
        SetLength(Attributes, i + 1);

        // ID
        Attributes[i].ID := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('id');
        if TempNode <> nil then
          Attributes[i].ID := TempNode.NodeValue
        else
          Log('Parsing Units.xml, id is required');

        // Name
        Attributes[i].Name := '';
        TempNode := CurrentNode.ChildNodes.FindNode('name');
        if TempNode <> nil then
          Attributes[i].Name := TempNode.Text;

        // Race
        Attributes[i].Race := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('race');
        if TempNode <> nil then
          Attributes[i].Race := TempNode.NodeValue;

        // Tooltip
        Attributes[i].ToolTip := '';
        TempNode := CurrentNode.ChildNodes.FindNode('tooltip');
        if TempNode <> nil then
          Attributes[i].ToolTip := TempNode.Text;

        // Icon
        Attributes[i].Icon := '';
        TempNode := CurrentNode.ChildNodes.FindNode('icon');
        if TempNode <> nil then
          Attributes[i].Icon := TempNode.Text;

        // Model
        Attributes[i].Model := '';
        TempNode := CurrentNode.ChildNodes.FindNode('model');
        if TempNode <> nil then
          Attributes[i].Model := TempNode.Text;

        // Sound Folder
        Attributes[i].SoundFolder := '';
        TempNode := CurrentNode.ChildNodes.FindNode('sound');
        if TempNode <> nil then
          Attributes[i].SoundFolder := TempNode.Text;

        for k := 0 to SOUNDTYPE_COUNT - 1 do
          Attributes[i].SoundCount[k] := -1;

        // Model Scale
        Attributes[i].ModelScale := 10;
        TempNode := CurrentNode.ChildNodes.FindNode('modelscale');
        if TempNode <> nil then
          Attributes[i].ModelScale := TempNode.NodeValue;

        // Model Size
        Attributes[i].ModelSize := 10;
        TempNode := CurrentNode.ChildNodes.FindNode('modelsize');
        if TempNode <> nil then
          Attributes[i].ModelSize := TempNode.NodeValue;

        // Unit Type
        Attributes[i].UnitType := Caster;
        TempNode := CurrentNode.ChildNodes.FindNode('type');
        if TempNode <> nil then begin
          if TempNode.NodeValue = 'Hero' then
            Attributes[i].UnitType := Hero
          else if TempNode.NodeValue = 'Infrantry' then
            Attributes[i].UnitType := Infantry
          else if TempNode.NodeValue = 'Ranged' then
            Attributes[i].UnitType := Ranged;
        end;

        // Size
        Attributes[i].Size := 4;
        TempNode := CurrentNode.ChildNodes.FindNode('size');
        if TempNode <> nil then
          Attributes[i].Size := TempNode.NodeValue;

        // Aggressivity
        Attributes[i].Aggressivity := PASSIVE;
        TempNode := CurrentNode.ChildNodes.FindNode('aggressivity');
        if TempNode <> nil then begin
          if TempNode.NodeValue = 'aggressive' then
          Attributes[i].Aggressivity := AGGRESSIVE
          else if TempNode.NodeValue = 'defensive' then
          Attributes[i].Aggressivity := DEFENSIVE
        end;

        // Damage
        Attributes[i].Damage := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('damage');
        if TempNode <> nil then
          Attributes[i].Damage := TempNode.NodeValue;

        // Speed
        Attributes[i].Speed := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('speed');
        if TempNode <> nil then
          Attributes[i].Speed := TempNode.NodeValue;

        // HP
        Attributes[i].HP := 100;
        TempNode := CurrentNode.ChildNodes.FindNode('hp');
        if TempNode <> nil then
          Attributes[i].HP := TempNode.NodeValue;

        // MP
        Attributes[i].MP := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('mp');
        if TempNode <> nil then
          Attributes[i].MP := TempNode.NodeValue;

        // HP Regen (HP/s)
        Attributes[i].HPRegen := 1;
        TempNode := CurrentNode.ChildNodes.FindNode('hpregen');
        if TempNode <> nil then
          Attributes[i].HPRegen := TempNode.NodeValue / 1000 * TURN_LENGTH;;

        // MP Regen (MP/s)
        Attributes[i].MPRegen := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('mpregen');
        if TempNode <> nil then
          Attributes[i].MPRegen := TempNode.NodeValue / 1000 * TURN_LENGTH;

        // Attack Speed
        Attributes[i].Atk_Speed := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('atk_speed');
        if TempNode <> nil then
          Attributes[i].Atk_Speed := TempNode.NodeValue div TURN_LENGTH;

        // Attack Range
        Attributes[i].Atk_Range := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('atk_range');
        if TempNode <> nil then
          Attributes[i].Atk_Range := TempNode.NodeValue;

        // Defense
        Attributes[i].Defense := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('defense');
        if TempNode <> nil then
          Attributes[i].Defense := TempNode.NodeValue;

        // Is Repairer
        Attributes[i].Repairer := False;
        TempNode := CurrentNode.ChildNodes.FindNode('repairer');
        if TempNode <> nil then
          Attributes[i].Repairer := TempNode.NodeValue;

        // Is Building
        Attributes[i].IsBuilding := False;
        TempNode := CurrentNode.ChildNodes.FindNode('isbuilding');
        if TempNode <> nil then
          Attributes[i].IsBuilding := TempNode.NodeValue;

        // Res1Cost
        Attributes[i].Res1Cost := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('res1cost');
        if TempNode <> nil then
          Attributes[i].Res1Cost := TempNode.NodeValue;

        // Res2Cost
        Attributes[i].Res2Cost := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('res2cost');
        if TempNode <> nil then
          Attributes[i].Res2Cost := TempNode.NodeValue;

        // Building Time
        Attributes[i].BuildingTime := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('buildingtime');
        if TempNode <> nil then
          Attributes[i].BuildingTime := TempNode.NodeValue div TURN_LENGTH;

        //Training
        Attributes[i].Training := 0;
        TempNode := CurrentNode.ChildNodes.FindNode('training');
        if TempNode <> nil then
        begin
          if TempNode.NodeValue = -1 then
            Attributes[i].Training := -1
          else
            Attributes[i].Training := (TempNode.NodeValue/1000)*TURN_LENGTH;//ressources par tour
        end;


        // Spells
        TempNode := CurrentNode.ChildNodes.FindNode('spells');
        if (TempNode <> nil) and (TempNode.HasChildNodes) then begin
          TempNode := TempNode.ChildNodes.First;
          j := 0;
          repeat
            if TempNode.NodeName = 'spellid' then begin
              SetLength(Attributes[i].Abilities, j + 1);
              k := 0;
              len := Length(Abilities);
              while (k < len) and (TempNode.NodeValue <> Abilities[k].id) do
                inc(k);
              if k = len then begin
                Log('Parsing Units.xml, Cannot find spell id `' + TempNode.NodeValue + '` on `' + Attributes[i].Name + '`');
                SetLength(Attributes[i].Abilities, j);
              end else begin
                Attributes[i].Abilities[j].Ability := @Abilities[k];
                Attributes[i].Abilities[j].Innate := False;
                if (TempNode.ChildNodes.FindNode('innate') <> nil)
                and (TempNode.ChildNodes['innate'].NodeValue = 'true') then
                  Attributes[i].Abilities[j].Innate := True;

                inc(j);
              end;
            end;
            TempNode := TempNode.NextSibling;
          until TempNode = nil;
        end;

        // Upgrades
        TempNode := CurrentNode.ChildNodes.FindNode('upgrades');
        if (TempNode <> nil) and (TempNode.HasChildNodes) then begin
          TempNode := TempNode.ChildNodes.First;
          j := 0;
          repeat
            if TempNode.NodeName = 'upgradeid' then begin
              SetLength(Attributes[i].Upgrades, j + 1);
              k := 0;
              len := Length(Upgrades);
              while (k < len) and (TempNode.NodeValue <> Upgrades[k].id) do
                inc(k);
              if k = len then begin
                Log('Parsing Units.xml, Cannot find upgrade id `' + TempNode.NodeValue + '` on `' + Attributes[i].Name + '`');
                SetLength(Attributes[i].Upgrades, j);
              end else begin                    
                Attributes[i].Upgrades[j] := @Upgrades[k];
                inc(j);
              end;
            end;
            TempNode := TempNode.NextSibling;
          until TempNode = nil;
        end;
             
        inc(i);
      end;

      CurrentNode := CurrentNode.NextSibling;
    until CurrentNode = nil;


    i := 0;
    CurrentNode := GlWindow.Document.DocumentElement.ChildNodes.First;
    repeat
      if CurrentNode.NodeName = 'unit' then begin
        // Buildings
        TempNode := CurrentNode.ChildNodes.FindNode('buildings');
        if (TempNode <> nil) and (TempNode.HasChildNodes) then begin
          TempNode := TempNode.ChildNodes.First;
          j := 0;
          repeat
            if TempNode.NodeName = 'buildingid' then begin
              SetLength(Attributes[i].Buildings, j + 1);
              k := 0;
              len := Length(Attributes);
              while (k < len) and (TempNode.NodeValue <> Attributes[k].id) do
                inc(k);
              if k = len then begin
                Log('Parsing Units.xml, Cannot find building id `' + TempNode.NodeValue + '` on `' + Attributes[i].Name + '`');
                SetLength(Attributes[i].Buildings, j);
              end else begin
                Attributes[i].Buildings[j] := @Attributes[k];

                inc(j);
              end;
            end;
            TempNode := TempNode.NextSibling;
          until TempNode = nil;
        end;
        inc(i);
      end;
      CurrentNode := CurrentNode.NextSibling;
    until CurrentNode = nil;
  end;

  GlWindow.Document.Active := False;
end;

procedure LoadAbilities();
var
  i : integer;
  tmp : string;
  Node : IXMLNode;
begin
	GlWindow.Document.LoadFromFile('Data/abilities.xml');
  Node := GlWindow.Document.DocumentElement.ChildNodes.First;
  i := 0;
  repeat
    try
      SetLength(Abilities, i + 1);
      Abilities[i].Name := Node.ChildNodes['name'].Text;
      Abilities[i].ToolTip := Node.ChildNodes['tooltip'].Text;
      Abilities[i].Icon := Node.ChildNodes['icon'].Text;
      tmp := Node.ChildNodes['shortcut'].Text;
      Abilities[i].Shortcut := tmp[1];
      Abilities[i].ID := Node.ChildNodes['id'].NodeValue;
      tmp := Node.ChildNodes['target'].NodeValue;
      if tmp = 'Friendly' then
        Abilities[i].Target := Friendly
      else if tmp = 'Enemy' then
        Abilities[i].Target := Enemy
      else
        Abilities[i].Target := Myself;
      tmp := Node.ChildNodes['areaeffecttarget'].NodeValue;
      if tmp = 'Friendly' then
        Abilities[i].AreaEffectTarget := Friendly
      else
        Abilities[i].AreaEffectTarget := Enemy;
      Abilities[i].Range  := Node.ChildNodes['range'].NodeValue;
      Abilities[i].AreaEffect  := Node.ChildNodes['areaeffect'].NodeValue;
      Abilities[i].Duration := Node.ChildNodes['duration'].NodeValue div TURN_LENGTH;
      Abilities[i].cooldown := Node.ChildNodes['cooldown'].NodeValue div TURN_LENGTH;
      Abilities[i].Cost := Node.ChildNodes['cost'].NodeValue;
      New(Abilities[i].Instant);
      Abilities[i].Instant.Size := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('size').NodeValue;
      Abilities[i].Instant.Hp := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('hp').NodeValue;
      Abilities[i].Instant.Attack := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('attack').NodeValue;
      Abilities[i].Instant.Defense := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('defense').NodeValue;
      Abilities[i].Instant.Damage := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('damage').NodeValue;
      Abilities[i].Instant.Speed := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('speed').NodeValue;
//      tmp := Node.ChildNodes.FindNode('instanteffect').ChildNodes.FindNode('special').Text;
//      if tmp <> '' then
//        Abilities[i].Instant.Special := @Whirlwind
//      else
//        Abilities[i].Instant.Special := nil;
      Abilities[i].tick := Node.ChildNodes['tick'].NodeValue div TURN_LENGTH;
      New(Abilities[i].Periodic);
      Abilities[i].Periodic.Size := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('size').NodeValue;
      Abilities[i].Periodic.hp := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('hp').NodeValue;
      Abilities[i].Periodic.Attack := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('attack').NodeValue;
      Abilities[i].Periodic.Defense := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('defense').NodeValue;
      Abilities[i].Periodic.Damage := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('damage').NodeValue;
      Abilities[i].Periodic.Speed := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('speed').NodeValue;
       tmp := Node.ChildNodes.FindNode('periodiceffect').ChildNodes.FindNode('special').Text;
//      if tmp <> '' then
//      begin
//        Abilities[i].Periodic.Special := @Whirlwind;
//        Abilities[i].CancelSpecial := @WhirlwindCancel;
//      end
//      else
//      begin
//        Abilities[i].Periodic.Special := nil;
//        Abilities[i].CancelSpecial := nil;
//      end;
      inc(i);
    except

    end;
    Node := Node.NextSibling;
  until Node = nil;
  GlWindow.Document.Active := False;
end;

procedure LoadUpgrades();
var
  i : integer;
  Node : IXMLNode;
begin
	GlWindow.Document.LoadFromFile('Data/upgrades.xml');
  Node := GlWindow.Document.DocumentElement.ChildNodes.First;
  i := 0;
  repeat
    try
      SetLength(Upgrades, i + 1);
      Upgrades[i].Name := Node.ChildNodes['name'].Text;
      Upgrades[i].Icon := Node.ChildNodes['icon'].Text;
      Upgrades[i].ID := Node.ChildNodes['id'].NodeValue;
      Upgrades[i].targetsID  := Node.ChildNodes['targetsid'].NodeValue;
      Upgrades[i].Res1Cost := Node.ChildNodes['res1cost'].NodeValue;
      Upgrades[i].Res2Cost := Node.ChildNodes['res2cost'].NodeValue;
      New(Upgrades[i].Effects);
      Upgrades[i].Effects.size := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('size').NodeValue;
      Upgrades[i].Effects.hp := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('hp').NodeValue;
      Upgrades[i].Effects.Attack := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('attack').NodeValue;
      Upgrades[i].Effects.Defense := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('defense').NodeValue;
      Upgrades[i].Effects.Damage := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('damage').NodeValue;
      Upgrades[i].Effects.Speed := Node.ChildNodes.FindNode('effects').ChildNodes.FindNode('speed').NodeValue;
      Upgrades[i].ToolTip := Node.ChildNodes['tooltip'].Text;
      inc(i);
    except

    end;
    Node := Node.NextSibling;
  until Node = nil;
  GlWindow.Document.Active := False;
end;

end.
