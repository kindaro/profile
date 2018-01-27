TODO
====

There are two approaches to generalizing this.
----------------------------------------------

1. Why do I give a, basically, module name as an argument? This is simplistic. This approach is
   useful for small experiments, but with packages I should do something more elaborate, like
   running a benchmark, or adding a benchmark to package.yaml and running it... Or maybe just
   running a benchmark!

   Can I add ghc flags to `stack build`? Can I then add flags to `stack exec`? This is pretty much
   all I need to launch an ad-hoc profiling session.

2. What do I do about comparing separate build trees with differing `stack.yaml` files, like for
   testing different compiler versions? This is essential.

   Where do I store `stack.yaml`s? Who writes them?
