import Page
import View

main! = |args| {
	echo!(Str.join_with(Page.greet(args.len()), ","))
	Ok({})
}
