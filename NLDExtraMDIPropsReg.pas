unit NLDExtraMDIPropsReg;

interface

uses
  Classes, NLDExtraMDIProps;
  
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDExtraMDIProps, TNLDPicture]);
end;

end.
