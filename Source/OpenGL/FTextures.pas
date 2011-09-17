unit FTextures;

interface

uses
	Windows, FOpenGL, Classes, SysUtils, FLogs;

var
	LoadedTextures : TList;
  BlankGLID : GLuint;
  TransparentGLID : GLuint;
  CircleGLID : GLuint;

type
  PTTexture = ^TTexture;
  TTexture = record
    Path : string;
    GLID : GLuint;
  end;

procedure InitTextures();                                             
function LoadTexture(path: string) : GLuint; overload;
function LoadTexture(Filename: string; var Texture: GLuint): Boolean; overload;
procedure BindTexture(id : GLuint);  
procedure FreeTextures();

implementation

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;


procedure InitTextures();
begin
  LoadedTextures := TList.Create();
  BlankGLID := LoadTexture('Textures/Shared/Blank.blp');
  TransparentGLID := LoadTexture('Textures/Shared/Transparent.blp');
  CircleGLID := LoadTexture('Textures/Shared/Circle.blp');
end;

procedure FreeTextures();
var
  i : integer;
begin
  for i := 0 to LoadedTextures.Count - 1 do
    glDeleteTextures(1, @PTTexture(LoadedTextures[i])^.GLID);
  LoadedTextures.Destroy();
  LoadedTextures := TList.Create();
end;

function LoadTexture(path: string) : GLuint; overload;
var
  index, len : integer;
  t : PTTexture;
begin
	if path <> '' then begin
    index := 0;
    len := LoadedTextures.Count;
    while (index < len) and (PTTexture(LoadedTextures.Items[index])^.Path <> path) do
      Inc(index);

		if (index = len) then begin
      New(t);
      t^.Path := copy(path, 0, length(path)-3) + 'tga';
      LoadTexture(t^.Path, t^.GLID);
      LoadedTextures.Add(t);
      Result := t^.GLID;
		end else begin
      Result := PTTexture(LoadedTextures.Items[index])^.GLID;
    end;
	end else
    Result := 0;
end;

procedure BindTexture(id : GLuint);
begin
  glBindTexture(GL_TEXTURE_2D, id);
end;

//----------------------------------------------------------------------------
// Author      : Jan Horn
// Email       : jhorn@global.co.za
// Website     : http://home.global.co.za/~jhorn
// Version     : 1.01
// Date        : 1 May 2001
//----------------------------------------------------------------------------
procedure CreateTexture(var Texture: GLuint; Width, Height, Format : Word; pData : Pointer);
begin
  glGenTextures(1, Texture);
  glBindTexture(GL_TEXTURE_2D, Texture);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  if Format = GL_RGBA then
    gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, Width, Height, GL_RGBA, GL_UNSIGNED_BYTE, pData)
  else
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, Width, Height, GL_RGB, GL_UNSIGNED_BYTE, pData);
end;

function LoadTexture(Filename: string; var Texture: GLuint): Boolean;
var
  TGAHeader : packed record   // Header type for TGA images
    FileType     : Byte;
		ColorMapType : Byte;
    ImageType    : Byte;
    ColorMapSpec : Array[0..4] of Byte;
    OrigX  : Array [0..1] of Byte;
    OrigY  : Array [0..1] of Byte;
    Width  : Array [0..1] of Byte;
    Height : Array [0..1] of Byte;
    BPP    : Byte;
    ImageInfo : Byte;
  end;
  TGAFile   : File;
  bytesRead : Integer;
  image     : Pointer;    {or PRGBTRIPLE}
  Width, Height : Integer;
  ColorDepth    : Integer;
  ImageSize     : Integer;
  I : Integer;
  Front: ^Byte;
  Back: ^Byte;
  Temp: Byte;
begin
	Result := True;

  if not FileExists(Filename) then begin
    Log('Error: File not found `' + Filename + '`');
    Result := False;
    Exit;
  end;

  AssignFile(TGAFile, Filename);
  Reset(TGAFile, 1);

  // Read in the bitmap file header
  BlockRead(TGAFile, TGAHeader, SizeOf(TGAHeader));

  // Only support uncompressed images
  if (TGAHeader.ImageType <> 2) then begin { TGA_RGB }
    Result := False;
    CloseFile(TgaFile);
    Log('Couldn''t load "'+ Filename +'". Compressed TGA files not supported.');
    Exit;
  end;

  // Don't support colormapped files
  if TGAHeader.ColorMapType <> 0 then begin
    Result := False;
    CloseFile(TGAFile);
    Log('Couldn''t load "'+ Filename +'". Colormapped TGA files not supported.');
    Exit;
  end;

  // Get the width, height, and color depth
  Width  := TGAHeader.Width[0]  + TGAHeader.Width[1]  * 256;
  Height := TGAHeader.Height[0] + TGAHeader.Height[1] * 256;
  ColorDepth := TGAHeader.BPP;
  ImageSize  := Width * Height * (ColorDepth div 8);

  if ColorDepth < 24 then begin
    Result := False;
    CloseFile(TGAFile);
    Log('Couldn''t load "'+ Filename +'". Only 24 bit TGA files supported.');
    Exit;
  end;

  GetMem(Image, ImageSize);

  BlockRead(TGAFile, image^, ImageSize, bytesRead);
  if bytesRead <> ImageSize then begin
    Result := False;
    CloseFile(TGAFile);
    Log('Couldn''t read file "'+ Filename +'".');
    Exit;
  end;

  // TGAs are stored BGR and not RGB, so swap the R and B bytes.
  // 32 bit TGA files have alpha channel and gets loaded differently
  if TGAHeader.BPP = 24 then begin
    for i := 0 to Width * Height - 1 do begin
      Front := Pointer(Integer(Image) + i * 3);
			Back := Pointer(Integer(Image) + i * 3 + 2);
      Temp := Front^;
			Front^ := Back^;
			Back^ := Temp;
		end;
		CreateTexture(Texture, Width, Height, GL_RGB, Image);
	end else begin
		for i := 0 to Width * Height - 1 do begin
			Front := Pointer(Integer(Image) + i * 4);
			Back := Pointer(Integer(Image) + i * 4 + 2);
			Temp := Front^;
			Front^ := Back^;
			Back^ := Temp;
		end;
		CreateTexture(Texture, Width, Height, GL_RGBA, Image);
  end;
  FreeMem(Image);   
  CloseFile(TGAFile);
end;

end.
