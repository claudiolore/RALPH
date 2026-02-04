param(
    [int]$iterations = 10
)

if ($iterations -eq 0) {
    Write-Host "Usage: .\ralph.ps1 <iterations>"
    exit 1
}

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Iteration $i"
    Write-Host "--------------------------------"

    $prompt = @"
@prd.json @progress.txt
1. Find the highest-priority feature to work on and work only on that feature. This should be the one YOU decide has the highest priority - not necessarily the first in the list.
2. Check that the types check via npm run typecheck and that the tests pass via npm run test.
3. Update the PRD with the work that was done.
4. Append your progress to the progress.txt file. Use this to leave a note for the next person working in the codebase.
5. Make a git commit of that feature.
ONLY WORK ON A SINGLE FEATURE.
If, while implementing the feature, you notice the PRD is complete, output <promise>COMPLETE</promise>.
"@

    $result = docker sandbox run claude --permission-mode acceptEdits -p $prompt 2>&1

    Write-Host $result

    if ($result -match "<promise>COMPLETE</promise>") {
        Write-Host "PRD complete, exiting."
        exit 0
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Claude exited with error code: $LASTEXITCODE"
    }
}
