{ *************************************************************************** }
{                                                                             }
{ NLDExtraMDIProps  -  www.nldelphi.com Open Source designtime component      }
{                                                                             }
{ Initiator: Albert de Weerd (aka NGLN)                                       }
{ License: Free to use, free to modify                                        }
{ Website: http://www.nldelphi.com/forum/forumdisplay.php?f=128               }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/nldextramdiprops }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Date: May 3, 2008                                                           }
{ Version: 1.0.0.1                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDExtraMDIProps;

interface

uses
  Classes, Windows, Graphics, Messages, Forms;

type
  TNLDPicture = class(TComponent)
  private
    FBitmap: TBitmap;
    FBitmapResName: String;
    FFileName: String;
    FOnChange: TNotifyEvent;
    FPicture: TPicture;
    procedure PictureChanged(Sender: TObject);
    procedure SetBitmapResName(const Value: String);
    procedure SetFileName(const Value: String);
    procedure SetPicture(const Value: TPicture);
  protected
    procedure Changed; virtual;
  public
    procedure Assign(Source: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Empty: Boolean; virtual;
    property Bitmap: TBitmap read FBitmap;
  published
    property BitmapResName: String read FBitmapResName write SetBitmapResName;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property FileName: String read FFileName write SetFileName;
    property Picture: TPicture read FPicture write SetPicture;
  end;

  TNLDExtraMDIProps = class(TComponent)
  private
    FBGPicture: TNLDPicture;
    FForm: TForm;
    FOldClientWndProc: TFarProc;
    FOnChange: TNotifyEvent;
    FShowScrollBars: Boolean;
    FShowClientEdge: Boolean;
    procedure BackgroundPictureChanged(Sender: TObject);
    procedure NewClientWndProc(var Message: TMessage);
    procedure SetBackgroundPicture(const Value: TNLDPicture);
    procedure SetShowClientEdge(const Value: Boolean);
    procedure SetShowScrollBars(const Value: Boolean);
  protected
    procedure Changed; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BackgroundPicture: TNLDPicture read FBGPicture
      write SetBackgroundPicture stored True;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ShowClientEdge: Boolean read FShowClientEdge
      write SetShowClientEdge default True;
    property ShowScrollBars: Boolean read FShowScrollBars
      write SetShowScrollBars default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDExtraMDIProps, TNLDPicture]);
end;

{ TNLDPicture }

procedure TNLDPicture.Assign(Source: TPersistent);
begin
  if Source is TNLDPicture then
  begin
    FBitmapResName := TNLDPicture(Source).FBitmapResName;
    FFileName := TNLDPicture(Source).FFileName;
    FOnChange := TNLDPicture(Source).FOnChange;
    FPicture.Assign(TNLDPicture(Source).FPicture);
  end
  else
    inherited Assign(Source);
end;

procedure TNLDPicture.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TNLDPicture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
  FBitmap := TBitmap.Create;
  FPicture.OnChange := PictureChanged;
  if AOwner is TNLDExtraMDIProps then
  begin
    Name := 'SubPicture';
    SetSubcomponent(True);
  end;
end;

destructor TNLDPicture.Destroy;
begin
  FBitmap.Free;
  FPicture.Free;
  inherited Destroy;
end;

function TNLDPicture.Empty: Boolean;
begin
  Result := not Assigned(FPicture.Graphic);
  if not Result then
    Result := FPicture.Graphic.Empty;
end;

procedure TNLDPicture.PictureChanged(Sender: TObject);
begin
  if Empty then
  begin
    FBitmap.Width := 0;
    FBitmap.Height := 0;
  end
  else
  begin
    FBitmap.Width := FPicture.Width;
    FBitmap.Height := FPicture.Height;
    FBitmap.Canvas.Draw(0, 0, FPicture.Graphic);
    if not (csDesigning in ComponentState) then
    begin
      FFileName := '';
      FBitmapResName := '';
    end;
  end;
  Changed;
end;

procedure TNLDPicture.SetBitmapResName(const Value: String);
begin
  if FBitmapResName <> Value then
  begin
    FFileName := '';
    if csDesigning in ComponentState then
    begin
      FBitmapResName := Value;
      if Assigned(FPicture.Graphic) then
        FPicture.Graphic := nil;
    end
    else
      FPicture.Bitmap.LoadFromResourceName(HInstance, Value);
  end;
end;

procedure TNLDPicture.SetFileName(const Value: String);
begin
  if FFileName <> Value then
  begin
    FBitmapResName := '';
    if csDesigning in ComponentState then
    begin
      FFileName := Value;
      if Assigned(FPicture.Graphic) then
        FPicture.Graphic := nil;
    end
    else
      FPicture.LoadFromFile(Value);
  end;
end;

procedure TNLDPicture.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
  if Assigned(FPicture.Graphic) then
  begin
    FBitmapResName := '';
    FFileName := '';
  end;
end;

{ TNLDExtraMDIProps }

procedure TNLDExtraMDIProps.BackgroundPictureChanged(Sender: TObject);
begin
  if Assigned(FForm) then
  begin
    PostMessage(FForm.ClientHandle, WM_PAINT, 0, 0);
    Changed;
  end;
end;

procedure TNLDExtraMDIProps.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TNLDExtraMDIProps.Create(AOwner: TComponent);
{Remark: this version of NLDExtraMDIProps simply expects AOwner.FormStyle to
remain fsMDIForm. To be notified when the FormStyle property changes, you
would need an AOwner.WndProc-hook and catch CM_SHOWINGCHANGED.}
begin
  inherited Create(AOwner);
  FBGPicture := TNLDPicture.Create(Self);
  FBGPicture.FreeNotification(Self);
  FBGPicture.OnChange := BackgroundPictureChanged;
  FShowScrollBars := True;
  FShowClientEdge := True;
  if Assigned(AOwner) then
    if AOwner is TForm then
      if TForm(AOwner).FormStyle = fsMDIForm then
      begin
        FForm := TForm(AOwner);
        FForm.HandleNeeded;
        FOldClientWndProc :=
          Pointer(GetWindowLong(FForm.ClientHandle, GWL_WNDPROC));
        SetWindowLong(FForm.ClientHandle, GWL_WNDPROC,
          Integer(MakeObjectInstance(NewClientWndProc)));
      end;
end;

destructor TNLDExtraMDIProps.Destroy;
begin
  if Assigned(FForm) then
    SetWindowLong(FForm.ClientHandle, GWL_WNDPROC, Integer(FOldClientWndProc));
  inherited Destroy;
end;

procedure TNLDExtraMDIProps.NewClientWndProc(var Message: TMessage);
const
  ScrollStyle = WS_HSCROLL or WS_VSCROLL;
  EdgeStyle = WS_EX_CLIENTEDGE;
var
  DC: HDC;
  Height: Integer;
  Width: Integer;
  Left: Integer;
  Top: Integer;
  Right: Integer;
  Bottom: Integer;
  Style: Integer;
begin
  case Message.Msg of
    WM_ERASEBKGND:
      if Assigned(FBGPicture) then
        Message.Result := 1
      else
        Message.Result := 0;
    WM_PAINT:
      if Assigned(FBGPicture) then
      begin
        DC := GetDC(FForm.ClientHandle);
        try
          Height := FForm.ClientHeight;
          Width := FForm.ClientWidth;
          if FBGPicture.Empty then
            FillRect(DC, Rect(0, 0, Width, Height), FForm.Brush.Handle)
          else
          begin
            Left := (Width - FBGPicture.Bitmap.Width) div 2;
            Top := (Height - FBGPicture.Bitmap.Height) div 2;
            Right := (Width + FBGPicture.Bitmap.Width) div 2;
            Bottom := (Height + FBGPicture.Bitmap.Height) div 2;
            FillRect(DC, Rect(0, 0, Left, Height), FForm.Brush.Handle);
            FillRect(DC, Rect(Right, 0, Width, Height), FForm.Brush.Handle);
            FillRect(DC, Rect(Left, 0, Right, Top), FForm.Brush.Handle);
            FillRect(DC, Rect(Left, Bottom, Right, Height), FForm.Brush.Handle);
            BitBlt(DC, Left, Top, FBGPicture.Bitmap.Width,
              FBGPicture.Bitmap.Height, FBGPicture.Bitmap.Canvas.Handle, 0, 0,
              SRCCOPY);
          end;
        finally
          ReleaseDC(FForm.ClientHandle, DC);
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
    if Msg <> WM_ERASEBKGND then
      Result := CallWindowProc(
        FOldClientWndProc, FForm.ClientHandle, Msg, wParam, lParam);
end;

procedure TNLDExtraMDIProps.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FBGPicture) and (Operation = opRemove) then
    FBGPicture := nil;
end;

procedure TNLDExtraMDIProps.SetBackgroundPicture(const Value: TNLDPicture);
begin
  if Assigned(FBGPicture) then
    FBGPicture.Assign(Value);
end;

procedure TNLDExtraMDIProps.SetShowClientEdge(const Value: Boolean);
begin
  if FShowClientEdge <> Value then
  begin
    FShowClientEdge := Value;
    if Assigned(FForm) then
      PostMessage(FForm.ClientHandle, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

procedure TNLDExtraMDIProps.SetShowScrollBars(const Value: Boolean);
begin
  if FShowScrollBars <> Value then
  begin
    FShowScrollBars := Value;
    if Assigned(FForm) then
      PostMessage(FForm.ClientHandle, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

end.
