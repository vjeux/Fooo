unit FFPS;

interface
uses
 Windows, FLogs, SysUtils, FData, Math;

const
  MAX_ELAPSED = 100;
type
  TCount = Record
		Real : Int64;
    Now : Int64;
		Last : Int64;
		Frame : Integer;
  	FPS : Integer;
    Elapsed, ElapsedGlobal : Integer;
	end;

var
  Count : TCount;

procedure InitFPS();
procedure OnUpdateFPS();

implementation

uses
  FInterfaceDraw;

procedure InitFPS();
begin
  Count.Last := GetTickCount();
  Count.Real := GetTickCount();
  Count.Elapsed := 0;
  Count.ElapsedGlobal := 0;
  Count.Frame := 0;
  Count.FPS := 0;
  Count.Now := 0;
end;

procedure OnUpdateFPS();
var
  Counter, Frequency, NewTime : int64;
begin
  QueryPerformanceCounter(Counter);
  QueryPerformanceFrequency(Frequency);
  NewTime := (Counter * 1000) div Frequency;

  Count.ElapsedGlobal := NewTime - Count.Real;
  if Count.ElapsedGlobal > MAX_ELAPSED then
    Count.Elapsed := MAX_ELAPSED
  else
    Count.Elapsed := Count.ElapsedGlobal;

  Count.Real := Count.ElapsedGlobal + Count.Real;
  Count.Now := Count.ElapsedGlobal + Count.Now;

	Inc(Count.Frame);

	if (Count.Real - Count.Last) > 1000 then begin
		Count.FPS := Trunc(Count.Frame * 1000 / (Count.Real - Count.Last));
		Count.Last := Count.Real;
		Count.Frame := 0;
	end;
end;

end.
