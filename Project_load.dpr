program Project_load;

uses
  Vcl.Forms,
  Unit1 in 'modul\Unit1.pas' {Form1},
  Unit4 in 'modul\Unit4.pas' {Form4};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
