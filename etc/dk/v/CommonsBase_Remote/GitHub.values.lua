local M = {
  id = "CommonsBase_Remote.GitHub@0.1.0"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside the rules/uirules function bodies.
-- So a should-be-unique global is used instead.
CommonsBase_Remote__GitHub__0_1_0 = {}

rules, uirules = build.newrules(M)

function CommonsBase_Remote__GitHub__0_1_0.parse_positive_int(name, value, default)
  if value == nil then
    return default
  end
  local parsed = tonumber(value)
  assert(parsed and parsed >= 1 and math.floor(parsed) == parsed, "Expected `" .. name .. "=N` where N is a positive integer")
  return parsed
end

function CommonsBase_Remote__GitHub__0_1_0.user_scalar(value)
  if type(value) == "table" then
    return value[1]
  end
  return value
end

function CommonsBase_Remote__GitHub__0_1_0.parse_timestamp(value)
  if value == nil then
    return "19700101000000"
  end
  local value_s = tostring(value)
  assert(string.len(value_s) == 14, "Expected `timestamp=YYYYMMDDHHmmSS`")
  local i = 1
  while i <= 14 do
    local ch = string.sub(value_s, i, i)
    assert(ch >= "0" and ch <= "9", "Expected `timestamp=YYYYMMDDHHmmSS`")
    i = i + 1
  end
  return value_s
end

function CommonsBase_Remote__GitHub__0_1_0.normalize_repo(repo)
  assert(type(repo) == "string" and repo ~= "", "Expected a repository like `github.com/OWNER/REPO`")
  local rest = repo
  if string.sub(repo, 1, 11) == "github.com/" then
    rest = string.sub(repo, 12)
  end
  local slash = string.find(rest, "/", 1, true)
  local owner = nil
  local name = nil
  if slash then
    owner = string.sub(rest, 1, slash - 1)
    name = string.sub(rest, slash + 1)
  end
  if name ~= nil and string.find(name, "/", 1, true) then
    name = nil
  end
  assert(owner and name, "Expected a repository like `OWNER/REPO` or `github.com/OWNER/REPO`")
  return "github.com/" .. owner .. "/" .. name
end

function CommonsBase_Remote__GitHub__0_1_0.parse_common_args(request)
  local p = {}
  local continued = request.continued or {}
  local create_repo = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.create_repo)
  local dry_run = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.dry_run)
  if create_repo == nil then
    create_repo = CommonsBase_Remote__GitHub__0_1_0.user_scalar(continued.create_repo)
  end
  if dry_run == nil then
    dry_run = CommonsBase_Remote__GitHub__0_1_0.user_scalar(continued.dry_run)
  end
  local timestamp = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.timestamp)
  p.workspace = assert(stringdk.sanitizesubpath(CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.workspace) or "dk.u"), "Expected `workspace=RELATIVE_PATH`")
  p.sessions = CommonsBase_Remote__GitHub__0_1_0.parse_positive_int("sessions", CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.sessions), 4)
  p.retention = CommonsBase_Remote__GitHub__0_1_0.parse_positive_int("retention", CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.retention), 8)
  p.create_repo = create_repo ~= nil and tostring(create_repo) ~= "false" and tostring(create_repo) ~= "0"
  p.dryrun = dry_run ~= nil and tostring(dry_run) ~= "false" and tostring(dry_run) ~= "0"
  p.timestamp = CommonsBase_Remote__GitHub__0_1_0.parse_timestamp(timestamp)
  p.repo = CommonsBase_Remote__GitHub__0_1_0.normalize_repo(CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.repo) or "")
  p.cmd = assert(CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.cmd), "Expected `cmd=COMMAND`")
  p.commandvsl = assert(CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.commandvsl), "Expected `commandvsl=COMMAND`")
  p.argv = request.user.argv or {}
  assert(type(p.argv) == "table", "Expected at least one `argv[]=...` entry")
  assert(next(p.argv) ~= nil, "Expected at least one `argv[]=...` entry")
  p.requested_trace_key_id = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.requested_trace_key_id)
  p.requested_trace_key_description = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.requested_trace_key_description)
  p.gh = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.gh) or "gh"
  p.git = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.git) or "git"
  return p
end

function CommonsBase_Remote__GitHub__0_1_0.make_dry_run_plan(p)
  local orchestration_date = "20260527"
  local session_number = 1
  return {
    orchestration_date = orchestration_date,
    session_number = session_number,
    session_root_branch = "dk-session-root",
    session_branch = "dk-session-" .. tostring(session_number),
    workflow_path = ".dk/r/c/.github/workflows/dk-session." .. tostring(session_number) .. ".yml",
    audit_path = ".dk/r/c/etc/dk/s/" .. tostring(session_number) .. "-audit.txt",
    argv_path = ".dk/r/c/etc/dk/s/" .. tostring(session_number) .. "-argv.txt",
    stage_index_path = ".dk/r/c/etc/dk/s/" .. tostring(session_number) .. "-stage-index.txt",
    stage_signature_path = ".dk/r/c/etc/dk/s/" .. tostring(session_number) .. "-stage-index.sig",
    audit_line = p.timestamp .. "Z " .. p.commandvsl,
    stage_tag = "0.1." .. p.timestamp .. "-stage",
    exec_tag = "0.1." .. p.timestamp .. "-exec"
  }
end

function CommonsBase_Remote__GitHub__0_1_0.write_plan(request, file, p, rule_name)
  local create_repo = "false"
  local dry_run = "false"
  local plan = CommonsBase_Remote__GitHub__0_1_0.make_dry_run_plan(p)
  if p.create_repo then
    create_repo = "true"
  end
  if p.dryrun then
    dry_run = "true"
  end
  request.io.write(file, "[dry-run] CommonsBase_Remote.GitHub." .. rule_name .. "@0.1.0\n")
  request.io.write(file, "repo=" .. p.repo .. "\n")
  request.io.write(file, "workspace=" .. p.workspace .. "\n")
  request.io.write(file, "sessions=" .. tostring(p.sessions) .. "\n")
  request.io.write(file, "retention=" .. tostring(p.retention) .. "\n")
  request.io.write(file, "timestamp=" .. p.timestamp .. "\n")
  request.io.write(file, "create_repo=" .. create_repo .. "\n")
  request.io.write(file, "dry_run=" .. dry_run .. "\n")
  request.io.write(file, "cmd=" .. p.cmd .. "\n")
  request.io.write(file, "commandvsl=" .. p.commandvsl .. "\n")
  request.io.write(file, "session_root_branch=" .. plan.session_root_branch .. "\n")
  request.io.write(file, "session_branch=" .. plan.session_branch .. "\n")
  request.io.write(file, "workflow_path=" .. plan.workflow_path .. "\n")
  request.io.write(file, "workflow_generated_by=CommonsBase_Remote.GitHub@0.1.0\n")
  request.io.write(file, "audit_path=" .. plan.audit_path .. "\n")
  request.io.write(file, "argv_path=" .. plan.argv_path .. "\n")
  request.io.write(file, "stage_index_path=" .. plan.stage_index_path .. "\n")
  request.io.write(file, "stage_signature_path=" .. plan.stage_signature_path .. "\n")
  request.io.write(file, "audit_line=" .. plan.audit_line .. "\n")
  request.io.write(file, "stage_tag=" .. plan.stage_tag .. "\n")
  request.io.write(file, "exec_tag=" .. plan.exec_tag .. "\n")
  if p.requested_trace_key_id then
    request.io.write(file, "requested_trace_key_id=" .. p.requested_trace_key_id .. "\n")
  end
  if p.requested_trace_key_description then
    request.io.write(file, "requested_trace_key_description=" .. p.requested_trace_key_description .. "\n")
  end
  local i = 1
  while p.argv[i] do
    request.io.write(file, "argv[" .. tostring(i - 1) .. "]=" .. p.argv[i] .. "\n")
    i = i + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.trim(s)
  s = s or ""
  local first = 1
  local last = string.len(s)
  local scanning = true
  while first <= last and scanning do
    local ch = string.sub(s, first, first)
    if ch == " " or ch == "\t" or ch == "\r" or ch == "\n" then
      first = first + 1
    else
      scanning = false
    end
  end
  scanning = true
  while last >= first and scanning do
    local ch = string.sub(s, last, last)
    if ch == " " or ch == "\t" or ch == "\r" or ch == "\n" then
      last = last - 1
    else
      scanning = false
    end
  end
  if first > last then
    return ""
  end
  return string.sub(s, first, last)
end

function CommonsBase_Remote__GitHub__0_1_0.replace_all(s, needle, replacement)
  local out = {}
  local i = 1
  local n = string.len(needle)
  while i <= string.len(s) do
    if string.sub(s, i, i + n - 1) == needle then
      table.insert(out, replacement)
      i = i + n
    else
      table.insert(out, string.sub(s, i, i))
      i = i + 1
    end
  end
  return table.concat(out, "")
end

function CommonsBase_Remote__GitHub__0_1_0.base64_encode(s)
  local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local out = {}
  local i = 1
  while i <= string.len(s) do
    local b1 = string.byte(s, i) or 0
    local b2 = string.byte(s, i + 1) or 0
    local b3 = string.byte(s, i + 2) or 0
    local n = b1 * 65536 + b2 * 256 + b3
    local c1 = math.floor(n / 262144) % 64 + 1
    local c2 = math.floor(n / 4096) % 64 + 1
    local c3 = math.floor(n / 64) % 64 + 1
    local c4 = (n % 64) + 1
    table.insert(out, string.sub(alphabet, c1, c1))
    table.insert(out, string.sub(alphabet, c2, c2))
    if i + 1 <= string.len(s) then
      table.insert(out, string.sub(alphabet, c3, c3))
    else
      table.insert(out, "=")
    end
    if i + 2 <= string.len(s) then
      table.insert(out, string.sub(alphabet, c4, c4))
    else
      table.insert(out, "=")
    end
    i = i + 3
  end
  return table.concat(out, "")
end

function CommonsBase_Remote__GitHub__0_1_0.write_base64_lines(request, path, values)
  CommonsBase_Remote__GitHub__0_1_0.write_text(request, path, CommonsBase_Remote__GitHub__0_1_0.base64_lines_text(values))
end

function CommonsBase_Remote__GitHub__0_1_0.base64_lines_text(values)
  local out = {}
  local i = 1
  while values[i] do
    table.insert(out, CommonsBase_Remote__GitHub__0_1_0.base64_encode(values[i]))
    i = i + 1
  end
  return table.concat(out, "\n") .. "\n"
end

function CommonsBase_Remote__GitHub__0_1_0.lines(s)
  local t = {}
  s = s or ""
  local pos = 1
  while pos <= string.len(s) do
    local nl = string.find(s, "\n", pos, true)
    local line = nil
    if nl then
      line = string.sub(s, pos, nl - 1)
      pos = nl + 1
    else
      line = string.sub(s, pos)
      pos = string.len(s) + 1
    end
    if string.sub(line, -1) == "\r" then
      line = string.sub(line, 1, -2)
    end
    if line ~= "" then
      table.insert(t, line)
    end
  end
  return t
end

function CommonsBase_Remote__GitHub__0_1_0.first_line(s)
  local lines = CommonsBase_Remote__GitHub__0_1_0.lines(s)
  return lines[1] or ""
end

function CommonsBase_Remote__GitHub__0_1_0.shell_quote(s)
  if s == "" then
    return "''"
  end
  if string.find(s, "[^A-Za-z0-9_@%%+=:,./-]") then
    return "'" .. CommonsBase_Remote__GitHub__0_1_0.replace_all(s, "'", "'\\''") .. "'"
  end
  return s
end

function CommonsBase_Remote__GitHub__0_1_0.show_command(program, args)
  local parts = { program }
  local i = 1
  while args[i] do
    table.insert(parts, CommonsBase_Remote__GitHub__0_1_0.shell_quote(args[i]))
    i = i + 1
  end
  return table.concat(parts, " ")
end

function CommonsBase_Remote__GitHub__0_1_0.helper_envmods(options)
  local envmods = {}
  if options and options.envmods then
    local i = 1
    while options.envmods[i] do
      envmods[#envmods + 1] = options.envmods[i]
      i = i + 1
    end
  end
  envmods[#envmods + 1] = "-ZIG_PROGRESS"
  return envmods
end

function CommonsBase_Remote__GitHub__0_1_0.capture(request, program, args, options)
  options = options or {}
  local allowfailure = options.allowfailure or options.allow_failure
  print("+ " .. CommonsBase_Remote__GitHub__0_1_0.show_command(program, args))
  local request_options = {
    program = program,
    args = args,
    max_output_bytes = options.max_output_bytes or 16777211,
    envmods = CommonsBase_Remote__GitHub__0_1_0.helper_envmods(options),
  }
  if options.cwd then
    request_options.cwd = options.cwd
  end
  local result, msg, kind = request.ui.capture(request_options)
  if not result then
    if allowfailure then
      return { status = "capture", code = 255, stdout = "", stderr = tostring(kind) .. ": " .. tostring(msg) }
    end
    assert(false, "Could not run `" .. program .. "`: " .. tostring(kind) .. ": " .. tostring(msg))
  end
  if result.stdout and result.stdout ~= "" and not options.quiet then
    print(result.stdout)
  end
  if result.stderr and result.stderr ~= "" and not options.quiet then
    print(result.stderr)
  end
  if result.status ~= "exit" or result.code ~= 0 then
    if allowfailure then
      return result
    end
    assert(false, "`" .. program .. "` exited with code " .. tostring(result.code) .. ": " .. tostring(result.stderr))
  end
  return result
end

function CommonsBase_Remote__GitHub__0_1_0.spawn(request, program, args, options)
  options = options or {}
  print("+ " .. CommonsBase_Remote__GitHub__0_1_0.show_command(program, args))
  local request_options = {
    program = program,
    args = args,
    envmods = CommonsBase_Remote__GitHub__0_1_0.helper_envmods(options)
  }
  if options.cwd then
    request_options.cwd = options.cwd
  end
  if options.envmods then
    request_options.envmods = options.envmods
  end
  local ok, msg, kind, code = request.ui.spawn(request_options)
  if ok then
    return { status = "exit", code = 0 }
  end
  if options.allowfailure or options.allow_failure then
    return { status = kind or "exit", code = code or 255, stderr = tostring(msg or "") }
  end
  assert(false, "Could not run `" .. program .. "`: " .. tostring(kind) .. ": " .. tostring(msg))
end

function CommonsBase_Remote__GitHub__0_1_0.path_join(base, child)
  local sep = "/"
  if string.find(base, "\\") then
    sep = "\\"
  end
  if string.sub(base, -1) == "/" or string.sub(base, -1) == "\\" then
    return base .. child
  end
  return base .. sep .. child
end

function CommonsBase_Remote__GitHub__0_1_0.is_windows(request)
  local abi = tostring(request.execution and request.execution.ABIv3 or "")
  if abi ~= "" then
    return string.sub(abi, 1, 8) == "Windows_"
  end
  -- Some UI rule contexts do not populate request.execution.ABIv3.
  -- Fall back to probing for cmd.exe availability.
  local cap = request.ui.capture {
    program = "cmd",
    args = { "/d", "/c", "ver" },
    max_output_bytes = 1024
  }
  if cap and cap.status == "exit" and cap.code == 0 then
    return true
  end
  return false
end

function CommonsBase_Remote__GitHub__0_1_0.write_text(request, path, content)
  local file = request.io.open(path, "w")
  request.io.write(file, content)
  local realpath = request.io.realpath(file)
  request.io.close(file)
  return realpath
end

function CommonsBase_Remote__GitHub__0_1_0.dirname(path)
  local i = string.len(path)
  while i >= 1 do
    local ch = string.sub(path, i, i)
    if ch == "/" or ch == "\\" then
      return string.sub(path, 1, i - 1)
    end
    i = i - 1
  end
  return ""
end

function CommonsBase_Remote__GitHub__0_1_0.windows_quote(s)
  s = tostring(s or "")
  if s == "" then
    return "\"\""
  end
  if string.find(s, "[ \t\"&|<>^()]") then
    return "\"" .. CommonsBase_Remote__GitHub__0_1_0.replace_all(s, "\"", "\"\"") .. "\""
  end
  return s
end

function CommonsBase_Remote__GitHub__0_1_0.windows_force_quote(s)
  s = tostring(s or "")
  return "\"" .. CommonsBase_Remote__GitHub__0_1_0.replace_all(s, "\"", "\"\"") .. "\""
end

function CommonsBase_Remote__GitHub__0_1_0.try_capture(request, program, args, options)
  options = options or {}
  local request_options = {
    program = program,
    args = args,
    max_output_bytes = options.max_output_bytes or 16777211,
    envmods = CommonsBase_Remote__GitHub__0_1_0.helper_envmods(options),
  }
  if options.cwd then
    request_options.cwd = options.cwd
  end
  -- Use request.ui.capture directly. Its built-in stdout/stderr capture uses
  -- internal file I/O (not request.io), so it is not affected by request.io
  -- content caching. On Windows, request.ui.capture can execute .cmd wrappers.
  local cap, msg, kind = request.ui.capture(request_options)
  if not cap then
    return { status = "capture", code = "255", stdout = "", stderr = tostring(kind) .. ": " .. tostring(msg) }
  end
  return {
    status = cap.status or "exit",
    code = tostring(cap.code),
    stdout = cap.stdout or "",
    stderr = cap.stderr or ""
  }
end

function CommonsBase_Remote__GitHub__0_1_0.try_file_abs(request, path)
  local file = request.io.open(path, "r")
  if request.io.isfile(file) then
    local abs = request.io.realpath(file)
    request.io.close(file)
    return abs
  end
  request.io.close(file)
  return nil
end

function CommonsBase_Remote__GitHub__0_1_0.find_named_file_abs(request, dir, name)
  local entries = request.io.list(dir, "all")
  local i = 1
  while entries[i] do
    local entry = entries[i]
    if request.io.isdir(entry) then
      local nested = CommonsBase_Remote__GitHub__0_1_0.find_named_file_abs(request, entry, name)
      request.io.close(entry)
      if nested then
        return nested
      end
    elseif request.io.isfile(entry) then
      local rel = request.io.realpath(entry, { relative = 1 })
      if CommonsBase_Remote__GitHub__0_1_0.basename(rel) == name then
        local abs = request.io.realpath(entry)
        request.io.close(entry)
        return abs
      end
    end
    request.io.close(entry)
    i = i + 1
  end
  return nil
end

function CommonsBase_Remote__GitHub__0_1_0.project_root_cmd(request)
  local result = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    "cmd",
    { "/d", "/c", "cd" },
    { quiet = true, allowfailure = true, max_output_bytes = 4096 })
  if result.code ~= "0" then
    return ""
  end
  return CommonsBase_Remote__GitHub__0_1_0.trim(CommonsBase_Remote__GitHub__0_1_0.first_line(result.stdout))
end

function CommonsBase_Remote__GitHub__0_1_0.normalize_program(program)
  local s = tostring(program or "")
  if s == "" then
    return s
  end
  if string.sub(s, 1, 2) == "./" or string.sub(s, 1, 2) == ".\\" then
    return s
  end
  if string.find(s, "/", 1, true) or string.find(s, "\\", 1, true) or string.find(s, ":", 1, true) then
    return s
  end
  return "./" .. s
end

function CommonsBase_Remote__GitHub__0_1_0.local_dk0_program(request, snapshot_dir)
  if snapshot_dir then
    local snapshot_cmd = CommonsBase_Remote__GitHub__0_1_0.find_named_file_abs(request, snapshot_dir, "dk0.cmd")
    if snapshot_cmd then
      return CommonsBase_Remote__GitHub__0_1_0.normalize_program(snapshot_cmd)
    end
    local snapshot_sh = CommonsBase_Remote__GitHub__0_1_0.find_named_file_abs(request, snapshot_dir, "dk0")
    if snapshot_sh then
      return CommonsBase_Remote__GitHub__0_1_0.normalize_program(snapshot_sh)
    end
  end
  local local_cmd = CommonsBase_Remote__GitHub__0_1_0.try_file_abs(request, "dk0.cmd")
  if local_cmd then
    return CommonsBase_Remote__GitHub__0_1_0.normalize_program(local_cmd)
  end
  local local_sh = CommonsBase_Remote__GitHub__0_1_0.try_file_abs(request, "dk0")
  if local_sh then
    return CommonsBase_Remote__GitHub__0_1_0.normalize_program(local_sh)
  end
  if CommonsBase_Remote__GitHub__0_1_0.is_windows(request) then
    local root = CommonsBase_Remote__GitHub__0_1_0.project_root_cmd(request)
    if root ~= "" then
      return root .. "\\dk0.cmd"
    end
    return "./dk0.cmd"
  end
  return "./dk0"
end

function CommonsBase_Remote__GitHub__0_1_0.run_local_dk0(request, snapshot_dir, args)
  if CommonsBase_Remote__GitHub__0_1_0.is_windows(request) then
    local root = CommonsBase_Remote__GitHub__0_1_0.project_root_cmd(request)
    if root ~= "" then
      local cmdline = ".\\dk0.cmd"
      local i = 1
      while args[i] do
        cmdline = cmdline .. " " .. CommonsBase_Remote__GitHub__0_1_0.windows_quote(args[i])
        i = i + 1
      end
      local root_result = CommonsBase_Remote__GitHub__0_1_0.try_capture(
        request,
        "cmd",
        { "/d", "/c", cmdline },
        { cwd = root, allowfailure = true })
      if root_result.code == "0" then
        return root_result
      end
    end
  end
  local local_program = CommonsBase_Remote__GitHub__0_1_0.local_dk0_program(request, snapshot_dir)
  return CommonsBase_Remote__GitHub__0_1_0.capture(
    request,
    local_program,
    args)
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_coreutils(request, snapshot_dir)
  local program = ".dk/r/c/.local/coreutils/coreutils.exe"
  local probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    program,
    { "--version" },
    { quiet = true, allowfailure = true })
  if probe.code ~= "0" then
    CommonsBase_Remote__GitHub__0_1_0.run_local_dk0(
      request,
      snapshot_dir,
      { "get-object", "CommonsBase_Std.Coreutils@0.8.0", "-s", "Release.execution_abi", "-d", ".dk/r/c/.local/coreutils" })
  end
  return program
end

function CommonsBase_Remote__GitHub__0_1_0.normalize_relpath(path)
  path = tostring(path)
  local parts = {}
  local part_count = 0
  local i = 1
  while i <= string.len(path) do
    local ch = string.sub(path, i, i)
    if ch == "\\" then
      part_count = part_count + 1
      parts[part_count] = "/"
    else
      part_count = part_count + 1
      parts[part_count] = ch
    end
    i = i + 1
  end
  return table.concat(parts)
end

function CommonsBase_Remote__GitHub__0_1_0.windows_relpath(path)
  path = CommonsBase_Remote__GitHub__0_1_0.normalize_relpath(path)
  local parts = {}
  local part_count = 0
  local i = 1
  while i <= string.len(path) do
    local ch = string.sub(path, i, i)
    if ch == "/" then
      part_count = part_count + 1
      parts[part_count] = "\\"
    else
      part_count = part_count + 1
      parts[part_count] = ch
    end
    i = i + 1
  end
  return table.concat(parts)
end

function CommonsBase_Remote__GitHub__0_1_0.ends_with(text, suffix)
  text = tostring(text or "")
  suffix = tostring(suffix or "")
  if suffix == "" then
    return true
  end
  if string.len(suffix) > string.len(text) then
    return false
  end
  return string.sub(text, string.len(text) - string.len(suffix) + 1) == suffix
end

function CommonsBase_Remote__GitHub__0_1_0.sort_strings(values)
  local i = 2
  while values[i] do
    local value = values[i]
    local j = i - 1
    while j >= 1 and values[j] > value do
      values[j + 1] = values[j]
      j = j - 1
    end
    values[j + 1] = value
    i = i + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.extract_14_digit_timestamp(text)
  text = tostring(text or "")
  local start = 1
  while start <= string.len(text) - 13 do
    local ok = true
    local offset = 0
    while offset < 14 and ok do
      local ch = string.sub(text, start + offset, start + offset)
      if ch < "0" or ch > "9" then
        ok = false
      end
      offset = offset + 1
    end
    if ok then
      return string.sub(text, start, start + 13)
    end
    start = start + 1
  end
  return nil
end

function CommonsBase_Remote__GitHub__0_1_0.synthetic_14_digit_timestamp(request)
  local symbol = tostring(request.rule.generatesymbol() or "")
  if symbol == "" then
    return "19700101000000"
  end
  local out = {}
  local len = string.len(symbol)
  local i = 1
  while i <= 14 do
    local pos = ((i - 1) % len) + 1
    local ch = string.byte(symbol, pos) or 0
    out[i] = tostring(ch % 10)
    i = i + 1
  end
  return table.concat(out, "")
end

function CommonsBase_Remote__GitHub__0_1_0.json_string_field(json_text, field_name)
  local text = tostring(json_text or "")
  local needle = "\"" .. tostring(field_name or "") .. "\""
  local search_from = 1
  while true do
    local key_start, key_end = string.find(text, needle, search_from, true)
    if not key_start then
      return nil
    end
    local colon = string.find(text, ":", key_end + 1, true)
    if not colon then
      return nil
    end
    local quote_start = string.find(text, "\"", colon + 1, true)
    if quote_start then
      local value_start = quote_start + 1
      local value_end = string.find(text, "\"", value_start, true)
      if value_end then
        return string.sub(text, value_start, value_end - 1)
      end
    end
    search_from = key_end + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.write_project_text(request, coreutils, dest_rel, content, mode)
  local temp_rel =
    "remote-github/generated-" ..
    CommonsBase_Remote__GitHub__0_1_0.basename(dest_rel) ..
    "-" .. request.rule.generatesymbol() .. ".txt"
  local temp_abs = CommonsBase_Remote__GitHub__0_1_0.write_text(request, temp_rel, content)
  CommonsBase_Remote__GitHub__0_1_0.install_project_file(request, coreutils, temp_abs, dest_rel, mode)
end

function CommonsBase_Remote__GitHub__0_1_0.install_project_file(request, coreutils, source_abs, dest_rel, mode)
  local dest_dir = CommonsBase_Remote__GitHub__0_1_0.dirname(dest_rel)
  if dest_dir and dest_dir ~= "" and dest_dir ~= "." then
    CommonsBase_Remote__GitHub__0_1_0.spawn(request, coreutils, { "mkdir", "-p", dest_dir })
  end
  CommonsBase_Remote__GitHub__0_1_0.spawn(request, coreutils, { "rm", "-f", dest_rel })
  CommonsBase_Remote__GitHub__0_1_0.spawn(request, coreutils, { "cp", "-f", source_abs, dest_rel })
end

function CommonsBase_Remote__GitHub__0_1_0.copy_snapshot_file_to_project(request, coreutils, source_file, dest_rel)
  local source_abs = request.io.realpath(source_file)
  CommonsBase_Remote__GitHub__0_1_0.install_project_file(request, coreutils, source_abs, dest_rel)
end

function CommonsBase_Remote__GitHub__0_1_0.copy_project_dir_to_commit(request, dir, p, copied, seen)
  local entries = request.io.list(dir, "all")
  local i = 1
  while entries[i] do
    local entry = entries[i]
    if request.io.isdir(entry) then
      CommonsBase_Remote__GitHub__0_1_0.copy_project_dir_to_commit(request, entry, p, copied, seen)
    elseif request.io.isfile(entry) then
      local source_rel = CommonsBase_Remote__GitHub__0_1_0.normalize_relpath(request.io.realpath(entry, { relative = 1 }))
      local source_name = CommonsBase_Remote__GitHub__0_1_0.basename(source_rel)
      local workspace_name = CommonsBase_Remote__GitHub__0_1_0.basename(CommonsBase_Remote__GitHub__0_1_0.normalize_relpath(p.workspace))
      local rel = nil
      local dest_rel = nil
      if source_name == workspace_name then
        rel = "dk.u"
        dest_rel = ".dk/r/c/dk.u"
        seen.workspace = true
      elseif source_name == "dk0" then
        rel = "dk0"
        dest_rel = ".dk/r/c/dk0"
        seen.dk0 = true
      elseif source_name == "dk0.cmd" then
        rel = "dk0.cmd"
        dest_rel = ".dk/r/c/dk0.cmd"
        seen.dk0cmd = true
      elseif CommonsBase_Remote__GitHub__0_1_0.ends_with(source_rel, "/t/k/build.sec") then
        dest_rel = ".dk/r/c/t/k/build.sec"
        seen.buildsec = true
      elseif CommonsBase_Remote__GitHub__0_1_0.ends_with(source_rel, "/t/k/build.pub") then
        rel = "t/k/build.pub"
        dest_rel = ".dk/r/c/t/k/build.pub"
        seen.buildpub = true
      else
        local idx = string.find(source_rel, "/etc/dk/d/", 1, true)
        if not idx then
          idx = string.find(source_rel, "/etc/dk/i/", 1, true)
        end
        if not idx then
          idx = string.find(source_rel, "/etc/dk/v/", 1, true)
        end
        if idx then
          rel = string.sub(source_rel, idx + 1)
          dest_rel = ".dk/r/c/" .. rel
        end
      end
      if dest_rel then
        CommonsBase_Remote__GitHub__0_1_0.copy_snapshot_file_to_project(request, p.coreutils, entry, dest_rel)
        if rel then
          table.insert(copied, rel)
        end
      end
    end
    request.io.close(entry)
    i = i + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_control_tree(request, coreutils)
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(request, coreutils, ".dk/r/.gitignore", "*\n", "0644")
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(request, coreutils, ".dk/r/.hgignore", "syntax: glob\n*\n", "0644")
end

function CommonsBase_Remote__GitHub__0_1_0.collect_relative_files(request, dir, root, out, rel_prefix)
  local entries = request.io.list(dir, "all")
  local i = 1
  while entries[i] do
    local entry = entries[i]
    if request.io.isdir(entry) then
      CommonsBase_Remote__GitHub__0_1_0.collect_relative_files(
        request,
        entry,
        root,
        out,
        rel_prefix)
    elseif request.io.isfile(entry) then
      local entry_abs = request.io.realpath(entry)
      local rel = string.sub(entry_abs, string.len(root) + 2)
      table.insert(out, rel_prefix .. "/" .. rel)
    end
    request.io.close(entry)
    i = i + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.prepare_commit_repo_inputs(request, snapshot_dir, p, coreutils)
  local copied = {}
  local seen = {}
  p.coreutils = coreutils
  CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    {
      "-C", ".dk/r/c", "rm", "-r", "-f", "--ignore-unmatch",
      "dk.u",
      "dk0",
      "dk0.cmd",
      "etc/dk/d",
      "etc/dk/i",
      "etc/dk/v",
      "INDEX",
      "INDEX.sig",
      "t/k/build.pub"
    },
    { quiet = true, allowfailure = true })
  CommonsBase_Remote__GitHub__0_1_0.copy_project_dir_to_commit(request, snapshot_dir, p, copied, seen)
  return copied
end

function CommonsBase_Remote__GitHub__0_1_0.write_windows_wrapper(request, wrapper_name, body)
  return CommonsBase_Remote__GitHub__0_1_0.write_text(
    request,
    "remote-github/bin/" .. wrapper_name .. ".cmd",
    "@echo off\r\n" .. body .. "\r\n")
end

function CommonsBase_Remote__GitHub__0_1_0.wrap_windows_program(request, wrapper_name, target)
  local body = "if exist \"" .. target .. "\" goto found\r\n" ..
    "echo Could not find required program at " .. target .. " 1>&2\r\n" ..
    "exit /b 1\r\n" ..
    ":found\r\n" ..
    "\"" .. target .. "\" %*\r\n" ..
    "exit /b %ERRORLEVEL%"
  return CommonsBase_Remote__GitHub__0_1_0.write_windows_wrapper(request, wrapper_name, body)
end

function CommonsBase_Remote__GitHub__0_1_0.write_windows_path_wrapper(request, wrapper_name, command_name, fallback_dirs)
  local lines = {
    "setlocal"
  }
  local i = 1
  while fallback_dirs[i] do
    local dir = fallback_dirs[i]
    table.insert(lines, "if exist \"" .. dir .. "\\" .. command_name .. ".exe\" set \"PATH=%PATH%;" .. dir .. "\"")
    i = i + 1
  end
  table.insert(lines, command_name .. " --version >nul 2>nul")
  table.insert(lines, "if errorlevel 1 (")
  table.insert(lines, "  echo Could not find required program `" .. command_name .. "` on PATH 1>&2")
  table.insert(lines, "  exit /b 1")
  table.insert(lines, ")")
  table.insert(lines, command_name .. " %*")
  table.insert(lines, "exit /b %ERRORLEVEL%")
  return CommonsBase_Remote__GitHub__0_1_0.write_windows_wrapper(request, wrapper_name, table.concat(lines, "\r\n"))
end

function CommonsBase_Remote__GitHub__0_1_0.resolve_programs(request, p)
  local gh_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request, p.gh, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
  if gh_probe.code ~= "0" then
    if p.gh == "gh" then
      local wrapped = CommonsBase_Remote__GitHub__0_1_0.write_windows_path_wrapper(
        request,
        "resolve-gh",
        "gh",
        { "C:\\Program Files\\GitHub CLI" })
      local wrapped_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
        request, wrapped, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
      if wrapped_probe.code == "0" then
        p.gh = wrapped
      end
    elseif string.find(p.gh, " ", 1, true) then
      local wrapped = CommonsBase_Remote__GitHub__0_1_0.wrap_windows_program(request, "resolve-gh", p.gh)
      local wrapped_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
        request, wrapped, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
      if wrapped_probe.code == "0" then
        p.gh = wrapped
      end
    end
  end
  local git_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request, p.git, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
  if git_probe.code ~= "0" then
    if p.git == "git" then
      local wrapped = CommonsBase_Remote__GitHub__0_1_0.write_windows_path_wrapper(
        request,
        "resolve-git",
        "git",
        { "C:\\Program Files\\Git\\cmd", "C:\\Program Files\\Git\\bin" })
      local wrapped_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
        request, wrapped, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
      if wrapped_probe.code == "0" then
        p.git = wrapped
      end
    elseif string.find(p.git, " ", 1, true) then
      local wrapped = CommonsBase_Remote__GitHub__0_1_0.wrap_windows_program(request, "resolve-git", p.git)
      local wrapped_probe = CommonsBase_Remote__GitHub__0_1_0.try_capture(
        request, wrapped, { "--version" }, { quiet = true, allowfailure = true, max_output_bytes = 4096 })
      if wrapped_probe.code == "0" then
        p.git = wrapped
      end
    end
  end
end

function CommonsBase_Remote__GitHub__0_1_0.read_text(request, path)
  local file = request.io.open(path, "r")
  local content = request.io.read(file, "all")
  request.io.close(file)
  return content or ""
end

function CommonsBase_Remote__GitHub__0_1_0.safe_name(s)
  local ok = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-"
  local out = {}
  local i = 1
  while i <= string.len(s) do
    local ch = string.sub(s, i, i)
    if string.find(ok, ch, 1, true) then
      table.insert(out, ch)
    else
      table.insert(out, "-")
    end
    i = i + 1
  end
  return table.concat(out, "")
end

function CommonsBase_Remote__GitHub__0_1_0.ownerrepo(repo)
  local prefix = "github.com/"
  assert(string.sub(repo, 1, string.len(prefix)) == prefix, "Expected a repository like `github.com/OWNER/REPO`")
  return string.sub(repo, string.len(prefix) + 1)
end

function CommonsBase_Remote__GitHub__0_1_0.now_utc(request, p)
  local result = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request, p.git, { "show", "-s", "--date=format:%Y%m%d%H%M%S", "--format=%cd", "HEAD" },
    { quiet = true, allowfailure = true })
  local timestamp = CommonsBase_Remote__GitHub__0_1_0.extract_14_digit_timestamp(result.stdout)
  if not timestamp then
    timestamp = CommonsBase_Remote__GitHub__0_1_0.extract_14_digit_timestamp(result.stderr)
  end
  if not timestamp then
    -- Some wrapper scripts can make stdout/stderr capture unreliable for .cmd
    -- wrappers. Use a deterministic synthetic timestamp shape as fallback so
    -- stage/exec tag generation still proceeds.
    timestamp = CommonsBase_Remote__GitHub__0_1_0.synthetic_14_digit_timestamp(request)
  end
  assert(timestamp, "Could not derive a timestamp")
  return timestamp
end

function CommonsBase_Remote__GitHub__0_1_0.workflow_yaml(session, keep)
  local template = table.concat({
    "# Generated by CommonsBase_Remote.GitHub@0.1.0.",
    "# See dist-any.u/run.u for the detailed orchestration flow.",
    "name: dk-session.__SESSION__",
    "on:",
    "  push:",
    "    branches:",
    "      - dk-session-__SESSION__",
    "    paths:",
    "      - 'etc/dk/s/__SESSION__-audit.txt'",
    "      - '.github/workflows/dk-session.__SESSION__.yml'",
    "      - 'dk.u'",
    "      - 'dk0'",
    "      - 'dk0.cmd'",
    "      - 'etc/dk/**'",
    "      - 'INDEX'",
    "      - 'INDEX.sig'",
    "permissions:",
    "  contents: write # needed to create prereleases, upload release assets, and delete old orchestration prereleases",
    "concurrency:",
    "  group: dk-session-__SESSION__",
    "  cancel-in-progress: false",
    "jobs:",
    "  session:",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2",
    "        with:",
    "          fetch-depth: 0",
    "      - name: Install mlfront-signify",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          mkdir -p .dk-remote/bin",
    "          curl -fsSL 'https://gitlab.com/api/v4/projects/60486861/packages/generic/mlfront-signify/2.4.2.180/mlfront-signify-linux_x86_64' -o .dk-remote/bin/mlfront-signify",
    "          printf '%s  %s\\n' '07a378f0db43999a9fdf1ab8b031a2007f90fbc24664cc5bca90315634b10f06' '.dk-remote/bin/mlfront-signify' | sha256sum -c -",
    "          chmod +x .dk-remote/bin/mlfront-signify",
    "          ./.dk-remote/bin/mlfront-signify --help >/dev/null",
    "      - name: Determine phase",
    "        id: phase",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          tag=\"$(git tag --points-at HEAD | grep -E '0[.]1[.][0-9]{14}-(stage|exec)$' | head -n 1 || true)\"",
    "          if [ -z \"$tag\" ]; then",
    "            echo 'Expected the current commit to have a dk-session stage or exec tag' 1>&2",
    "            exit 1",
    "          fi",
    "          phase=\"${tag##*-}\"",
    "          case \"$phase\" in",
    "            stage|exec) ;;",
    "            *)",
    "              echo \"Unsupported dk-session phase: $phase\" 1>&2",
    "              exit 1",
    "              ;;",
    "          esac",
    "          ./.dk-remote/bin/mlfront-signify -V -p t/k/build.pub -x etc/dk/s/__SESSION__-stage-index.sig -m etc/dk/s/__SESSION__-stage-index.txt",
    "          sha256sum -c etc/dk/s/__SESSION__-stage-index.txt",
    "          argv_file='etc/dk/s/__SESSION__-argv.txt'",
    "          test -s \"$argv_file\"",
    "          argv_count=0",
    "          while IFS= read -r encoded; do",
    "            [ -n \"$encoded\" ]",
    "            printf '%s' \"$encoded\" | grep -Eq '^[A-Za-z0-9+/=]+$'",
    "            printf '%s' \"$encoded\" | base64 -d >/dev/null",
    "            argv_count=$((argv_count + 1))",
    "          done < \"$argv_file\"",
    "          [ \"$argv_count\" -ge 1 ]",
    "          echo \"tag=$tag\" >> \"$GITHUB_OUTPUT\"",
    "          echo \"phase=$phase\" >> \"$GITHUB_OUTPUT\"",
    "      - name: Print remote command",
    "        if: steps.phase.outputs.phase == 'stage' || steps.phase.outputs.phase == 'exec'",
    "        shell: bash",
    "        run: |",
    "          audit_line=\"$(tail -n 1 etc/dk/s/__SESSION__-audit.txt)\"",
    "          printf 'Remote command: %s\\n' \"${audit_line#*Z }\"",
    "      - name: Create stage prerelease",
    "        if: steps.phase.outputs.phase == 'stage'",
    "        env:",
    "          GH_TOKEN: ${{ github.token }}",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          tag='${{ steps.phase.outputs.tag }}'",
    "          notes=\"$(tail -n 1 etc/dk/s/__SESSION__-audit.txt)\"",
    "          gh release view \"$tag\" >/dev/null 2>&1 || \\",
    "            gh release create \"$tag\" --prerelease --title \"$tag\" --notes \"$notes\"",
    "      - name: Verify INDEX signature",
    "        if: steps.phase.outputs.phase == 'exec'",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          ./.dk-remote/bin/mlfront-signify -V -p t/k/build.pub -x INDEX.sig -m INDEX",
    "          sha256sum -c INDEX",
    "      - name: Execute remote command",
    "        if: steps.phase.outputs.phase == 'exec'",
    "        id: exec",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          chmod +x ./dk0 2>/dev/null || true",
    "          argv=()",
    "          while IFS= read -r encoded; do",
    "            arg=\"$(printf '%s' \"$encoded\" | base64 -d)\"",
    "            argv+=(\"$arg\")",
    "          done < etc/dk/s/__SESSION__-argv.txt",
    "          [ \"${#argv[@]}\" -ge 1 ]",
    "          set +e",
    "          ./dk0 \"${argv[@]}\" >dk-session-stdout.txt 2>dk-session-stderr.txt",
    "          code=$?",
    "          set -e",
    "          printf '%s\\n' \"$code\" > dk-session-exit-code.txt",
    "          zip -q -j dk-session-result.zip dk-session-stdout.txt dk-session-stderr.txt dk-session-exit-code.txt",
    "          echo \"code=$code\" >> \"$GITHUB_OUTPUT\"",
    "          exit 0",
    "      - name: Publish exec prerelease",
    "        if: steps.phase.outputs.phase == 'exec'",
    "        env:",
    "          GH_TOKEN: ${{ github.token }}",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          tag='${{ steps.phase.outputs.tag }}'",
    "          notes=\"exit=${{ steps.exec.outputs.code }}\"",
    "          gh release view \"$tag\" >/dev/null 2>&1 || \\",
    "            gh release create \"$tag\" --prerelease --title \"$tag\" --notes \"$notes\" dk-session-result.zip",
    "          gh release upload \"$tag\" dk-session-result.zip --clobber",
    "      - name: Cleanup old dk-session prereleases",
    "        if: steps.phase.outputs.phase == 'stage' || steps.phase.outputs.phase == 'exec'",
    "        env:",
    "          GH_TOKEN: ${{ github.token }}",
    "        shell: bash",
    "        run: |",
    "          set -euo pipefail",
    "          gh release list --exclude-drafts --json tagName,isPrerelease,createdAt --jq '.[] | select(.isPrerelease and (.tagName|test(\"^0[.]1[.][0-9]{14}-(stage|exec)$\"))) | [.createdAt,.tagName] | @tsv' |",
    "            sort -r |",
    "            awk 'NR>__KEEP__ {print $2}' |",
    "            while read -r oldtag; do",
    "              [ -n \"$oldtag\" ] && gh release delete \"$oldtag\" --cleanup-tag --yes",
    "            done",
  }, "\n") .. "\n"
  template = CommonsBase_Remote__GitHub__0_1_0.replace_all(template, "__SESSION__", tostring(session))
  template = CommonsBase_Remote__GitHub__0_1_0.replace_all(template, "__KEEP__", tostring(keep))
  return template
end

function CommonsBase_Remote__GitHub__0_1_0.wait_release(request, ownerrepo, tag, p)
  local attempt = 1
  while attempt <= 12 do
    print("Polling GitHub release " .. tag .. " (" .. tostring(attempt) .. "/12)")
    local result = CommonsBase_Remote__GitHub__0_1_0.try_capture(
      request, p.gh, { "release", "view", tag, "-R", ownerrepo, "--json", "url" },
      { quiet = true })
    local url = CommonsBase_Remote__GitHub__0_1_0.json_string_field(result.stdout, "url") or ""
    if result.code == "0" and url ~= "" then
      print("GitHub release: " .. url)
      return
    end
    request.ui.sleep { seconds = 10 }
    attempt = attempt + 1
  end
  assert(false, "Timed out waiting for GitHub release " .. tag)
end

function CommonsBase_Remote__GitHub__0_1_0.workflow_base_name(workflow)
  local base = tostring(workflow or "")
  if string.sub(base, -4) == ".yml" then
    base = string.sub(base, 1, string.len(base) - 4)
  elseif string.sub(base, -5) == ".yaml" then
    base = string.sub(base, 1, string.len(base) - 5)
  end
  return base
end

function CommonsBase_Remote__GitHub__0_1_0.find_workflow_run(json_text)
  local segment = json_text or ""
  local status = CommonsBase_Remote__GitHub__0_1_0.json_string_field(segment, "status")
  local conclusion = CommonsBase_Remote__GitHub__0_1_0.json_string_field(segment, "conclusion") or ""
  local url = CommonsBase_Remote__GitHub__0_1_0.json_string_field(segment, "url")
  if not status and (not url or url == "") then
    return nil
  end
  return { status = status, conclusion = conclusion, url = url }
end

function CommonsBase_Remote__GitHub__0_1_0.wait_workflow(request, ownerrepo, branch, workflow, p)
  local attempt = 1
  while attempt <= 60 do
    print("Polling GitHub workflow " .. workflow .. " on " .. branch .. " (" .. tostring(attempt) .. "/60)")
    local result = CommonsBase_Remote__GitHub__0_1_0.try_capture(
      request,
      p.gh,
      {
        "run", "list", "-R", ownerrepo, "--branch", branch, "--event", "push",
        "--limit", "20", "--json", "workflowName,status,conclusion,url"
      },
      { quiet = true })
    local combined = (result.stdout or "") .. "\n" .. (result.stderr or "")
    if result.code == "0" then
      local found = CommonsBase_Remote__GitHub__0_1_0.find_workflow_run(combined)
      if found then
        print("GitHub workflow status: " .. tostring(found.status) .. " conclusion: " .. tostring(found.conclusion))
        if found.url and found.url ~= "" then
          print("GitHub workflow: " .. found.url)
        end
        if found.status and found.status == "completed" then
          assert(found.conclusion == "success", "GitHub workflow " .. workflow .. " on " .. branch .. " completed with " .. tostring(found.conclusion))
          return
        end
      else
        local out = CommonsBase_Remote__GitHub__0_1_0.trim(combined)
        local err = CommonsBase_Remote__GitHub__0_1_0.trim(result.stderr or "")
        if out ~= "" then
          print("GitHub workflow poll stdout (first 200): " .. string.sub(out, 1, 200))
        else
          print("GitHub workflow poll: empty output (code=" .. tostring(result.code) .. ")")
        end
        if err ~= "" then
          print("GitHub workflow poll stderr (first 200): " .. string.sub(err, 1, 200))
        end
      end
    else
      local msg = CommonsBase_Remote__GitHub__0_1_0.trim(result.stderr or "")
      if msg ~= "" then
        print("GitHub workflow poll command failed with exit " .. tostring(result.code) .. ": " .. msg)
      else
        print("GitHub workflow poll command failed with exit " .. tostring(result.code) .. " (no stderr)")
      end
    end
    request.ui.sleep { seconds = 10 }
    attempt = attempt + 1
  end
  assert(false, "Timed out waiting for workflow " .. workflow .. " on " .. branch)
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_repo(request, ownerrepo, p)
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.gh, { "auth", "status" }, { quiet = true })
  if p.create_repo then
    local created = CommonsBase_Remote__GitHub__0_1_0.try_capture(
      request, p.gh, { "repo", "create", ownerrepo, "--private", "--confirm" }, { quiet = true })
    if created.code == "0" or string.find(created.stderr or "", "Name already exists on this account", 1, true) then
      return
    end
    assert(false, "Could not create private repository " .. ownerrepo .. ": " .. CommonsBase_Remote__GitHub__0_1_0.trim(created.stderr))
  end
  local view = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request, p.gh, { "repo", "view", ownerrepo, "--json", "nameWithOwner", "--jq", ".nameWithOwner" },
    { quiet = true })
  assert(view.code == "0", "Repository " .. ownerrepo .. " does not exist or is not visible; rerun with create_repo=true to create a private repository")
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_commit_repo(request, ownerrepo, commit_dir, coreutils, p)
  local repo_ok = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    { "-C", commit_dir, "rev-parse", "--git-dir" },
    { quiet = true, allowfailure = true })
  if repo_ok.code ~= "0" then
    CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "init", commit_dir })
  end
  local add_origin = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    { "-C", commit_dir, "remote", "add", "origin", "https://github.com/" .. ownerrepo .. ".git" },
    { quiet = true, allowfailure = true })
  if add_origin.code ~= "0" then
    CommonsBase_Remote__GitHub__0_1_0.capture(
      request,
      p.git,
      { "-C", commit_dir, "remote", "set-url", "origin", "https://github.com/" .. ownerrepo .. ".git" })
  end
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "config", "user.name", "dk remote session" }, { quiet = true })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "config", "user.email", "dk-remote-session@users.noreply.github.com" }, { quiet = true })
  CommonsBase_Remote__GitHub__0_1_0.try_capture(request, p.git, { "-C", commit_dir, "fetch", "origin", "--prune", "--tags" }, { quiet = true, allowfailure = true })
end

function CommonsBase_Remote__GitHub__0_1_0.commit_repo_gitignore_text()
  return table.concat({
    "# Local-only isolated commit-repo state",
    "t/k/build.sec",
    "t/c/",
    "t/d/",
    ".local",
    ""
  }, "\n")
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_commit_repo_gitignore(request, coreutils, commit_dir)
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(
    request,
    coreutils,
    commit_dir .. "/.gitignore",
    CommonsBase_Remote__GitHub__0_1_0.commit_repo_gitignore_text(),
    "0644")
end

function CommonsBase_Remote__GitHub__0_1_0.reset_commit_repo_worktree(request, commit_dir, p)
  CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    { "-C", commit_dir, "restore", "--staged", "--worktree", "--source=HEAD", "--", "." },
    { quiet = true, allowfailure = true })
  CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    {
      "-C", commit_dir, "clean", "-f", "-d", "--",
      ".github/workflows",
      ".gitignore",
      "dk.u",
      "dk0",
      "dk0.cmd",
      "etc/dk",
      "INDEX",
      "INDEX.sig",
      "t/k/build.pub"
    },
    { quiet = true, allowfailure = true })
end

function CommonsBase_Remote__GitHub__0_1_0.stash_commit_repo_changes(request, commit_dir, p)
  local status = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request,
    p.git,
    { "-C", commit_dir, "status", "--porcelain=v1", "--untracked-files=all" },
    { quiet = true, allowfailure = true })
  if CommonsBase_Remote__GitHub__0_1_0.trim(status.stdout) == "" then
    return
  end
  CommonsBase_Remote__GitHub__0_1_0.capture(
    request,
    p.git,
    { "-C", commit_dir, "stash", "push", "--all", "--message", "dk remote pre-sync" })
end

function CommonsBase_Remote__GitHub__0_1_0.ensure_branches(request, commit_dir, sessions, p)
  CommonsBase_Remote__GitHub__0_1_0.reset_commit_repo_worktree(request, commit_dir, p)
  local has_root = CommonsBase_Remote__GitHub__0_1_0.try_capture(
    request, p.git, { "-C", commit_dir, "ls-remote", "--heads", "origin", "dk-session-root" },
    { quiet = true })
  if CommonsBase_Remote__GitHub__0_1_0.trim(has_root.stdout) == "" then
    CommonsBase_Remote__GitHub__0_1_0.try_capture(request, p.git, { "-C", commit_dir, "checkout", "--orphan", "dk-session-root" })
    CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "commit", "--allow-empty", "-m", "Create dk-session root" })
    CommonsBase_Remote__GitHub__0_1_0.try_capture(request, p.git, { "-C", commit_dir, "branch", "-M", "dk-session-root" })
    CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "-u", "origin", "HEAD:refs/heads/dk-session-root" })
  else
    CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "checkout", "-B", "dk-session-root", "origin/dk-session-root" })
  end
  local i = 1
  while i <= sessions do
    local branch = "dk-session-" .. tostring(i)
    local has_branch = CommonsBase_Remote__GitHub__0_1_0.try_capture(
      request, p.git, { "-C", commit_dir, "ls-remote", "--heads", "origin", branch },
      { quiet = true })
    if CommonsBase_Remote__GitHub__0_1_0.trim(has_branch.stdout) == "" then
      CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "checkout", "-B", branch, "origin/dk-session-root" })
      CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "-u", "origin", "HEAD:refs/heads/" .. branch })
    end
    i = i + 1
  end
end

function CommonsBase_Remote__GitHub__0_1_0.select_session(request, ownerrepo, sessions, p)
  local order = {}
  local seed_source = ownerrepo .. ":" .. tostring(p.timestamp or "")
  local seed = 0
  local i = 1
  while i <= string.len(seed_source) do
    seed = seed + string.byte(seed_source, i)
    i = i + 1
  end
  local start = (seed % sessions) + 1
  i = 0
  while i < sessions do
    table.insert(order, ((start + i - 1) % sessions) + 1)
    i = i + 1
  end
  i = 1
  while order[i] do
    local session = order[i]
    local workflow = "dk-session." .. tostring(session) .. ".yml"
    local branch = "dk-session-" .. tostring(session)
    local running = CommonsBase_Remote__GitHub__0_1_0.try_capture(
      request,
      p.gh,
      {
        "run", "list", "-R", ownerrepo, "--branch", branch, "--status",
        "in_progress", "--limit", "20", "--json", "workflowName,status"
      },
      { quiet = true })
    local found = nil
    if running.code == "0" then
      local combined = (running.stdout or "") .. "\n" .. (running.stderr or "")
      found = CommonsBase_Remote__GitHub__0_1_0.find_workflow_run(combined)
    end
    if running.code ~= "0" or not found then
      return session
    end
    print("Session " .. tostring(session) .. " is busy; trying another session.")
    i = i + 1
  end
  assert(false, "No free dk remote GitHub session was available")
end

function CommonsBase_Remote__GitHub__0_1_0.write_checksum_manifest(request, clone_root, rel_paths, manifest_rel, coreutils)
  local lines = {}
  local i = 1
  while rel_paths[i] do
    local meta = request.ui.checksum { path = CommonsBase_Remote__GitHub__0_1_0.path_join(clone_root, rel_paths[i]) }
    table.insert(lines, meta.sha256 .. " *" .. rel_paths[i])
    i = i + 1
  end
  CommonsBase_Remote__GitHub__0_1_0.sort_strings(lines)
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(
    request,
    coreutils,
    CommonsBase_Remote__GitHub__0_1_0.path_join(clone_root, manifest_rel),
    table.concat(lines, "\n") .. "\n",
    "0644")
end

function CommonsBase_Remote__GitHub__0_1_0.sign_file(request, clone_root, message_rel, signature_rel)
  local signed, msg = request.ui.signify {
    operation = "sign",
    secret_key = CommonsBase_Remote__GitHub__0_1_0.path_join(clone_root, "t/k/build.sec"),
    message = CommonsBase_Remote__GitHub__0_1_0.path_join(clone_root, message_rel),
    signature = CommonsBase_Remote__GitHub__0_1_0.path_join(clone_root, signature_rel)
  }
  assert(signed, "Could not sign " .. message_rel .. ": " .. tostring(msg))
end

function CommonsBase_Remote__GitHub__0_1_0.download_result_zip(request, ownerrepo, tag, timestamp, p)
  local result_dir = ".dk/r/results/" .. timestamp
  local result_zip_rel = result_dir .. "/dk-session-result.zip"
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.gh, {
    "release", "download", tag, "-R", ownerrepo, "-D", result_dir,
    "-p", "dk-session-result.zip"
  })
  local metadata = request.ui.checksum { path = result_zip_rel }
  return result_zip_rel, metadata
end

function CommonsBase_Remote__GitHub__0_1_0.basename(path)
  local i = string.len(path)
  while i >= 1 do
    local ch = string.sub(path, i, i)
    if ch == "/" or ch == "\\" then
      return string.sub(path, i + 1)
    end
    i = i - 1
  end
  return path
end

function CommonsBase_Remote__GitHub__0_1_0.read_named_file(request, dir, name)
  local entries = request.io.list(dir, "all")
  local i = 1
  while entries[i] do
    local entry = entries[i]
    local rel = request.io.realpath(entry, { relative = 1 })
    if request.io.isfile(entry) and CommonsBase_Remote__GitHub__0_1_0.basename(rel) == name then
      local content = request.io.read(entry, "all") or ""
      request.io.close(entry)
      return content
    end
    request.io.close(entry)
    i = i + 1
  end
  return nil
end

function CommonsBase_Remote__GitHub__0_1_0.orchestrate_submit(request, p)
  local ownerrepo = CommonsBase_Remote__GitHub__0_1_0.ownerrepo(p.repo)
  CommonsBase_Remote__GitHub__0_1_0.resolve_programs(request, p)
  local timestamp = p.timestamp
  if timestamp == "19700101000000" then
    timestamp = CommonsBase_Remote__GitHub__0_1_0.now_utc(request, p)
  end
  local snapshot_dir = request.continued and request.continued.project_snapshot
  assert(snapshot_dir, "Expected a project snapshot from the submit phase")
  local coreutils = CommonsBase_Remote__GitHub__0_1_0.ensure_coreutils(request, snapshot_dir)
  local commit_dir = ".dk/r/c"

  CommonsBase_Remote__GitHub__0_1_0.ensure_repo(request, ownerrepo, p)
  CommonsBase_Remote__GitHub__0_1_0.ensure_control_tree(request, coreutils)
  CommonsBase_Remote__GitHub__0_1_0.ensure_commit_repo(request, ownerrepo, commit_dir, coreutils, p)
  CommonsBase_Remote__GitHub__0_1_0.ensure_branches(request, commit_dir, p.sessions, p)
  CommonsBase_Remote__GitHub__0_1_0.stash_commit_repo_changes(request, commit_dir, p)

  local selected = CommonsBase_Remote__GitHub__0_1_0.select_session(request, ownerrepo, p.sessions, p)
  local branch = "dk-session-" .. tostring(selected)
  local workflow = "dk-session." .. tostring(selected) .. ".yml"
  local stage_tag = "0.1." .. timestamp .. "-stage"
  local exec_tag = "0.1." .. timestamp .. "-exec"

  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "checkout", "-B", branch, "origin/" .. branch })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "pull", "--rebase", "origin", branch })
  CommonsBase_Remote__GitHub__0_1_0.ensure_commit_repo_gitignore(request, coreutils, commit_dir)

  local copied = CommonsBase_Remote__GitHub__0_1_0.prepare_commit_repo_inputs(request, snapshot_dir, p, coreutils)

  local audit_rel = "etc/dk/s/" .. tostring(selected) .. "-audit.txt"
  local argv_rel = "etc/dk/s/" .. tostring(selected) .. "-argv.txt"
  local stage_index_rel = "etc/dk/s/" .. tostring(selected) .. "-stage-index.txt"
  local stage_sig_rel = "etc/dk/s/" .. tostring(selected) .. "-stage-index.sig"
  local workflow_rel = ".github/workflows/" .. workflow
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(request, coreutils, commit_dir .. "/" .. audit_rel, timestamp .. "Z " .. p.commandvsl .. "\n", "0644")
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(
    request,
    coreutils,
    commit_dir .. "/" .. argv_rel,
    CommonsBase_Remote__GitHub__0_1_0.base64_lines_text(p.argv),
    "0644")
  CommonsBase_Remote__GitHub__0_1_0.write_project_text(
    request,
    coreutils,
    commit_dir .. "/" .. workflow_rel,
    CommonsBase_Remote__GitHub__0_1_0.workflow_yaml(selected, p.retention),
    "0644")
  CommonsBase_Remote__GitHub__0_1_0.write_checksum_manifest(request, commit_dir, { audit_rel, argv_rel, workflow_rel }, stage_index_rel, coreutils)
  CommonsBase_Remote__GitHub__0_1_0.sign_file(request, commit_dir, stage_index_rel, stage_sig_rel)
  CommonsBase_Remote__GitHub__0_1_0.capture(
    request,
    p.git,
    {
      "-C", commit_dir, "add",
      ".gitignore", audit_rel, argv_rel, stage_index_rel, stage_sig_rel, workflow_rel, "t/k/build.pub"
    })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "commit", "-m", "dk remote " .. timestamp .. " stage" })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "tag", stage_tag })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "origin", branch })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "origin", stage_tag })
  CommonsBase_Remote__GitHub__0_1_0.wait_workflow(request, ownerrepo, branch, workflow, p)
  CommonsBase_Remote__GitHub__0_1_0.wait_release(request, ownerrepo, stage_tag, p)

  local manifest_paths = {}
  local i = 1
  while copied[i] do
    table.insert(manifest_paths, copied[i])
    i = i + 1
  end
  table.insert(manifest_paths, audit_rel)
  table.insert(manifest_paths, argv_rel)
  table.insert(manifest_paths, stage_index_rel)
  table.insert(manifest_paths, stage_sig_rel)
  table.insert(manifest_paths, workflow_rel)
  table.insert(manifest_paths, ".gitignore")
  CommonsBase_Remote__GitHub__0_1_0.write_checksum_manifest(request, commit_dir, manifest_paths, "INDEX", coreutils)
  CommonsBase_Remote__GitHub__0_1_0.sign_file(request, commit_dir, "INDEX", "INDEX.sig")
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "add", "-A" })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "commit", "-m", "dk remote " .. timestamp .. " exec" })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "tag", exec_tag })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "origin", branch })
  CommonsBase_Remote__GitHub__0_1_0.capture(request, p.git, { "-C", commit_dir, "push", "origin", exec_tag })
  CommonsBase_Remote__GitHub__0_1_0.wait_workflow(request, ownerrepo, branch, workflow, p)
  CommonsBase_Remote__GitHub__0_1_0.wait_release(request, ownerrepo, exec_tag, p)
  local result_zip_rel, result_zip_meta =
    CommonsBase_Remote__GitHub__0_1_0.download_result_zip(request, ownerrepo, exec_tag, timestamp, p)
  local bundle_id = "CommonsBase_Remote.GitHub.Result." .. request.rule.generatesymbol() .. "@0.1.0"
  if snapshot_dir then
    request.io.close(snapshot_dir)
  end
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        bundles = {
          {
            id = bundle_id,
            listing = {
              origins = {
                {
                  name = "project-tree",
                  mirrors = { "cell://root" }
                }
              }
            },
            assets = {
              {
                origin = "project-tree",
                path = result_zip_rel,
                size = result_zip_meta.size,
                checksum = {
                  sha256 = result_zip_meta.sha256
                }
              }
            }
          }
        }
      },
      expressions = {
        directories = {
          remote_result_dir = "$(get-asset " .. bundle_id .. " -p " .. result_zip_rel .. " -d :)"
        },
        strings = {
          remote_result_tag = exec_tag
        }
      }
    }
  }
end

function CommonsBase_Remote__GitHub__0_1_0.present_result(request)
  local result_dir = assert(request.continued and request.continued.remote_result_dir, "Expected fetched remote result directory")
  local stdout_text = CommonsBase_Remote__GitHub__0_1_0.read_named_file(request, result_dir, "stdout.txt")
  local stderr_text = CommonsBase_Remote__GitHub__0_1_0.read_named_file(request, result_dir, "stderr.txt")
  local exit_code_text = CommonsBase_Remote__GitHub__0_1_0.read_named_file(request, result_dir, "exit-code.txt")
  if stdout_text and stdout_text ~= "" then
    print("----- remote stdout -----")
    print(stdout_text)
  end
  if stderr_text and stderr_text ~= "" then
    print("----- remote stderr -----")
    print(stderr_text)
  end
  request.io.close(result_dir)
  local exit_code = tonumber(CommonsBase_Remote__GitHub__0_1_0.trim(exit_code_text or "0")) or 0
  assert(exit_code == 0, "Remote command exited with code " .. tostring(exit_code))
end

function rules.F_DryRunPlan(command, request)
  local p = CommonsBase_Remote__GitHub__0_1_0.parse_common_args(request)
  local path = "dry-run.txt"
  if not p.dryrun then
    error("Only `dry_run=true` is implemented for CommonsBase_Remote.GitHub.F_DryRunPlan@0.1.0")
  end
  if command == "declareoutput" then
    return {
      declareoutput = {
        return_asset = {
          id = "CommonsBase_Remote.GitHub.F_DryRunPlan.Output." .. request.rule.generatesymbol() .. "@0.1.0",
          path = path
        }
      }
    }
  elseif command == "submit" then
    local file = request.io.open(path, "w")
    CommonsBase_Remote__GitHub__0_1_0.write_plan(request, file, p, "F_DryRunPlan")
    local origin, asset = request.io.toasset(file, {
      path = path,
      origin_name = "CommonsBase_Remote"
    })
    return {
      submit = {
        values = {
          schema_version = { major = 1, minor = 0 },
          bundles = {
            {
              id = request.submit.outputid,
              listing = { origins = { origin } },
              assets = { asset }
            }
          }
        }
      }
    }
  end
end

function uirules.Run(command, request, continue_)
  local p = CommonsBase_Remote__GitHub__0_1_0.parse_common_args(request)
  if command == "submit" then
    if p.dryrun then
      local bundle, getbundle = request.ui.glob {
        trace = 0,
        cell = "root",
        patterns = { "README.md" }
      }
      return {
        submit = {
          values = {
            schema_version = { major = 1, minor = 0 },
            bundles = { bundle }
          },
          expressions = {
            directories = {
              dry_run_complete = "$(" .. getbundle .. " -d :)"
            }
          }
        }
      }
    end
    if continue_ == nil or continue_ == "start" then
      local bundle, getbundle = request.ui.glob {
        trace = 0,
        cell = "root",
        patterns = {
          p.workspace,
          "dk0",
          "dk0.cmd",
          "etc/dk/d/**",
          "etc/dk/i/**",
          "etc/dk/v/**",
          "t/k/build.sec",
          "t/k/build.pub"
        },
        excludes = { ".dk/**", ".git", ".git/**", "_build/**", "remote-github/**", "dk-session-results-*/**" }
      }
      return {
        submit = {
          values = {
            schema_version = { major = 1, minor = 0 },
            bundles = { bundle }
          },
          expressions = {
            directories = {
              project_snapshot = "$(" .. getbundle .. " -d :)"
            },
            strings = {
              create_repo = p.create_repo and "true" or "false",
              dry_run = p.dryrun and "true" or "false"
            }
          },
          andthen = {
            continue_ = {
              state = "orchestrate"
            }
          }
        }
      }
    elseif continue_ == "orchestrate" then
      return CommonsBase_Remote__GitHub__0_1_0.orchestrate_submit(request, p)
    else
      assert(false, "Unsupported continuation state `" .. tostring(continue_) .. "`")
    end
  elseif command == "ui" then
    if p.dryrun then
      local file = request.io.open("dry-run-plan.txt", "w")
      CommonsBase_Remote__GitHub__0_1_0.write_plan(request, file, p, "Run")
      request.io.close(file)
      file = request.io.open("dry-run-plan.txt", "r")
      local text = request.io.read(file, "all")
      request.io.close(file)
      print(text)
      request.io.flush()
      if request.continued and request.continued.dry_run_complete then
        request.io.close(request.continued.dry_run_complete)
      end
    else
      CommonsBase_Remote__GitHub__0_1_0.present_result(request)
    end
  end
end

return M
