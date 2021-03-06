unit Form_RemoteScreen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, IdGlobal, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Buttons;

type
  TTagAbrefecha   = (teAbrir, teFechar);
  TExecuteProc = Reference to Procedure;

  Tfrm_RemoteScreen = class(TForm)
    ScrollBox1: TScrollBox;
    Pnl_menu: TPanel;
    MouseIcon_Image: TImage;
    KeyboardIcon_Image: TImage;
    ResizeIcon_Image: TImage;
    MouseRemote_CheckBox: TCheckBox;
    KeyboardRemote_CheckBox: TCheckBox;
    Resize_CheckBox: TCheckBox;
    MouseIcon_checked_Image: TImage;
    KeyboardIcon_checked_Image: TImage;
    ResizeIcon_checked_Image: TImage;
    ResizeIcon_unchecked_Image: TImage;
    KeyboardIcon_unchecked_Image: TImage;
    MouseIcon_unchecked_Image: TImage;
    CaptureKeys_Timer: TTimer;
    Chat_Image: TImage;
    FileShared_Image: TImage;
    ScreenStart_Image: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Screen_Image: TImage;
    Label4: TLabel;
    btnFechar: TSpeedButton;
    btnabrir: TSpeedButton;
    Procedure Resize_CheckBoxClick(Sender: TObject);
    Procedure Resize_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure KeyboardRemote_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure MouseRemote_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure KeyboardRemote_CheckBoxClick(Sender: TObject);
    Procedure MouseRemote_CheckBoxClick(Sender: TObject);
    Procedure SendSocketKeys(Keys: string);
    Procedure CaptureKeys_TimerTimer(Sender: TObject);
    Procedure Chat_ImageClick(Sender: TObject);
    Procedure FileShared_ImageClick(Sender: TObject);
    Procedure FormClose(Sender: TObject; var Action: TCloseAction);
    Procedure FormShow(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
      var Handled: Boolean);
    Procedure Label3Click(Sender: TObject);
    Procedure Screen_ImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    Procedure Screen_ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    Procedure Screen_ImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    Procedure Screen_ImageDblClick(Sender: TObject);
    Procedure Label4Click(Sender: TObject);
    Procedure btnabrirClick(Sender: TObject);
    Procedure btnFecharClick(Sender: TObject);
    Procedure FormResize(Sender: TObject);
  private
    Procedure WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    Procedure Rolarmenu(Value: TTagAbrefecha = teAbrir);
    Procedure MoverBotoes;
    { Private declarations }
  public
    Direcao                        : TTagAbrefecha;
    CtrlPressed, ShiftPressed, AltPressed: Boolean;
    { Public declarations }
  end;

var
  frm_RemoteScreen: Tfrm_RemoteScreen;

implementation

{$R *.dfm}

uses
  Form_Main, Form_Chat, Form_ShareFiles, uClsMouseSendRec;

Procedure Tfrm_RemoteScreen.WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo);
{ sets Size-limits for the Form }
var
  MinMaxInfo: PMinMaxInfo;
begin
  inherited;
  MinMaxInfo                   := message.MinMaxInfo;
  MinMaxInfo^.ptMinTrackSize.X := 800; // Minimum Width
  MinMaxInfo^.ptMinTrackSize.Y := 500; // Minimum Height

  if (Resize_CheckBox.Checked) then
  begin
    MinMaxInfo^.ptMaxTrackSize.X := frm_Main.ResolutionTargetWidth;
    MinMaxInfo^.ptMaxTrackSize.Y := frm_Main.ResolutionTargetHeight;
  end
  else
  begin
    MinMaxInfo^.ptMaxTrackSize.X := frm_Main.ResolutionTargetWidth + 25;
    MinMaxInfo^.ptMaxTrackSize.Y := frm_Main.ResolutionTargetHeight + 130;
  end;
end;

Procedure Tfrm_RemoteScreen.Screen_ImageDblClick(Sender: TObject);
begin
  if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    if (frm_Main.lsoTarget <> '') then
    begin
      if not frm_Main.lsoTarget.ToUpper.Contains('WINDOWS 10') then
        frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEDOUBLECLICK|>');
    end
    else
      frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEDOUBLECLICK|>');
  end;
end;

Procedure Tfrm_RemoteScreen.Screen_ImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  bLord, bAction: string;
begin
  if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * frm_Main.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * frm_Main.ResolutionTargetHeight) div (Screen_Image.Height);
    case Button of
      mbLeft:
        bLord := 'L';
      mbRight:
        bLord := 'R';
    else
      bLord := 'X';
    end;
    bAction := 'D';
    frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|MOUSE|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|>' + bAction +
      '<|>' + bLord + '<|END|>');
  end;
end;

Procedure Tfrm_RemoteScreen.Screen_ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * frm_Main.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * frm_Main.ResolutionTargetHeight) div (Screen_Image.Height);
    frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEPOS|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>');
  end;
end;

Procedure Tfrm_RemoteScreen.Screen_ImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  bLord, bAction: string;
begin
  if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * frm_Main.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * frm_Main.ResolutionTargetHeight) div (Screen_Image.Height);
    case Button of
      mbLeft:
        bLord := 'L';
      mbRight:
        bLord := 'R';
    else
      bLord := 'X';
    end;
    bAction := 'U';
    frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|MOUSE|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|>' + bAction +
      '<|>' + bLord + '<|END|>');
  end;
end;

Procedure Tfrm_RemoteScreen.SendSocketKeys(Keys: string);
begin
  if (Active) then
    frm_Main.Keyboard_Socket.Socket.SendText(ansistring(Keys));
end;

Procedure Tfrm_RemoteScreen.btnabrirClick(Sender: TObject);
begin
  Direcao := teAbrir;
  Rolarmenu(Direcao);
end;

Procedure Tfrm_RemoteScreen.btnFecharClick(Sender: TObject);
begin
  Direcao := teFechar;
  Rolarmenu(Direcao);
end;

Procedure Tfrm_RemoteScreen.CaptureKeys_TimerTimer(Sender: TObject);
var
  i: Byte;
begin
  // The keys programmed here, may not match the keys on your keyboard. I recommend to undertake adaptation.
  try
    { Combo }
    if (Active) then
    begin
      // Alt
      if not(AltPressed) then
      begin
        if (GetKeyState(VK_MENU) < 0) then
        begin
          AltPressed := true;
          SendSocketKeys('<|ALTDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_MENU) > -1) then
        begin
          AltPressed := false;
          SendSocketKeys('<|ALTUP|>');
        end;
      end;

      // Ctrl
      if not(CtrlPressed) then
      begin
        if (GetKeyState(VK_CONTROL) < 0) then
        begin
          CtrlPressed := true;
          SendSocketKeys('<|CTRLDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_CONTROL) > -1) then
        begin
          CtrlPressed := false;
          SendSocketKeys('<|CTRLUP|>');
        end;
      end;

      // Shift
      if not(ShiftPressed) then
      begin
        if (GetKeyState(VK_SHIFT) < 0) then
        begin
          ShiftPressed := true;
          SendSocketKeys('<|SHIFTDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_SHIFT) > -1) then
        begin
          ShiftPressed := false;
          SendSocketKeys('<|SHIFTUP|>');
        end;
      end;
    end;

    for i := 8 to 228 do
    begin
      if (GetAsyncKeyState(i) = -32767) then
      begin
        case i of
          8:
            SendSocketKeys('{BS}');
          9:
            SendSocketKeys('{TAB}');
          13:
            SendSocketKeys('{ENTER}');
          27:
            SendSocketKeys('{ESCAPE}');
          32:
            SendSocketKeys(' ');
          33:
            SendSocketKeys('{PGUP}');
          34:
            SendSocketKeys('{PGDN}');
          35:
            SendSocketKeys('{END}');
          36:
            SendSocketKeys('{HOME}');
          37:
            SendSocketKeys('{LEFT}');
          38:
            SendSocketKeys('{UP}');
          39:
            SendSocketKeys('{RIGHT}');
          40:
            SendSocketKeys('{DOWN}');
          44:
            SendSocketKeys('{PRTSC}');
          46:
            SendSocketKeys('{DEL}');
          145:
            SendSocketKeys('{SCROLLLOCK}');

          // Numbers: 1 2 3 4 5 6 7 8 9 and ! @ # $ % ?& * ( )
          48:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys(')')
            else
              SendSocketKeys('0');
          49:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('!')
            else
              SendSocketKeys('1');
          50:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('@')
            else
              SendSocketKeys('2');
          51:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('#')
            else
              SendSocketKeys('3');
          52:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('$')
            else
              SendSocketKeys('4');
          53:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('%')
            else
              SendSocketKeys('5');
          54:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('^')
            else
              SendSocketKeys('6');
          55:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('&')
            else
              SendSocketKeys('7');
          56:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('*')
            else
              SendSocketKeys('8');
          57:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('(')
            else
              SendSocketKeys('9');

          65 .. 90: // A..Z / a..z
            begin
              if (GetKeyState(VK_CAPITAL) = 1) then
                if (GetKeyState(VK_SHIFT) < 0) then
                  SendSocketKeys(LowerCase(Chr(i)))
                else
                  SendSocketKeys(UpperCase(Chr(i)))
              else if (GetKeyState(VK_SHIFT) < 0) then
                SendSocketKeys(UpperCase(Chr(i)))
              else
                SendSocketKeys(LowerCase(Chr(i)))

            end;

          96 .. 105: // Numpad 1..9
            SendSocketKeys(IntToStr(i - 96));

          106:
            SendSocketKeys('*');
          107:
            SendSocketKeys('+');
          109:
            SendSocketKeys('-');
          110:
            SendSocketKeys(',');
          111:
            SendSocketKeys('/');
          194:
            SendSocketKeys('.');

          // F1..F12
          112 .. 123:
            SendSocketKeys('{F' + IntToStr(i - 111) + '}');

          186:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('?')
            else
              SendSocketKeys('?');
          187:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('+')
            else
              SendSocketKeys('=');
          188:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('<')
            else
              SendSocketKeys(',');
          189:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('_')
            else
              SendSocketKeys('-');
          190:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('>')
            else
              SendSocketKeys('.');
          191:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys(':')
            else
              SendSocketKeys(';');
          192:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('"')
            else
              SendSocketKeys('''');
          193:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('?')
            else
              SendSocketKeys('/');
          219:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('`')
            else
              SendSocketKeys('?');
          220:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('}')
            else
              SendSocketKeys(']');
          221:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('{')
            else
              SendSocketKeys('[');
          222:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('^')
            else
              SendSocketKeys('~');
          226:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('|')
            else
              SendSocketKeys('\');
        end;
      end;
    end;
  except
  end;
end;

Procedure Tfrm_RemoteScreen.Chat_ImageClick(Sender: TObject);
begin
  frm_Chat.Show;
end;

Procedure Tfrm_RemoteScreen.FileShared_ImageClick(Sender: TObject);
begin
  frm_ShareFiles.Show;
end;

Procedure Tfrm_RemoteScreen.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  frm_ShareFiles.Hide;
  frm_Chat.Hide;
  frm_Main.Main_Socket.Socket.SendText('<|STOPACCESS|>');
  frm_Main.SetOnline;
  frm_Main.Show;
  frm_Main.lsoTarget := '';
end;

Procedure Tfrm_RemoteScreen.FormCreate(Sender: TObject);
begin
  // Separate Window
  SetWindowLong(Handle, GWL_EXSTYLE, WS_EX_APPWINDOW);
end;

Procedure Tfrm_RemoteScreen.MoverBotoes;
begin
  btnabrir.Top  := Pnl_menu.Top + Pnl_menu.Height;
  btnabrir.Left := Pnl_menu.Left + Pnl_menu.Width - btnabrir.Width;
  //
  btnFechar.Top  := btnabrir.Top;
  btnFechar.Left := btnabrir.Left;
end;

Procedure Tfrm_RemoteScreen.Rolarmenu(Value: TTagAbrefecha = teAbrir);
var
  vBarDec, i: Integer;
  Procedure ExecMethod(Execute: TExecuteProc = Nil);
  begin
    TThread.CreateAnonymousThread(
      Procedure
      begin
        if Assigned(Execute) then
          TThread.Synchronize(TThread.CurrentThread,
            Procedure
            begin
              Execute;
            end);
      end).Start;
  end;

begin
  Pnl_menu.Left := (Self.Width div 2) - (Pnl_menu.Width div 2);
  MoverBotoes;
  btnabrir.Visible     := Value = teFechar;
  btnFechar.Visible := not btnabrir.Visible;
  case Value of
    teAbrir:
      begin
        Pnl_menu.Top := 0;
        MoverBotoes;
        if frm_Main.MouseCapture then
          Screen_Image.Cursor := crDefault;
      end;
    teFechar:
      begin
        Pnl_menu.Top := Pnl_menu.Height * -1;
        MoverBotoes;
        if frm_Main.MouseCapture then
          Screen_Image.Cursor := crNone;
      end;
  end;
end;

Procedure Tfrm_RemoteScreen.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
var Handled: Boolean);
begin
  if (MouseRemote_CheckBox.Checked) then
    frm_Main.Main_Socket.Socket.SendText(ansistring('<|REDIRECT|><|WHEELMOUSE|>' + IntToStr(WheelDelta) + '<|END|>'));
end;

Procedure Tfrm_RemoteScreen.FormResize(Sender: TObject);
begin
  Pnl_menu.Left := (Self.Width div 2) - (Pnl_menu.Width div 2);
  Rolarmenu(Direcao);
end;

Procedure Tfrm_RemoteScreen.FormShow(Sender: TObject);
begin
  CtrlPressed  := false;
  ShiftPressed := false;
  AltPressed   := false;
  Caption      := frm_Main.lsoTarget;
  Rolarmenu(Direcao);
end;

Procedure Tfrm_RemoteScreen.KeyboardRemote_CheckBoxClick(Sender: TObject);
begin
  if KeyboardRemote_CheckBox.Checked then
  begin
    KeyboardIcon_Image.Picture.Assign(KeyboardIcon_checked_Image.Picture);
    CaptureKeys_Timer.Enabled := true;
  end
  else
  begin
    KeyboardIcon_Image.Picture.Assign(KeyboardIcon_unchecked_Image.Picture);
    CaptureKeys_Timer.Enabled := false;
  end;
end;

Procedure Tfrm_RemoteScreen.KeyboardRemote_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    Key := 0;
end;

Procedure Tfrm_RemoteScreen.Label3Click(Sender: TObject);
begin
  frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|CTALTDEL|>');
end;

Procedure Tfrm_RemoteScreen.Label4Click(Sender: TObject);
begin
  frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|RUNWINR|>');
end;

Procedure Tfrm_RemoteScreen.MouseRemote_CheckBoxClick(Sender: TObject);
begin
  if MouseRemote_CheckBox.Checked then
  begin
    MouseIcon_Image.Picture.Assign(MouseIcon_checked_Image.Picture);
  end
  else
  begin
    MouseIcon_Image.Picture.Assign(MouseIcon_unchecked_Image.Picture);
  end;
end;

Procedure Tfrm_RemoteScreen.MouseRemote_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) then
    Key := 0;
end;

Procedure Tfrm_RemoteScreen.Resize_CheckBoxClick(Sender: TObject);
begin
  if Resize_CheckBox.Checked then
  begin
    Screen_Image.AutoSize := false;
    Screen_Image.Stretch  := true;
    Screen_Image.Align    := alClient;
    ResizeIcon_Image.Picture.Assign(ResizeIcon_checked_Image.Picture);
  end
  else
  begin
    Screen_Image.AutoSize := true;
    Screen_Image.Stretch  := false;
    Screen_Image.Align    := alNone;
    ResizeIcon_Image.Picture.Assign(ResizeIcon_unchecked_Image.Picture);
  end;
end;

Procedure Tfrm_RemoteScreen.Resize_CheckBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    Key := 0;
end;

end.
