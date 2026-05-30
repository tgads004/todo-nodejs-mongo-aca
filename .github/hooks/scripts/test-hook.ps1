$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"
# Escape backslashes for JSON
$projEscaped = $proj -replace '\\', '\\\\'
$json = "{`"tool`":{`"name`":`"replace_string_in_file`",`"parameters`":{`"filePath`":`"$projEscaped\\\\src\\\\api\\\\src\\\\routes\\\\lists.ts`"}}}"
$json | pwsh -NoProfile -File "$proj\.github\hooks\scripts\test-coverage-check.ps1"
