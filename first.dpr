library first;

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
  Unit2 in 'modul\Unit2.pas' {Form2},
  Unit3 in 'modul\Unit3.pas' {Form3};

{$R *.res}
Procedure DialogFindFile stdcall;
var Form2 : TForm2;
begin
    Form2 := TForm2.Create(nil);
    Form2.Show;
end;

Procedure DialogFindTextFromFile stdcall;
var Form3 : TForm3;
begin
    Form3 := TForm3.Create(nil);
    Form3.Show;
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
    method.Add('DialogFindTextFromFile');
    method.Add('About');
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
  DialogFindFile         name 'DialogFindFile',
  About                  name 'About',
  GetFunctionList        name 'GetFunctionList',
  DialogFindTextFromFile name 'DialogFindTextFromFile'  ;

begin
  getdir(0, dir);
end.
