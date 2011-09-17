unit FLogs;

interface
uses
	SysUtils, Forms, FLua;

const
	LOG_DEBUG = 0;
	LOG_WARNING = 1;
	LOG_ERROR = 2;
                                                 
procedure InitLog();
procedure Log(msg: string; factor: Integer = 0);

implementation
uses
  FLuaFunctions, FInterfaceDraw;

function GetTime() : string;
begin
	Result := FormatDateTime('hh:mm:ss:zzz', Now());
end;

procedure InitLog();
var
	myFile : TextFile;
begin
	if not DirectoryExists('Logs') then
		MkDir('Logs');
	AssignFile(myFile, 'Logs/log.txt');
	ReWrite(myFile);

	Write(myFile, GetTime() + ' Initialisation' + #13#10);
	CloseFile(myFile);
end;

procedure Log(msg: string; factor: Integer=0);
var
	myFile : TextFile;
	pre : string;
begin
//  AddLine(msg);
	AssignFile(myFile, 'Logs/log.txt');
	Append(myFile);

	if factor = LOG_DEBUG then
		pre := 'Debug'
	else if factor = LOG_WARNING then
		pre := 'Warning'
	else if factor = LOG_ERROR then
		pre := 'Error';

	WriteLn(myFile, GetTime() + ' ' + pre + ': ' + msg);
	CloseFile(myFile);

	if factor = LOG_ERROR then begin
		Raise Exception.Create(msg);
		Application.Terminate;
	end;
end;

end.

