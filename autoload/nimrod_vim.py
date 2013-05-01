import threading, Queue, subprocess, signal, os

try:
  import vim
except ImportError:
  class Vim:
    def command(self, x):
      print("Executing vim command: " + x)
  
  vim = Vim()

def disable_sigint():
  # Ignore the SIGINT signal by setting the handler to the standard
  # signal handler SIG_IGN.
  signal.signal(signal.SIGINT, signal.SIG_IGN)

class NimrodThread(threading.Thread):
  def __init__(self, project_path):
    super(NimrodThread, self).__init__()
    self.tasks = Queue.Queue()
    self.responses = Queue.Queue()
    self.nim = subprocess.Popen(
       ["nimrod", "serve", "--server.type:stdin", project_path],
       cwd = os.path.dirname(project_path),
       stdin = subprocess.PIPE,
       stdout = subprocess.PIPE,
       stderr = subprocess.STDOUT,
       universal_newlines = True,
       preexec_fn = disable_sigint,
       bufsize = 1)
 
  def postNimCmd(self, msg, async = True):
    self.tasks.put((msg, async))
    if not async:
      return self.responses.get()

  def run(self):
    while True:
      (msg, async) = self.tasks.get()

      if msg == "quit":
        self.nim.terminate()
        break

      self.nim.stdin.write(msg + "\n")
      result = ""
      
      while True:
        line = self.nim.stdout.readline()
        result += line
        if line == "\n":
          if not async:
            self.responses.put(result)
          else:
            self.asyncOpComplete(msg, result)
          break
        

def vimEscapeExpr(expr):
  return expr.replace("\\", "\\\\").replace('"', "\\\"").replace("\n", "\\n")

class NimrodVimThread(NimrodThread):
  def asyncOpComplete(self, msg, result):
    cmd = "/usr/local/bin/mvim --remote-expr 'NimrodAsyncCmdComplete(1, \"" + vimEscapeExpr(result) + "\")'"
    os.system (cmd)

projects = {}

log = open("/tmp/nim-log.txt", "w")

def execNimCmd(project, cmd, async = True):
  target = None
  if projects.has_key(project):
    target = projects[project]
  else:
    target = NimrodVimThread(project)
    projects[project] = target
    target.start()
  
  result = target.postNimCmd(cmd, async)
  if result != None:
    log.write(result)
    log.flush()
  
  if not async:
    vim.command('let l:py_res = "' + vimEscapeExpr(result) + '"')

