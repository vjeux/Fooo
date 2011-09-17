unit FStructure;

interface
uses
	Windows, FOpenGl, Classes;

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

  PSequenceChunk = ^SequenceChunk;
  SequenceChunk = Record
    Name : string[80];

    IntervalStart : Dword;
    IntervalEnd : Dword;
    MoveSpeed : Float;
    NonLooping : Dword;

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
    GLID : GLuint;
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

  PGeosetChunk = ^GeosetChunk;
	GeosetChunk = Record
    VertexPosition : array of Float3;
    TransformedVertexPosition : array of Float3;
    TransformedTime : array of integer;
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

  PNodeChunk = ^NodeChunk;
  NodeChunk = Record
    Name : string[80];
    ObjectId : Dword;
    ParentId : Dword;
    Flags : Dword;
		NodeTranslation : Transformation3;
    NodeRotation : Transformation4;
    NodeScaling : Transformation3;
    Matrix : PGLFloat;
    MatrixTime : Integer;
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

  pMdxModel = ^MdxModel;
  MdxModel = Record
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
		Light             : array of LightChunk;
		Helper            : array of NodeChunk;
    Attachment        : array of AttachmentChunk;
    PivotPoint        : array of Float3;
    ParticleEmitter   : array of ParticleEmitterChunk;
		ParticleEmitter2  : array of ParticleEmitter2Chunk;
    RibbonEmitter     : array of RibbonEmitterChunk;
    EventObject       : array of EventObjectChunk;
    Camera            : array of CameraChunk;
    CollisionShape    : array of CollisionShapeChunk;
    ObjectMaxId       : integer;
  end;

var
  Models : TStringList;
  LoadedModels : array of MDXModel;

implementation

end.

