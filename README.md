# serviceability
Repository for useful serviceability files, e.g. scripts we'll advise users to run, any Dockerfiles if we containerise them, any particularly useful snippets

## Must-gather usage

`./must-gather.sh`

With no parameters this script gathers Microclimate installation information, including logs. The findings are saved to a file in the current directory.

The following optional parameters can be provided.

`-n`: the namespace you have installed Microclimate in, for example: `./must-gather.sh -n myothernamespace`. Defaults to `default`.

`-r`: the Helm release name for Microclimate, for example: `./must-gather.sh -r mymicroclimaterelease`. Defaults to `microclimate`.

`-o`: the desired output location for the file this script creates, for example: `./must-gather.sh -o $HOME/myoutputfile.txt`. Defaults to `microclimate-default-date-logs.txt` where the naming pattern consists of the Microclimate release name first, followed by the namespace it is installed into.

`-t`: the tiller namespace to use for any Helm commands, for example: `./must-gather.sh -t myothernamespace`. Defaults to `kube-system`.

`-s`: to add SSL/TLS `(--tls)` to all helm commands, for example: `./must-gather.sh -s`.
