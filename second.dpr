library second;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  Vcl.Dialogs,
  System.SysUtils,
  System.Classes,
  Unit4 in 'modul\Unit4.pas' {Form4};

{$R *.res}
Procedure ExecuteShellCMD stdcall;
var Form4 : TForm4;
begin
    Form4 := TForm4.Create(nil);
    Form4.Show;
end;


Procedure About; stdcall;
begin
  Showmessage('DLL демонстрация версия 1.0.0');
end;

function GetFunctionList : PChar; stdcall;
var method : TStringList;
begin
  method := TStringList.Create;
  try
    method.Add('ExecuteShellCMD');
    method.Add('About');
    Result := PChar(method.Text);
  finally
    method.Free;
  end;
end;



exports

  About                  name 'About',
  GetFunctionList        name 'GetFunctionList',
  ExecuteShellCMD name 'ExecuteShellCMD'  ;

begin
end.
