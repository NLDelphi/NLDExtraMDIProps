(*****************************************************************************
******************************************************************************

TNLDExtraMDIProps is een component dat een paar extra properties aan een MDIForm
toevoegd. De volgende zijn reeds voorzien:

- BackgroundPicture: TPicture
- ShowClientEdge: Boolean
- ShowScrollBars: Boolean

Het BackgroundPicture wordt in deze versie 1:1 gecentreerd weergegeven in het
ClientWindow van een MDIForm. Mogelijke toekomstige wijziging is eventueel
stretchen.

Bij vragen, opmerkingen, bugs, etc... hoor ik het graag.

Veel plezier er mee.

Albert de Weerd
******************************************************************************
******************************************************************************)

unit NLDExtraMDIProps;

interface

uses
  Classes, Windows, Graphics, Messages, Forms;

type
  TNLDExtraMDIProps = class(TComponent)
  private
    FBackgroundBitmap: TBitmap;
    FBackgroundPicture: TPicture;
    FForm: TForm;
    FOldClientWndProc: TFarProc;
    FOnChange: TNotifyEvent;
    FShowScrollBars: Boolean;
    FShowClientEdge: Boolean;
    procedure BackgroundPictureChanged(Sender: TObject);
    procedure NewClientWndProc(var Message: TMessage);
    procedure SetShowClientEdge(const Value: Boolean);
    procedure SetShowScrollBars(const Value: Boolean);
  protected
    procedure Changed; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function HasBackgroundGraphic: Boolean;
  published
    property BackgroundPicture: TPicture read FBackgroundPicture
      write FBackgroundPicture;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ShowClientEdge: Boolean read FShowClientEdge
      write SetShowClientEdge default True;
    property ShowScrollBars: Boolean read FShowScrollBars
      write SetShowScrollBars default True;
  end;

procedure Register;

implementation

{$R *.DCR}

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDExtraMDIProps]);
end;

{ TNLDExtraMDIProps }

procedure TNLDExtraMDIProps.BackgroundPictureChanged(Sender: TObject);
begin
  with FBackgroundBitmap do
    if HasBackgroundGraphic then
    begin
      Width := FBackgroundPicture.Width;
      Height := FBackgroundPicture.Height;
      Canvas.Draw(0, 0, FBackgroundPicture.Graphic);
    end
    else
    begin
      Width := 0;
      Height := 0;
    end;
  if Assigned(FForm) then
    PostMessage(FForm.ClientHandle, WM_PAINT, 0, 0);
  Changed;
end;

procedure TNLDExtraMDIProps.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TNLDExtraMDIProps.Create(AOwner: TComponent);
//This version simply expects AOwner.FormStyle remains fsMDIForm.
//If we would want to know if AOwner.FormStyle is changed from/to fsMDIForm,
//we would need an AOwner.WndProc-hook and catch CM_SHOWINGCHANGED.
begin
  inherited;
  FBackgroundPicture := TPicture.Create;
  FBackgroundBitmap := TBitmap.Create;
  FShowScrollBars := True;
  FShowClientEdge := True;
  FBackgroundPicture.OnChange := BackgroundPictureChanged;
  if Assigned(AOwner) then
    if AOwner is TForm then
      if TForm(AOwner).FormStyle = fsMDIForm then
      begin
        FForm := TForm(AOwner);
        FForm.HandleNeeded; //FForm.ClientHandle couldn't exist
        FOldClientWndProc :=
          Pointer(GetWindowLong(FForm.ClientHandle, GWL_WNDPROC));
        SetWindowLong(FForm.ClientHandle, GWL_WNDPROC,
          Integer(MakeObjectInstance(NewClientWndProc)));
      end;
end;

destructor TNLDExtraMDIProps.Destroy;
begin
  FBackgroundBitmap.Free;
  FBackgroundPicture.Free;
  if Assigned(FForm) then
    SetWindowLong(FForm.ClientHandle, GWL_WNDPROC, Integer(FOldClientWndProc));
  inherited;
end;

function TNLDExtraMDIProps.HasBackgroundGraphic: Boolean;
begin
  Result := Assigned(FBackgroundPicture.Graphic);
end;

procedure TNLDExtraMDIProps.NewClientWndProc(var Message: TMessage);
const
  ScrollStyle = WS_HSCROLL or WS_VSCROLL;
  EdgeStyle = WS_EX_CLIENTEDGE;
var
  DC: HDC;
  L, T, R, B: Integer; //Left, Top, Right, Bottom
  Style: Integer;
begin
  case Message.Msg of
    WM_PAINT, WM_SIZE, WM_NCHITTEST:
      if HasBackgroundGraphic then
        with FForm do
        begin
          DC := GetDC(ClientHandle);
          try
            L := (ClientWidth - FBackgroundBitmap.Width) div 2;
            T := (ClientHeight - FBackgroundBitmap.Height) div 2;
            R := (ClientWidth + FBackgroundBitmap.Width) div 2;
            B := (ClientHeight + FBackgroundBitmap.Height) div 2;
            //To prevent flickering: no erasing of previous image:
            FillRect(DC, Rect(0, 0, L, ClientHeight), Brush.Handle);
            FillRect(DC, Rect(R, 0, ClientWidth, ClientHeight), Brush.Handle);
            FillRect(DC, Rect(L, 0, R, T), Brush.Handle);
            FillRect(DC, Rect(L, B, R, ClientHeight), Brush.Handle);
            BitBlt(DC, L, T, FBackgroundBitmap.Width, FBackgroundBitmap.Height,
              FBackgroundBitmap.Canvas.Handle, 0, 0, SRCCOPY);
          finally
            ReleaseDC(ClientHandle, DC);
          end;
        end;
    WM_NCCALCSIZE:
      with FForm do
      begin
        Style := GetWindowLong(ClientHandle, GWL_STYLE);
        if not FShowScrollBars and ((Style and ScrollStyle) <> 0) then
          SetWindowLong(ClientHandle, GWL_STYLE, Style and not ScrollStyle);
        Style := GetWindowLong(ClientHandle, GWL_EXSTYLE);
        if not FShowClientEdge and ((Style and EdgeStyle) <> 0) then
          SetWindowLong(ClientHandle, GWL_EXSTYLE, Style and not EdgeStyle);
      end;
  end;
  with Message do
    Result := CallWindowProc(
      FOldClientWndProc, FForm.ClientHandle, Msg, wParam, lParam);
end;

procedure TNLDExtraMDIProps.SetShowClientEdge(const Value: Boolean);
begin
  if FShowClientEdge <> Value then
  begin
    FShowClientEdge := Value;
    if Assigned(FForm) then
      SendMessage(FForm.ClientHandle, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

procedure TNLDExtraMDIProps.SetShowScrollBars(const Value: Boolean);
begin
  if FShowScrollBars <> Value then
  begin
    FShowScrollBars := Value;
    if Assigned(FForm) then
      SendMessage(FForm.ClientHandle, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

end.
