.onAttach <- function(libname, pkgname) {
    packageStartupMessage("contextR loaded. Default backend: mock (no network).")
    packageStartupMessage("Use context_backend_set('ollama', model = 'mistral') or context_backend_set('openai', model = 'gpt-4o-mini') for real backends.")
}
