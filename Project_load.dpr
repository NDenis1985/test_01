program Project_load;

uses
  Vcl.Forms,
  Unit1 in 'modul\Unit1.pas' {Form1},
  Unit3 in 'modul\Unit3.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
