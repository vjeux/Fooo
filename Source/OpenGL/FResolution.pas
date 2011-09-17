unit FResolution;

interface
uses
  Windows, Forms;

var
  Resolution : record
    Windowed : boolean;
    FullScreen : boolean;
    Width : integer;
    Height : integer;
  end;

procedure ChangeResolution();
procedure InitResolution();
procedure ResetResolution();

implementation
uses
  FLogs, sysutils, FGlWindow, FConfig;

procedure ResetResolution();
begin
  if Resolution.FullScreen and not Resolution.Windowed then
    ChangeDisplaySettings(devmode(nil^), 0);
end;

procedure ChangeResolution();
var
  dmScreenSettings : DevMode;
begin
  if Resolution.FullScreen then begin
    GlWindow.BorderStyle := bsNone;
    GlWindow.WindowState := wsMaximized;

    if not Resolution.Windowed then begin
      ZeroMemory(@dmScreenSettings, SizeOf(dmScreenSettings));
      with dmScreenSettings do begin
        dmSize       := SizeOf(dmScreenSettings);
        dmPelsWidth  := Resolution.Width;
        dmPelsHeight := Resolution.Height;
        dmBitsPerPel := 32;
        dmFields     := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
      end;
      ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN);
    end;
  end else begin
    GlWindow.BorderStyle := bsSizeable;
    GlWindow.WindowState := wsNormal;
  end;
end;

procedure InitResolution();
var
  cfg : TConfig;
begin
  cfg := TConfig.create;
  if not FileExists('Fooo.cfg') then begin
    cfg.set_resolution(1024, 768);
    cfg.set_windowed(true);
    cfg.set_fullscreen(false);
  end;
  Resolution.Windowed := cfg.get_windowed;
  Resolution.FullScreen := cfg.get_fullscreen;
  Resolution.Width := cfg.get_Wresolution;
  Resolution.Height := cfg.get_Hresolution;
end;

end.
