program Server;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uClsConexoes in 'uClsConexoes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
