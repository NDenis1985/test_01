unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Shellapi, TlHelp32;

const
  WM_USER_SENDMESSAGE = WM_USER + 1; // Определяем пользовательское сообщение

type
  TArrayAnsiChar  = array [0..255] of AnsiChar;

  TConsoleEvent = function(dwCtrlEvent: DWORD; dwProcessGroupId: DWORD)
    : BOOL; stdcall;
  TConsoleHwnd = function(): HWND; stdcall;

  TCommandThread = class(TThread)
  private
    FCommand: string;
    FHandleWin: THandle;
    FOutputPipeRead: THandle;
    FOutputPipeWrite: THandle;
    FMemo: TMemo;
    FRunning : boolean;
    FCriticalSection: TRTLCriticalSection; // Критическая секция для защиты FRunning
    function ConvertFromOEM(const S: AnsiString): string;
  protected
    procedure Execute; override;

  public
    Procedure OutputHandler(OutPutline : AnsiString);
    constructor Create(const Command: string);
    destructor Destroy; override;
    Procedure setconsole(value : TMemo);
    procedure Stop;
    procedure SetWinHandle(value : THandle);
  end;

  TForm4 = class(TForm)
    Panel1: TPanel;
    Memo1: TMemo;
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
     ThreadConsole : TCommandThread;
    { Private declarations }

  public
    procedure WMSendMessage(var Msg: TMessage); message WM_USER_SENDMESSAGE;

    { Public declarations }
  end;



var
  Form4: TForm4;

implementation

{$R *.dfm}



function TCommandThread.ConvertFromOEM(const S: AnsiString): string;
var
  Dst: array[0..1024] of WideChar;
begin
  // Преобразование из OEM в Unicode
  MultiByteToWideChar(CP_OEMCP, 0, PAnsiChar(S), -1, Dst, Length(Dst));
  Result := Dst;
end;

constructor TCommandThread.Create(const Command: string);
var
  SecurityAttributes: TSecurityAttributes;
begin
  inherited Create(True); // Создаем поток в состоянии "приостановлен"
  FCommand := Command;
  fRunning := true;
   // Инициализация критической секции
  InitializeCriticalSection(FCriticalSection);

  // Настройка безопасности для пайпа
  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;


  // Создание пайпа для чтения вывода
  if not CreatePipe(FOutputPipeRead, FOutputPipeWrite, @SecurityAttributes, 0 ) then
  Exit;


  // Перенаправление вывода
  SetHandleInformation(FOutputPipeRead, HANDLE_FLAG_INHERIT, 0);

  FreeOnTerminate := True; // Освобождаем поток после завершения
end;
destructor TCommandThread.Destroy;
begin
  CloseHandle(FOutputPipeRead);
  CloseHandle(FOutputPipeWrite);
  DeleteCriticalSection(FCriticalSection);
  inherited;
end;

function KillProcessTree(const PID: Cardinal): boolean;
var hProc, hSnap,
    hChildProc  : THandle;
    pe          : TProcessEntry32;
    bCont       : BOOL;
begin
    Result := true;
    FillChar(pe, SizeOf(pe), #0);
    pe.dwSize := SizeOf(pe);

    hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (hSnap <> INVALID_HANDLE_VALUE) then
    begin
        if (Process32First(hSnap, pe)) then
        begin
            hProc := OpenProcess(PROCESS_TERMINATE , false, PID); //PROCESS_ALL_ACCESS

            if (hProc <> 0) then
            begin
                Result := Result and TerminateProcess(hProc, 1);
                WaitForSingleObject(hProc, INFINITE);
                CloseHandle(hProc);
            end;

            bCont := true;
            while bCont do
            begin
                if (pe.th32ParentProcessID = PID) then
                begin
                    KillProcessTree(pe.th32ProcessID);

                    hChildProc := OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);

                    if (hChildProc <> 0) then
                    begin
                        Result := Result and TerminateProcess(hChildProc, 1);
                        WaitForSingleObject(hChildProc, INFINITE);
                        CloseHandle(hChildProc);
                    end;
                end;
                bCont := Process32Next(hSnap, pe);
            end;
        end;

        CloseHandle(hSnap);
    end;
end;
procedure TCommandThread.SetWinHandle(value: THandle);
begin
  FHandleWin := value;
end;

function CtrlBreak(ConsoleEvent: TConsoleEvent): DWORD; stdcall;
begin

  // Generate the control break
  result := DWORD(ConsoleEvent(CTRL_BREAK_EVENT, 0));

end;

function CtrlC(ConsoleEvent: TConsoleEvent): DWORD; stdcall;
begin

  // Generate the control break
  result := DWORD(ConsoleEvent(CTRL_C_EVENT, 0));

end;

function ExecConsoleEvent(ProcessHandle: THandle; Event: DWORD): Boolean;
var
  lpCtrlEvent: Pointer;
  hThread: THandle;
  dwSize: SIZE_T;
  dwWrite: SIZE_T;
  dwExit: DWORD;
begin

  // Check event
  case Event of
    // Control C
    CTRL_C_EVENT:
      begin
        // Get size of function that we need to inject
        dwSize := PChar(@ExecConsoleEvent) - PChar(@CtrlC);
        // Allocate memory in remote process
        lpCtrlEvent := VirtualAllocEx(ProcessHandle, nil, dwSize, MEM_COMMIT,
          PAGE_EXECUTE_READWRITE);
        // Check memory, write code from this process
        if Assigned(lpCtrlEvent) then
          WriteProcessMemory(ProcessHandle, lpCtrlEvent, @CtrlC,
            dwSize, dwWrite);
      end;
    // Control break
    CTRL_BREAK_EVENT:
      begin
        // Get size of function that we need to inject
        dwSize := PChar(@CtrlC) - PChar(@CtrlBreak);
        // Allocate memory in remote process
        lpCtrlEvent := VirtualAllocEx(ProcessHandle, nil, dwSize, MEM_COMMIT,
          PAGE_EXECUTE_READWRITE);
        // Check memory, write code from this process
        if Assigned(lpCtrlEvent) then
          WriteProcessMemory(ProcessHandle, lpCtrlEvent, @CtrlBreak,
            dwSize, dwWrite);
      end;
  else
    // Not going to handle
    lpCtrlEvent := nil;
  end;

  // Check remote function address
  if Assigned(lpCtrlEvent) then
  begin
    // Resource protection
    try
      // Create remote thread starting at the injected function, passing in the address to GenerateConsoleCtrlEvent
      hThread := CreateRemoteThread(ProcessHandle, nil, 0, lpCtrlEvent,
        GetProcAddress(GetModuleHandle(kernel32), 'GenerateConsoleCtrlEvent'),
        0, DWORD(Pointer(nil)^));
      // Check thread
      if (hThread = 0) then
        // Failed to create thread
        result := False
      else
      begin
        // Resource protection
        try
          // Wait for the thread to complete
          WaitForSingleObject(hThread, INFINITE);
          // Get the exit code from the thread
          if GetExitCodeThread(hThread, dwExit) then
            // Set return
            result := not(dwExit = 0)
          else
            // Failed to get exit code
            result := False;
        finally
          // Close the thread handle
          CloseHandle(hThread);
        end;
      end;
    finally
      // Free allocated memory
      VirtualFreeEx(ProcessHandle, lpCtrlEvent, 0, MEM_RELEASE);
    end;
  end
  else
    // Failed to create remote injected function
    result := False;

end;



procedure TCommandThread.Execute;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: TArrayAnsiChar;
  BytesRead: DWORD;
  s : AnsiString;
  x : integer;
  SendStopComand : boolean;
begin
 try
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESTDHANDLES or FILE_FLAG_OVERLAPPED;
  StartupInfo.hStdOutput := FOutputPipeWrite;
  StartupInfo.hStdError := FOutputPipeWrite;
  SendStopComand := false;
//  SW_SHOW

  // Запуск процесса
//  CREATE_NO_WINDOW or CREATE_UNICODE_ENVIRONMENT
// CREATE_NEW_PROCESS_GROUP
//CREATE_NEW_CONSOLE
  if CreateProcess(nil, PChar('cmd.exe /C chcp 1251&&' + FCommand), nil, nil, True,
  CREATE_NO_WINDOW  , nil, nil, StartupInfo, ProcessInfo) then
  begin
    CloseHandle(ProcessInfo.hThread); // Закрываем дескриптор потока

    // Чтение вывода
    repeat
    application.ProcessMessages;
    if AnsiString('Control-C') = s then break;
    if ReadFile(FOutputPipeRead, Buffer, SizeOf(Buffer)-1, BytesRead, nil) then
      begin
        if BytesRead > 0 then
        begin
         for x := 0 to BytesRead-1 do
          if (Buffer[x] = #13) or (Buffer[x] = #10) then
          begin
             if AnsiString('Control-C') = s then break;

             OutputHandler(s);
             s := '';
          end
          else
          if Buffer[x] <> #0 then    s := s + Buffer[x];

          application.ProcessMessages;
//          Buffer[BytesRead] := #0; // Завершаем строку
          // Используем Queue для обновления Memo


        end;
     end;

      // Проверяем, запущен ли процесс
      EnterCriticalSection(FCriticalSection);
      try
        if (not FRunning) and (not SendStopComand) then
        begin
         SendStopComand := true;
         ExecConsoleEvent(ProcessInfo.hProcess, CTRL_C_EVENT);
        //  GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, ProcessInfo.dwProcessId);

//          GenerateConsoleCtrlEvent(CTRL_C_EVENT, ProcessInfo.dwProcessId);
//          GenerateConsoleCtrlEvent(CTRL_CLOSE_EVENT, ProcessInfo.dwProcessId);
//          TerminateProcess(ProcessInfo.hProcess, 0);
//          KillProcessTree(ProcessInfo.dwProcessId);

        //  TerminateProcess(ProcessInfo.hProcess, 0); // Завершаем процесс



        end;
      finally
      LeaveCriticalSection(FCriticalSection);
      end;

    until BytesRead = 0;
    if s <> '' then OutputHandler(s);


    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    CloseHandle(ProcessInfo.hProcess);
  end;
 finally
   PostMessage(FHandleWin, WM_USER_SENDMESSAGE, 0, 0);
 end;

end;


procedure TCommandThread.OutputHandler(OutPutline : AnsiString);
begin
   fMemo.Lines.Add(ConvertFromOEM(OutPutline)); // Добавляем вывод в Memo
end;

procedure TCommandThread.setconsole(value: TMemo);
begin
  fmemo := value;
end;

procedure TForm4.Button1Click(Sender: TObject);
var
  Command: string;

begin
  Button1.Enabled := false;
  Button2.Enabled := true;
  Command := edit1.Text;
  Memo1.Clear; // Очищаем Memo перед запуском
  ThreadConsole := TCommandThread.Create(Command);
  ThreadConsole.setconsole(Memo1);
  ThreadConsole.SetWinHandle(self.Handle);
  ThreadConsole.Start; // Запускаем поток
end;
procedure TForm4.Button2Click(Sender: TObject);
begin
if Assigned(ThreadConsole) then ThreadConsole.Stop;
end;



procedure TForm4.WMSendMessage(var Msg: TMessage);
begin
   if Msg.Msg =WM_USER_SENDMESSAGE then
   begin
     self.Button1.Enabled := true;
     self.Button2.Enabled := false;
   end;
end;


procedure TCommandThread.Stop;
begin
  EnterCriticalSection(FCriticalSection);
  try
    FRunning := False; // Устанавливаем флаг завершения
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

end.
