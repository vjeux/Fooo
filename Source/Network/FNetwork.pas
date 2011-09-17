unit FNetwork;

interface

uses
  sysutils, winsock, FInterfaceDraw, FNetworkTypes  ;

type
  TNetwork = class
    public
      constructor connect();
      function receiveFrom(buffer : pointer ; var senderIP : string255) : integer;
      procedure sendToIp(ip: PAnsiChar; buffer: pointer ; l: integer);
      procedure broadcast(buffer: pointer ; l: integer);
      procedure disconnect();
    private
      FSocket : integer;
      blockMode : integer;
  end;

//var
//  socketGlobale : integer;

implementation
uses
  FTransmit;
const
  PORT : integer = 61440;
  BLOCK_MODE = 1; // 0 : block, <>0 : non-block

constructor TNetwork.connect();
var
  FServerAddress : TSockAddr;
  WSAData : TWSAData; // For winsock ini.
  NbErrors : byte;
begin

  NbErrors := 0;
//   Winsock initialisation
  if WSAStartup($101,wsaData) <> 0 then begin
    AddLine('Error #1 : Winsock initialisation failed');
    Inc(NbErrors);
  end;

//   Connection to socket
  self.blockMode := BLOCK_MODE;
  self.Fsocket := socket(AF_INET, SOCK_DGRAM, 0);
  ioctlsocket(self.Fsocket, FIONBIO, self.blockMode);
  if self.FSocket = -1 then begin
    AddLine('Error #2 :  Can''t connect to socket');
    Inc(NbErrors);
  end;

//   Setting self info
  FServerAddress.sin_family := AF_INET;
  FServerAddress.sin_port := PORT;
  FServerAddress.sin_addr.S_addr := INADDR_ANY; //inet_addr('10.12.110.57');
  FillChar(FServerAddress.sin_zero, sizeof(FServerAddress.sin_zero), '0');

//   Binding socket
  if bind(self.Fsocket, FServerAddress, sizeof(FServerAddress)) = -1 then begin
    AddLine('Error #3 :  Can''t bind socket');
    Inc(NbErrors);
  end;
  if NbErrors = 0 then begin
    //Addline('Connected');
//    socketGlobale := self.Fsocket;
  end else begin
    AddLine(IntToStr(NbErrors) + ' errors while trying to connect');
  end;
end;

function TNetwork.receiveFrom(buffer : pointer ; var senderIP : string255) : integer;
var
  FRecvFrom : integer;
  FClientAddress: TSockAddr;
  FClientAddressSize : integer;
begin
  // Receive data and put it in the buffer
//  FClientAddressSize := sizeof(FClientAddress);
  FRecvFrom := RecvFrom(self.FSocket,
                        buffer^,
                        1024,
                        0,
                        FClientAddress,
                        FClientAddressSize);
  SenderIP := inet_ntoa(FClientAddress.sin_addr);
  if FRecvFrom = -1 then begin
    result := -1;
  end else begin
    if FRecvFrom = 0 then begin
      result := 0;
      Addline('Received zero');
    end else begin
      result := 1;
    end;
  end;
end;

procedure TNetwork.sendToIp(ip: PAnsiChar; buffer: pointer ; l: integer);
var
  FServerAddress : TSockAddr;
  FServerAddressSize : integer;
  FSendTo : integer;
begin
  // Definition de l'addresse du serveur
  FServerAddress.sin_family := AF_INET;
  FServerAddress.sin_port := PORT;
  FServerAddress.sin_addr.S_addr := inet_addr(ip);
  FillChar(FServerAddress.sin_zero, sizeof(FServerAddress.sin_zero), '0');

  // Sending data
  FServerAddressSize := sizeof(FServerAddress);
  FSendTo := SendTo(self.FSocket,
                    buffer^,
                    l,
                    0,
                    FServerAddress,
                    FServerAddressSize);
  if FSendTo = -1 then begin
    Addline('Error #5 :  Can''t send to ' + inet_ntoa(FServerAddress.sin_addr));
  end else begin
    Addline(IntToStr(FSendTo) + ' bytes sent to ' + inet_ntoa(FServerAddress.sin_addr));
  end;
end;

procedure TNetwork.broadcast(buffer: pointer ; l: integer);
var
  FServerAddress : TSockAddr;
  FServerAddressSize : integer;
  FSendTo : integer;
  bc : PAnsiChar;
begin
  Addline('Sending broadcast...');
  bc := '1';
  setsockopt(Self.FSocket, SOL_SOCKET ,SO_BROADCAST, bc, sizeof(bc));
  // Definition de l'addresse du serveur
  FServerAddress.sin_family := AF_INET;
  FServerAddress.sin_port := PORT;
  FServerAddress.sin_addr.S_addr := inet_addr('255.255.255.255');
  FillChar(FServerAddress.sin_zero, sizeof(FServerAddress.sin_zero), '0');

  // Sending data
  FServerAddressSize := sizeof(FServerAddress);
  FSendTo := SendTo(self.FSocket,
                    buffer^,
                    l,
                    0,
                    FServerAddress,
                    FServerAddressSize);
  if FSendTo = -1 then begin
    Addline('Error #5 :  Can''t send to ' + inet_ntoa(FServerAddress.sin_addr));
  end else begin
    Addline(IntToStr(FSendTo) + ' bytes sent to ' + inet_ntoa(FServerAddress.sin_addr));
  end;
end;

procedure TNetwork.disconnect();
begin
  Shutdown(self.FSocket, 1);

  // Loop on receive to clean the socket...
//  while receiveNetwork() <> -1 do begin
//    Addline('Cleaning Socket...');
//  end;

  CloseSocket(self.FSocket);
  WSACleanup();
  AddLine('Connection closed');
end;

end.
