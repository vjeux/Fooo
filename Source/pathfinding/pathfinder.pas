unit pathfinder;

interface

uses node, pqueue, myQueue, game_env, point, my_swap, 
  Windows, classes, SysUtils, Math, Funit;

  
type

  Plist = ^Tlist;

  Pcalc = ^Tcalc;

  Tcalc = record
    node : Pointer;
    stat : integer;
  end;

  TcalcMap = array of array of Tcalc;

  Tastar = class
    public
      Constructor Create(wi, hi : integer);
        //returns a pointer to a TmyQueue containing pointers of Tpoints
      Function Astar(u : Punit): PMyQueue;
        //should be called at the end of a game
      procedure kill();
    private
      cmap        : TcalcMap;
      Open, close : integer;
      openList    : Tpqueue;
      Env         : Tenv;

        //returns the Astar closest node from finish
      function find_path(start, finish: Tpoint; minDist2 : integer): Pnode;

        //make a list of Tpoint pointers from a node
      procedure make_path(p: Pnode;var li : Tlist);

        //removes useless nodes and straighten path
      procedure arrange_path(var li: TList; inf, sup: integer);

        //transforms the list into a queue
      function queue_points(var li : Tlist): PMyQueue;

        //used when open/close values are too high
      procedure reset_openClose();

        //tells if a straight move is possible
      function straight_move(depart, arrivee: Tpoint):boolean;
  end;

Var
  pathfind : Tastar;


implementation


uses
  Fdata, FInterfaceDraw, MyMath;


  //used because pointers in open list do not need to be freed
procedure do_nothing(var p : pointer);
begin
end;



Constructor Tastar.Create(wi, hi : integer);
var
  i           : Integer;
  j           : Integer;
  comp_func   : Tcomp_func;
  free_func   : Tfree_func;
begin
    //init calc_map
  setlength(Self.cmap, wi, hi);
  Self.Env := Tenv.create(wi, hi);

  for i := 0 to wi - 1 do
    for j := 0 to hi - 1 do
    begin
      new(Pnode(Self.cmap[i, j].node));
      Tnode(Self.cmap[i, j].node^).pos.x := i;
      Tnode(Self.cmap[i, j].node^).pos.y := j;
    end;

  Self.reset_openClose;

    //init open list priority queue
  comp_func       := weight_comp;
  free_func       := do_nothing;
  Self.openlist   := TpQueue.Create((wi * hi) shr 3, comp_func, free_func);
end;



procedure Tastar.reset_openClose();
var
  i: Integer;
  j: Integer;
begin
   for i := 0 to env.width - 1 do
    for j := 0 to env.height - 1 do
      Self.cmap[i, j].stat := 0;

  Self.open  := 1;
  Self.close := 2;
end;



procedure Tastar.kill;
var
  i: Integer;
  j: Integer;
begin
   for i := 0 to env.width - 1 do
    for j := 0 to env.height - 1 do
      dispose(Self.cmap[i, j].node);

    Self.openList.Destroy;
end;



function Tastar.Astar(u : Punit): PMyQueue;
var
  last_node : Pnode;
  list      : Tlist;
begin
    //init open/close values
  Self.open := Self.open + 2;
  Self.close := Self.Open + 1;
  if Self.Open >= MaxInt - 2 then
    Self.reset_openClose;

  Self.env.init(u);

    //empty open list
  Self.openList.clear;

    //make the astar and get it's last node
  last_node := find_path(u^.pos, u^.get_dest, pow2(u^.get_action_dist));

  list := Tlist.Create;

    //make the list from the node
  make_path(last_node, list);

    //arrange path to make it smoother
  //arrange_path(list, 0, list.Count - 1);

  Result := Self.queue_points(list);
end;



function Tastar.queue_points(var li : Tlist): PMyQueue;
var
  i   : integer;
begin
   new(Result);
  Result^ := TMyQueue.Create;

  for i := li.Count - 1 downto 0 do
    Result^.push(li[i]);

  li.Destroy;
end;



function Tastar.find_path(start, finish: Tpoint; minDist2 : integer): Pnode;
var
i, j        : integer;
tmp_n       : Tnode;
curr_node   : Pnode;
curr_cal    : Pcalc;
curr_pos    : Tpoint;
reached     : boolean;

begin

//init start node
  curr_node := Pnode(cmap[start.x, start.y].node);
  curr_node^.parent := nil;
  Pnode_make_cost(curr_node, finish);
//insert in open list
  cmap[start.x, start.y].stat := Self.Open;
  openList.insert(curr_node);

//contains closest node from finish
  Result := curr_node;

  reached := TpDist2(curr_node^.pos, finish) <= minDist2;//(pointCmp(curr_node^.pos, finish));
//while there are still some nodes to check
  while (openList.Count > 0) and not reached do
  begin
//pick best node
    openList.extract(Pointer(curr_node));
//switch from open list to close
    cmap[curr_node^.pos.x, curr_node^.pos.y].stat := Self.close;

    reached := TpDist2(curr_node^.pos, finish) <= minDist2;//(pointCmp(curr_node^.pos, finish));
//for each node around current_node
    if not reached then
      for i := -1 to 1 do
        for j := -1 to 1 do
          if (i <> 0) or (j <> 0) then
          begin
            curr_pos.x := curr_node^.pos.x + i;
            curr_pos.y := curr_node^.pos.y + j;

//if position reachable and not in close list
            if (env.can_access(curr_node^.pos, curr_pos))
            and (cmap[curr_pos.x, curr_pos.y].stat <> Self.close) then
            begin
//init node at this position
              curr_cal := Pcalc(@(cmap[curr_pos.x, curr_pos.y]));
              tmp_n := Tnode(curr_cal^.node^);
              Pnode(curr_cal^.node)^.parent := curr_node;
              Pnode_make_cost(Pnode(curr_cal^.node), finish);
//if its in open list              
              if (curr_cal^.stat = Self.Open) then
              begin
//and its parent was better than current_node
                if tmp_n.g <= Pnode(curr_cal^.node)^.g then
                begin
//change the parent back
                  Pnode(curr_cal^.node)^.parent := tmp_n.parent;
                  Pnode_make_cost(curr_cal^.node, finish);
                end;
              end
              else
//if not in open list
              begin
//create node and add it
                openList.insert(curr_cal^.node);
                curr_cal^.stat := Self.Open;
              end;
//memorize node if closest from finish
              if Result.h > Pnode(curr_cal^.node)^.h then
                Result := curr_cal^.node;
                
           end;//correct point
          end;//not same point
  end;//main loop
end;




procedure Tastar.make_path(p: Pnode; var li : Tlist);
var
last_dir  : Tpoint;
direction : Tpoint;
new_pos   : Ppoint;
begin
  last_dir.x := 0;
  last_dir.y := 0;

  while (p <> nil) do
  begin
    if p^.parent <> nil then
    begin
      direction := Tpoint_way(p^.pos, p^.parent^.pos);
      if not pointCmp(direction, last_dir) then
      begin
        new(new_pos);
        new_pos^.x := p^.pos.x;
        new_pos^.y := p^.pos.y;
        li.Add(new_pos);
      end;
    end;

    p := p^.parent;
    last_dir  := direction;
  end;
end;


procedure Tastar.arrange_path(var li: TList; inf, sup: integer);
var i : integer;
begin
  if abs(inf - sup) > 1 then
  begin
      //if there's a shortcut, remove all extra nodes
    if straight_move(Tpoint(li[inf]^), Tpoint(li[sup]^)) then
      for i := inf + 1 to sup - 1 do
      begin
        addline('point ' + IntToStr(Tpoint(li[inf]^).x) + ', '
          + IntToStr(Tpoint(li[inf]^).y) + ' not needed, skipping');
        dispose(li[i]);
        li.Delete(i);
      end
    else
    begin
        //take a value in the middle
      i := (sup + inf) shr 1;
      arrange_path(li, inf, i);
      arrange_path(li, i, sup);
    end;
  end;
end;


function Tastar.straight_move(depart,arrivee: Tpoint):boolean;
var
i, j      : integer;
borne     : integer;
x1, y1    : integer;
x2, y2 	  : integer;

tmp       : real;
bornemin  : real;
bornemax  : real;
factor    : real;
begin

	if (depart.x > arrivee.x) then
		swap(depart, arrivee);

	x1 := (1 + depart.x shl 1) shr 1;
	y1 := (1 + depart.y shl 1) shr 1;
	x2 := (1 + arrivee.x shl 1) shr 1;
	y2 := (1 + arrivee.y shl 1) shr 1;
	Result := true;

	if x2 = x1 then
	begin
		i := depart.y;
		while (i <= arrivee.y) and Result do
		begin
			Result := env.is_empty(depart.x, i);
			i := i + 1;
		end;
	end
	else
  begin
    factor := (y2 - y1) / (x2 - x1);
		i := depart.Y;
		while (i <= arrivee.y) and Result do
		begin
			bornemin := y1 + floor(factor*(i - x1));
			bornemax := y1 + floor(factor*(i + 1 - x1));

			// swap la plus petite valeur dans "borne mini", et la plus grande dans "borne max"
			if bornemin > bornemax then
      begin
        tmp := bornemin;
        bornemin := bornemax;
        bornemax := tmp;
      end;
      
    		// test necessaire pour certaines collisions d'angles
			if (bornemin = floor(bornemin))then
				bornemin := bornemin - 1;

      tmp := Math.min(Depart.y, Arrivee.y);
			bornemin := Math.max(bornemin, tmp);
			bornemax := Math.min(bornemax, Math.max(Depart.y, Arrivee.y));

			borne := floor(bornemax);
			j 	  := floor(bornemin);
			while (j <= borne) and Result do
				Result := env.is_empty(i,j);

			i := i + 1;
		end;
  end;
end;

end.
