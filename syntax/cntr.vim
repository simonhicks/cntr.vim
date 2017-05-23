
syntax match cntr_comment /^#.*/
syntax match cntr_definition /^[a-zA-Z_][a-zA-Z_]*\ze=[^[:space:]][^[:space:]]*/
syntax match cntr_definition /^=[^[:space:]]*/
syntax match cntr_variable /%[^[:space:]][^[:space:]]*/
syntax match cntr_variable /$[a-zA-Z_][a-zA-Z_]*/
syntax match cntr_singlequote_string /'[^']*'/
syntax match cntr_doublequote_string /"\(\\"\|[^"]\)*"/
syntax match cntr_todo /TODO\|FIXME/ containedin=cntr_comment
syntax match cntr_string_expression_substitution /\$([^)]*)/ containedin=cntr_doublequote_string
syntax match cntr_string_expression_substitution /`[^`]*`/ containedin=cntr_doublequote_string

hi def link cntr_comment Comment
hi def link cntr_todo Todo
hi def link cntr_definition Special
hi def link cntr_variable Identifier
hi def link cntr_doublequote_string String
hi def link cntr_singlequote_string String
hi def link cntr_string_expression_substitution Special
