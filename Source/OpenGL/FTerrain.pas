unit FTerrain;

interface
uses
	FOpenGl;

type
	TTile = Record
		path : string;
		is_square : boolean;
	end;

  TSquares = record
    vertex  : array of GLFloat;
    texture : array of GLFloat;
    color : array of GLFloat;
  end;


var
  DispTerrain : TSquares;
  TerrainGLID : GLuint;

const
	TerrainSize = 80;
	TileSize = 96;
	TileFactor = 20;

procedure InitTerrain();
procedure DrawTerrain();
procedure StoreTile(x, y : integer; tile : TTile; ix : integer; iy : integer);

implementation
uses
  FTextures, SysUtils, FFrustum, FBase, FLogs;
  
procedure InitTerrain();
var
	i, j, w : Integer;
	tile : TTile;
begin              
	tile.path := 'Textures/Terrain/Ashen_Grass.blp';
	tile.is_square := false;  
  TerrainGLID := LoadTexture(tile.path);

  SetLength(DispTerrain.vertex, (TerrainSize * TerrainSize) * 12);
  SetLength(DispTerrain.texture, (TerrainSize * TerrainSize)* 8);
	for i := 0 to TerrainSize - 1 do begin
		for j := 0 to TerrainSize - 1 do begin
			w := Random(TileFactor + 3);
			if w <= TileFactor then
				w := 0
			else
        Dec(w, TileFactor);

      StoreTile(i, j, tile, w + 4, Random(4));
		end;
	end;
end;

procedure StoreTile(x, y : integer; tile : TTile; ix : integer; iy : integer);
var
	max, n : integer;
begin
	if tile.is_square then
		max := 4
	else
		max := 8;

  n := (x * TerrainSize) + y;

  DispTerrain.vertex[n*8 + 0] := x * TileSize + 0;
  DispTerrain.vertex[n*8 + 1] := (y + 1) * TileSize;

  DispTerrain.vertex[n*8 + 2] := (x + 1) * TileSize;
  DispTerrain.vertex[n*8 + 3] := (y + 1) * TileSize;

  DispTerrain.vertex[n*8 + 4] := (x + 1) * TileSize;
  DispTerrain.vertex[n*8 + 5] := y * TileSize;

  DispTerrain.vertex[n*8 + 6]  := x * TileSize;
  DispTerrain.vertex[n*8 + 7] := y * TileSize;

  DispTerrain.texture[n*8 + 0] := ix / max;
  DispTerrain.texture[n*8 + 1] := (iy + 1) / 4;

  DispTerrain.texture[n*8 + 2] := (ix + 1) / max;
  DispTerrain.texture[n*8 + 3] := (iy + 1) / 4;

  DispTerrain.texture[n*8 + 4] := (ix + 1) / max;
  DispTerrain.texture[n*8 + 5] := iy / 4;

  DispTerrain.texture[n*8 + 6] := ix / max;
  DispTerrain.texture[n*8 + 7] := iy / 4;
end;

procedure DrawTerrain();
var
	i, j, n : Integer;
  first: array of Integer;
begin
  n := 0;
  SetLength(first, TerrainSize * TerrainSize * 4);
	for i := 0 to TerrainSize - 1 do begin
		for j := 0 to TerrainSize - 1 do begin                           // Sqrt(2)/2
			if (SphereInFrustum((i + 0.5) * TileSize, (j + 0.5) * TileSize, 0, 0.7071 * TileSize)) then begin
        first[n*4 + 0] := ((i * TerrainSize) + j) * 4;
        first[n*4 + 1] := ((i * TerrainSize) + j) * 4 + 1;
        first[n*4 + 2] := ((i * TerrainSize) + j) * 4 + 2;
        first[n*4 + 3] := ((i * TerrainSize) + j) * 4 + 3;
        Inc(n);
      end;
		end;
	end;
  SetLength(first, 4 * n);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

 	glEnable(GL_TEXTURE_2D);  
	BindTexture(TerrainGLID);

  glVertexPointer(2, GL_FLOAT, 0, DispTerrain.vertex);
  glTexCoordPointer(2, GL_FLOAT, 0, DispTerrain.texture);

  glDrawElements(GL_QUADS, 4 * n, GL_UNSIGNED_INT, first);

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
end;

end.

