# chezmoi.nu
# chezmoi completions for nushell
#
# ```sh
# ~> chezmoi __complete
# chezmoi: requires at least 1 arg(s), only received 0
# ~> chezmoi __complete a
# add     Add an existing file, directory, or symlink to the source state
# age     Interact with age
# age-keygen      Generate an age identity or convert an age identity to an age recipient
# apply   Update the destination directory to match the target state
# archive Generate a tar archive of the target state
# :4
# Completion ended with directive: ShellCompDirectiveNoFileComp
# ~> chezmoi __complete add
# add     Add an existing file, directory, or symlink to the source state
# :4
# Completion ended with directive: ShellCompDirectiveNoFileComp
# ~> chezmoi __complete l
# license Print license
# :4
# Completion ended with directive: ShellCompDirectiveNoFileComp
# ```
###
# def get_chezmoi_completions (context: string, offset: int) {
#     let args_for_chezmoi = if ($args | length) > 0 { $args } else { [""] }
#
#     let result = (^chezmoi __complete ...$args_for_chezmoi | complete).stdout
#         | lines
# 		| drop
# 		| split column "\t"
# 		| rename value description
#
# 	[$result]
#
# }

def "nu-complete chezmoi" [context: string] {
    
	# "chezmoi a" ==> ["a"]
    let args = $context | split words | skip
    
	# if args = null ==> show all completions
	# "chezmoi" ==> show all completions
	let words = if ($args | length) > 0 { $args } else { [""] }
	
    let $result = (^chezmoi __complete ...$words | complete).stdout
        | lines
        | drop
        | split column "\t"
        | rename value description
		# result:
		# ╭───┬────────────┬─────────────────────────────────────────────────────────────────────────╮
		# │ # │   value    │                               description                               │
		# ├───┼────────────┼─────────────────────────────────────────────────────────────────────────┤
		# │ 0 │ add        │ Add an existing file, directory, or symlink to the source state         │
		# │ 1 │ age        │ Interact with age                                                       │
		# │ 2 │ age-keygen │ Generate an age identity or convert an age identity to an age recipient │
		# │ 3 │ apply      │ Update the destination directory to match the target state              │
		# │ 4 │ archive    │ Generate a tar archive of the target state                              │
		# ╰───┴────────────┴─────────────────────────────────────────────────────────────────────────╯
	# return completions
	{
        options: {
            sort: false,
            completion_algorithm: substring,
            case_sensitive: false,
        },
        completions: $result,
    }
}

export extern "chezmoi" [
    ...args: string@"nu-complete chezmoi"
]

export extern "chezmoi add" [
    ...args: string
]

export extern "chezmoi apply" [
    ...args: string
]

export extern "chezmoi cd" [
    ...args: string
]
