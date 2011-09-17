unit FLoader;

interface
uses
  Windows, SysUtils, Math, FStructure, FLogs, Classes, FTextures;

function LoadModel(filename : string) : MDXModel;
function GetModel(path: string) : integer;
procedure InitModels();

implementation
var
	myFile : File;
  p : Integer;

procedure InitModels();
begin
  Models := TStringList.Create();
end;

function GetModel(path: string) : integer;
begin
  Result := Models.IndexOf(path);
  if (Result = -1) then begin
    Result := Models.Add(path);
    SetLength(LoadedModels, Result + 1);
    LoadedModels[Result] := LoadModel(path);
  end;
end;

function Get_Char(length: Integer): string;
var
	buffer : array[1..255] of byte;
begin
	// String can only contains 255 chars, skip if more.
	if length > 255 then begin
		BlockRead(myFile, buffer, 255);
		Result := string(PChar(@buffer));
		BlockRead(myFile, buffer, length - 255);
	end else begin
		BlockRead(myFile, buffer, length);
		Result := string(PChar(@buffer));
	end;
end;

function Get_Float(): Float;
begin
	BlockRead(myFile, Result, 4);
end;

function Get_Float2(): Float2;
begin
	BlockRead(myFile, Result, 8);
end;

function Get_Float3(): Float3;
begin
	BlockRead(myFile, Result, 12);
end;

function Get_Float4(): Float4;
begin
	BlockRead(myFile, Result, 16);
end;

function Get_Word(): Word;
begin
  BlockRead(myFile, Result, 2);
end;

function Get_Word3(): Word3;
begin
  BlockRead(myFile, Result, 6);
end;

function Get_Dword(): DWord;
begin
	BlockRead(myFile, Result, 4);
end;

function Get_Byte(): Byte;
begin
  BlockRead(myFile, Result, 1);
end;

function Get_Byte3(): Byte3;
begin
  BlockRead(myFile, Result, 3);
end;

function Get_Transformation() : Transformation1;
var
	nb : Integer;
  i: Integer;
begin
  p := 0;
  nb := Get_Dword();
  Result.InterpolationType := Get_Dword();
  Result.GlobalSequenceId := Get_Dword();
  p := p + 12;
  SetLength(Result.Scaling, nb);
	for i := 0 to nb - 1 do begin
    Result.Scaling[i].Time := Get_Dword();
    Result.Scaling[i].Value := Get_Dword();
    p := p + 8;
    if Result.InterpolationType > 1 then begin
      Result.Scaling[i].InTan := Get_Dword();
      Result.Scaling[i].OutTan := Get_Dword();
      p := p + 8;
    end;
	end;
end;

function Get_Transformation1() : Transformation1;
var
  nb : Integer;
  i: Integer;
begin
	p := 0;
	nb := Get_Dword();
  Result.InterpolationType := Get_Dword();
  Result.GlobalSequenceId := Get_Dword();
  p := p + 12;
  SetLength(Result.Scaling, nb);
  for i := 0 to nb - 1 do begin
    Result.Scaling[i].Time := Get_Dword();
    Result.Scaling[i].Value := Get_Float();
    p := p + 8;
		if Result.InterpolationType > 1 then begin
      Result.Scaling[i].InTan := Get_Float();
      Result.Scaling[i].OutTan := Get_Float();
      p := p + 8;
    end;
  end;
end;

function Get_Transformation3() : Transformation3;
var
  nb : Integer;
  i: Integer;
begin
  p := 0;
  nb := Get_Dword();
  Result.InterpolationType := Get_Dword();
  Result.GlobalSequenceId := Get_Dword(); 
  p := p + 12;
	SetLength(Result.Scaling, nb);
  for i := 0 to nb - 1 do begin
    Result.Scaling[i].Time := Get_Dword();
    Result.Scaling[i].Value := Get_Float3();
    p := p + 16;
		if Result.InterpolationType > 1 then begin
      Result.Scaling[i].InTan := Get_Float3();
      Result.Scaling[i].OutTan := Get_Float3();
      p := p + 24;
		end;
  end;
end;

function Get_Transformation4() : Transformation4;
var
  nb : Integer;
  i: Integer;
begin
	p := 0;
  nb := Get_Dword();
  Result.InterpolationType := Get_Dword();
  Result.GlobalSequenceId := Get_Dword();  
  p := p + 12;
  SetLength(Result.Scaling, nb);
	for i := 0 to nb - 1 do begin
    Result.Scaling[i].Time := Get_Dword();
    Result.Scaling[i].Value := Get_Float4();   
		p := p + 20;
    if Result.InterpolationType > 1 then begin
      Result.Scaling[i].InTan := Get_Float4();
      Result.Scaling[i].OutTan := Get_Float4();
      p := p + 32;
    end;
  end;
end;

function Get_Node() : NodeChunk;
var
	posi, temp, k : Integer;
  opcode : string[4];
begin
  posi := Get_Dword();
  Result.Name := Get_Char(80);

  Result.ObjectId := Get_Dword();
	Result.ParentId := Get_Dword();
	Result.Flags := Get_Dword();

	SetLength(Result.NodeTranslation.Scaling, 0);
	SetLength(Result.NodeRotation.Scaling, 0);
	SetLength(Result.NodeScaling.Scaling, 0);

	temp := 80 + 16;
  posi := posi - 80 - 16;
	k := -1;
  while ((k < 3) and (posi > 0)) do begin
    k := k + 1;
    opcode := Get_Char(4);
    posi := posi - 4;
    temp := temp + 4;
    if opcode = 'KGTR' then begin
      Result.NodeTranslation := Get_Transformation3();
      temp := temp + p;
			posi := posi - p;
    end else if opcode = 'KGRT' then begin
      Result.NodeRotation := Get_Transformation4(); 
      temp := temp + p;
      posi := posi - p;
    end else if opcode = 'KGSC' then begin
      Result.NodeScaling := Get_Transformation3();   
      temp := temp + p;
			posi := posi - p;
    end else begin
      Seek(myFile, FilePos(myFile)-4);
    end;
  end;
  p := temp;
end;

function LoadModel(filename : string) : MDXModel;
var
  opcode    : string[4];
	size, i, j, k, l, posi, posj : Integer;
begin
	if not FileExists(filename) then begin
		Log('File does not exist : ' + filename);
    exit;
  end;

	AssignFile(myFile, filename);
	Reset(myFile, 1);

  Result.ObjectMaxId := 0;

	opcode := Get_Char(4);
	if opcode <> 'MDLX' then begin
		Log('Not a Warcraft 3 Mdx : ' + filename);
    exit;
  end;

	while not Eof(myFile) do begin
    opcode := Get_Char(4);
		size := Get_Dword();

		if opcode = 'VERS' then begin
			Result.Version.version := Get_Dword();

		end else if opcode = 'MODL' then begin
			Result.Model.Name := Get_Char(80);
			Result.Model.AnimationFileName := Get_Char(260);
			Result.Model.BoundsRadius := Get_Float();
			Result.Model.MinimumExtent := Get_Float3();
			Result.Model.MaximumExtent := Get_Float3();
			Result.Model.BlendTime := Get_Dword();

		end else if opcode = 'SEQS' then begin
			SetLength(Result.Sequence, (size div 132));
			for i := 0 to (size div 132)-1 do begin
				Result.Sequence[i].Name := Get_Char(80);

				Result.Sequence[i].IntervalStart := Get_Dword();
				Result.Sequence[i].IntervalEnd := Get_Dword();
				Result.Sequence[i].MoveSpeed := Get_Float();
				Result.Sequence[i].NonLooping := Get_Dword();

				Result.Sequence[i].Rarity := Get_Float();
				Result.Sequence[i].SyncPoint := Get_Dword();

				Result.Sequence[i].BoundsRadius := Get_Float();
				Result.Sequence[i].MinimumExtent := Get_Float3();
				Result.Sequence[i].MaximumExtent := Get_Float3();
			end;

		end else if opcode = 'GLBS' then begin
  		SetLength(Result.GlobalSequence, (size div 4));
			for i := 0 to (size div 4)-1 do begin
				Result.GlobalSequence[i].Duration := Get_Dword();
			end;

		end else if opcode = 'TEXS' then begin
			SetLength(Result.Texture, (size div 268));
			for i := 0 to (size div 268)-1 do begin
				Result.Texture[i].ReplaceableId := Get_Dword();
				Result.Texture[i].FileName := Get_Char(260);
        Result.Texture[i].GLID := LoadTexture(Result.Texture[i].FileName);
				Result.Texture[i].Flags := Get_Dword();
			end;

		end else if opcode = 'MTLS' then begin
			SetLength(Result.Material, 255);
			posi := size;
			i := -1;
			while posi > 0 do begin
				i := i + 1;
				posj := Get_Dword();
				Result.Material[i].PriorityPlane := Get_Dword();
				Result.Material[i].Flags := Get_Dword();
				posi := posi - 12;
				posj := posj - 12;

				if ((posi > 0) and (posj > 0)) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'LAYS' then begin
						size := Get_Dword();
						posi := posi - 4;
						SetLength(Result.Material[i].Layer, size);
						for j := 0 to size-1 do begin
							posj := Get_Dword();
							Result.Material[i].Layer[j].FilterMode := Get_Dword();
							Result.Material[i].Layer[j].ShadingFlags := Get_Dword();
							Result.Material[i].Layer[j].TextureId := Get_Dword();
							Result.Material[i].Layer[j].TextureAnimationId := Get_Dword();
							Result.Material[i].Layer[j].CoordId := Get_Dword();
							Result.Material[i].Layer[j].Alpha := Get_Float();
							posi := posi - 28;
							posj := posj - 28;

							k := 0;
							while (k < 2) and (posi > 0) and (posj > 0) do begin
								k := k + 1;
								opcode := Get_Char(4);
								if opcode = 'KMTA' then begin
									Result.Material[i].Layer[j].MaterialAlpha := Get_Transformation1();
									posi := posi - p - 4;
									posj := posj - p - 4;
								end else if opcode = 'KMTF' then begin
									Result.Material[i].Layer[j].MaterialTextureId := Get_Transformation();
									posi := posi - p - 4;
									posj := posj - p - 4;
								end else
                  Raise Exception.Create('Error on loading MTLS : ' + filename);
							end;
						end;
					end;
				end;
			end;
			SetLength(Result.Material, i + 1);

		end else if opcode = 'TXAN' then begin
			SetLength(Result.TextureAnimation, 255);
			posi := size;
			k := -1;
			while ((k < 2) and (posi > 0)) do begin
				k := k + 1;
				opcode := Get_Char(4);
				if opcode = 'KTAT' then begin
					Result.TextureAnimation[k].TextureTranslation := Get_Transformation3();
					posi := posi - p;
				end else if opcode = 'KTAR' then begin
					Result.TextureAnimation[k].TextureRotation := Get_Transformation4();
					posi := posi - p;
				end else if opcode = 'KTAS' then begin
					Result.TextureAnimation[k].TextureScaling := Get_Transformation3();
					posi := posi - p;
				end else
					Raise Exception.Create('Error on loading TXAN : ' + filename);
			end;
			SetLength(Result.TextureAnimation, k + 1);

		end else if opcode = 'GEOS' then begin
			SetLength(Result.Geoset, 255);
			posi := size;
			k := -1;
			while (posi > 0) do begin
				k := k + 1;
				Get_Dword();
				opcode := Get_Char(4); // VRTX
				j := Get_Dword();
				SetLength(Result.Geoset[k].Vertexposition, j);
				SetLength(Result.Geoset[k].TransformedVertexposition, j);
				SetLength(Result.Geoset[k].TransformedTime, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].Vertexposition[i] := Get_Float3();
				posi := posi - (8 + j*3*4);

				opcode := Get_Char(4); // NRMS
				j := Get_Dword();
				SetLength(Result.Geoset[k].Normalposition, j);
				for i := 0 to j - 1 do begin
					Result.Geoset[k].Normalposition[i] := Get_Float3();
				end;
				posi := posi - (8 + j*3*4);

				opcode := Get_Char(4); // PTYP
				j := Get_Dword();
				SetLength(Result.Geoset[k].FaceTypeGroup, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].FaceTypeGroup[i] := Get_Dword();
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // PCNT
				j := Get_Dword();
				SetLength(Result.Geoset[k].FaceGroup, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].FaceGroup[i] := Get_Dword();
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // PVTX
				j := Get_Dword();
				SetLength(Result.Geoset[k].Face, j div 3);
				for i := 0 to (j div 3) - 1 do
					Result.Geoset[k].Face[i] := Get_Word3();
				posi := posi - (8 + j*2);

				opcode := Get_Char(4); // GNDX
				j := Get_Dword();
				SetLength(Result.Geoset[k].VertexGroup, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].VertexGroup[i] := Get_Byte();
				posi := posi - (8 + j);

				opcode := Get_Char(4); // MTGC
				j := Get_Dword();
				SetLength(Result.Geoset[k].MatrixGroup, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].MatrixGroup[i] := Get_Dword();
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // MATS
				j := Get_Dword();
				SetLength(Result.Geoset[k].MatrixIndex, j);
				for i := 0 to j - 1 do
					Result.Geoset[k].MatrixIndex[i] := Get_Dword();
				posi := posi - (8 + j*4);

				l := 0;
				SetLength(Result.Geoset[k].Matrix, Length(Result.Geoset[k].MatrixGroup));
				for i := 0 to Length(Result.Geoset[k].MatrixGroup) - 1 do begin
					SetLength(Result.Geoset[k].Matrix[i], Result.Geoset[k].MatrixGroup[i]);
					for j := 0 to Result.Geoset[k].MatrixGroup[i] - 1 do begin
						Result.Geoset[k].Matrix[i][j] := Result.Geoset[k].MatrixIndex[l];
						Inc(l);
					end;
				end;

				Result.Geoset[k].MaterialId := Get_Dword();
				Result.Geoset[k].SelectionGroup := Get_Dword();
				Result.Geoset[k].SelectionFlags := Get_Dword();
				Result.Geoset[k].BoundsRadius := Get_Float();
				Result.Geoset[k].MinimumExtent := Get_Float3();
				Result.Geoset[k].MaximumExtent := Get_Float3();
				posi := posi - 40;

				j := Get_Dword();
				for i := 0 to j - 1 do begin
					Result.Geoset[k].Extent.BoundsRadius := Get_Float();
					Result.Geoset[k].Extent.MinimumExtent := Get_Float3();
					Result.Geoset[k].Extent.MaximumExtent := Get_Float3();
				end;
				posi := posi - (8 + j*7*4);

				opcode := Get_Char(4); // UVAS
				Result.Geoset[k].NrofTextureVertexGroups := Get_Dword();
				posi := posi - 8;

				opcode := Get_Char(4); // UVBS
				j := Get_Dword();
				SetLength(Result.Geoset[k].Textureposition, j);
				for i := 0 to j - 1 do begin
					Result.Geoset[k].Textureposition[i] := Get_Float2();
				end;
				posi := posi - (8 + j*2*4);

			end;
			SetLength(Result.Geoset, k + 1);

		end else if opcode = 'GEOA' then begin
			SetLength(Result.GeosetAnimation, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				Result.GeosetAnimation[i].Alpha := Get_Float();
				Result.GeosetAnimation[i].Flags := Get_Dword();
				Result.GeosetAnimation[i].Color := Get_Float3();
				Result.GeosetAnimation[i].GeosetId := Get_Dword();
				posi := posi - 28;
				posj := posj - 28;
				k := -1;
				while ((k < 2) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KGAO' then begin
						Result.GeosetAnimation[i].GeosetAlpha := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KGAC' then begin
						Result.GeosetAnimation[i].GeosetColor := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
  				end else
            Raise Exception.Create('Error on loading GEOA : ' + filename);
				end;
			end;
			SetLength(Result.GeosetAnimation, i + 1);

		end else if opcode = 'BONE' then begin
			SetLength(Result.Bone, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Result.Bone[i].Node := Get_Node();
        Result.ObjectMaxId := Max(Result.ObjectMaxId, Result.Bone[i].Node.ObjectId);
				Result.Bone[i].GeosetId := Get_Dword();
				Result.Bone[i].GeosetAnimation := Get_Dword();
				posi := posi - p - 8;
			end;
			SetLength(Result.Bone, i + 1);

		end else if opcode = 'HELP' then begin
			SetLength(Result.Helper, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Result.Helper[i] := Get_Node(); 
        Result.ObjectMaxId := Max(Result.ObjectMaxId, Result.Helper[i].ObjectId);
				posi := posi - p;
			end;
			SetLength(Result.Helper, i + 1);

		end else if opcode = 'CLID' then begin
			SetLength(Result.CollisionShape, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Result.CollisionShape[i].Node := Get_Node();
				Result.CollisionShape[i].TypeType := Get_Dword();
				Result.CollisionShape[i].Vertex1 := Get_Float3();
				if (Result.CollisionShape[i].TypeType = 0) then begin
					Result.CollisionShape[i].Vertex2 := Get_Float3();
					posi := posi - 12;
				end;
				if (Result.CollisionShape[i].TypeType = 2) then begin
					Result.CollisionShape[i].BoundRadius := Get_Float();
					posi := posi - 4;
				end;
				posi := posi - p - 20;
			end;
			SetLength(Result.CollisionShape, i + 1);

		end else if opcode = 'ATCH' then begin
			SetLength(Result.Attachment, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				Result.Attachment[i].Node := Get_Node();
				posi := posi - 268 - p;
				posj := posj - 268 - p;
				Result.Attachment[i].Path := Get_Char(260);
				Result.Attachment[i].AttachmentId := Get_Dword();
				if (posi > 0) and (posj > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KATV' then begin
						Result.Attachment[i].AttachmentVisibility := Get_Transformation1();
						posi := posi - p;
					end;
				end;
			end;
			SetLength(Result.Attachment, i + 1);

		end else if opcode = 'PIVT' then begin
			SetLength(Result.PivotPoint, (size div 12));
			for i := 0 to (size div 12)-1 do begin
				Result.PivotPoint[i] := Get_Float3();
			end;

		end else if opcode = 'PREM' then begin
			SetLength(Result.ParticleEmitter, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				Result.ParticleEmitter[i].Node := Get_Node();
				posi := posi - 288 - p;
				posj := posj - 288 - p;
				Result.ParticleEmitter[i].EmissionRate := Get_Float();
				Result.ParticleEmitter[i].Gravity := Get_Float();
				Result.ParticleEmitter[i].Longitude := Get_Float();
				Result.ParticleEmitter[i].Latitude := Get_Float();
				Result.ParticleEmitter[i].SpawnModelFileName := Get_Char(260);
				Result.ParticleEmitter[i].LifeSpan := Get_Float();
				Result.ParticleEmitter[i].InitialVelocity := Get_Float();
				if (posi > 0) and (posj > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KPEV' then begin
						Result.ParticleEmitter[i].ParticleEmitterVisibility := Get_Transformation1();
						posi := posi - p;
					end;
				end;
			end;
			SetLength(Result.Attachment, i + 1);

		end else if opcode = 'PRE2' then begin
			SetLength(Result.ParticleEmitter2, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				Result.ParticleEmitter2[i].Node := Get_Node();

				posi := posi - p - 175;
				posj := posj - p - 175;

				Result.ParticleEmitter2[i].Speed := Get_Float();
				Result.ParticleEmitter2[i].Variation := Get_Float();
				Result.ParticleEmitter2[i].Latitude := Get_Float();
				Result.ParticleEmitter2[i].Gravity := Get_Float();
				Result.ParticleEmitter2[i].Lifespan := Get_Float();
				Result.ParticleEmitter2[i].EmissionRate := Get_Float();
				Result.ParticleEmitter2[i].Length := Get_Float();
				Result.ParticleEmitter2[i].Width := Get_Float();
				Result.ParticleEmitter2[i].FilterMode := Get_Dword();
				Result.ParticleEmitter2[i].Rows := Get_Dword();
				Result.ParticleEmitter2[i].Columns := Get_Dword();
				Result.ParticleEmitter2[i].HeadOrTail := Get_Dword();
				Result.ParticleEmitter2[i].TailLength := Get_Float();
				Result.ParticleEmitter2[i].Time := Get_Float();

				Result.ParticleEmitter2[i].SegmentColor.a := Get_Float3();
				Result.ParticleEmitter2[i].SegmentColor.b := Get_Float3();
				Result.ParticleEmitter2[i].SegmentColor.c := Get_Float3();
				Result.ParticleEmitter2[i].SegmentAlpha := Get_Byte3();
				Result.ParticleEmitter2[i].SegmentScaling := Get_Float3();

				Result.ParticleEmitter2[i].HeadIntervalStart := Get_Dword();
				Result.ParticleEmitter2[i].HeadIntervalEnd := Get_Dword();
				Result.ParticleEmitter2[i].HeadIntervalRepeat := Get_Dword();
				Result.ParticleEmitter2[i].HeadDecayIntervalStart := Get_Dword();
				Result.ParticleEmitter2[i].HeadDecayIntervalEnd  := Get_Dword();
				Result.ParticleEmitter2[i].HeadDecayIntervalRepeat := Get_Dword();

				Result.ParticleEmitter2[i].TailIntervalStart := Get_Dword();
				Result.ParticleEmitter2[i].TailIntervalEnd := Get_Dword();
				Result.ParticleEmitter2[i].TailIntervalRepeat := Get_Dword();
				Result.ParticleEmitter2[i].TailDecayIntervalStart := Get_Dword();
				Result.ParticleEmitter2[i].TailDecayIntervalEnd  := Get_Dword();
				Result.ParticleEmitter2[i].TailDecayIntervalRepeat := Get_Dword();

				Result.ParticleEmitter2[i].TextureId := Get_Dword();
				Result.ParticleEmitter2[i].Squirt := Get_Dword();
				Result.ParticleEmitter2[i].PriorityPlane := Get_Dword();
				Result.ParticleEmitter2[i].ReplaceableId := Get_Dword();

				k := -1;
				while ((k < 5) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KP2V' then begin
						Result.ParticleEmitter2[i].ParticleEmitter2Visibility := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2E' then begin
						Result.ParticleEmitter2[i].ParticleEmitter2EmissionRate := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2W' then begin
						Result.ParticleEmitter2[i].ParticleEmitter2Width := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2N' then begin
						Result.ParticleEmitter2[i].ParticleEmitter2Length := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2S' then begin
						Result.ParticleEmitter2[i].ParticleEmitter2Speed := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else
						Raise Exception.Create('Error on loading PRE2 : ' + filename);
				end;
			end;
			SetLength(Result.ParticleEmitter2, i + 1);

		end else if opcode = 'LITE' then begin
			SetLength(Result.Light, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				Result.Light[i].Node := Get_Node();

				posi := posi - p - 48;
				posj := posj - p - 48;

				Result.Light[i].TypeType := Get_Dword();
				Result.Light[i].AttenuationStart := Get_Dword();
				Result.Light[i].AttenuationEnd := Get_Dword();
				Result.Light[i].Color := Get_Float3();
				Result.Light[i].Intensity := Get_Float();
				Result.Light[i].AmbientColor := Get_Float3();
				Result.Light[i].AmbientIntensity := Get_Float();

				k := -1;
				while ((k < 5) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KLAV' then begin
						Result.Light[i].LightVisibility := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KLAC' then begin
						Result.Light[i].LightColor := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KLAI' then begin
						Result.Light[i].LightIntensity := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KLBC' then begin
						Result.Light[i].LightAmbientColor := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KLBI' then begin
						Result.Light[i].LightAmbientIntensity := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else
						Raise Exception.Create('Error on loading LITE : ' + filename);
				end;
			end;
			SetLength(Result.Light, i + 1);

		end else if opcode = 'RIBB' then begin
			SetLength(Result.RibbonEmitter, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				Result.RibbonEmitter[i].Node := Get_Node();

				posi := posi - p - 56;
				posj := posj - p - 56;

				Result.RibbonEmitter[i].HeightAbove := Get_Float();
				Result.RibbonEmitter[i].HeightBelow := Get_Float();
				Result.RibbonEmitter[i].Alpha := Get_Float();
				Result.RibbonEmitter[i].Color := Get_Float3();
				Result.RibbonEmitter[i].LifeSpan := Get_Float();
				Result.RibbonEmitter[i].Unk := Get_Dword();
				Result.RibbonEmitter[i].EmissionRate := Get_Dword();
				Result.RibbonEmitter[i].Rows := Get_Dword();
				Result.RibbonEmitter[i].Columns := Get_Dword();
				Result.RibbonEmitter[i].MaterialId := Get_Dword();
				Result.RibbonEmitter[i].Gravity := Get_Dword();

				k := -1;
				while ((k < 3) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KRVS' then begin
						Result.RibbonEmitter[i].RibbonEmitterVisibility := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KRHA' then begin
						Result.RibbonEmitter[i].RibbonEmitterHeightAbove := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KRHB' then begin
						Result.RibbonEmitter[i].RibbonEmitterHeightBelow := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;    
	  			end else
            Raise Exception.Create('Error on loading RIBB : ' + filename);
				end;
			end;
			SetLength(Result.RibbonEmitter, i + 1);

		end else if opcode = 'CAMS' then begin
			SetLength(Result.Camera, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				Result.Camera[i].Name := Get_Char(80);
				Result.Camera[i].Position := Get_Float3();
				Result.Camera[i].FieldOfView := Get_Dword();
				Result.Camera[i].FarClippingPlane := Get_Dword();
				Result.Camera[i].NearClippingPlane := Get_Dword();
				Result.Camera[i].TargetPosition := Get_Float3();

				posi := posi - 120;
				posj := posj - 120;

				k := -1;
				while ((k < 3) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KCTR' then begin
						Result.Camera[i].CameraPositionTranslation := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KTTR' then begin
						Result.Camera[i].CameraTargetTranslation := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KCRL' then begin
						Result.Camera[i].CameraRotation := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else begin
            Raise Exception.Create('Error on loading CAMS : ' + filename);
					end;
				end;
			end;
			SetLength(Result.Camera, i + 1);

		end else if opcode = 'EVTS' then begin
			SetLength(Result.EventObject, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Result.EventObject[i].Node := Get_Node();
				posi := posi - 4 - p;

				if (posi > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KEVT' then begin
						k := Get_Dword();
						Result.EventObject[i].GlobalSequenceId := Get_Dword();
						posi := posi - 8;
						SetLength(Result.EventObject[i].Tracks, k);
						for j := 0 to k - 1 do begin
							Result.EventObject[i].Tracks[j] := Get_Dword();
							posi := posi - 4;
						end;
					end;
				end;
			end;
			SetLength(Result.EventObject, i + 1);
		end;
	end;
	CloseFile(myFile);
end;

end.
