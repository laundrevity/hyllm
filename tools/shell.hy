(import asyncio)
(import tools.toolkit [tool])
(require core.macros *)

(defn/a
  [(tool
    "Run a shell command asynchronously in the system shell and return stdout and stderr output."
    :command "The shell command to execute (e.g., 'ls -lah', 'pwd', 'cat /etc/hosts | grep localhost')."
    :capture_stderr "If true, capture stderr (default: true)."
    :timeout "Timeout in seconds before killing process (default: 5)."
   )]
  run-shell-command
  [#^ str command
   #^ bool [capture_stderr True]
   #^ int [timeout 5]]

  (import asyncio.subprocess [PIPE])
  (try
    (setv proc (<- (asyncio.create_subprocess_shell
                     command
                     :stdout PIPE
                     :stderr (if capture_stderr PIPE None))))
    (setv #(stdout stderr) (<- (asyncio.wait_for (.communicate proc) timeout)))
    {"returncode" proc.returncode
     "stdout" (.decode (or stdout b"") "utf-8")
     "stderr" (if capture_stderr (.decode (or stderr b"") "utf-8") "")}
    (except [e Exception]
      {"error" (str e)})))
