let autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
for $i in $autoload_dir {
	if ($i | path exists) {
		let $files = ( (ls $i | where name =~ '.nu$').name | path expand)
		# print $files
		for $file in $files {rm $file -v}
	} else { print $"Directory not found: ($i)"}
}
