unit FModelLoader;

interface
uses
	Windows, FOpenGL, Math, SysUtils,
	Contnrs, // TObjectList
	Classes, // TStrings
	FTextures, FLogs, Dialogs, FGeometry;

type
	Float = Single;

	Float2 = array[0..1] of Float;
	Float3 = array[0..2] of Float;
	Float4 = array[0..3] of Float;

	Word3 = array [0..2] of Word;
	Byte3 = array [0..2] of Byte;

  VersionChunk = Record
    version : DWord;
  end;

	ModelChunk = Record
		Name : string[80];
    AnimationFileName : string[255];

    BoundsRadius : Float;
    MinimumExtent : Float3;
    MaximumExtent : Float3;
    BlendTime : Dword;
  end;

  SequenceChunk = Record
    Name : string[80];

    IntervalStart : Dword;
    IntervalEnd : Dword;
    MoveSpeed : Float;
    Flags : Dword;

    Rarity : Float;
    SyncPoint : Dword;

    BoundsRadius : Float;
    MinimumExtent : Float3;
    MaximumExtent : Float3;
  end;

  GlobalSequenceChunk = Record
    Duration : Dword;
  end;

	TextureChunk = Record
		ReplaceableId : Dword;
    Filename : string[255];
    Flags : Dword;
	end;

	ScalingTrack1 = Record
		Time : Dword;
		Value : Float;
		InTan : Float;
		OutTan : Float;
	end;

	Transformation1 = Record
		InterpolationType : Dword;
		GlobalSequenceId : Dword;
		Scaling : array of ScalingTrack1;
	end;

  ScalingTrack3 = Record
    Time : Dword;
    Value : Float3;
    InTan : Float3;
    OutTan : Float3;
	end;

	Transformation3 = Record
		InterpolationType : Dword;
		GlobalSequenceId : Dword;
		Scaling : array of ScalingTrack3;
	end;

  ScalingTrack4 = Record
    Time : Dword;
    Value : Float4;
    InTan : Float4;
    OutTan : Float4;
  end;

  Transformation4 = Record
    InterpolationType : Dword;
    GlobalSequenceId : Dword;
    Scaling : array of ScalingTrack4;
  end;

  LayerChunk = Record
    FilterMode : Dword;
    ShadingFlags : Dword;
    TextureId : Dword;
    TextureAnimationId : Dword;
    CoordId : Dword;
    Alpha : Float;
    MaterialAlpha : Transformation1;
		MaterialTextureId : Transformation1;
  end;

  MaterialChunk = Record
    PriorityPlane : Dword;
    Flags : Dword;
    Layer : array of LayerChunk;
  end;

  TextureAnimationChunk = Record
    TextureTranslation : Transformation3;
    TextureRotation : Transformation4;
    TextureScaling : Transformation3;
  end;

	GeosetChunk = Record
    VertexPosition : array of Float3;
    NormalPosition : array of Float3;
		FaceTypeGroup : array of Dword;
		FaceGroup : array of Dword;
    Face : array of Word3;
		VertexGroup : array of Byte;
    MatrixGroup : array of Dword;
		MatrixIndex : array of Dword;
  	Matrix : array of array of Dword;
		MaterialId : Dword;
		SelectionGroup : Dword;
		SelectionFlags : Dword;
    BoundsRadius : Float;
    MinimumExtent : Float3;
    MaximumExtent : Float3;
    Extent : Record
      BoundsRadius : Float;
      MinimumExtent : Float3;
      MaximumExtent : Float3;
    end;
    NrofTextureVertexGroups : Dword;
    TexturePosition : array of Float2;
  end;

  GeosetAnimationChunk = Record
    Alpha : Float;
    Flags : Dword;
    Color : Float3;
    GeosetId : Dword;
    GeosetAlpha : Transformation1;
    GeosetColor : Transformation3;
  end;

  NodeChunk = Record
    Name : string[80];
    ObjectId : Dword;
    ParentId : Dword;
    Flags : Dword;
		NodeTranslation : Transformation3;
    NodeRotation : Transformation4;
    NodeScaling : Transformation3;
  end;

	BoneChunk = Record
    Node : NodeChunk;
    GeosetId : Dword;
    GeosetAnimation : Dword;
  end;

  LightChunk = Record
    Node : NodeChunk;
    TypeType : Dword;
    AttenuationStart : Dword;
    AttenuationEnd : Dword;
    Color : Float3;
    Intensity : Float;
    AmbientColor : Float3;
    AmbientIntensity : Float;

    LightVisibility : Transformation1;
    LightColor : Transformation3;
    LightIntensity : Transformation1;
    LightAmbientColor : Transformation3;
    LightAmbientIntensity : Transformation1;
  end;

  AttachmentChunk = Record
    Node : NodeChunk;
    Path : string[255];
    AttachmentId : Dword;
    AttachmentVisibility : Transformation1;
  end;

  ParticleEmitterChunk = Record
    Node : NodeChunk;
    EmissionRate : Float;
    Gravity : Float;
    Longitude : Float;
    Latitude : Float;
    SpawnModelFileName : string[255];
    LifeSpan : Float;
    InitialVelocity : Float;

    ParticleEmitterVisibility : Transformation1;
  end;

  Particleemitter2Chunk = Record
    Node : NodeChunk;
    Speed : Float;
    Variation : Float;
    Latitude : Float;
    Gravity : Float;
    Lifespan : Float;
    EmissionRate : Float;
    Length : Float;
    Width : Float;
    FilterMode : Dword;
    Rows : Dword;
    Columns : Dword;
    HeadOrTail : Dword;
    TailLength : Float;
    Time : Float;

    SegmentColor    : Record a : Float3; b : Float3; c : Float3; end;
    SegmentAlpha    : Byte3;
    SegmentScaling  : Float3;

    HeadIntervalStart : Dword;
    HeadIntervalEnd : Dword;
    HeadIntervalRepeat : Dword;
    HeadDecayIntervalStart : Dword;
    HeadDecayIntervalEnd : Dword;
    HeadDecayIntervalRepeat : Dword;
    TailIntervalStart : Dword;
    TailIntervalEnd : Dword;
    TailIntervalRepeat : Dword;
    TailDecayIntervalStart : Dword;
    TailDecayIntervalEnd : Dword;
    TailDecayIntervalRepeat : Dword;
    TextureId : Dword;
    Squirt : Dword;
    PriorityPlane : Dword;
    ReplaceableId : Dword;

    ParticleEmitter2Visibility : Transformation1;
    ParticleEmitter2EmissionRate : Transformation1;
    ParticleEmitter2Width : Transformation1;
    ParticleEmitter2Length : Transformation1;
    ParticleEmitter2Speed : Transformation1;
  end;

  RibbonEmitterChunk = Record
    Node : NodeChunk;
    HeightAbove : Float;
    HeightBelow : Float;
    Alpha : Float;
    Color : Float3;
    LifeSpan : Float;
    Unk : Dword; // always 0 ?
    EmissionRate : Dword;
    Rows : Dword;
    Columns : Dword;
    MaterialId : Dword;
    Gravity : Float;
    RibbonEmitterVisibility : Transformation1;
    RibbonEmitterHeightAbove : Transformation1;
    RibbonEmitterHeightBelow : Transformation1;
  end;

  EventObjectChunk = Record
    Node : NodeChunk;
    GlobalSequenceId : Dword;
    Tracks : array of Dword;
  end;

  CameraChunk = Record
    Name : string[80];
    Position : Float3;
    FieldOfView : Dword;
    FarClippingPlane : Dword;
    NearClippingPlane : Dword;
    TargetPosition : Float3;

    CameraPositionTranslation : Transformation3;
    CameraTargetTranslation : Transformation3;
    CameraRotation : Transformation1;
  end;

  CollisionShapeChunk = Record
    Node : NodeChunk;
    TypeType : Dword;
    Vertex1 : Float3;
    Vertex2 : Float3;
    BoundRadius : Float;
  end;

  MdxModel = Class (TObject)      
		procedure LoadMDX(filename : String);
		procedure DisplayModel(time : int64; anim : integer);
		function CalculatePos(Transfo : Transformation3; time, time1, time2 : integer) : Float3; overload;
		function CalculatePos(Transfo : Transformation4; time, time1, time2 : integer) : Float4; overload;
		function FindKey(Transfo : Transformation3; t, tmin : Integer) : integer; overload;
		function FindKey(Transfo : Transformation4; t, tmin : Integer) : integer; overload;
		function GetTransfo(anim, time, i, j : integer) : PGLFloat;
		procedure DrawTriangle(i, j : integer);
		procedure ApplyTexture(anim, time, i, j : integer);
	public
		path 							: string[255];
    Version           : VersionChunk;
    Model             : ModelChunk;
    Sequence          : array of SequenceChunk;
    GlobalSequence    : array of GlobalSequenceChunk;
    Texture           : array of TextureChunk;
    Material          : array of MaterialChunk;
    TextureAnimation  : array of TextureAnimationChunk;
    Geoset            : array of GeosetChunk;
		GeosetAnimation   : array of GeosetAnimationChunk;
		Bone              : array of BoneChunk;
//    Light             : array of LightChunk;
		Helper            : array of NodeChunk;
    Attachment        : array of AttachmentChunk;
    PivotPoint        : array of Float3;
    ParticleEmitter   : array of ParticleEmitterChunk;
    ParticleEmitter2  : array of ParticleEmitter2Chunk;
    RibbonEmitter     : array of RibbonEmitterChunk;
    EventObject       : array of EventObjectChunk;
    Camera            : array of CameraChunk;
//    CollisionShape    : array of CollisionShapeChunk;
  end;                                  

var
	myFile : File;
  p : Integer;

	LoadedModel : MdxModel;
	LoadedModels : TObjectList;

implementation

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
	Result[0] := Get_Float();
	Result[1] := Get_Float();
end;

function Get_Float3(): Float3;
begin
	Result[0] := Get_Float();
	Result[1] := Get_Float();
	Result[2] := Get_Float();
end;

function Get_Float4(): Float4;
begin
	Result[0] := Get_Float();
	Result[1] := Get_Float();
	Result[2] := Get_Float();
	Result[3] := Get_Float();
end;

function Get_Word(): Word;
begin
  BlockRead(myFile, Result, 2);
end;

function Get_Word3(): Word3;
begin
	Result[0] := Get_Word();
	Result[1] := Get_Word();
	Result[2] := Get_Word();
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
	Result[0] := Get_Byte();
	Result[1] := Get_Byte();
	Result[2] := Get_Byte();
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

procedure MDXModel.LoadMDX(filename : string);
var
  opcode    : string[4];
	size, i, j, k, l, posi, posj, posk : Integer;
begin
	if not FileExists(filename) then
		Log('File does not exist : ' + filename, LOG_ERROR);

	AssignFile(myFile, filename);
	Reset(myFile, 1);

	opcode := Get_Char(4);
	if opcode <> 'MDLX' then
		Log('Not a Warcraft 3 Mdx : ' + filename, LOG_ERROR);

	while not Eof(myFile) do begin
    opcode := Get_Char(4);
		size := Get_Dword();

 	 if opcode = 'MDLX' then begin
		end else if opcode = 'VERS' then begin
			Version.version := Get_Dword();

		end else if opcode = 'MODL' then begin
			Model.Name := Get_Char(80);
			Model.AnimationFileName := Get_Char(260);
			Model.BoundsRadius := Get_Float();
			Model.MinimumExtent := Get_Float3();
			Model.MaximumExtent := Get_Float3();
			Model.BlendTime := Get_Dword();

		end else if opcode = 'SEQS' then begin
			SetLength(Sequence, (size div 132));
			for i := 0 to (size div 132)-1 do begin
				Sequence[i].Name := Get_Char(80);

				Sequence[i].IntervalStart := Get_Dword();
				Sequence[i].IntervalEnd := Get_Dword();
				Sequence[i].MoveSpeed := Get_Float();
				Sequence[i].Flags := Get_Dword();

				Sequence[i].Rarity := Get_Float();
				Sequence[i].SyncPoint := Get_Dword();

				Sequence[i].BoundsRadius := Get_Float();
				Sequence[i].MinimumExtent := Get_Float3();
				Sequence[i].MaximumExtent := Get_Float3();
			end;

		end else if opcode = 'GLBS' then begin
  		SetLength(GlobalSequence, (size div 4));
			for i := 0 to (size div 4)-1 do begin
				GlobalSequence[i].Duration := Get_Dword();
			end;

		end else if opcode = 'TEXS' then begin
			SetLength(Texture, (size div 268));
			for i := 0 to (size div 268)-1 do begin
				Texture[i].ReplaceableId := Get_Dword();
				Texture[i].FileName := Get_Char(260);
				Texture[i].Flags := Get_Dword();
			end;

		end else if opcode = 'MTLS' then begin
			SetLength(Material, 255);
			posi := size;
			i := -1;
			while posi > 0 do begin
				i := i + 1;
				posj := Get_Dword();
				Material[i].PriorityPlane := Get_Dword();
				Material[i].Flags := Get_Dword();
				posi := posi - 12;
				posj := posj - 12;

				if ((posi > 0) and (posj > 0)) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'LAYS' then begin
						size := Get_Dword();
						posj := size * 28;
						posi := posi - 4;
						SetLength(Material[i].Layer, size);
						for j := 0 to size-1 do begin
							posk := Get_Dword();
							Material[i].Layer[j].FilterMode := Get_Dword();
							Material[i].Layer[j].ShadingFlags := Get_Dword();
							Material[i].Layer[j].TextureId := Get_Dword();
							Material[i].Layer[j].TextureAnimationId := Get_Dword();
							Material[i].Layer[j].CoordId := Get_Dword();
							Material[i].Layer[j].Alpha := Get_Float();
							posi := posi - 28;
							posj := posj - 28;
							posk := posk - 28;

							k := 0;
							while ((k < 2) and (posi > 0) and (posj > 0) and (posk > 0)) do begin
								k := k + 1;
								opcode := Get_Char(4);
								if opcode = 'KMTA' then begin
									Material[i].Layer[j].MaterialAlpha := Get_Transformation1();
									posi := posi - p;
									posj := posj - p;
									posk := posk - p;
								end else if opcode = 'KMTF' then begin
									Material[i].Layer[j].MaterialTextureId := Get_Transformation();
									posi := posi - p;
									posj := posj - p;
									posk := posk - p;
								end else
                  Raise Exception.Create('Error on loading MTLS : ' + filename);
							end;
						end;
					end;
				end;
			end;
			SetLength(Material, i + 1);

		end else if opcode = 'TXAN' then begin
			SetLength(TextureAnimation, 255);
			posi := size;
			k := -1;
			while ((k < 2) and (posi > 0)) do begin
				k := k + 1;
				opcode := Get_Char(4);
				if opcode = 'KTAT' then begin
					TextureAnimation[k].TextureTranslation := Get_Transformation3();
					posi := posi - p;
				end else if opcode = 'KTAR' then begin
					TextureAnimation[k].TextureRotation := Get_Transformation4();
					posi := posi - p;
				end else if opcode = 'KTAS' then begin
					TextureAnimation[k].TextureScaling := Get_Transformation3();
					posi := posi - p;
				end else
					Raise Exception.Create('Error on loading TXAN : ' + filename);
			end;
			SetLength(TextureAnimation, k + 1);

		end else if opcode = 'GEOS' then begin
			SetLength(Geoset, 255);
			posi := size;
			k := -1;
			while (posi > 0) do begin
				k := k + 1;
				Get_Dword();
				opcode := Get_Char(4); // VRTX
				j := Get_Dword();
				SetLength(Geoset[k].Vertexposition, j);
				for i := 0 to j - 1 do begin
					Geoset[k].Vertexposition[i] := Get_Float3();
				end;
				posi := posi - (8 + j*3*4);

				opcode := Get_Char(4); // NRMS
				j := Get_Dword();
				SetLength(Geoset[k].Normalposition, j);
				for i := 0 to j - 1 do begin
					Geoset[k].Normalposition[i] := Get_Float3();
				end;
				posi := posi - (8 + j*3*4);

				opcode := Get_Char(4); // PTYP
				j := Get_Dword();
				SetLength(Geoset[k].FaceTypeGroup, j);
				for i := 0 to j - 1 do begin
					Geoset[k].FaceTypeGroup[i] := Get_Dword();
				end;
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // PCNT
				j := Get_Dword();
				SetLength(Geoset[k].FaceGroup, j);
				for i := 0 to j - 1 do begin
					Geoset[k].FaceGroup[i] := Get_Dword();
				end;
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // PVTX
				j := Get_Dword();
				SetLength(Geoset[k].Face, j div 3);
				for i := 0 to (j div 3) - 1 do begin
					Geoset[k].Face[i] := Get_Word3();
				end;
				posi := posi - (8 + j*2);

				opcode := Get_Char(4); // GNDX
				j := Get_Dword();
				SetLength(Geoset[k].VertexGroup, j);
				for i := 0 to j - 1 do begin
					Geoset[k].VertexGroup[i] := Get_Byte();
				end;
				posi := posi - (8 + j);

				opcode := Get_Char(4); // MTGC
				j := Get_Dword();
				SetLength(Geoset[k].MatrixGroup, j);
				for i := 0 to j - 1 do
					Geoset[k].MatrixGroup[i] := Get_Dword();
				posi := posi - (8 + j*4);

				opcode := Get_Char(4); // MATS
				j := Get_Dword();
				SetLength(Geoset[k].MatrixIndex, j);
				for i := 0 to j - 1 do
					Geoset[k].MatrixIndex[i] := Get_Dword();
				posi := posi - (8 + j*4);

				l := 0;
				SetLength(Geoset[k].Matrix, Length(Geoset[k].MatrixGroup));
				for i := 0 to Length(Geoset[k].MatrixGroup) - 1 do begin
					SetLength(Geoset[k].Matrix[i], Geoset[k].MatrixGroup[i]);
					for j := 0 to Geoset[k].MatrixGroup[i] - 1 do begin
						Geoset[k].Matrix[i][j] := Geoset[k].MatrixIndex[l];
						Inc(l);
					end;
				end;

				Geoset[k].MaterialId := Get_Dword();
				Geoset[k].SelectionGroup := Get_Dword();
				Geoset[k].SelectionFlags := Get_Dword();
				Geoset[k].BoundsRadius := Get_Float();
				Geoset[k].MinimumExtent := Get_Float3();
				Geoset[k].MaximumExtent := Get_Float3();
				posi := posi - 40;

				j := Get_Dword();
				for i := 0 to j - 1 do begin
					Geoset[k].Extent.BoundsRadius := Get_Float();
					Geoset[k].Extent.MinimumExtent := Get_Float3();
					Geoset[k].Extent.MaximumExtent := Get_Float3();
				end;
				posi := posi - (8 + j*7*4);

				opcode := Get_Char(4); // UVAS
				Geoset[k].NrofTextureVertexGroups := Get_Dword();
				posi := posi - 8;

				opcode := Get_Char(4); // UVBS
				j := Get_Dword();
				SetLength(Geoset[k].Textureposition, j);
				for i := 0 to j - 1 do begin
					Geoset[k].Textureposition[i] := Get_Float2();
				end;
				posi := posi - (8 + j*2*4);

			end;
			SetLength(Geoset, k + 1);

		end else if opcode = 'GEOA' then begin
			SetLength(GeosetAnimation, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				GeosetAnimation[i].Alpha := Get_Float();
				GeosetAnimation[i].Flags := Get_Dword();
				GeosetAnimation[i].Color := Get_Float3();
				GeosetAnimation[i].GeosetId := Get_Dword();
				posi := posi - 28;
				posj := posj - 28;
				k := -1;
				while ((k < 2) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KGAO' then begin
						GeosetAnimation[i].GeosetAlpha := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KGAC' then begin
						GeosetAnimation[i].GeosetColor := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;   
  				end else
            Raise Exception.Create('Error on loading GEOA : ' + filename);
				end;
			end;
			SetLength(GeosetAnimation, i + 1);

		end else if opcode = 'BONE' then begin
			SetLength(Bone, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Bone[i].Node := Get_Node();
				Bone[i].GeosetId := Get_Dword();
				Bone[i].GeosetAnimation := Get_Dword();
				posi := posi - p - 8;
			end;
			SetLength(Bone, i + 1);
			Log('Bone Count : ' + IntToStr(i));

		end else if opcode = 'HELP' then begin
			SetLength(Helper, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				Helper[i] := Get_Node();
				posi := posi - p;
			end;
			SetLength(Helper, i + 1);

		end else if opcode = 'ATCH' then begin
			SetLength(Attachment, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				Attachment[i].Node := Get_Node();
				posi := posi - 268 - p;
				posj := posj - 268 - p;
				Attachment[i].Path := Get_Char(260);
				Attachment[i].AttachmentId := Get_Dword();
				if (posi > 0) and (posj > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KATV' then begin
						Attachment[i].AttachmentVisibility := Get_Transformation1();
						posi := posi - p;
					end;
				end;
			end;
			SetLength(Attachment, i + 1);

		end else if opcode = 'PIVT' then begin
			SetLength(PivotPoint, (size div 12));
			for i := 0 to (size div 12)-1 do begin
				PivotPoint[i] := Get_Float3();
			end;

		end else if opcode = 'PREM' then begin
			SetLength(ParticleEmitter, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();
				ParticleEmitter[i].Node := Get_Node();
				posi := posi - 288 - p;
				posj := posj - 288 - p;
				ParticleEmitter[i].EmissionRate := Get_Float();
				ParticleEmitter[i].Gravity := Get_Float();
				ParticleEmitter[i].Longitude := Get_Float();
				ParticleEmitter[i].Latitude := Get_Float();
				ParticleEmitter[i].SpawnModelFileName := Get_Char(260);
				ParticleEmitter[i].LifeSpan := Get_Float();
				ParticleEmitter[i].InitialVelocity := Get_Float();
				if (posi > 0) and (posj > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KPEV' then begin
						ParticleEmitter[i].ParticleEmitterVisibility := Get_Transformation1();
						posi := posi - p;
					end;
				end;
			end;
			SetLength(Attachment, i + 1);

		end else if opcode = 'PRE2' then begin
			SetLength(ParticleEmitter2, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				ParticleEmitter2[i].Node := Get_Node();

				posi := posi - p - 175;
				posj := posj - p - 175;

				ParticleEmitter2[i].Speed := Get_Float();
				ParticleEmitter2[i].Variation := Get_Float();
				ParticleEmitter2[i].Latitude := Get_Float();
				ParticleEmitter2[i].Gravity := Get_Float();
				ParticleEmitter2[i].Lifespan := Get_Float();
				ParticleEmitter2[i].EmissionRate := Get_Float();
				ParticleEmitter2[i].Length := Get_Float();
				ParticleEmitter2[i].Width := Get_Float();
				ParticleEmitter2[i].FilterMode := Get_Dword();
				ParticleEmitter2[i].Rows := Get_Dword();
				ParticleEmitter2[i].Columns := Get_Dword();
				ParticleEmitter2[i].HeadOrTail := Get_Dword();
				ParticleEmitter2[i].TailLength := Get_Float();
				ParticleEmitter2[i].Time := Get_Float();

				ParticleEmitter2[i].SegmentColor.a := Get_Float3();
				ParticleEmitter2[i].SegmentColor.b := Get_Float3();
				ParticleEmitter2[i].SegmentColor.c := Get_Float3();
				ParticleEmitter2[i].SegmentAlpha := Get_Byte3();
				ParticleEmitter2[i].SegmentScaling := Get_Float3();

				ParticleEmitter2[i].HeadIntervalStart := Get_Dword();
				ParticleEmitter2[i].HeadIntervalEnd := Get_Dword();
				ParticleEmitter2[i].HeadIntervalRepeat := Get_Dword();
				ParticleEmitter2[i].HeadDecayIntervalStart := Get_Dword();
				ParticleEmitter2[i].HeadDecayIntervalEnd  := Get_Dword();
				ParticleEmitter2[i].HeadDecayIntervalRepeat := Get_Dword();

				ParticleEmitter2[i].TailIntervalStart := Get_Dword();
				ParticleEmitter2[i].TailIntervalEnd := Get_Dword();
				ParticleEmitter2[i].TailIntervalRepeat := Get_Dword();
				ParticleEmitter2[i].TailDecayIntervalStart := Get_Dword();
				ParticleEmitter2[i].TailDecayIntervalEnd  := Get_Dword();
				ParticleEmitter2[i].TailDecayIntervalRepeat := Get_Dword();

				ParticleEmitter2[i].TextureId := Get_Dword();
				ParticleEmitter2[i].Squirt := Get_Dword();
				ParticleEmitter2[i].PriorityPlane := Get_Dword();
				ParticleEmitter2[i].ReplaceableId := Get_Dword();

				k := -1;
				while ((k < 5) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KP2V' then begin
						ParticleEmitter2[i].ParticleEmitter2Visibility := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2E' then begin
						ParticleEmitter2[i].ParticleEmitter2EmissionRate := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2W' then begin
						ParticleEmitter2[i].ParticleEmitter2Width := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2N' then begin
						ParticleEmitter2[i].ParticleEmitter2Length := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KP2S' then begin
						ParticleEmitter2[i].ParticleEmitter2Speed := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
				  end else
            Raise Exception.Create('Error on loading PRE2 : ' + filename);
        end;
			end;
			SetLength(ParticleEmitter2, i + 1);

		end else if opcode = 'RIBB' then begin
			SetLength(RibbonEmitter, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				RibbonEmitter[i].Node := Get_Node();

				posi := posi - p - 56;
				posj := posj - p - 56;

				RibbonEmitter[i].HeightAbove := Get_Float();
				RibbonEmitter[i].HeightBelow := Get_Float();
				RibbonEmitter[i].Alpha := Get_Float();
				RibbonEmitter[i].Color := Get_Float3();
				RibbonEmitter[i].LifeSpan := Get_Float();
				RibbonEmitter[i].Unk := Get_Dword();
				RibbonEmitter[i].EmissionRate := Get_Dword();
				RibbonEmitter[i].Rows := Get_Dword();
				RibbonEmitter[i].Columns := Get_Dword();
				RibbonEmitter[i].MaterialId := Get_Dword();
				RibbonEmitter[i].Gravity := Get_Dword();

				k := -1;
				while ((k < 3) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KRVS' then begin
						RibbonEmitter[i].RibbonEmitterVisibility := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KRHA' then begin
						RibbonEmitter[i].RibbonEmitterHeightAbove := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KRHB' then begin
						RibbonEmitter[i].RibbonEmitterHeightBelow := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;    
	  			end else
            Raise Exception.Create('Error on loading RIBB : ' + filename);
				end;
			end;
			SetLength(RibbonEmitter, i + 1);

		end else if opcode = 'CAMS' then begin
			SetLength(Camera, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				posj := Get_Dword();

				Camera[i].Name := Get_Char(80);
				Camera[i].Position := Get_Float3();
				Camera[i].FieldOfView := Get_Dword();
				Camera[i].FarClippingPlane := Get_Dword();
				Camera[i].NearClippingPlane := Get_Dword();
				Camera[i].TargetPosition := Get_Float3();

				posi := posi - p - 120;
				posj := posj - p - 120;

				k := -1;
				while ((k < 3) and (posi > 0) and (posj > 0)) do begin
					k := k + 1;
					opcode := Get_Char(4);
					posi := posi - 4;
					posj := posj - 4;
					if opcode = 'KCTR' then begin
						Camera[i].CameraPositionTranslation := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KTTR' then begin
						Camera[i].CameraTargetTranslation := Get_Transformation3();
						posi := posi - p;
						posj := posj - p;
					end else if opcode = 'KCRL' then begin
						Camera[i].CameraRotation := Get_Transformation1();
						posi := posi - p;
						posj := posj - p;
					end else begin
            Raise Exception.Create('Error on loading CAMS : ' + filename);
					end;
				end;
			end;
			SetLength(Camera, i + 1);

		end else if opcode = 'EVTS' then begin
			SetLength(EventObject, 255);
			posi := size;
			i := -1;
			while (posi > 0) do begin
				i := i + 1;
				EventObject[i].Node := Get_Node();
				posi := posi - 4 - p;

				if (posi > 0) then begin
					opcode := Get_Char(4);
					posi := posi - 4;
					if opcode = 'KEVT' then begin
						k := Get_Dword();
						EventObject[i].GlobalSequenceId := Get_Dword();
						posi := posi - 8;
						SetLength(EventObject[i].Tracks, k);
						for j := 0 to k - 1 do begin
							EventObject[i].Tracks[j] := Get_Dword();
							posi := posi - 4;
						end;
					end;
				end;
			end;
			SetLength(EventObject, i + 1);
		end;
	end;
  CloseFile(myFile);
end;

function Interpolate(t, t1, t2 : integer; v1, v2 : Float) : Float;
begin
	Result := v1 + ( (t - t1) / (t2 - t1) )  * (v2 - v1);
end;

function MDXModel.FindKey(Transfo : Transformation3; t, tmin : Integer) : integer;
var
	i : integer;
	len : integer;
	found : boolean;
begin
	len := Length(Transfo.Scaling);

	if len = 0 then
		Result := -1
	else begin
		i := 0;
		found := false;
		while (not found) and (i <= len - 1) do begin
			if Transfo.Scaling[i].Time = tmin then
				found := true
			else
				Inc(i);
		end;

		if (not found) then
			Result := -1
		else begin
			found := false;
			while (not found) and (i <= len - 1) do begin
				if Transfo.Scaling[i].Time >= t then
					found := true
				else
					Inc(i);
			end;
			if (not found) then
				Result := -1
			else
				Result := i;
		end;
	end;
end;

function MDXModel.FindKey(Transfo : Transformation4; t, tmin : Integer) : integer;
var
	i : integer;
	len : integer;
	found : boolean;
begin
	len := Length(Transfo.Scaling);

	if len = 0 then
		Result := -1
	else begin
		i := 0;
		found := false;
		while (not found) and (i <= len - 1) do begin
			if Transfo.Scaling[i].Time = tmin then
				found := true
			else
				Inc(i);
		end;

		if (not found) then
			Result := -1
		else begin
			found := false;
			while (not found) and (i <= len - 1) do begin
				if Transfo.Scaling[i].Time >= t then
					found := true
				else
					Inc(i);
			end;
			if (not found) then
				Result := -1
			else
				Result := i;
		end;
	end;
end;

function MDXModel.CalculatePos(Transfo : Transformation3; time, time1, time2 : integer) : Float3;
var
	m : integer;
begin
	m := FindKey(Transfo, time, time1);
	if (m <> -1) and (time = time1) then begin
		Result[0] := Transfo.Scaling[m].Value[0];
		Result[1] := Transfo.Scaling[m].Value[1];
		Result[2] := Transfo.Scaling[m].Value[2]
	end else if (m <> -1) then begin
		Result[0] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[0],
				Transfo.Scaling[m-1].Value[0]
			);
		Result[1] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[1],
				Transfo.Scaling[m-1].Value[1]
			);
		Result[2] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[2],
				Transfo.Scaling[m-1].Value[2]
			);
	end else begin
		Result[0] := 0;
		Result[1] := 0;
		Result[2] := 0;
	end;
end;

function o(a : TQuaternion) : Float4; overload;
begin
	Result[0] := a.ImagPart[0];
	Result[1] := a.ImagPart[1];
	Result[2] := a.ImagPart[2];
	Result[3] := a.RealPart;
end;

function o(a : Float4) : TQuaternion; overload;
begin
	Result.ImagPart[0] := a[0];
	Result.ImagPart[1] := a[1];
	Result.ImagPart[2] := a[2];
	Result.RealPart := a[3];
end;

function o(a : THomogeneousFltMatrix) : PGLfloat; overload;
var
	i : integer;
begin
	for i := 0 to 15 do
		Result[i] := a[i div 4][i mod 4];
end;

function MDXModel.CalculatePos(Transfo : Transformation4; time, time1, time2 : integer) : Float4;
var
	m : integer;
begin
	m := FindKey(Transfo, time, time1);
	if (m <> -1) and (time = time1) then begin
		Result[0] := Transfo.Scaling[m].Value[0];
		Result[1] := Transfo.Scaling[m].Value[1];
		Result[2] := Transfo.Scaling[m].Value[2];
		Result[3] := Transfo.Scaling[m].Value[3]
	end else if (m <> -1) then begin
//		Result := o(QuaternionSlerp(
//			o(Transfo.Scaling[m-1].Value),
//			o(Transfo.Scaling[m-1].Value),
//			0,
//			(time - Transfo.Scaling[m-1].Time) / (Transfo.Scaling[m].Time - Transfo.Scaling[m-1].Time)
//		));
		Result[0] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[0],
				Transfo.Scaling[m-1].Value[0]
			);
		Result[1] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[1],
				Transfo.Scaling[m-1].Value[1]
			);
		Result[2] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[2],
				Transfo.Scaling[m-1].Value[2]
			);
		Result[3] :=
			Interpolate(time,
				Transfo.Scaling[m].Time,
				Transfo.Scaling[m-1].Time,
				Transfo.Scaling[m].Value[3],
				Transfo.Scaling[m-1].Value[3]
			);
	end else begin
		Result[0] := 0;
		Result[1] := 0;
		Result[2] := 0;
		Result[3] := 1;
	end;
end;

function QuatToMatrix(q : Float4) : PGLFloat;
var
	x, y, z, w, xs, ys, zs, xx, yy, yz, xy, xz, zz, x2, y2, z2 : single;
begin
	x := q[0];
	y := q[1];
	z := q[2];
	w := q[3];

	x2 := x * 2;
	y2 := y * 2;
	z2 := z * 2;

	xx := x * x2;
	xy := x * y2;
	xz := x * z2;
	xs := w * x2;

	yy := y * y2;
	yz := y * z2;
	ys := w * y2;

	zz := z * z2;
	zs := w * z2;

	Result[0]  := 1 - (yy + zz);
	Result[4]  :=     (xy - zs);
	Result[8]  :=     (xz + ys);

	Result[1]  :=     (xy + zs);
	Result[5]  := 1 - (xx + zz);
	Result[9]  :=     (yz - xs);

	Result[2]  :=     (xz - ys);
	Result[6]  :=     (yz + xs);
	Result[10] := 1 - (xx + yy);

	Result[3]  := 0;
	Result[7]  := 0;
	Result[11] := 0;
	Result[12] := 0;
	Result[13] := 0;
	Result[14] := 0;
	Result[15] := 1;
end;

function MDXModel.GetTransfo(anim, time, i, j : integer) : PGLFloat;
var
	oMatrixList : array of PGLFLoat;
	len, l, m, n, oBone : integer;
	oTranslation : Float3;
begin
	len := Length(Geoset[i].Matrix[Geoset[i].VertexGroup[Geoset[i].Face[j][0]]]);
	SetLength(oMatrixList, len);
	for l := 0 to len - 1 do begin
		glPushMatrix();
		glLoadIdentity();
		oBone := Geoset[i].Matrix[Geoset[i].VertexGroup[Geoset[i].Face[j][0]]][l];

		glTranslatef(
			PivotPoint[Bone[oBone].Node.ObjectId][2],
			PivotPoint[Bone[oBone].Node.ObjectId][0],
			PivotPoint[Bone[oBone].Node.ObjectId][1]
		);

		Log(Bone[oBone].Node.Name);
		oTranslation := CalculatePos(Bone[oBone].Node.NodeTranslation, time, Sequence[anim].IntervalStart, Sequence[anim].IntervalEnd);
		glTranslatef(oTranslation[0], oTranslation[1], oTranslation[2]);

		glMultMatrixf(QuatToMatrix(CalculatePos(Bone[oBone].Node.NodeRotation, time, Sequence[anim].IntervalStart, Sequence[anim].IntervalEnd)));

		glTranslatef(
			-PivotPoint[Bone[oBone].Node.ObjectId][2],
			-PivotPoint[Bone[oBone].Node.ObjectId][0],
			-PivotPoint[Bone[oBone].Node.ObjectId][1]
		);

//			oScaling := CalculatePos(Bone[oBone].Node.NodeScaling, time, Sequence[anim].IntervalStart, Sequence[anim].IntervalEnd);

		glGetFloatv(GL_MODELVIEW_MATRIX, oMatrixList[l]);
		glPopMatrix();
	end;

	for m := 0 to 15 do begin
		Result[m] := 0;
		for n := 0 to len - 1 do
			Result[m] := Result[m] + oMatrixList[n][m];
		Result[m] := Result[m] / len;
	end;
end;

procedure MDXModel.DrawTriangle(i, j : integer);
var
	oTexture : Float2;
	oNormal, oVertex : Float3;
	f, k : integer;
begin
	glBegin(GL_TRIANGLES);
	for f := 0 to 2 do begin
		k := Geoset[i].Face[j][f];
		oTexture := Geoset[i].TexturePosition[k];
		oVertex := Geoset[i].VertexPosition[k];
		oNormal := Geoset[i].NormalPosition[k];

		glTexCoord2f( oTexture[0], oTexture[1] );
		glVertex3f( oVertex[0], oVertex[1], oVertex[2]);
		glNormal3f( oNormal[0], oNormal[1], oNormal[2]);
	end;
	glEnd();
end;

procedure MDXModel.ApplyTexture(anim, time, i, j : integer);
var
	l : integer;
	alpha : float;
begin
	glEnable(GL_DEPTH_TEST);
	for l := 0 to Length(Material[Geoset[i].MaterialId].Layer) - 1 do begin
//		float alpha=mat->getFrameAlpha(animInfo.currentFrame,l);
//		glEnable(GL_LIGHTING);

//		glColor4f(1, 1, 1, alpha);

		glEnable(GL_TEXTURE_2D);
		BindTexture(Texture[Material[Geoset[i].MaterialId].Layer[l].TextureId].Filename);
//		if (l < Length(Material[Geoset[i].MaterialId].Layer) - 1) then
//			glDisable(GL_LIGHTING)
//		else
//			glEnable(GL_LIGHTING);

		if (Material[Geoset[i].MaterialId].Layer[l].FilterMode = 1) then begin // transparent
			glEnable(GL_ALPHA_TEST);
			glAlphaFunc(GL_GREATER, 0.8);
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		end else if(Material[Geoset[i].MaterialId].Layer[l].FilterMode = 2) then begin // blend
			glDisable(GL_ALPHA_TEST);
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
			glDepthMask(true);
		end else if(Material[Geoset[i].MaterialId].Layer[l].FilterMode = 3 ) then begin // additive
			glEnable(GL_DEPTH_TEST);
			glDepthMask(true);
			glEnable(GL_BLEND);
			glBlendFunc(GL_ONE,GL_ONE);
			glDisable(GL_ALPHA_TEST);

			if (Texture[Material[Geoset[i].MaterialId].Layer[l].TextureId].ReplaceableId <> 2) then begin // ! team glow
				glColor4f(0.4, 0.4, 0.4, alpha/2);
				glEnable(GL_LIGHTING);
			end else
				glColor4f(1, 1, 1, 1);
		end else
			glDisable(GL_BLEND);
	end;
end;

procedure MDXModel.DisplayModel(time : int64; anim : integer);
var
	i, j : Integer;
	Transfo : PGLFLoat;
begin
	if length(Geoset) = 0 then
		exit;

	time := time div 5;
	time := (time - Sequence[anim].IntervalStart) mod (Sequence[anim].IntervalEnd - Sequence[anim].IntervalStart) + Sequence[anim].IntervalStart;
//	time := 2167;

	glEnable(GL_TEXTURE_2D);
	glEnable(GL_DEPTH_TEST);
	for i := 0 to length(Geoset) - 1 do begin
		for j := 0 to length(Geoset[i].Face) - 1 do begin
			Transfo := GetTransfo(anim, time, i, j);
			glPushMatrix();
			glLoadMatrixf(Transfo);
			ApplyTexture(anim, time, i, j);
			DrawTriangle(i, j);
			glPopMatrix();
		end;
	end;
	glDisable(GL_TEXTURE_2D);

end;

end.
