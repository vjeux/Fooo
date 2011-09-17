unit pqueue;

interface


type

    //type of the function used to compare elements
Tcomp_func = function(p1, p2: pointer): integer;


    //type of the function used to free elements
Tfree_func = procedure (var p: pointer);


    //array type that will hold elements as a binary tree (used like a heap)
Ttree = array of Pointer;




TpQueue = class(Tobject)
  public
    constructor   create(max_size : integer; compare: Tcomp_func; free: Tfree_func);

    function    insert(p : pointer): integer;

    function    extract(var p : pointer): integer;

    function    peek(): pointer;

    function    count(): integer;

    procedure  clear();
  private
    size      : integer;
    max_size  : integer;
    comp_data : Tcomp_func;
    free_data : Tfree_func;
    tree      : Ttree;
end;



    //returns the index of the parent of a position
function TpQueue_parent(pos: integer): integer;

    //returns the index of the left child of a position
function TpQueue_left(pos: integer): integer;

    //returns the index of the right child of a position
function TpQueue_right(pos: integer): integer;


implementation



{ -------------- TpQueue methods implementations --------------- }

//init

  constructor TpQueue.create(max_size : integer; compare: Tcomp_func; free: Tfree_func);
  begin
    Self.size       := 0;
    Self.max_size   := max_size;
    setlength(Self.tree, Self.max_size);

    Self.comp_data  := compare;
    Self.free_data  := free;
  end;


//peek
  function TpQueue.peek(): pointer;
  begin
    if Self.size > 0 then
      Result := tree[0]
    else
      Result := nil;
  end;


//count
  function TpQueue.count(): integer;
  begin
    Result := Self.size;
  end;


//clear
  procedure TpQueue.clear;
  var i : integer;
  begin    
    for i := 0 to Self.size - 1 do
      Self.free_data(tree[i]);

    Self.size := 0;
  end;



//insert
  function TpQueue.insert(p: Pointer): integer;
  var
    tmp   : Pointer;
    ppos  : integer;
    ipos  : integer;
  begin
      //checl if the new node can fit
    if Self.size >= max_size then
      Result := -1
    else
    begin

        //inserts element after last node
      tree[Self.size] := p;

      ipos := Self.size;
      ppos := TpQueue_parent(ipos);

        //move the new node up until it's closer than it's parent
      while (ipos > 0) do
      begin
        if (Self.comp_data(tree[ppos], tree[ipos]) >= 0)  then
          break;

          //swap both node and parent
        tmp := tree[ppos];
        tree[ppos] := tree[ipos];
        tree[ipos] := tmp;

          //then go up to new parent
        ipos := ppos;
        ppos := TpQueue_parent(ipos);
      end;

      Self.size := Self.size + 1;

        //everything went well
      Result := 0;
    end;
    
  end;


//extract first node in p parameter and reorder the queue
  function TpQueue.extract(var p: Pointer): integer;
  var
    tmp   : pointer;
    go    : boolean;

    ipos  : integer;
    lpos  : integer;
    rpos  : integer;
    mpos  : integer;
  begin

      //can't extract from an empty queue
    if Self.size = 0 then
      Result := -1
    else
    begin
        //put the first element into p
      p := tree[0];


        //update size
      Self.size := Self.size - 1;

        //if we didn't take the last node, reorder the queue
      if Self.size > 0 then
      begin
          //move the last node to the top before we lose it
        tree[0] := tree[size];

        ipos  := 0;
        go    := true;

        while(go) do
        begin
          lpos := TpQueue_left(ipos);
          rpos := TpQueue_right(ipos);

            //chose the child to swap with
          if (lpos < Self.size)
          and (Self.comp_data(tree[lpos], tree[ipos]) > 0) then
            mpos := lpos
          else
            mpos := ipos;

          if (rpos < Self.size) then
          if (Self.comp_data(tree[rpos], tree[mpos]) > 0) then
            mpos := rpos;

            //when ipos = mpos, the queue is in a correct ordrer
          if mpos = ipos then
            go := false
          else
          begin
              //swap node and chosen child
            tmp := tree[mpos];
            tree[mpos] := tree[ipos];
            tree[ipos] := tmp;

              //and go down one level
            ipos := mpos;
          end;
        end; //while
      end; //size > 0

        //everything went well
      Result := 0;
    end;
  end;


{ -------------- TpQueue related functions --------------- }

  { Since we use an array to store the priority queue,
    Parent, left child and right child positions are quite easy to calculate.
  }

//parent
  function TpQueue_parent(pos: integer): integer;
  begin
    //(pos - 1) / 2 : used shr instead of dividind by 2 (faster)
    Result := (pos - 1) shr 1;
  end;


//left
  function TpQueue_left(pos: integer): integer;
  begin
    //(pos * 2) + 1 : used shl instead of multiplying by 2 (faster)
    Result := (pos shl 1) + 1;
  end;


//right
  function TpQueue_right(pos: integer): integer;
  begin
    //(pos * 2) + 2 : used shl instead of multiplying by 2 (faster)
    Result := (pos shl 1) + 2;
  end;


end.
