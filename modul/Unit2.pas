unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Grids, Vcl.Outline, Vcl.Samples.DirOutln, Vcl.FileCtrl,   IOUtils;

const
  WM_SETADD10000ROWS               = WM_USER + 4;

type

  TFileThread = class(TThread)
  private
    FPath : String;
    FMask : String;
    FResult : TStringList;
    fmemo : TMemo; // выводим результат
    FStopRequested : Boolean;
    fFilename : String;
  protected
    procedure Execute; override;
    procedure ShowResult;
  public
    MainWinHandle : THandle;
    Function GetFileName : String;
    Procedure GetFileFromPath(vPath : String; mask : String);
    constructor Create(const vPath, mask: String; memo : Tmemo);
    procedure SetConsoleStringList(var value:TStringList);
    procedure Stop; // Метод для остановки потока
    destructor Destroy;
  end;


  TForm2 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    Edit2: TEdit;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  protected
    procedure WndProc(var Msg: TMessage);  override;
  private
   FStop : Boolean;
    { Private declarations }

  public
    FindThread : TFileThread; // поток поиска
    ShowResult : TStringList;
    { Public declarations }
  end;

procedure ClearMemory;

 var
   indexWindowX : Integer;
   indexWindowY : Integer;
   step : Integer = 50; //для отображения окна
   dir : string = '';

implementation


{$R *.dfm}

procedure ClearMemory;
  var  mainHandle     : THandle;
begin
  mainHandle    := OpenProcess(PROCESS_ALL_ACCESS, false , GetCurrentProcessID);
  SetProcessWorkingSetSize(mainHandle, DWORD(-1), DWORD(-1));
  CloseHandle(mainHandle);
end;

procedure TFileThread.GetFileFromPath(vPath : String; mask : String);
var
  FindData       : TWin32FindData;
  FindHandle     : THandle;
  FullPath       : string;
  Path           : String;
  filename       : string;
  DirList        : TstringList;
  FileList       : TStringList;
  pPathToFind    : pChar;
begin
  DirList  := TstringList.Create;
  FileList := TStringList.Create;
  Path := vPath;
  try
    try
      DirList.add(Path);
      repeat
       if FStopRequested  then
        begin
          break;
        end;

        Path := DirList[0];
        if Path[length(Path)] = '\' then
          FullPath := Path
        else
          FullPath := Path + '\'; // Добавляем символы для поиска

        pPathToFind := pchar(FullPath + mask);
        FindHandle := FindFirstFile(pPathToFind, FindData); // Начинаем поиск
        pPathToFind := nil;

        if FindHandle <> INVALID_HANDLE_VALUE then
       repeat
        if FStopRequested  then
         begin
           break;
         end;

          // Игнорируем текущую и родительскую директории
          filename := FindData.cFileName;
          if (filename <> '.') and (filename <> '..') then
          begin
            filename := FullPath + '' + FindData.cFileName;
            // Выводим имя файла или папки
            if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
              FileList.add( filename);
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

      try
        FResult.Assign(FileList);
      except
      end;
      DirList.free;
      FileList.Free;
    end;
  except
   on E: Exception do
   begin
   fmemo.Lines.Add('Ошибка ' + e.Message);
   end;
  end;
end;




function CreateTempFolderAndGetFileName(const BaseDir: string; Number: Integer; out FileName: string): Boolean;
var
  TempFolder: string;
  BaseFileName: string;
  FileIndex: Integer;
begin
  Result := False;

  // Генерируем имя временной папки
  TempFolder := TPath.Combine(BaseDir, 'Temp');
  // Проверяем, существует ли папка, если нет, создаем её
  if not TDirectory.Exists(TempFolder) then
  begin
    TDirectory.CreateDirectory(TempFolder);
    if not DirectoryExists(TempFolder) then   Exit; // Если не удалось создать папку, выходим
  end;
  // Формируем базовое имя файла с использованием переданного числа
  BaseFileName := TPath.Combine(TempFolder, 'File_' + IntToStr(Number));
  FileName := BaseFileName;
  // Инициализируем индекс для добавления к имени файла
  FileIndex := 1;

  // Проверяем, существует ли файл, и добавляем индекс, если это необходимо
  if TFile.Exists(FileName) then
  repeat
    FileName := BaseFileName + '_' + IntToStr(FileIndex) + '.txt'; // Имя файла с индексом
    Inc(FileIndex); // Увеличиваем индекс для следующей проверки
  until not TFile.Exists(FileName); // Продолжаем, пока файл существует
  Result := True; // Успешно завершено
end;

function TFileThread.GetFileName: String;
var sFilename : string;
begin
  sFilename := '';
  if CreateTempFolderAndGetFileName(dir, Handle, sFilename) then
  begin
    fFilename := sFilename;
    result := sFilename;
  end;
end;

constructor TFileThread.Create(const vPath, mask: String; memo : tmemo);
begin
  inherited Create(True); // Создаем поток в приостановленном состоянии
  self.FreeOnTerminate := true;
  FPath := vPath;
  FMask := mask;
  fmemo := memo;
  FStopRequested := false;
  Priority := tpNormal;
end;

destructor TFileThread.Destroy;
begin
 if assigned(FResult) then
  FResult.Free;
  inherited Destroy; // Создаем поток в приостановленном состоянии
end;

procedure TFileThread.Execute;
begin
  // Вызываем функцию в потоке
  getFileFromPath(FPath, FMask);
  ShowResult; // Обновляем интерфейс в основном потоке
end;

procedure TFileThread.SetConsoleStringList(var value: TStringList);
begin
   FResult := value;
end;



procedure TFileThread.ShowResult;
begin
   PostMessage(MainWinHandle,  WM_SETADD10000ROWS, 0, LPARAM(PChar(''))); // отправляем по 1000 строк на экран
end;

procedure TFileThread.Stop;
begin
   FStopRequested := True; // Устанавливаем флаг остановки
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  memo1.lines.Clear;
  FStop := false;
  FindThread := TFileThread.Create(edit1.Text, edit2.text, memo1);
  FindThread.MainWinHandle := self.Handle;
  Button1.Enabled := false;
  ShowResult := TstringList.Create;
  FindThread.SetConsoleStringList(ShowResult);
  FindThread.Start;
  Button1.Enabled := false;
  ClearMemory;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  memo1.lines.Add('Запрос на остановку потока.');
  if FindThread <> nil  then
  FindThread.Stop;
  FStop := true;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FStop := true;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin

   getdir(0, dir);
   if indexWindowX > 4 then
   begin
     indexWindowX := 0;
     indexWindowY := indexWindowY + 1;
   end;
   if indexWindowY = 4 then begin indexWindowY := 0; step := step +25; end;
 left := indexWindowX * Width + 50 + step;
 top := indexWindowY * Height + 50;
 indexWindowX := indexWindowX + 1;

end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  if assigned(FindThread) then
    FindThread.Terminate;
  if assigned(ShowResult) then
    ShowResult.Free;
end;

function GetFreeDiskSpaceAndCheck(const FilePath: string; const StringList: TStringList; out FreeSpace: Int64; out RequiredSpace: Int64): Boolean;
var
  Drive: string;
  FreeBytes, TotalBytes: Int64;
  StringListSize: Int64;
begin
  Result := False;
  FreeSpace := 0;
  RequiredSpace := 0;

  // Получаем размер данных в TStringList
  StringListSize := 0;
  for var i := 0 to StringList.Count - 1 do
    StringListSize := StringListSize + Length(StringList[i]) * SizeOf(Char); // Размер в байтах
  RequiredSpace := StringListSize;
  // Получаем букву диска из пути к файлу
  Drive := ExtractFileDrive(FilePath);
  // Получаем свободное место на диске
  if GetDiskFreeSpaceEx(PChar(Drive), FreeBytes, TotalBytes, nil) then
  begin
    FreeSpace := FreeBytes;
    Result := FreeSpace > RequiredSpace; // Успешно получено свободное место
  end;
end;

procedure TForm2.WndProc(var Msg: TMessage);
var
  s              : String;
  x              : integer;
  filename       : String;
  aFreeSpace     : int64;
  aRequiredSpace : int64;
  writefile      : boolean;
begin
  if Msg.Msg = WM_SETADD10000ROWS then
  begin
     Memo1.SelectAll;
     IF ShowResult.Count < 10000 THEN
       Memo1.SetSelText(ShowResult.Text)
     else
     begin
       memo1.Lines.Clear;
       Filename := FindThread.GetFileName;
       writefile := false; // записал файл
       try
         try

           if GetFreeDiskSpaceAndCheck(Filename, ShowResult, aFreeSpace, aRequiredSpace) then
           begin
             ShowResult.SaveToFile(Filename);
             writefile := true;
           end
           else
           begin
             memo1.Lines.Add('Ошибка сохранения результата в файл "' + Filename + '" свободно ' + inttostr(aFreeSpace) + ' а требуется ' + inttostr(aRequiredSpace)+ ' байт');
             writefile := false;
           end;

         except
           memo1.Lines.Add('Ошибка сохранения результата в файл "' + Filename + '"');
           exit;   // идем в блок finally
         end;
         memo1.Lines.Add('Найдено ' + inttostr(ShowResult.Count) + ' файлов, вывел первые 5 000 записей');
         if writefile then
         memo1.Lines.Add('Результат сохранен в файл ' + Filename);
         s := '';
         for x := 0 to 5000-1 do
         begin
           s := s + ShowResult[x]+#13+#10;
         end;
         s := s + ShowResult[5000];
         memo1.Lines.Add(s);
       finally
         memo1.SelStart := 0;
         memo1.SelLength := 1;
         application.ProcessMessages;
         memo1.SelLength := 0;
         ShowResult.Free;
         button1.Enabled := true;

       end;
      end;

  end;

   // Вызов стандартной обработки сообщений
  inherited WndProc(Msg);
end;

end.
