unit uClsMouseSendRec;

interface

uses
  REST.JSON, System.SysUtils, System.Variants, System.Classes;

type
  TMouseSR = class
  private
    FButtonLorD: char;
    FButtonAction: char;
    FButtonX: integer;
    FButtonY: integer;
  public
    property ButtonLorD: char read FButtonLorD write FButtonLorD;
    property ButtonAction: char read FButtonAction write FButtonAction;
    property ButtonX: integer read FButtonX write FButtonX;
    property ButtonY: integer read FButtonY write FButtonY;
    function JsonTostring : string;
    function StringTojson(lstring : string) : TMouseSR;
  end;

implementation

{ TMouseSR }

function TMouseSR.JsonTostring: string;
begin
  result := TJson.ObjectToJsonString(self);
end;

function TMouseSR.StringTojson(lstring: string): TMouseSR;
begin
  result := TJson.JsonToObject<TMouseSR>(lstring);
end;

end.
