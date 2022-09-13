library(nomnoml)

mturk_activity <- "
[<start> start] -> [<sender> /mturk]
[<sender> /mturk] ->
[<end> end]
"

mturk_activity_diagram <- nomnoml(mturk_activity)
mturk_activity_diagram
