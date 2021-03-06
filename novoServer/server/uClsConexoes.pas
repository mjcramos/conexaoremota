unit uClsConexoes;

interface

type
  TuserConnect = class

  private
    FID: string;
    Fpassword: string;
    Fmainsockethandle: integer;
    Fapelido: string;
    Fdatahora: tDatetime;
    Fdata: tObject;
    Fdadosping: string;
    FTargetID: string;
    FdadosDesk: TObject;
    FdadosKeyb: Tobject;
    FdadosFiles: Tobject;
    Fipaddress: string;
    FsoMaquina: string;
  public
  property ID: string read FID write FID;
  property password: string read Fpassword write Fpassword;
  property mainsockethandle: integer read Fmainsockethandle write Fmainsockethandle;
  property apelido: string read Fapelido write Fapelido;
  property datahora: tDatetime read Fdatahora write Fdatahora;
  property data: tObject read Fdata write Fdata;
  property dadosDesk: TObject read FdadosDesk write FdadosDesk;
  property dadosKeyb: Tobject read FdadosKeyb write FdadosKeyb;
  property dadosFiles: Tobject read FdadosFiles write FdadosFiles;
  property dadosping: string read Fdadosping write Fdadosping;
  property TargetID: string read FTargetID write FTargetID;
  property ipaddress: string read Fipaddress write Fipaddress;
  property soMaquina: string read FsoMaquina write FsoMaquina;
  end;

implementation

end.
