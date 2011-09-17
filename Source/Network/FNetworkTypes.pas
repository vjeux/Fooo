unit FNetworkTypes;

interface

uses
  Types, FUnit;

const
  // InfoToUpdate
  TUNIT_STATE = 1;
  TUNIT_TARGET_ID = 2;
  TUNIT_POS = 4;
  TUNIT_HP = 8;
  TUNIT_MP = 16;
  TUNIT_STOP = 32;
  TUNIT_MOVE_ORDER = 64;
  TUNIT_TO_DELETE = 128;
  TUNIT_IN_CONSTRUCTION = 256;
  TUNIT_ATTACK = 512;
  TUNIT_ROTATING = 1024;
  TUNIT_ACTIVE = 2048;
  TUNIT_LAST_UP_MOVE = 4096;
  TUNIT_MP_REGEN = 8192;
  TUNIT_HP_REGEN = 16384;
  TUNIT_CONSTRUCTION_PERCENT = 32768;
  TUNIT_EFFECTS = 32768*2;
  TUNIT_TIMER_EFFECTS = 32768*4;


type

  string255 = string[255];

  PPacket = ^TPacket;
  TPacket = packed record
    id : integer;    
    execTime : int64;
  end;

  PNetPacket = ^TNetPacket;
  TNetPacket = packed record
    time : int64;
    buffer : pointer;
    SenderIP : string255;
  end;

  PPacketString = ^TPacketString;
  TPacketString = packed record
    id : integer;
    execTime : int64;
    rank : integer;
    SenderIP : string[255];
    SenderNick : string255;
    data : string[255];
  end;

  PPacketDamages = ^TPacketDamages;
  TPacketDamages = packed record
    id : integer;
    execTime : int64;
    targetID, HP : integer;
  end;

  PPacketSetServer = ^TPacketSetServer;
  TPacketSetServer = packed record
    id          : integer;
    execTime : int64;
    SenderNick  : string255;
    SenderRace  : integer;
    SenderTeam  : integer;
    SenderColor : integer;
  end;

  PPacketDisconnectServer = ^TPacketDisconnectServer;
  TPacketDisconnectServer = packed record
    id : integer;
    execTime : int64;
    ClientIP : string[255];
  end;

  PPacketCreateUnit = ^TPacketCreateUnit;
  TPacketCreateUnit = packed record
    id : integer;
    execTime : int64;
    unitID : integer;
    pos : Tpoint;
    Attributes : integer;
    Team : integer;
    creatorID : integer;
  end;

  PPacketSetClientAs = ^TPacketSetClientAs;
  TPacketSetClientAs = packed record
    id : integer;
    execTime : int64;
    rank : integer;
  end;

  PPacketBroadcast = ^TPacketBroadcast;
  TPacketBroadcast = packed record
    id : integer;
    execTime : int64;
  end;

  PPacketBroadcastAnser = ^TPacketBroadcastAnswer;
  TPacketBroadcastAnswer = packed record
    id : integer;
    execTime : int64;
    serverName : string255;
    player_count : integer;
    map : string255;
  end;

  PPacketOrder = ^TPacketOrder;
  TPacketOrder = packed record
    id : integer;
    execTime : int64;
    selfID : integer;
    OrderType : TorderType;
    pos : TPoint;
    TargetID : integer;
    add : boolean;
  end;

  PPacketClientIP = ^TPacketClientIP;
  TPacketClientIP = packed record
    id : integer;
    execTime : int64;
    ClientIP : string255;
  end;

  PPacketPlayer = ^TPacketPlayer;
  TPacketPlayer = packed record
    id : integer;
    execTime : int64;
    nick : string255;
    ip : string255;
    race, color, team : integer;
  end;

  PPacketPing = ^TPacketPing;
  TPacketPing = packed record
    id : integer;
    execTime : int64;
    pingTime : int64;
  end;

  PPacketLaunchGame = ^TPacketLaunchGame;
  TPacketLaunchGame = packed record
    id : integer;
    execTime : int64;
    synchronisationTime : integer;
  end;

  PPacketDisconnect = ^TPacketDisconnect;
  TPacketDisconnect = packed record
    id : integer;
    execTime : int64;
  end;

  PPacketPublicInfo = ^TPacketPublicInfo;
  TPacketPublicInfo = packed record
    id : integer;
    execTime : Int64;
    infoId : integer;
    color, race, team : integer;
    nick : string255;
    isYou : boolean;
    ip : string255;
  end;

  PPacketTUnit = ^TPacketTUnit;
  TPacketTUnit = packed record
    id : integer;
    execTime : int64;
    unitId : integer;
    InfoToUpdate : integer;
    speed, TardetId : integer;
    realPosX, realPosY, realPosZ : currency;
    posX, posY, posZ : integer;
    destPosX, destPosY, destPosZ : integer;
    HP, MP, HPRegen, MPRegen : double;
    AimedAngle : currency;
    ToDelete, InConstruction, RotationgClockWise, Rotating, active : boolean;
//    Effects : TLsit;
    last_up_move : int64;
    State : TUnitState;
    modelScale, maxHP, maxMP, Damage, Defense, Atk_speed, Atk_range : integer;
    TurnsRemaining, Last_tick, ticks : integer;
    Temporary : boolean;
    AbilityID, uID : integer;
    constructionPercent : double ;
  end;

  PPacketUpdateRessources = ^TPacketUpdateRessources;
  TPacketUpdateRessources = packed record
    id : integer;
    execTime : Int64;
    res1 : double;
    res2 : double;
  end;

implementation

end.
