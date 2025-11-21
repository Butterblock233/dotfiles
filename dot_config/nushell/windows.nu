alias paste = win32yank.exe -o
alias copy = win32yank.exe -i
alias expo = explorer.exe .
alias expl = explorer.exe

alias start = cmd /c start
alias zedo = zed . 
alias nvim-qt = cmd /c start nvim-qt
alias neovide = cmd /c start neovide
alias nqt = nvim-qt
alias nqto = nvim-qt .
alias codeo = cmd /c code .

alias ss = scoop-search

alias typora = cmd /c start typora

chcp 65001 | ignore # use UTF-8 for shell

$env.PYTHONUTF8 = "1" # use UTF-8 in Python

def taskkill (task_name) {
  # Validate input
  if ($task_name | is-empty) {
    error make {msg: "Error: Process name cannot be empty"}
  }

  # Find processes matching the name pattern
  let processes = ps | where name =~ $task_name

  # Check if any processes were found
  if ($processes | is-empty) {
    error make {msg: $"Error: No processes found matching: ($task_name)"}
  }

  # Show what processes will be killed
  let process_count = $processes | length
  print $"Found ($process_count) process\(es\) matching: ($task_name)"
  $processes | select name pid

  # Kill processes and capture results
  let results = $processes | get pid | each { |pid|
    let process_name = ($processes | where pid == $pid | get name | first)
    try {
      kill --force $pid
      {pid: $pid, name: $process_name, status: "killed"}
    } catch {
      {pid: $pid, name: $process_name, status: "failed"}
    }
  }

  # Show results
  print "\nKill results:"
  $results | table

  # Summary
  let killed_count = ($results | where status == "killed" | length)
  let failed_count = ($results | where status == "failed" | length)

  if $failed_count > 0 {
    error make {msg: $"Processes killed: ($killed_count), failed: ($failed_count)"}
  } else {
    print $"Successfully killed ($killed_count) process\(es\)"
  }
}

