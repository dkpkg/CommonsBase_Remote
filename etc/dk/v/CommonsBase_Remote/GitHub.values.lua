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
  local create_repo = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.create_repo)
  local dry_run = CommonsBase_Remote__GitHub__0_1_0.user_scalar(request.user.dry_run)
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
    workflow_path = ".github/workflows/dk-session." .. tostring(session_number) .. ".yml",
    audit_path = "etc/dk/s/" .. tostring(session_number) .. "-audit.txt",
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
  request.io.write(file, "workflow_comment=Orchestration Version: " .. plan.orchestration_date .. "\n")
  request.io.write(file, "audit_path=" .. plan.audit_path .. "\n")
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

function CommonsBase_Remote__GitHub__0_1_0.handle_run(command, request, rule_name)
  local p = CommonsBase_Remote__GitHub__0_1_0.parse_common_args(request)
  if not p.dryrun then
    error("Only `dry_run=true` is implemented for CommonsBase_Remote.GitHub." .. rule_name .. "@0.1.0")
  end

  if command == "submit" then
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
  elseif command == "ui" then
    CommonsBase_Remote__GitHub__0_1_0.print_plan(p)
    request.io.flush()
    if request.continued and request.continued.dry_run_complete then
      request.io.close(request.continued.dry_run_complete)
    end
  end
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

function uirules.Run(command, request)
  local p = CommonsBase_Remote__GitHub__0_1_0.parse_common_args(request)
  if not p.dryrun then
    error("Only `dry_run=true` is implemented for CommonsBase_Remote.GitHub.Run@0.1.0")
  end
  if command == "submit" then
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
  elseif command == "ui" then
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
  end
end

return M
