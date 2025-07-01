library Project_dll;

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
  System.SysUtils,
  System.Classes,
  Vcl.Dialogs,
  Unit2 in 'modul\Unit2.pas' {Form2};


{$R *.res}
Procedure DialogFindFile stdcall;
var Form2 : TForm2;
begin
    Form2 := TForm2.Create(nil);
    Form2.Show;
end;

Procedure About; stdcall;
begin
  Showmessage('DLL демонстрация версия 1.0.5');
end;

function GetFunctionList : PChar; stdcall;
var method : TStringList;
begin
  method := TStringList.Create;
  try
    method.Add('DialogFindFile');
    method.Add('About');
    method.Add('ClearMemory');
    Result := PChar(method.Text);
  finally
    method.Free;
  end;
end;

Procedure ClearMemory;  stdcall;
begin
   unit2.ClearMemory;
end;

exports
  DialogFindFile name 'DialogFindFile',
  About name 'About',
  GetFunctionList name 'GetFunctionList',
  ClearMemory name 'ClearMemory';

begin
  getdir(0, dir);
end.
