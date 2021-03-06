unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, System.generics.collections, Vcl.Dialogs,
  System.Win.ScktComp, uClsConexoes, Vcl.ExtCtrls,
  Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, Vcl.Grids, Vcl.DBGrids, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.ComCtrls;

type
  TThreadConnection_Define = class(TThread)
  private
    defineSocket: TCustomWinSocket;
  public
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
  end;

type
  TThreadConnection_Main = class(TThread)
  private
    mainSocket: TCustomWinSocket;
    targetMainSocket: TCustomWinSocket;
    ID: string;
    Password: string;
    NameMachine: string;
    soMachime : string;
    TargetIDM: string;
    TargetPassword: string;
    StartPing: Int64;
    EndPing: Int64;
  public
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
    procedure AddItems;
  end;

type
  TThreadConnection_Desktop = class(TThread)
  private
    desktopSocket: TCustomWinSocket;
    targetDesktopSocket: TCustomWinSocket;
    MyID: string;
  public
    constructor Create(aSocket: TCustomWinSocket; ID: string); overload;
    procedure Execute; override;
  end;

  // Thread to Define type connection are Keyboard.
type
  TThreadConnection_Keyboard = class(TThread)
  private
    keyboardSocket: TCustomWinSocket;
    targetKeyboardSocket: TCustomWinSocket;
    MyID: string;
  public
    constructor Create(aSocket: TCustomWinSocket; ID: string); overload;
    procedure Execute; override;
  end;

  // Thread to Define type connection are Files.
type
  TThreadConnection_Files = class(TThread)
  private
    filesSocket: TCustomWinSocket;
    targetFilesSocket: TCustomWinSocket;
    MyID: string;
  public
    constructor Create(aSocket: TCustomWinSocket; ID: string); overload;
    procedure Execute; override;
  end;

type
  TfMain = class(TForm)
    Ping_Timer: TTimer;
    Logs_Memo: TMemo;
    Connections_ListView: TListView;
    Panel1: TPanel;
    chExibir: TCheckBox;
    procedure Ping_TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chExibirClick(Sender: TObject);
  private
    procedure Main_ServerSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure Main_ServerSocketClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    { Private declarations }
  public
    lista: TObjectList<TuserConnect>;
    Main_ServerSocket: TServerSocket;
    { Public declarations }
  end;

var
  fMain: TfMain;
  ID_cliente, senha_cliente, apelidoCli, SoCli: string;

const
  Port = 3898; // Port for Socket;
  ProcessingSlack = 2; // Processing slack for Sleep Commands

implementation

{$R *.dfm}
{ TThreadConnection_Define }

constructor TThreadConnection_Define.Create(aSocket: TCustomWinSocket);
begin
  inherited Create(False);
  defineSocket := aSocket;
  FreeOnTerminate := true;
end;

function CheckIDExists(ID: string): Boolean;
var
  userconn: TuserConnect;
  Exists: Boolean;
begin
  Exists := False;
  for userconn in fMain.lista.List do
  begin
    if userconn = nil then
      Continue;
    if userconn.ID = ID then
    begin
      Exists := true;
      break
    end;
  end;
  Result := Exists;
end;


function GenerateID(): string;
var
  i: Integer;
  ID: string;
  Exists: Boolean;
begin
  Exists := False;

  while true do
  begin
    Randomize;
    ID := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + '-'
      + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + '-' +
      IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));
    i := 0;
    if CheckIDExists(ID) then
      exists := true;
    if not(Exists) then
      break;
  end;
  Result := ID;
end;

function GeneratePassword(): string;
begin
  Randomize;
  Result := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) +
    IntToStr(Random(9));
end;

function GetAppVersionStr: string;
type
  TBytes = array of Byte;
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);

  if Size = 0 then
    RaiseLastOSError;

  SetLength(Buffer, Size);

  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;

  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;

  Result := Format('%d.%d.%d.%d', [LongRec(FixedPtr.dwFileVersionMS).Hi,
    // major
    LongRec(FixedPtr.dwFileVersionMS).Lo, // minor
    LongRec(FixedPtr.dwFileVersionLS).Hi, // release
    LongRec(FixedPtr.dwFileVersionLS).Lo]) // build
end;

procedure TThreadConnection_Define.Execute;
var
  Buffer: string;
  BufferTemp: string;
  ID: string;
  position: Integer;
  ThreadMain: TThreadConnection_Main;
  ThreadDesktop: TThreadConnection_Desktop;
  ThreadKeyboard: TThreadConnection_Keyboard;
  ThreadFiles: TThreadConnection_Files;
begin
  inherited;
  while true do
  begin
    Sleep(ProcessingSlack);

    if (defineSocket = nil) or not(defineSocket.Connected) then
      break;

    if defineSocket.ReceiveLength < 1 then
      Continue;

    Buffer := defineSocket.ReceiveText;

    position := Pos('<|MAINSOCKET|>', Buffer);
    // Storing the position in an integer variable will prevent it from having to perform two searches, gaining more performance
    if position > 0 then
    begin
      BufferTemp := Buffer;
      position := Pos('<|APELIDO|', BufferTemp);
      if position > 0 then
      begin
        Delete(BufferTemp, 1, position + 9);
        apelidoCli := Copy(BufferTemp, 1, Pos('|APELIDO|>', BufferTemp) - 1);
      end;
      // ID_cliente
      position := Pos('<|IDCLIENTE|', BufferTemp);
      if position > 0 then
      begin
        Delete(BufferTemp, 1, position + 11);
        ID_cliente := Copy(BufferTemp, 1, Pos('|IDCLIENTE|>', BufferTemp) - 1);
      end;
      position := Pos('<|SO|', BufferTemp);
      if position > 0 then
      begin
        Delete(BufferTemp, 1, position + 4);
        SoCli := Copy(BufferTemp, 1, Pos('|SO|>', BufferTemp) - 1);
      end;
      // Create the Thread for Main Socket
      ThreadMain := TThreadConnection_Main.Create(defineSocket);
      break; // Break the while
    end;
    position := Pos('<|DESKTOPSOCKET|>', Buffer);
    // For example, I stored the position of the string I wanted to find
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 16);
      // So since I already know your position, I do not need to pick it up again
      ID := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      // Create the Thread for Desktop Socket
      ThreadDesktop := TThreadConnection_Desktop.Create(defineSocket, ID);
      break; // Break the while
    end;

    position := Pos('<|KEYBOARDSOCKET|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 17);
      ID := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      // Create the Thread for Keyboard Socket
      ThreadKeyboard := TThreadConnection_Keyboard.Create(defineSocket, ID);
      break; // Break the while
    end;

    position := Pos('<|FILESSOCKET|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Pos('<|FILESSOCKET|>', Buffer) + 14);
      ID := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      // Create the Thread for Files Socket
      ThreadFiles := TThreadConnection_Files.Create(defineSocket, ID);
      break; // Break the while
    end;
  end;

end;

{ TThreadConnection_Main }

procedure TThreadConnection_Main.AddItems;
begin
  fMain.lista.Add(TuserConnect.Create);
  with fMain.lista.Last do
  begin
    if ID_cliente = '' then
      ID := GenerateID
    else
      ID := ID_cliente;
    Password := GeneratePassword;
    mainsockethandle := mainSocket.Handle;
    ipaddress := mainSocket.RemoteAddress;
    soMaquina := SoCli;
    apelido := apelidoCli;
    datahora := Now;
    dadosping := 'Calculating..';
    data := TObject(0);
  end;
  apelidoCli := '';
  ID_cliente := '';
  SoCli := '';
end;

constructor TThreadConnection_Main.Create(aSocket: TCustomWinSocket);
begin
  inherited Create(False);
  mainSocket := aSocket;
  StartPing := 0;
  EndPing := 256;
  FreeOnTerminate := true;
end;

function FindListItemID(ID: string): TuserConnect;
var
  userconn: TuserConnect;
  Exists: Boolean;
begin
  for userconn in fMain.lista.List do
  begin
    if userconn = nil then
      Continue;
    if userconn.ID = ID then
    begin
      Exists := true;
      break
    end;
  end;
  if Exists then
    Result := userconn
  else
    Result := nil;
end;


function CheckIDPassword(ID, Password: string): Boolean;
var
  userconn: TuserConnect;
  Correct: Boolean;
begin
  Correct := False;
  for userconn in fMain.lista.List do
  begin
    if userconn = nil then
      Continue;
    if (userconn.ID = ID) and (userconn.Password = Password) then
    begin
      Correct := true;
      break;
    end;
  end;
  Result := Correct;
end;

procedure TThreadConnection_Main.Execute;
var
  Buffer: string;
  BufferTemp: string;
  position: Integer;
  userconn, ulist: TuserConnect;
  L, L2: TuserConnect;
  lexiste: Boolean;
begin
  inherited;
  Synchronize(AddItems);
  for userconn in fMain.lista.List do
  begin
    if userconn = nil then
      Continue;
    if userconn.mainsockethandle = mainSocket.Handle then
      break
  end;
  if userconn <> nil then
    userconn.data := TObject(self);

 // addlog('TThreadConnection_Main.Execute manda ID p cliente ' + userconn.ID +
 //   ' ' + userconn.Password);

  while mainSocket.SendText('<|ID|>' + userconn.ID + '<|>' + userconn.Password +
    '<|END|>') < 0 do
    Sleep(ProcessingSlack);

  while true do
  begin
    Sleep(ProcessingSlack);

    if (mainSocket = nil) or not(mainSocket.Connected) then
      break;

    if mainSocket.ReceiveLength < 1 then
      Continue;

    Buffer := mainSocket.ReceiveText;
//    if (not Buffer.Contains('<|PONG|>')) and
//      (not Buffer.Contains('<|SETMOUSEPOS|>')) then
//      addlog('Buffer proc ' + userconn.ID + ' ' + Buffer);
    position := 0;
    position := Pos('<|GETLISTA|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := '';
      for ulist in fMain.lista.List do
      begin
        if ulist = nil then
          Continue;
        BufferTemp := BufferTemp + ulist.ID + ' - ' + ulist.Password + ' - ' +
          ulist.apelido;
      end;
      if BufferTemp <> '' then
        while mainSocket.SendText('<|LISTAIDS|>' + BufferTemp +
          '<|END|>') < 0 do
          Sleep(ProcessingSlack);
    end;
    position := 0;
    position := Pos('<|FINDID|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 9);
      TargetIDM := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);

      if (CheckIDExists(TargetIDM)) then
      begin
        if (FindListItemID(TargetIDM).TargetID = '') then
        begin
          while mainSocket.SendText('<|IDEXISTS!REQUESTPASSWORD|>') < 0 do
            Sleep(ProcessingSlack);
        end
        else
        begin
          while mainSocket.SendText('<|ACCESSBUSY|>') < 0 do
            Sleep(ProcessingSlack);
        end
      end
      else
      begin
        while mainSocket.SendText('<|IDNOTEXISTS|>') < 0 do
          Sleep(ProcessingSlack);
      end;
    end;
    if Buffer.Contains('<|PONG|>') then
    begin
      EndPing := GetTickCount - StartPing;
      if userconn <> nil then
        userconn.dadosping := IntToStr(EndPing) + ' ms';
    end;
    position := 0;
    position := Pos('<|CHECKIDPASSWORD|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 18);
      position := Pos('<|>', BufferTemp);
      TargetIDM := Copy(BufferTemp, 1, position - 1);
      Delete(BufferTemp, 1, position + 2);
      TargetPassword := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);

      if (CheckIDPassword(TargetIDM, TargetPassword)) then
      begin
        while mainSocket.SendText('<|ACCESSGRANTED|>') < 0 do
          Sleep(ProcessingSlack);
      end
      else
      begin
        while mainSocket.SendText('<|ACCESSDENIED|>') < 0 do
          Sleep(ProcessingSlack);
      end;
    end;
    position := 0;
    position := Pos('<|RELATION|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 11);
      position := Pos('<|>', BufferTemp);
      ID := Copy(BufferTemp, 1, position - 1);
      Delete(BufferTemp, 1, position + 2);
      TargetIDM := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      for ulist in fMain.lista.List do
      // pesquisa na lista e faz a ligacao dos IDs
      begin
        if ulist = nil then
          Continue;
        if ulist.ID = ID then
        begin
          ulist.TargetID := TargetIDM;
          L := ulist;
        end;
        if ulist.ID = TargetIDM then
        begin
          ulist.TargetID := ID;
          L2 := ulist;
        end;
      end;
      // Relates the main Sockets
      if L2.data <> nil then
        TThreadConnection_Main(L.data).targetMainSocket :=
          TThreadConnection_Main(L2.data).mainSocket;
      if L.data <> nil then
        TThreadConnection_Main(L2.data).targetMainSocket :=
          TThreadConnection_Main(L.data).mainSocket;
      // Relates the Remote Desktop
      if L2.dadosDesk <> nil then
        TThreadConnection_Desktop(L.dadosDesk).targetDesktopSocket :=
          TThreadConnection_Desktop(L2.dadosDesk).desktopSocket;
      if L.dadosDesk <> nil then
        TThreadConnection_Desktop(L2.dadosDesk).targetDesktopSocket :=
          TThreadConnection_Desktop(L.dadosDesk).desktopSocket;
      // Relates the Keyboard Socket
      if L2.dadosKeyb <> nil then
        TThreadConnection_Keyboard(L.dadosKeyb).targetKeyboardSocket :=
          TThreadConnection_Keyboard(L2.dadosKeyb).keyboardSocket;
      // Relates the Share Files
      if L2.dadosFiles <> nil then
        TThreadConnection_Files(L.dadosFiles).targetFilesSocket :=
          TThreadConnection_Files(L2.dadosFiles).filesSocket;
      if L.dadosFiles <> nil then
        TThreadConnection_Files(L2.dadosFiles).targetFilesSocket :=
          TThreadConnection_Files(L.dadosFiles).filesSocket;
      // Warns Access
      if L.data <> nil then
        TThreadConnection_Main(L.data).targetMainSocket.SendText('<|ACCESSING|>');

       if L2.data <> nil then
        TThreadConnection_Main(L.data).mainSocket.SendText('<|TARGETSO'+L2.soMaquina+'TARGETSO|>');


      // Get first screenshot
      if L.dadosDesk <> nil then
        TThreadConnection_Desktop(L.dadosDesk).targetDesktopSocket.SendText
          ('<|GETFULLSCREENSHOT|>');
    end;
    if Buffer.Contains('<|STOPACCESS|>') then
    begin
//      addlog(' <|STOPACCESS|> ' + userconn.ID + ' ' + userconn.apelido);
      mainSocket.SendText('<|DISCONNECTED|>');
      targetMainSocket.SendText('<|DISCONNECTED|>');
      targetMainSocket := nil;
      if userconn.TargetID <> '' then
      begin
        L2 := FindListItemID(TargetIDM);
        userconn.TargetID := '';
        if L2 <> nil then
        begin
          TThreadConnection_Main(L2.data).targetMainSocket := nil;
          L2.TargetID := '';
        end;
      end;
    end;
    position := Pos('<|REDIRECT|>', Buffer);
    if position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, position + 11);
      if (Pos('<|FOLDERLIST|>', BufferTemp) > 0) then
      begin
        while (mainSocket.Connected) do
        begin
          Sleep(ProcessingSlack); // Avoids using 100% CPU

          if (Pos('<|ENDFOLDERLIST|>', BufferTemp) > 0) then
            break;

          BufferTemp := BufferTemp + mainSocket.ReceiveText;
        end;
      end;
      if (Pos('<|FILESLIST|>', BufferTemp) > 0) then
      begin
        while (mainSocket.Connected) do
        begin
          Sleep(ProcessingSlack); // Avoids using 100% CPU

          if (Pos('<|ENDFILESLIST|>', BufferTemp) > 0) then
            break;

          BufferTemp := BufferTemp + mainSocket.ReceiveText;
        end;
      end;
      if (targetMainSocket <> nil) and (targetMainSocket.Connected) then
      begin
        while targetMainSocket.SendText(BufferTemp) < 0 do
          Sleep(ProcessingSlack);
      end;
    end;
  end;
  if (targetMainSocket <> nil) and (targetMainSocket.Connected) then
  begin
//    addlog('send <|DISCONNECTED|> ' + userconn.ID + ' ' + userconn.apelido);
    while targetMainSocket.SendText('<|DISCONNECTED|>') < 0 do
      Sleep(ProcessingSlack);
  end;
  // desconexao
  if userconn <> nil then
  begin
//    addlog('lista.Delete ' + userconn.ID + ' AP ' + userconn.apelido + ' TGID '
 //     + userconn.TargetID);
    if userconn.TargetID <> '' then
    begin
      for ulist in fMain.lista.List do
      begin
        if ulist = nil then
          Continue;
        if ulist.ID = userconn.TargetID then
        begin
          ulist.TargetID := '';
          break
        end;
      end;
    end;
    fMain.lista.Delete(fMain.lista.IndexOf(userconn));
  end;
end;

procedure TfMain.chExibirClick(Sender: TObject);
begin
   Connections_ListView.Clear;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  lista := TObjectList<TuserConnect>.Create;
  Main_ServerSocket := TServerSocket.Create(self);
  Main_ServerSocket.Active := False;
  Main_ServerSocket.ServerType := stNonBlocking;
  Main_ServerSocket.OnClientConnect := Main_ServerSocketClientConnect;
  Main_ServerSocket.OnClientError := Main_ServerSocketClientError;
  Main_ServerSocket.Port := Port;
  Main_ServerSocket.Active := true;
  Caption := Caption + ' - ' + GetAppVersionStr;
end;

procedure TfMain.Main_ServerSocketClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  ErrorCode := 0;
end;

procedure TfMain.Main_ServerSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  // Create Defines Thread of Connections
  TThreadConnection_Define.Create(Socket);
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  lista.Free;
end;

procedure RegisterErrorLog(Header: string; ClassError: string;
  MessageText: string);
begin
  with fMain do
  begin
    Logs_Memo.Lines.Add(' ');
    Logs_Memo.Lines.Add(' ');
    Logs_Memo.Lines.Add('--------');
    Logs_Memo.Lines.Add(Header + ' (Class: ' + ClassError + ')');
    Logs_Memo.Lines.Add('Error: ' + MessageText);
    Logs_Memo.Lines.Add('--------');
  end;
end;

procedure TfMain.Ping_TimerTimer(Sender: TObject);
var
  i: Integer;
  Item: TListItem;
  Connection: TThreadConnection_Main;
  plista: TuserConnect;
begin
  try
    if chExibir.Checked then
    begin
      Connections_ListView.Items.BeginUpdate;
      Connections_ListView.Items.Clear;
    end;
    try
      for plista in lista.List do
      begin
        if plista = nil then
          Continue;
        if plista.data = nil then
          Continue;
        Connection := TThreadConnection_Main(plista.data);
        if (Connection.mainSocket = nil) or not(Connection.mainSocket.Connected)
        then
          Continue;

        if chExibir.Checked then
        begin
          Item := Connections_ListView.Items.Add;
          item.Caption := plista.mainsockethandle.ToString;
          Item.SubItems.Add(plista.ipaddress);
          Item.SubItems.Add(plista.ID);
          Item.SubItems.Add(plista.password);
          Item.SubItems.Add(plista.TargetID);
          Item.SubItems.Add(plista.dadosping);
          Item.SubItems.Add(plista.apelido);
          Item.SubItems.Add(datetimetostr(plista.datahora));
          Item.SubItems.Add(plista.soMaquina);
        end;
        Connection.mainSocket.SendText('<|PING|>');
        Connection.StartPing := GetTickCount;

        if plista.dadosping <> 'Calculating...' then
          Connection.mainSocket.SendText
            ('<|SETPING|>' + IntToStr(Connection.EndPing) + '<|END|>');
      end;
    except
      On E: Exception do
        RegisterErrorLog('Ping Timer', E.ClassName, E.Message);
    end;
  finally
    if chExibir.Checked then
      Connections_ListView.Items.EndUpdate;
  end;
end;

{ TThreadConnection_Desktop }

constructor TThreadConnection_Desktop.Create(aSocket: TCustomWinSocket;
  ID: string);
begin
  inherited Create(False);
  desktopSocket := aSocket;
  MyID := ID;
  FreeOnTerminate := true;
end;

procedure TThreadConnection_Desktop.Execute;
var
  Buffer: string;
  plista: TuserConnect;
begin
  inherited;
  for plista in fMain.lista.List do
  begin
    if plista = nil then
      Continue;
    if plista.ID = MyID then
    begin
      plista.dadosDesk := TObject(self);
      break;
    end;
  end;
  while true do
  begin
    Sleep(ProcessingSlack);

    if (desktopSocket = nil) or not(desktopSocket.Connected) then
      break;

    if desktopSocket.ReceiveLength < 1 then
      Continue;

    Buffer := desktopSocket.ReceiveText;

    if (targetDesktopSocket <> nil) and (targetDesktopSocket.Connected) then
    begin
      while targetDesktopSocket.SendText(Buffer) < 0 do
        Sleep(ProcessingSlack);
    end;
  end;
end;

{ TThreadConnection_Keyboard }

constructor TThreadConnection_Keyboard.Create(aSocket: TCustomWinSocket;
  ID: string);
begin
  inherited Create(False);
  keyboardSocket := aSocket;
  MyID := ID;
  FreeOnTerminate := true;
end;

procedure TThreadConnection_Keyboard.Execute;
var
  Buffer: string;
  plista: TuserConnect;
begin
  inherited;
  for plista in fMain.lista.List do
  begin
    if plista = nil then
      Continue;
    if plista.ID = MyID then
    begin
      plista.dadosKeyb := TObject(self);
      break;
    end;
  end;
  while true do
  begin
    Sleep(ProcessingSlack);

    if (keyboardSocket = nil) or not(keyboardSocket.Connected) then
      break;

    if keyboardSocket.ReceiveLength < 1 then
      Continue;

    Buffer := keyboardSocket.ReceiveText;

    if (targetKeyboardSocket <> nil) and (targetKeyboardSocket.Connected) then
    begin
      while targetKeyboardSocket.SendText(Buffer) < 0 do
        Sleep(ProcessingSlack);
    end;
  end;

end;

{ TThreadConnection_Files }

constructor TThreadConnection_Files.Create(aSocket: TCustomWinSocket;
  ID: string);
begin
  inherited Create(False);
  filesSocket := aSocket;
  MyID := ID;
  FreeOnTerminate := true;
end;

procedure TThreadConnection_Files.Execute;
var
  Buffer: string;
  plista: TuserConnect;
begin
  inherited;
  for plista in fMain.lista.List do
  begin
    if plista = nil then
      Continue;
    if plista.ID = MyID then
    begin
      plista.dadosFiles := TObject(self);
      break;
    end;
  end;
  while true do
  begin
    Sleep(ProcessingSlack);

    if (filesSocket = nil) or not(filesSocket.Connected) then
      break;

    if filesSocket.ReceiveLength < 1 then
      Continue;

    Buffer := filesSocket.ReceiveText;

    if (targetFilesSocket <> nil) and (targetFilesSocket.Connected) then
    begin
      while targetFilesSocket.SendText(Buffer) < 0 do
        Sleep(ProcessingSlack);
    end;
  end;
end;

end.
