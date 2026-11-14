# under @narrow@ columns the prompt is just the directory
function __starship_fit --on-variable COLUMNS
    if test "$COLUMNS" -lt @narrow@
        set -gx STARSHIP_CONFIG @narrowConfig@
    else
        set -gx STARSHIP_CONFIG @fullConfig@
    end
end
__starship_fit
