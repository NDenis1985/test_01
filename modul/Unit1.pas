unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    TreeView1: TTreeView;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure TreeView1Expanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure TreeView1DblClick(Sender: TObject);
  private
    function GetFileFromPath(vPath : String; mask : String = '*') : String;
    { Private declarations }
  public
    { Public declarations }
  end;

  TGetFunctionList = function: PChar; stdcall;
  TAbout = Procedure ; stdcall;

 TProcedureByNotArgument = record
   name : string;
   proc : TAbout;
 end;

 TDLLWork = class (TComponent)
   private
    dllName  : string;
    fileName : String;
    GetFunctionList : TGetFunctionList;
    DLLHandle: THandle;
    ProcList :  array of TProcedureByNotArgument;
   public
     FunctionList : TStringList;
     constructor Create(dllName : string; FileName : string; owner : TComponent);
     Function loadDLL : boolean;
     procedure DLLFree;
   end;

var
  Form1: TForm1;
  load : boolean = true;
  dir : string;
implementation
{$R *.dfm}






Function TForm1.GetFileFromPath(vPath : String; mask : String = '*') : String;
var
  FindData       : TWin32FindData;
  FindHandle     : THandle;
  FullPath       : string;
  Path           : String;
  filename       : string;
  DirList        : TstringList;
  FileList       : TStringList;
  pPathToFind    : pChar;
  ShortFilenName : string;
begin
  DirList  := TstringList.Create;
  FileList := TStringList.Create;
  Path := vPath;
  try
    try
      DirList.add(Path);
      repeat
        Path := DirList[0];
        FullPath := Path + '\'; // Добавляем символы для поиска
        pPathToFind := pchar(FullPath + mask);
        FindHandle := FindFirstFile(pPathToFind, FindData); // Начинаем поиск
        if FindHandle <> INVALID_HANDLE_VALUE then
       repeat
          // Игнорируем текущую и родительскую директории
          filename := FindData.cFileName;
          if (filename <> '.') and (filename <> '..') then
          begin
            ShortFilenName := filename;
            filename := FullPath + '' + FindData.cFileName;
            // Выводим имя файла или папки
            if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
              FileList.add(ShortFilenName + '=' + filename);
            if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
            begin
               DirList.add(filename);
            end;
          end;
        until not FindNextFile(FindHandle, FindData); // Продолжаем поиск
        Winapi.Windows.FindClose(FindHandle);
        DirList.Delete(0); // Удаляем его из списка
      until dirlist.Count = 0;
    finally
      result := FileList.Text;
      DirList.free;
      FileList.free;

   //   ClearMemory;
    end;
  except
   on E: Exception do
   begin

   end;
  end;
 end;


procedure TForm1.TreeView1DblClick(Sender: TObject);
var x : integer;
begin
  if not assigned(TreeView1.selected) then exit;
  if not assigned(TreeView1.selected.Parent) then exit;
  if not assigned(TreeView1.selected.Parent.Data) then exit;

  with TDLLWork(TreeView1.selected.Parent.Data) do
  begin
    if not loadDLL then exit;

    for x := 0 to High(ProcList) do
      if ProcList[x].name =  TreeView1.selected.Text then ProcList[x].proc;
  end;
end;

procedure TForm1.TreeView1Expanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
    s : string;
begin
 if not  assigned(Node)   then exit;
 if not  assigned(Node.Data) then exit;
  with TDLLWork(Node.Data) do
  begin
   if not loadDLL then exit;
    if not Assigned(FunctionList) then exit;

      if Node.getFirstChild <> nil then exit;
      for s in FunctionList do
      TreeView1.Items.AddChild(Node, s);
      node.Expanded := true;

  end;
end;

procedure TForm1.FormActivate(Sender: TObject);
var
  t   : TStringlist;
  x   : integer;
  new : TDLLWork;
begin
 if load then // сингильтон
 begin
   load := false;
   getdir(0, dir);

   t := TStringlist.Create;
   try
     t.Text := GetFileFromPath(dir, '*.dll');
     for x := 0 to t.Count - 1 do
     begin
       new := TDLLWork.Create(t.Names[x], t.ValueFromIndex[x], TreeView1);
       TreeView1.Items.AddObject(nil, t.Names[x], new).HasChildren := true;
     end;
   finally
     t.Free;
   end;


 end;
end;

{ TDLLWork }

constructor TDLLWork.Create(dllName, FileName: string; owner : TComponent);
begin
  inherited Create(owner);
  self.dllName := dllName;
  self.fileName := Filename;
  DLLHandle  := 0;
end;

procedure TDLLWork.DLLFree;
begin
   FreeLibrary(DLLHandle);
end;

Function TDLLWork.loadDLL : boolean;
var
  res : pChar;
  s : string;
  x : integer;
begin
 result := false;
 if DLLHandle <> 0 then begin result := true; exit; end; // dll Уже был загружен
 DLLHandle := LoadLibrary(pchar(fileName));
 if DLLHandle <> 0 then
  begin
      // Получаем адрес функции
      @GetFunctionList := GetProcAddress(DLLHandle, 'GetFunctionList');
      if Assigned(GetFunctionList) then
      begin
        FunctionList := TStringList.Create;
        try
          res := GetFunctionList;
          FunctionList.text := res;
          Setlength(ProcList, FunctionList.Count);
          x := 0;
          for s in FunctionList do
          begin
            ProcList[x].name := s;
            ProcList[x].proc := GetProcAddress(DLLHandle, pChar(ProcList[x].name));
            if not Assigned(ProcList[x].proc) then
            begin
              Showmessage('Не удалось найти процедуру '+ ProcList[x].name + ' в DLL.');
            end;
            inc(x);
          end;

          result := true;

        except
          FunctionList.text := 'Function not found!';
        end;
      end
      else
      begin
        Showmessage('Не удалось найти функцию GetFunctionList в DLL.');
        DLLHandle := 0;
        exit;
      end;
  end
  else
  Showmessage('Не удалось загрузить DLL.');

end;

end.
