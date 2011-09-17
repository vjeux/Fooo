unit FConfig;

interface

const
  CONFIG = '.cfg';

type
  TConfig = class
    private

    public
      function get_Hresolution() : integer;
      function get_Wresolution() : integer;
      function get_windowed()    : boolean;
      function get_fullscreen()  : boolean;
      function get_nick() : string;
      function get_serverName() : string;

      procedure set_resolution(Width, Height : integer);
      procedure set_Hresolution(Height : integer);
      procedure set_Wresolution(Width : integer);
      procedure set_windowed(windowed : boolean);
      procedure set_fullscreen(fullscreen : boolean);
      procedure set_nick(nick : string);
      procedure set_serverName(name : string);
  end;

implementation

uses
  IniFiles, windows, sysutils, forms;

function TConfig.get_Hresolution() : integer;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadInteger('Resolution', 'Resolution.Height', 1024);
  ini.Free;
end;

function TConfig.get_Wresolution() : integer;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadInteger('Resolution', 'Resolution.Width', 1024);
  ini.Free;
end;

function TConfig.get_windowed() : boolean;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadBool('Resolution', 'Windowed', true);
  ini.Free;
end;

function TConfig.get_fullscreen() : boolean;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadBool('Resolution', 'Fullscreen', false);
  ini.Free;
end;


procedure TConfig.set_resolution(Width, Height : integer);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteInteger('Resolution', 'Resolution.Width', Width);
  ini.WriteInteger('Resolution', 'Resolution.Height', Height);
  ini.Free;
end;

procedure TConfig.set_Hresolution(Height : integer);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteInteger('Resolution', 'Resolution.Height', Height);
  ini.Free;
end;

procedure TConfig.set_Wresolution(Width : integer);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteInteger('Resolution', 'Resolution.Width', Width);
  ini.Free;
end;

procedure TConfig.set_windowed(windowed : boolean);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteBool('Resolution', 'Windowed', windowed);
  ini.Free;
end;

procedure TConfig.set_fullscreen(fullscreen : boolean);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteBool('Resolution', 'Fullscreen', fullscreen);
  ini.Free;
end;

procedure TConfig.set_nick(nick: string);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteString('Player info', 'Nickname', nick);
  ini.Free;
end;

function TConfig.get_nick() : string;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadString('Player info', 'Nickname', 'Unknown soldier');
  ini.Free;
end;

function TConfig.get_serverName() : string;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  result := ini.ReadString('Player info', 'Default server name', 'Fooo server');
  ini.Free;
end;

procedure TConfig.set_serverName(name : string);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, CONFIG));
  ini.WriteString('Player info', 'Default server name', name);
  ini.Free;
end;

end.
