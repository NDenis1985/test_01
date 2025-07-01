unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.SyncObjs;

type
  TForm3 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Edit1: TEdit;
    Memo1: TMemo;
    Button1: TButton;
    Memo2: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    { Private declarations }
    fStopAllFind : boolean;
    cr : TCriticalSection;
    function GetStopAllFind : boolean;
    procedure SetComponentsEnabled(EnabledValue: Boolean);
  public
    procedure setStopAllFind(value : boolean);
    property StopAllFind : boolean read GetStopAllFind write setStopAllFind;
    { Public declarations }
  end;
TArrayINT64 =  array of int64;

TResult = record
  text : AnsiString;
  list : TArrayINT64;
  listCount : Integer;
end;

TArrayResult = array of TResult;

TArrayTerms = array of AnsiString;

TFileSearchThread = class(TThread)
  private
    FFilePath: string;
    FSearchTerms: TArrayTerms;
    FStartPosition: Int64;
    FFinishPosition: Int64;
    FResults: TArrayResult;
    FStop : boolean;
    crThread : TCriticalSection;
    procedure SetStop(Value: boolean);
    function GetStop: boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const FilePath: string;SearchTerms: TArrayTerms; StartPosition, FinishPosition: Int64);
    property Results: TArrayResult read FResults;
    destructor Destroy; override; // Деструктор
    property Stop: boolean read GetStop write SetStop; // Обвязка для FStop

  end;

var
  Form3: TForm3;
  dir : string;
implementation

{$R *.dfm}




function CompareBytes(const Buffer: TBytes; const SearchTerm: AnsiString; StartIndex: Integer): Boolean;
var
  j: Integer;
begin
  Result := True; // Предполагаем, что совпадение найдено
  for j := 0 to length(SearchTerm) - 1 do
  begin
    if Buffer[StartIndex + j] <> Ord(SearchTerm[j + 1]) then
    begin
      Result := False; // Если не совпадает, устанавливаем флаг
      Break; // Выходим из цикла
    end;
  end;
end;

function SearchInBinaryFile(const FilePath: string;
                            const SearchTerms: array of AnsiString;
                            StartPosition : Int64;
                            FinsihPosition : Int64

                            ): TArrayResult;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  TermLength: Integer;
  i, k: Integer;
  BlockSize: Integer;
  LastBytes: TBytes;
  LastBytesSize: Integer;
  var BytesRead : Longint;
begin
  SetLength(Result, Length(SearchTerms));
  BlockSize := 8192; // Размер блока для чтения (8 КБ)

  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    try
      LastBytesSize := 0;
      TermLength := 0;
      FileStream.Position := StartPosition;

      // Ищем каждую последовательность
      for k := 0 to High(SearchTerms) do
      begin
        Result[k].Text := SearchTerms[k];
        if Length(SearchTerms[k]) > TermLength then
        TermLength := Length(SearchTerms[k]);
        SetLength(Result[k].List, 0);
        Result[k].listCount := 0;
      end;

        // Читаем файл блоками
        while FileStream.Position < FinsihPosition {FileStream.Size} do
        begin
          SetLength(Buffer, BlockSize);
          // Читаем блок данных
          BytesRead := FileStream.Read(Buffer[0], BlockSize);
          if BytesRead = 0 then Break;
           // Объединяем с предыдущими байтами
          if LastBytesSize > 0 then
          begin
            SetLength(Buffer, BytesRead + LastBytesSize);
            Move(LastBytes[0], Buffer[0], LastBytesSize);
            Move(Buffer[0], Buffer[LastBytesSize], BytesRead);
            BytesRead := BytesRead + LastBytesSize;
          end;

          // Поиск вхождений
          for i := 0 to BytesRead - TermLength do
          begin
            for k := 0 to High(SearchTerms) do
            if CompareBytes(Buffer, SearchTerms[k], i) then
            begin
              // Сохраняем позицию
              Result[k].listCount := Result[k].listCount + 1;
              SetLength(Result[k].List, Result[k].listCount);
              Result[k].List[Result[k].listCount-1] := FileStream.Position - BytesRead + i; // Добавляем позицию
            end;
            end;


          // Сохраняем последние байты для следующего блока
          LastBytesSize := TermLength - 1; // Сохраняем последние байты для следующего чтения
          SetLength(LastBytes, LastBytesSize);
          Move(Buffer[BytesRead - LastBytesSize], LastBytes[0], LastBytesSize);

          end;


    finally
      FileStream.Free;
     end;


  except
    on E: Exception do
      showmessage('Ошибка: ' + E.Message);
  end;
end;

constructor TFileSearchThread.Create(const FilePath: string;
                                           SearchTerms: TArrayTerms;
                                           StartPosition, FinishPosition: Int64);
begin
  inherited Create(True); // Создаем поток в приостановленном состоянии
  FFilePath := FilePath;
  FSearchTerms := SearchTerms;
  FStartPosition := StartPosition;
  FFinishPosition := FinishPosition;
  SetLength(FResults, Length(SearchTerms));
  crThread := TCriticalSection.Create;
end;


destructor TFileSearchThread.Destroy;
begin
  // Освобождение ресурсов
  crThread.Free; // Освобождаем критическую секцию
  inherited Destroy; // Вызываем деструктор родительского класса
end;

procedure TFileSearchThread.Execute;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  TermLength: Integer;
  i, k: Integer;
  BlockSize: Integer;
  BytesRead: Longint;
begin
  BlockSize := 8192; // Размер блока для чтения (8 КБ)

  try
    FileStream := TFileStream.Create(FFilePath, fmOpenRead or fmShareDenyWrite);
    try
      FileStream.Position := FStartPosition;
      // Ищем каждую последовательность
      for k := 0 to High(FSearchTerms) do
      begin
        FResults[k].Text := FSearchTerms[k];
        TermLength := Length(FSearchTerms[k]);
        SetLength(FResults[k].List, 0);
        FResults[k].listCount := 0;
      end;

      // Читаем файл блоками
      while (FileStream.Position < FFinishPosition) do
      begin
        if getstop then break;
        SetLength(Buffer, BlockSize);
        // Читаем блок данных
        BytesRead := FileStream.Read(Buffer[0], BlockSize);
        if BytesRead = 0 then Break;
 // Поиск вхождений
        for i := 0 to BytesRead - 1 do
        begin
          for k := 0 to High(FSearchTerms) do
          begin
            if CompareBytes(Buffer, FSearchTerms[k], i) then
            begin
              if getstop then break;
              // Сохраняем позицию
              FResults[k].listCount := FResults[k].listCount + 1;
              SetLength(FResults[k].List, FResults[k].listCount);
              FResults[k].List[FResults[k].listCount - 1] := FileStream.Position - BytesRead + i; // Добавляем позицию
            end;
          end;
        end;
      end;

    finally
      FileStream.Free;
    end;

  except
    on E: Exception do
      showmessage('Ошибка: ' + E.Message);
  end;
end;

function GetUniqueFileName(const Directory, BaseFileName, Extension: string): string;
var
  FullPath: string;
  FileIndex: Integer;
begin
  // Проверяем наличие директории, если нет - создаем
  if not DirectoryExists(Directory) then
    CreateDir(Directory);

  // Формируем полное имя файла
  FullPath := IncludeTrailingPathDelimiter(Directory) + BaseFileName + Extension;

  // Проверяем, существует ли файл, и подбираем уникальное имя
  FileIndex := 1;
  while FileExists(FullPath) do
  begin
    FullPath := IncludeTrailingPathDelimiter(Directory) + Format('%s<%d>%s', [BaseFileName, FileIndex, Extension]);
    Inc(FileIndex);
  end;

  Result := FullPath; // Возвращаем уникальное имя файла
end;

function SerializeToXML(const Results: TArrayResult; Filename : string): string;
var
  i, j: Integer;
  XMLString: TStringList;
begin
  XMLString := TStringList.Create;
  try
    XMLString.Add('<Results>'); // Начало корневого элемента
    // Проходим по каждому результату и добавляем его в XML
    for i := 0 to High(Results) do
    begin
      XMLString.Add('  <Result>'); // Начало элемента Result
      XMLString.Add(Format('    <Text>%s</Text>', [Results[i].text])); // Добавляем текст
      // Добавляем массив list
      XMLString.Add('    <List>');
      for j := 0 to Results[i].listCount - 1 do
      begin
        XMLString.Add(Format('      <Item>%d</Item>', [Results[i].list[j]])); // Добавляем каждый элемент
      end;
      XMLString.Add('    </List>'); // Конец элемента List
      XMLString.Add('  </Result>'); // Конец элемента Result
    end;
    XMLString.Add('</Results>'); // Конец корневого элемента
    Result := XMLString.Text; // Возвращаем XML как строку
    XMLString.SaveToFile(dir + '\temp.xml', TEncoding.UTF8);
  finally
    XMLString.Free; // Освобождаем ресурсы
  end;
end;

procedure RemoveDuplicatesFromSortedList(var result: TResult);
var
  i: Integer;
  NewList: TArrayINT64;
begin
  SetLength(NewList, 0);

  if result.listCount = 0 then
    Exit; // Если массив пустой, выходим

  // Добавляем первый элемент в новый массив
  SetLength(NewList, 1);
  NewList[0] := result.list[0];

  for i := 1 to result.listCount - 1 do
  begin
    // Если текущий элемент отличается от последнего добавленного, добавляем его в NewList
    if result.list[i] <> NewList[High(NewList)] then
    begin
      SetLength(NewList, Length(NewList) + 1);
      NewList[High(NewList)] := result.list[i];
    end;
  end;

  // Обновляем массив list и его счетчик
  result.list := NewList;
  result.listCount := Length(NewList);
end;

procedure RemoveDuplicatesFromArrayResult(var arrayResult: TArrayResult);
var
  i: Integer;
begin
  for i := 0 to High(arrayResult) do
  begin
    RemoveDuplicatesFromSortedList(arrayResult[i]);
  end;
end;

procedure TForm3.Button1Click(Sender: TObject);
const MaxThreadsCount = 10;
var
  Threads: array[0..MaxThreadsCount - 1] of TFileSearchThread;
  SearchTerms: TArrayTerms;
  i: Integer;
  FileSize : int64;
  FileStream :  TFileStream;
  k : integer;
  TermsMaxLength : Integer;
  PartSize : int64;
  start    : int64;
  finish   : int64;
  FinalResults : TArrayResult;
  l  : integer;
  r  : integer;
  sum : integer;
  s : string;
  ThreadCount : integer ;
  Filename    : String;

begin
  try
  memo2.Lines.Clear;
  SetComponentsEnabled(false);
  setStopAllFind(false);
  TermsMaxLength := 0;
  Setlength(SearchTerms, Memo1.Lines.Count);
  Setlength(FinalResults, Memo1.Lines.Count);
  for i := 0 to Memo1.Lines.Count - 1 do
  begin
    SearchTerms[i]  := trim(Memo1.Lines[i]);
    FinalResults[i].text := trim(Memo1.Lines[i]);
    if TermsMaxLength < Length(SearchTerms[i])  then
      TermsMaxLength := Length(SearchTerms[i]);
  end;

   // Получаем размер файла
  FileStream := TFileStream.Create(edit1.text, fmOpenRead or fmShareDenyWrite);
  try
    FileSize := FileStream.Size;
  finally
    FileStream.Free;
  end;


  // Создаем потоки
  start := 0;
  finish := 0;
  ThreadCount := FileSize div (1024*1024*1024); // создаем несколько потоков для чтения файла ,
  //   число потоков не больше MaxThreadsCount (4) в среднем по  потоку на каждый Гб файла.
  //
  if ThreadCount > MaxThreadsCount then
    ThreadCount:= MaxThreadsCount;

  PartSize := FileSize div ThreadCount;

  for i := 0 to ThreadCount - 1 do
  begin
    if i = 0 then begin start := 0; finish := PartSize + TermsMaxLength; end
    else
    begin
      start := (i * PartSize) - TermsMaxLength;
      finish := start + PartSize + TermsMaxLength * 2;
    end;
    Threads[i] := TFileSearchThread.Create(edit1.text, SearchTerms, start, finish);
    Threads[i].Start; // Запускаем поток
  end;

  // Ждем завершения всех потоков
  for i := 0 to ThreadCount - 1 do
  begin
    while true do
    begin

      if GetStopAllFind then
      Threads[i].SetStop(true);

      if Threads[i].Finished then break;
      application.ProcessMessages;
    end;

  end;



  sum := 0;
  for i := 0 to ThreadCount - 1 do
  begin
    if GetStopAllFind then break;
    // Обработка результатов
    for k := 0 to High(Threads[i].Results) do
    begin
     if GetStopAllFind then break;
      sum := sum + FinalResults[k].listCount;
      r := FinalResults[k].listCount;
      FinalResults[k].listCount := FinalResults[k].listCount + Threads[i].Results[k].listCount;
      setlength(FinalResults[k].list, FinalResults[k].listCount);
      for l := 0 to Threads[i].Results[k].listCount - 1 do
      begin
        FinalResults[k].list[r] := Threads[i].Results[k].list[l];
        r := r + 1;
      end;
    end;

  end;
   for i := 0 to ThreadCount - 1 do
   Threads[i].Free; // Освобождаем поток

   RemoveDuplicatesFromArrayResult(FinalResults); // выплолняем удаление дублей в заранее отсортированном массиве.
   Filename := GetUniqueFileName(dir+'\temp', 'temp', '.xml');
   SerializeToXML(FinalResults, Filename);
   if not GetStopAllFind then
   begin
     for k := 0 to High(FinalResults) do
     begin
       if GetStopAllFind then break;
       Memo2.Lines.Add('"' + FinalResults[k].text + '" встречается в тексте ' + inttostr(FinalResults[k].listCount) + ' раз');
       if FinalResults[k].listCount > 150 then
       begin
         Memo2.Lines.Add('Вывел первые 150 найденных, остальные в файле ' + Filename);
         s := '';
         for i := 0 to 148 do
         if ((i+1) mod 10) = 0 then s:= s + inttostr(FinalResults[k].list[i])+', ' + #13+#10
         else
           s := s + inttostr(FinalResults[k].list[i])+', ';
         s := s + inttostr(FinalResults[k].list[149])+'...';
         memo2.Lines.Add(s);
       end
       else
       begin
       s := '';
         for i := 0 to FinalResults[k].listCount - 2 do
         if ((i+1) mod 10) = 0 then
         s:= s + inttostr(FinalResults[k].list[i])+', ' + #13+#10
         else
         s := s + inttostr(FinalResults[k].list[i])+', ';
         s := s + inttostr(FinalResults[k].list[FinalResults[k].listCount -1])+';';
         memo2.Lines.Add(s);
       end;
     end;
   end
   else
    Memo2.Lines.Add('Выполнение поиска прервано по требованию пользователя');
  finally
    SetComponentsEnabled(true);
  end;

end;




procedure TForm3.Button2Click(Sender: TObject);
begin
  setStopAllFind(true);
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  getdir(0, dir);
  cr := TCriticalSection.Create;
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  if assigned(cr) then cr.Free;
end;

function TForm3.GetStopAllFind: boolean;
begin
  cr.Enter;
  try
    result := fStopAllFind;
  finally
    cr.Leave;
  end;
end;

procedure TFileSearchThread.SetStop(Value: boolean);
begin
  crThread.Enter;
  try
    FStop := Value;
  finally
    crThread.Leave;
  end;
end;

function TFileSearchThread.GetStop: boolean;
begin
  crThread.Enter;
  try
    Result := FStop;
  finally
    crThread.Leave;
  end;
end;

procedure TForm3.setStopAllFind(value: boolean);
begin
 cr.Enter;
 fStopAllFind := value;
 cr.Leave;
end;

procedure TForm3.SetComponentsEnabled(EnabledValue: Boolean);
begin
  Edit1.Enabled   := EnabledValue;
  Memo1.Enabled   := EnabledValue;
  Button1.Enabled := EnabledValue;
  Button2.Enabled := not EnabledValue;
end;

end.
