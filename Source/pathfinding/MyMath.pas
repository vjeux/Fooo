unit MyMath;

interface

{
  [2.1.1]
  calcule la moyenne des entiers de l'entree standard
  jusqu'a ce que l'entier -1 soit recontre
}
function Moyenne(): integer;


{
  [2.1.2]
  retourne le resultat de n!
}
function Factorielle(n : integer): integer;


{
  [2.1.3]
  calcule x a la puissance n (x et n entiers)
}
function Puissance(x, n : integer):integer;

  //retourne le carré d'un entier
function pow2(x : integer) : integer;


{
  [2.1.4]
  retourne le PGCD de a et b
}
function PGCD(a, b : integer): integer;


{
  [2.1.5]
  affiche les n premiers nombres premiers
}
procedure PremiersPremiers(n : integer);

{
  determine si un nombre est premier, ou pas
}
function est_premier(n : integer): boolean;

{
  valeur absolue d'un entier
}
function int_abs(n : integer): integer;

{
  maximum de 2 entiers
}
function max(a, b : integer): integer overload;

{
  minimum de 2 entiers
}
function min(a, b : integer): integer overload;


  //retourne la moitié de a
function half(n : integer) : integer;

  //retourne 1 si a > b, -1 si a < b, 0 si a = b
function intComp(a, b : integer): integer;

function randpercent(value, percent : integer) : integer;
function randinter(binf, bsup : integer) : integer;

const sqrt2 = 1.4142;


//------------------------

implementation
uses
  FLogs, SysUtils;

//------------------------



function Moyenne(): integer;
var somme, n, nb : integer;
stop : boolean;
begin

  somme := 0;
  nb    := 0;
  stop  := false;

  repeat
    readln(n);

    if n = -1 then
      stop := true
    else
    begin
      somme := n + somme;
      nb := nb + 1;
    end;

  until stop;

  result := somme div nb;
end;



function Factorielle(n : integer): integer;
begin
  Result := 1;

  if n < 0 then
    Result := -1  //factorielle doit etre positive ou nulle
  else
    while n > 1 do
    begin
      Result := Result * n;
      n := n - 1;
    end;
end;



function Puissance(x, n : integer):integer;
begin
  Result := 1;        //si on ne rentre pas dans la boucle le resultat est 1
  if n < 0 then
    Result := -1      //on ne s'occupe pas des puissances negatives
  else
    while n > 0 do
    begin
      Result := x * Result;
      if n mod 2 = 0 then
      begin
        x := Result;  //si la puissance est paire, on remplace x par x*x
        n := (n div 2); //et on divise la puissance par 2 : x^2n = (x^2)^n
      end;
      n := n - 1;
    end;
end;



function PGCD(a, b : integer): integer;
begin
    while b <> 0 do
    begin
      Result := a; //on utilise Result comme var temp, ca poutre nan ?
      a := b;
      b := Result mod b;
    end;
    Result := a;
end;



function est_premier(n : integer): boolean;
var i : integer;
begin
  i       := 1;
  Result  := True;
  while (i * i < n) and Result do // on va jusau'a la racine de n max
  begin
    i := i + 1;
    Result := (n mod i <> 0);
  end;
end;



procedure PremiersPremiers(n : integer);
var i, nb : integer;
begin
  i   := 1;
  nb  := 0;
  while nb < n do
  begin
    if est_premier(i) then
    begin
      nb := nb + 1;
      write(i, ' ');
    end;
    i := i + 1;
  end;
end;



function int_abs(n : integer): integer;
begin
  if n < 0 then
    Result := -n
  else
    Result := n;
end;



function max(a, b : integer): integer;
begin
  if a > b then
    Result := a
  else
    Result := b;
end;



function min(a, b : integer): integer;
begin
  if a < b then
    Result := a
  else
    Result := b;
end;


function intComp(a, b : integer): integer;
begin
  if a > b then
    Result := 1
  else
  begin
    if a < b then
      Result := -1
    else
      Result := 0;
  end;
end;


function pow2(x : integer) : integer;
begin
  if abs(x) > 46340 then begin
    Log('Integer Overflow ! ' + IntToStr(x));
    Result := 1;
    exit;
  end;

  Result := x * x;
end;


function half(n : integer) : integer;
begin
  if n  > 0 then
    Result := n shr 1
  else
    Result := n div 2;
end;

function randinter(binf, bsup : integer) : integer;
begin
  result := binf + Random(bsup - binf);
end;

function randpercent(value, percent : integer) : integer;
var
  valper : integer;
begin
  valper := percent*value div 100;
  result := randinter(value - valper, value + valper);
end;
end.
